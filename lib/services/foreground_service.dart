import 'dart:io' show Platform;

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:logging/logging.dart';

final _logger = Logger('ForegroundService');

// coverage:ignore-start
@pragma('vm:entry-point')
void _startCallback() {
  FlutterForegroundTask.setTaskHandler(_KeepAliveTaskHandler());
}

class _KeepAliveTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _logger.info('Foreground task started: ${starter.name}');
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
