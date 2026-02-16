import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/services/foreground_service.dart';

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
        final isRunning = await service.isRunning;
        expect(isRunning, isFalse);
      });

      test('requestBatteryOptimizationExemption is no-op', () async {
        await service.requestBatteryOptimizationExemption();
      });
    });
  });
}
