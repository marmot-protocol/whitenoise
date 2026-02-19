import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/services/foreground_service.dart';

class _MockForegroundTaskApi extends ForegroundTaskApi {
  final List<String> calls = [];
  bool isRunning = false;
  bool isIgnoringBattery = false;
  ServiceRequestResult startResult = const ServiceRequestSuccess();
  ServiceRequestResult stopResult = const ServiceRequestSuccess();

  @override
  void initCommunicationPort() => calls.add('initCommunicationPort');

  @override
  void init({
    required AndroidNotificationOptions androidNotificationOptions,
    required IOSNotificationOptions iosNotificationOptions,
    required ForegroundTaskOptions foregroundTaskOptions,
  }) => calls.add('init');

  @override
  Future<bool> get isRunningService async => isRunning;

  @override
  Future<ServiceRequestResult> startService({
    required int serviceId,
    required String notificationTitle,
    required String notificationText,
    required Function callback,
  }) async {
    calls.add('startService');
    return startResult;
  }

  @override
  Future<ServiceRequestResult> stopService() async {
    calls.add('stopService');
    return stopResult;
  }

  @override
  Future<bool> get isIgnoringBatteryOptimizations async => isIgnoringBattery;

  @override
  Future<bool> requestIgnoreBatteryOptimization() async {
    calls.add('requestIgnoreBatteryOptimization');
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ForegroundService', () {
    group('when disabled', () {
      late ForegroundService service;

      setUp(() {
        service = ForegroundService(enabled: false);
      });

      test('initialize is no-op', () async {
        await service.initialize();
      });

      test('start is no-op', () async {
        await service.start();
      });

      test('stop is no-op', () async {
        await service.stop();
      });

      test('isRunning returns false', () async {
        expect(await service.isRunning, isFalse);
      });

      test('requestBatteryOptimizationExemption is no-op', () async {
        await service.requestBatteryOptimizationExemption();
      });
    });

    group('when enabled', () {
      late _MockForegroundTaskApi mockApi;
      late ForegroundService service;

      setUp(() {
        mockApi = _MockForegroundTaskApi();
        service = ForegroundService(enabled: true, api: mockApi);
      });

      group('initialize', () {
        test('calls initCommunicationPort and init', () async {
          await service.initialize();

          expect(mockApi.calls, ['initCommunicationPort', 'init']);
        });

        test('second call is no-op', () async {
          await service.initialize();
          mockApi.calls.clear();

          await service.initialize();

          expect(mockApi.calls, isEmpty);
        });
      });

      group('start', () {
        test('initializes first when not initialized', () async {
          await service.start();

          expect(mockApi.calls, ['initCommunicationPort', 'init', 'startService']);
        });

        test('skips initialize when already initialized', () async {
          await service.initialize();
          mockApi.calls.clear();

          await service.start();

          expect(mockApi.calls, ['startService']);
        });

        test('does not start when already running', () async {
          await service.initialize();
          mockApi.calls.clear();
          mockApi.isRunning = true;

          await service.start();

          expect(mockApi.calls, isNot(contains('startService')));
        });

        test('handles start failure', () async {
          mockApi.startResult = const ServiceRequestFailure(error: 'test error');

          await service.start();

          expect(mockApi.calls, contains('startService'));
        });
      });

      group('stop', () {
        test('calls stopService', () async {
          await service.stop();

          expect(mockApi.calls, ['stopService']);
        });

        test('handles stop failure', () async {
          mockApi.stopResult = const ServiceRequestFailure(error: 'test error');

          await service.stop();

          expect(mockApi.calls, ['stopService']);
        });
      });

      test('isRunning delegates to api', () async {
        mockApi.isRunning = true;

        expect(await service.isRunning, isTrue);
      });

      group('requestBatteryOptimizationExemption', () {
        test('requests when not ignoring', () async {
          await service.requestBatteryOptimizationExemption();

          expect(mockApi.calls, ['requestIgnoreBatteryOptimization']);
        });

        test('skips when already ignoring', () async {
          mockApi.isIgnoringBattery = true;

          await service.requestBatteryOptimizationExemption();

          expect(mockApi.calls, isEmpty);
        });
      });
    });
  });
}
