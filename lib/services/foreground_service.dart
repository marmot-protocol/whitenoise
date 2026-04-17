import 'dart:io' show Directory, Platform;

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/widgets.dart' show WidgetsFlutterBinding;
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart' show getApplicationDocumentsDirectory;
import 'package:whitenoise/src/rust/api.dart' as rust_api;
import 'package:whitenoise/src/rust/api/accounts.dart' as accounts_api;
import 'package:whitenoise/src/rust/frb_generated.dart';

final _logger = Logger('ForegroundService');

// SPIKE: opt-in toggle for profile/release builds so the spike can be tested
// against production relay config (debug builds point at localhost). Default
// off — keeps logcat clean for normal users.
// Enable with: --dart-define=WHITENOISE_ENABLE_SPIKE_LOGS=true
const _kEnableSpikeLogs = bool.fromEnvironment(
  'WHITENOISE_ENABLE_SPIKE_LOGS',
);

// coverage:ignore-start
@pragma('vm:entry-point')
void _startCallback() {
  // The task handler runs in its own Dart isolate; forward only this file's
  // logger to logcat so SPIKE output is visible without enabling global
  // logging (which could leak third-party or account-level details).
  // Gated to debug builds (or explicit opt-in via WHITENOISE_ENABLE_SPIKE_LOGS)
  // so boot/package-replaced events don't emit user metadata to production
  // logcat by default.
  if (kDebugMode || _kEnableSpikeLogs) {
    Logger.root.onRecord.listen((record) {
      if (record.loggerName != 'ForegroundService') return;
      final buf = StringBuffer('[${record.level.name}] ${record.loggerName}: ${record.message}');
      if (record.error != null) buf.write(' | error: ${record.error}');
      debugPrint(buf.toString());
    });
  }
  FlutterForegroundTask.setTaskHandler(_KeepAliveTaskHandler());
}

class _KeepAliveTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _logger.info('Foreground task started: ${starter.name}');
    await _runHeadlessSpike(starter);
  }

  // SPIKE: Temporary instrumentation to verify the task isolate can reach
  // Rust, platform channels, and persisted data from the background isolate.
  // TODO(#488): Remove when the real headless subscription lands.
  Future<void> _runHeadlessSpike(TaskStarter starter) async {
    _logger.info('[SPIKE] begin (starter=${starter.name})');

    try {
      WidgetsFlutterBinding.ensureInitialized();
      _logger.info('[SPIKE] PASS: WidgetsFlutterBinding.ensureInitialized()');
    } catch (e, st) {
      _logger.severe('[SPIKE] FAIL: WidgetsFlutterBinding.ensureInitialized() threw $e', e, st);
      return;
    }

    try {
      await RustLib.init();
      _logger.info('[SPIKE] PASS: RustLib.init()');
    } catch (e, st) {
      _logger.severe('[SPIKE] FAIL: RustLib.init() threw $e', e, st);
      return;
    }

    final String dataDir;
    final String logsDir;
    try {
      final dir = await getApplicationDocumentsDirectory();
      dataDir = '${dir.path}/whitenoise/data';
      logsDir = '${dir.path}/whitenoise/logs';
      await Directory(dataDir).create(recursive: true);
      await Directory(logsDir).create(recursive: true);
      _logger.info('[SPIKE] PASS: platform channel + dirs; dataDir=$dataDir');
    } catch (e, st) {
      _logger.severe('[SPIKE] FAIL: path_provider / dir create threw $e', e, st);
      return;
    }

    try {
      final config = await rust_api.createWhitenoiseConfig(dataDir: dataDir, logsDir: logsDir);
      _logger.info('[SPIKE] PASS: createWhitenoiseConfig');
      await rust_api.initializeWhitenoise(config: config);
      _logger.info('[SPIKE] PASS: initializeWhitenoise (fresh — likely headless start)');
    } catch (e, st) {
      // The whitenoise Rust crate uses a `OnceCell` singleton. If the main
      // isolate has already initialized it, a second call throws — benign
      // for the spike. Anything else is a real problem and surfaces as a
      // WARNING so it's visible, not swallowed.
      final msg = e.toString().toLowerCase();
      if (msg.contains('already')) {
        _logger.info(
          '[SPIKE] INFO: initializeWhitenoise skipped (main isolate already initialized): $e',
        );
      } else {
        // Abort — continuing to getAccounts() with an uninitialized singleton
        // would produce a second, misleading failure instead of real signal.
        _logger.warning('[SPIKE] WARN: initializeWhitenoise failed unexpectedly', e, st);
        return;
      }
    }

    try {
      final accounts = await accounts_api.getAccounts();
      _logger.info('[SPIKE] PASS: getAccounts returned ${accounts.length} account(s)');
    } catch (e, st) {
      _logger.severe('[SPIKE] FAIL: getAccounts threw $e', e, st);
      return;
    }

    _logger.info('[SPIKE] DONE: headless isolate can reach Rust + platform channels');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    _logger.info('Foreground task destroyed (isTimeout: $isTimeout)');
  }

  @override
  void onReceiveData(Object data) {}

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp();
  }

  @override
  void onNotificationButtonPressed(String id) {}

  @override
  void onNotificationDismissed() {}
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
}
