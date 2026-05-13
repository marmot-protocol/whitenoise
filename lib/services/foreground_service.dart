import 'dart:async' show unawaited;
import 'dart:convert' show jsonDecode, jsonEncode;
import 'dart:developer' as developer;
import 'dart:io' show Directory, Platform;
import 'dart:ui' show DartPluginRegistrant, Locale;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/widgets.dart' show AppLifecycleState, WidgetsFlutterBinding;
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart' show getApplicationDocumentsDirectory;
import 'package:rust_lib_whitenoise/src/rust/api.dart' as rust_api;
import 'package:rust_lib_whitenoise/src/rust/api/relays.dart' as relays_api;
import 'package:rust_lib_whitenoise/src/rust/api/utils.dart' as rust_utils;
import 'package:rust_lib_whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/services/external_signer_callback_registry.dart';
import 'package:whitenoise/services/notification_service.dart';
import 'package:whitenoise/services/notification_subscription.dart';

final _logger = Logger('ForegroundService');

const _kTaskEventKey = 'event';
const _kEventMainStarted = 'main_started';
const _kEventMainStopped = 'main_stopped';

/// Key used to stash a headless notification-tap payload so the main isolate
/// can consume and route it once it launches.
const _kPendingNotificationTapKey = 'pending_notification_tap';

