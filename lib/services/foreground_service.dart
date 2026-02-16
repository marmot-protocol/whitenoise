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
// coverage:ignore-end

class ForegroundService {
  ForegroundService({bool? enabled}) : _enabled = enabled ?? Platform.isAndroid;

  final bool _enabled;
  bool _initialized = false;

  static const _serviceId = 888;
  static const _channelId = 'whitenoise_foreground';
  static const _channelName = 'White Noise';

  Future<void> initialize() async {
    if (!_enabled) return;
    if (_initialized) return;

    // coverage:ignore-start
    FlutterForegroundTask.initCommunicationPort();

    FlutterForegroundTask.init(
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
    // coverage:ignore-end
  }

  Future<void> start() async {
    if (!_enabled) return;
    // coverage:ignore-start
    if (!_initialized) {
      await initialize();
    }

    if (await FlutterForegroundTask.isRunningService) {
      _logger.info('Foreground service already running');
      return;
    }

    final result = await FlutterForegroundTask.startService(
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
    // coverage:ignore-end
  }

  Future<void> stop() async {
    if (!_enabled) return;

    // coverage:ignore-start
    final result = await FlutterForegroundTask.stopService();
    if (result is ServiceRequestSuccess) {
      _logger.info('Foreground service stopped');
    } else {
      _logger.warning('Failed to stop foreground service: $result');
    }
    // coverage:ignore-end
  }

  Future<bool> get isRunning async {
    if (!_enabled) return false;
    return FlutterForegroundTask.isRunningService; // coverage:ignore-line
  }

  Future<void> requestBatteryOptimizationExemption() async {
    if (!_enabled) return;

    // coverage:ignore-start
    if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }
    // coverage:ignore-end
  }
}
