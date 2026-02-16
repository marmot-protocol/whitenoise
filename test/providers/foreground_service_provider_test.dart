import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/providers/foreground_service_provider.dart';
import 'package:whitenoise/services/foreground_service.dart';

void main() {
  test('foregroundServiceProvider creates ForegroundService', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final service = container.read(foregroundServiceProvider);
    expect(service, isA<ForegroundService>());
  });
}
