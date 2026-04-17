import 'dart:async' show unawaited;
import 'dart:io' show Directory, Platform;
import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/widgets.dart' show WidgetsFlutterBinding;
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart' show getApplicationDocumentsDirectory;
import 'package:whitenoise/services/notification_service.dart';
import 'package:whitenoise/services/notification_subscription.dart';
import 'package:whitenoise/src/rust/api.dart' as rust_api;
import 'package:whitenoise/src/rust/api/utils.dart' as rust_utils;
import 'package:whitenoise/src/rust/frb_generated.dart';

final _logger = Logger('ForegroundService');

const _kTaskEventKey = 'event';
const _kEventMainStarted = 'main_started';
const _kEventMainStopped = 'main_stopped';

// coverage:ignore-start
@pragma('vm:entry-point')
void _startCallback() {
  // Task handler runs in its own Dart isolate; forward only this file's
  // logger to logcat so task-side logs are visible during development.
  // Gated to debug builds so boot/package-replaced events don't emit
  // process state to production logcat.
  if (kDebugMode) {
    Logger.root.onRecord.listen((record) {
      if (record.loggerName != 'ForegroundService' &&
          record.loggerName != 'NotificationSubscription') {
        return;
      }
      final buf = StringBuffer('[${record.level.name}] ${record.loggerName}: ${record.message}');
      if (record.error != null) buf.write(' | error: ${record.error}');
      debugPrint(buf.toString());
    });
  }
  FlutterForegroundTask.setTaskHandler(_NotificationTaskHandler());
}

/// Task handler that runs inside the foreground-task background isolate.
///
/// On [TaskStarter.system] starts (boot / package-replaced), the main
/// UI isolate isn't running, so we own the notification subscription.
///
/// On [TaskStarter.developer] starts (main isolate called
/// `foregroundService.start()`), the main isolate is driving its own
/// subscription — we stay idle until it tells us otherwise.
///
/// The main isolate coordinates via [FlutterForegroundTask.sendDataToTask]:
/// `{'event': 'main_started'}` → we stop our subscription.
/// `{'event': 'main_stopped'}` → we start our subscription.
class _NotificationTaskHandler extends TaskHandler {
  NotificationSubscription? _subscription;
  Locale _cachedLocale = const Locale('en');
  bool _bootstrapped = false;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _logger.info('Foreground task started: ${starter.name}');

    _bootstrapped = await _bootstrapIsolate();
    if (!_bootstrapped) return;

    _cachedLocale = await _loadLocale();

    if (starter == TaskStarter.system) {
      await _startSubscription();
    } else {
      _logger.info('Task started by main isolate; awaiting coordination message');
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  void onReceiveData(Object data) {
    if (data is! Map) return;
    final event = data[_kTaskEventKey];
    if (event == _kEventMainStarted) {
      _logger.info('Received main_started — yielding subscription');
      unawaited(_stopSubscription());
    } else if (event == _kEventMainStopped) {
      _logger.info('Received main_stopped — taking over subscription');
      unawaited(_startSubscription());
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    _logger.info('Foreground task destroyed (isTimeout: $isTimeout)');
    await _stopSubscription();
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp();
  }

  @override
  void onNotificationButtonPressed(String id) {}

  @override
  void onNotificationDismissed() {}

  /// Initializes Flutter bindings, Rust FFI, and the whitenoise singleton
  /// inside this isolate. Idempotent — if the main isolate already
  /// initialized whitenoise, we accept the "already initialized" error.
  Future<bool> _bootstrapIsolate() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await RustLib.init();

      final dir = await getApplicationDocumentsDirectory();
      final dataDir = '${dir.path}/whitenoise/data';
      final logsDir = '${dir.path}/whitenoise/logs';
      await Directory(dataDir).create(recursive: true);
      await Directory(logsDir).create(recursive: true);

      try {
        final config = await rust_api.createWhitenoiseConfig(
          dataDir: dataDir,
          logsDir: logsDir,
        );
        await rust_api.initializeWhitenoise(config: config);
        _logger.info('Initialized whitenoise singleton in task isolate');
      } catch (e, st) {
        final msg = e.toString().toLowerCase();
        if (msg.contains('already')) {
          _logger.fine('whitenoise already initialized by another isolate');
        } else {
          _logger.severe('Failed to initialize whitenoise in task isolate', e, st);
          return false;
        }
      }
      return true;
    } catch (e, st) {
      _logger.severe('Failed to bootstrap task isolate', e, st);
      return false;
    }
  }

  Future<void> _startSubscription() async {
    if (!_bootstrapped) {
      _logger.warning('Cannot start subscription: bootstrap failed earlier');
      return;
    }
    if (_subscription != null) return;

    final notificationService = NotificationService(
      onNotificationTap: (_, _, _) {
        // Headless tap: just launch the app. Deep-link routing is
        // tracked in #488.
        FlutterForegroundTask.launchApp();
      },
    );
    final sub = NotificationSubscription(
      notificationService: notificationService,
      getActiveChatId: () => null,
      getLocale: () => _cachedLocale,
    );
    _subscription = sub;
    await sub.start();
    _logger.info('Headless notification subscription started');
  }