// coverage:ignore-start
@pragma('vm:entry-point')
void _startCallback() {
  DartPluginRegistrant.ensureInitialized();

  Logger.root.level = kDebugMode ? Level.INFO : Level.WARNING;
  Logger.root.onRecord.listen((record) {
    if (record.loggerName != 'ForegroundService' &&
        record.loggerName != 'ExternalSignerCallbackRegistry' &&
        record.loggerName != 'NotificationSubscription') {
      return;
    }
    final buf = StringBuffer('[${record.level.name}] ${record.loggerName}: ${record.message}');
    if (record.error != null) buf.write(' | error: ${record.error}');
    if (record.stackTrace != null) buf.write(' | stackTrace: ${record.stackTrace}');
    developer.log(
      buf.toString(),
      name: record.loggerName,
      level: record.level.value,
      error: record.error,
      stackTrace: record.stackTrace,
    );
  });
  FlutterForegroundTask.setTaskHandler(NotificationTaskHandler());
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
class NotificationTaskHandler extends TaskHandler {
  NotificationTaskHandler({
    Future<bool> Function()? bootstrapIsolate,
    Future<Locale> Function()? loadLocale,
    Future<void> Function()? ensureExternalSigners,
    Future<void> Function()? ensureSubscriptions,
    Future<bool> Function()? startSubscription,
    bool Function()? isSubscriptionRunning,
    Future<void> Function()? stopSubscription,
  }) : _bootstrapIsolateOverride = bootstrapIsolate,
       _loadLocaleOverride = loadLocale,
       _ensureExternalSignersOverride = ensureExternalSigners,
       _ensureSubscriptionsOverride = ensureSubscriptions,
       _startSubscriptionOverride = startSubscription,
       _isSubscriptionRunningOverride = isSubscriptionRunning,
       _stopSubscriptionOverride = stopSubscription;

  final Future<bool> Function()? _bootstrapIsolateOverride;
  final Future<Locale> Function()? _loadLocaleOverride;
  final Future<void> Function()? _ensureExternalSignersOverride;
  final Future<void> Function()? _ensureSubscriptionsOverride;
  final Future<bool> Function()? _startSubscriptionOverride;
  final bool Function()? _isSubscriptionRunningOverride;
  final Future<void> Function()? _stopSubscriptionOverride;

  NotificationSubscription? _subscription;
  ExternalSignerCallbackRegistry? _externalSignerCallbackRegistry;
  final _registeredExternalSignerPubkeys = <String>{};
  final _externalSignerRegistrationFutures = <String, Future<void>>{};
  Locale _cachedLocale = const Locale('en');
  bool _bootstrapped = false;
  bool _shouldOwnSubscription = false;
  int _ownershipGeneration = 0;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _logger.info('Foreground task started: ${starter.name}');

    final ownershipGeneration = _setShouldOwnSubscription(starter == TaskStarter.system);
    _bootstrapped = await _runBootstrapIsolate();
    if (!_matchesOwnershipGeneration(ownershipGeneration)) return;
    if (!_bootstrapped) return;

    _cachedLocale = await _runLoadLocale();
    if (!_matchesOwnershipGeneration(ownershipGeneration)) return;

    if (_shouldOwnSubscription) {
      await _ensureSubscriptionRunning(ownershipGeneration);
    } else {
      _logger.info('Task started by main isolate; awaiting coordination message');
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    final ownershipGeneration = _ownershipGeneration;
    if (!_ownsSubscription(ownershipGeneration)) return;
    _logger.fine('Repeat event while task owns subscription');
    unawaited(_ensureSubscriptionRunning(ownershipGeneration));
  }

  @override
  void onReceiveData(Object data) {
    if (data is! Map) return;
    final event = data[_kTaskEventKey];
    if (event == _kEventMainStarted) {
      _logger.info('Received main_started — yielding subscription');
      final ownershipGeneration = _setShouldOwnSubscription(false);
      unawaited(_stopSubscription(ownershipGeneration));
    } else if (event == _kEventMainStopped) {
      _logger.info('Received main_stopped — taking over subscription');
      final ownershipGeneration = _setShouldOwnSubscription(true);
      unawaited(_ensureSubscriptionRunning(ownershipGeneration));
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    _logger.info('Foreground task destroyed (isTimeout: $isTimeout)');
    final ownershipGeneration = _setShouldOwnSubscription(false);
    await _stopSubscription(ownershipGeneration);
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp();
  }

  @override
  void onNotificationButtonPressed(String id) {}

  @override
  void onNotificationDismissed() {}

  Future<void> _ensureSubscriptionRunning(int ownershipGeneration) async {
    if (!_ownsSubscription(ownershipGeneration)) return;

    if (!_bootstrapped) {
      _logger.info('Bootstrapping task isolate before subscription retry');
      _bootstrapped = await _runBootstrapIsolate();
      if (!_ownsSubscription(ownershipGeneration)) return;
      if (!_bootstrapped) {
        _logger.warning('Task isolate bootstrap still failing');
        return;
      }
      _cachedLocale = await _runLoadLocale();
      if (!_ownsSubscription(ownershipGeneration)) return;
    }

    try {
      await _runEnsureExternalSigners();
    } catch (e, st) {
      _logger.warning('Failed to ensure external signer callbacks', e, st);
      return;
    }
    if (!_ownsSubscription(ownershipGeneration)) return;

    try {
      await _runEnsureSubscriptions();
    } catch (e, st) {
      _logger.warning('Failed to ensure Rust relay subscriptions', e, st);
      return;
    }
    if (!_ownsSubscription(ownershipGeneration)) return;

    if (_subscriptionIsRunning) {
      _logger.fine('Subscription already running');
      return;
    }

    _logger.info('Ensuring headless notification subscription is running');
    await _startSubscription(ownershipGeneration);
  }

  Future<bool> _runBootstrapIsolate() {
    final override = _bootstrapIsolateOverride;
    if (override != null) return override();
    return _bootstrapIsolate();
  }

  Future<Locale> _runLoadLocale() {
    final override = _loadLocaleOverride;
    if (override != null) return override();
    return _loadLocale();
  }

  Future<void> _runEnsureExternalSigners() {
    final override = _ensureExternalSignersOverride;
    if (override != null) return override();
    _logger.fine('Ensuring external signer callbacks are registered');
    final service = _externalSignerCallbackRegistry ??= ExternalSignerCallbackRegistry();
    return service.ensureRegistered(
      registeredExternalSignerPubkeys: _registeredExternalSignerPubkeys,
      externalSignerRegistrationFutures: _externalSignerRegistrationFutures,
      requireAll: true,
    );
  }

  Future<void> _runEnsureSubscriptions() {
    final override = _ensureSubscriptionsOverride;
    if (override != null) return override();
    _logger.fine('Ensuring Rust relay subscriptions are active');
    return relays_api.ensureAllSubscriptions();
  }

  /// Initializes Flutter bindings, Rust FFI, and the whitenoise singleton
  /// inside this isolate. Idempotent — if the main isolate already
  /// initialized whitenoise, we accept the "already initialized" error.
  Future<bool> _bootstrapIsolate() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await RustLib.init();
      _logger.info('RustLib initialized in task isolate');

      final dir = await getApplicationDocumentsDirectory();
      final dataDir = '${dir.path}/whitenoise/data';
      final logsDir = '${dir.path}/whitenoise/logs';
      _logger.fine('Task isolate data dir: $dataDir');
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

  Future<bool> _startSubscription(int ownershipGeneration) async {
    if (!_ownsSubscription(ownershipGeneration)) return false;

    final override = _startSubscriptionOverride;
    if (override != null) {
      final started = await override();
      if (!_ownsSubscription(ownershipGeneration)) return false;
      return started;
    }

    if (!_ownsSubscription(ownershipGeneration)) return false;
    if (!_bootstrapped) {
      _logger.warning('Cannot start subscription: bootstrap failed earlier');
      return false;
    }
    if (_subscriptionIsRunning) return true;
    _subscription = null;

    final notificationService = NotificationService(
      onNotificationTap: _persistTapAndLaunch,
    );
    final sub = NotificationSubscription(
      notificationService: notificationService,
      getActiveChatId: () => null,
      getLocale: () => _cachedLocale,
      requestPermissionOnStart: false,
    );
    await sub.start();
    if (!_ownsSubscription(ownershipGeneration)) {
      await sub.stop();
      return false;
    }
    // NotificationSubscription.start() catches its own failures and logs
    // them, so a successful return doesn't mean the stream is attached.
    // Check isRunning and clear our reference on failure so a follow-up
    // coordination signal can retry instead of perma-no-op'ing.
    if (!sub.isRunning) {
      _logger.warning(
        'Headless notification subscription did not attach; will retry on next coordination signal',
      );
      return false;
    }
    _subscription = sub;
    _logger.info('Headless notification subscription started');
    return true;
  }

  Future<void> _stopSubscription(int ownershipGeneration) async {
    if (!_matchesOwnershipGeneration(ownershipGeneration)) return;

    final override = _stopSubscriptionOverride;
    if (override != null) {
      await override();
      return;
    }

    final sub = _subscription;
    if (sub == null) return;
    _subscription = null;
    await sub.stop();
    _logger.info('Headless notification subscription stopped');
  }

  int _setShouldOwnSubscription(bool shouldOwnSubscription) {
    if (_shouldOwnSubscription != shouldOwnSubscription) {
      _shouldOwnSubscription = shouldOwnSubscription;
      _ownershipGeneration++;
    }
    return _ownershipGeneration;
  }

  bool _ownsSubscription(int ownershipGeneration) =>
      _shouldOwnSubscription && _matchesOwnershipGeneration(ownershipGeneration);

  bool _matchesOwnershipGeneration(int ownershipGeneration) =>
      _ownershipGeneration == ownershipGeneration;

  bool get _subscriptionIsRunning {
    final override = _isSubscriptionRunningOverride;
    if (override != null) return override();
    return _subscription?.isRunning ?? false;
  }

  /// Persists the tapped notification's payload so the main isolate can route
  /// to the right chat/invite on launch, then brings the app to the
  /// foreground.
  void _persistTapAndLaunch(String groupId, bool isInvite, String receiverPubkey) {
    unawaited(() async {
      try {
        await FlutterForegroundTask.saveData(
          key: _kPendingNotificationTapKey,
          value: jsonEncode({
            'groupId': groupId,
            'isInvite': isInvite,
            'receiverPubkey': receiverPubkey,
          }),
        );
      } catch (e, st) {
        _logger.warning('Failed to persist pending notification tap', e, st);
      }
      FlutterForegroundTask.launchApp();
    }());
  }

  Future<Locale> _loadLocale() async {
    try {
      final settings = await rust_api.getAppSettings();
      final language = await rust_api.appSettingsLanguage(appSettings: settings);
      final code = rust_utils.languageToString(language: language);
      _logger.fine('Loaded task isolate locale setting: $code');
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

/// Payload captured when the user taps a notification fired by the headless
/// task isolate. Stashed via [FlutterForegroundTask.saveData] and consumed by
/// the main isolate on launch.
class PendingNotificationTap {
  const PendingNotificationTap({
    required this.groupId,
    required this.isInvite,
    required this.receiverPubkey,
  });

  final String groupId;
  final bool isInvite;
  final String receiverPubkey;
}

/// Reads and clears any notification-tap payload stashed by the task
/// isolate. Returns null if there's nothing pending.
Future<PendingNotificationTap?> consumePendingNotificationTap() async {
  if (!Platform.isAndroid) return null;
  try {
    final raw = await FlutterForegroundTask.getData<String>(key: _kPendingNotificationTapKey);
    if (raw == null) return null;
    await FlutterForegroundTask.removeData(key: _kPendingNotificationTapKey);
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final groupId = data['groupId'] as String?;
    final isInvite = data['isInvite'] as bool?;
    final receiverPubkey = data['receiverPubkey'] as String?;
    if (groupId == null ||
        groupId.isEmpty ||
        isInvite == null ||
        receiverPubkey == null ||
        receiverPubkey.isEmpty) {
      _logger.warning('Malformed pending notification tap payload: $raw');
      return null;
    }
    return PendingNotificationTap(
      groupId: groupId,
      isInvite: isInvite,
      receiverPubkey: receiverPubkey,
    );
  } catch (e, st) {
    _logger.warning('Failed to consume pending notification tap', e, st);
    return null;
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
    List<ForegroundServiceTypes>? serviceTypes,
    required String notificationTitle,
    required String notificationText,
    NotificationIcon? notificationIcon,
    required Function callback,
  }) => FlutterForegroundTask.startService(
    serviceId: serviceId,
    serviceTypes: serviceTypes,
    notificationTitle: notificationTitle,
    notificationText: notificationText,
    notificationIcon: notificationIcon,
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
  ForegroundService({bool? enabled, ForegroundTaskApi? api, String? packageName})
    : _enabled = enabled ?? Platform.isAndroid,
      _api = api ?? ForegroundTaskApi(), // coverage:ignore-line
      _packageName = packageName;

  final bool _enabled;
  final ForegroundTaskApi _api;
  final String? _packageName;
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

    final resolvedPackageName = _packageName ?? (await PackageInfo.fromPlatform()).packageName;

    final result = await _api.startService(
      serviceId: _serviceId,
      serviceTypes: const [ForegroundServiceTypes.dataSync],
      notificationTitle: 'White Noise',
      notificationText: 'Connected to relays',
      notificationIcon: NotificationIcon(
        metaDataName: '$resolvedPackageName.NOTIFICATION_ICON',
      ),
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

  /// Translates a Flutter [AppLifecycleState] into the matching coordination
  /// signal for the task isolate. Resumed → main took over; any other state
  /// → main is releasing.
  Future<void> handleAppLifecycleChange(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        await notifyMainStarted();
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        await notifyMainStopped();
    }
  }
}
