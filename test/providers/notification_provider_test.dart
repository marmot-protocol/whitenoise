import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/providers/notification_provider.dart';
import 'package:whitenoise/services/notification_service.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';

import '../mocks/mock_wn_api.dart';

void main() {
  late MockWnApi mockApi;

  setUpAll(() {
    mockApi = MockWnApi();
    RustLib.initMock(api: mockApi);
  });

  group('notificationListenerProvider', () {
    late ProviderContainer container;

    setUp(() {
      mockApi.reset();
      container = ProviderContainer();
    });

    tearDown(() => container.dispose());

    test('can be read without error', () {
      expect(() => container.read(notificationListenerProvider), returnsNormally);
    });
  });

  group('notificationServiceProvider', () {
    test('creates a NotificationService', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = container.read(notificationServiceProvider);

      expect(service, isA<NotificationService>());
    });
  });
}