  Future<void> _stopSubscription() async {
    final sub = _subscription;
    if (sub == null) return;
    _subscription = null;
    await sub.stop();
    _logger.info('Headless notification subscription stopped');
  }

  Future<Locale> _loadLocale() async {
    try {
      final settings = await rust_api.getAppSettings();
      final language = await rust_api.appSettingsLanguage(appSettings: settings);
      final code = rust_utils.languageToString(language: language);
      const supported = ['en', 'es', 'fr', 'de', 'it', 'pt', 'ru', 'tr'];
      if (code == 'system' || code.isEmpty || !supported.contains(code)) {
        return const Locale('en');
      }
      return Locale(code);
    } catch (e, st) {
      _logger.warning('Failed to load locale; falling back to en', e, st);
      return const Locale('en');
    }
  }
}

class ForegroundTaskApi {
  void initCommunicationPort() => FlutterForegroundTask.initCommunicationPort();

  void init({
    required AndroidNotificationOptions androidNotificationOptions,
    required IOSNotificationOptions iosNotificationOptions,
    required ForegroundTaskOptions foregroundTaskOptions,
  }) => FlutterForegroundTask.init(
    androidNotificationOptions: androidNotificationOptions,
    iosNotificationOptions: iosNotificationOptions,
    foregroundTaskOptions: foregroundTaskOptions,
  );

  Future<bool> get isRunningService => FlutterForegroundTask.isRunningService;

  Future<ServiceRequestResult> startService({
    required int serviceId,
    required String notificationTitle,
    required String notificationText,
    required Function callback,
  }) => FlutterForegroundTask.startService(
    serviceId: serviceId,
    notificationTitle: notificationTitle,
    notificationText: notificationText,
    callback: callback,
  );

  Future<ServiceRequestResult> stopService() => FlutterForegroundTask.stopService();

  Future<bool> get isIgnoringBatteryOptimizations =>
      FlutterForegroundTask.isIgnoringBatteryOptimizations;

  Future<bool> requestIgnoreBatteryOptimization() =>
      FlutterForegroundTask.requestIgnoreBatteryOptimization();

  void sendDataToTask(Object data) => FlutterForegroundTask.sendDataToTask(data);
}
// coverage:ignore-end

class ForegroundService {
  ForegroundService({bool? enabled, ForegroundTaskApi? api})
    : _enabled = enabled ?? Platform.isAndroid,
      _api = api ?? ForegroundTaskApi(); // coverage:ignore-line

  final bool _enabled;
  final ForegroundTaskApi _api;
  bool _initialized = false;

  static const _serviceId = 888;
  static const _channelId = 'whitenoise_foreground';
  static const _channelName = 'White Noise';

  Future<void> initialize() async {
    if (!_enabled) return;
    if (_initialized) return;

    _api.initCommunicationPort();

    _api.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: _channelId,
        channelName: _channelName,
        channelDescription: 'Keeps White Noise connected to receive messages',
        visibility: NotificationVisibility.VISIBILITY_SECRET,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(60000),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
      ),
    );

    _initialized = true;
    _logger.info('ForegroundService initialized');
  }

  Future<void> start() async {
    if (!_enabled) return;

    if (!_initialized) {
      await initialize();
    }

    if (await _api.isRunningService) {
      _logger.info('Foreground service already running');
      return;
    }

    final result = await _api.startService(
      serviceId: _serviceId,
      notificationTitle: 'White Noise',
      notificationText: 'Connected to relays',
      callback: _startCallback,
    );

    if (result is ServiceRequestSuccess) {
      _logger.info('Foreground service started');
    } else {
      _logger.warning('Failed to start foreground service: $result');
    }
  }

  Future<void> stop() async {
    if (!_enabled) return;

    final result = await _api.stopService();
    if (result is ServiceRequestSuccess) {
      _logger.info('Foreground service stopped');
    } else {
      _logger.warning('Failed to stop foreground service: $result');
    }
  }

  Future<bool> get isRunning async {
    if (!_enabled) return false;
    return _api.isRunningService;
  }

  Future<void> requestBatteryOptimizationExemption() async {
    if (!_enabled) return;

    if (!await _api.isIgnoringBatteryOptimizations) {
      await _api.requestIgnoreBatteryOptimization();
    }
  }

  /// Notifies the task isolate that the main isolate has taken over the
  /// notification subscription — the task should yield.
  Future<void> notifyMainStarted() async {
    if (!_enabled) return;
    if (!await _api.isRunningService) return;
    _api.sendDataToTask(const {_kTaskEventKey: _kEventMainStarted});
  }

  /// Notifies the task isolate that the main isolate is releasing the
  /// subscription — the task should take over.
  Future<void> notifyMainStopped() async {
    if (!_enabled) return;
    if (!await _api.isRunningService) return;
    _api.sendDataToTask(const {_kTaskEventKey: _kEventMainStopped});
  }
}
