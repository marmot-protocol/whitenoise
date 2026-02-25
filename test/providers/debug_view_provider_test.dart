import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/providers/debug_view_provider.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('DebugViewNotifier', () {
    test('initializes to false when no stored value', () async {
      final enabled = await container.read(debugViewProvider.future);

      expect(enabled, isFalse);
    });

    test('initializes to true when stored value is true', () async {
      FlutterSecureStorage.setMockInitialValues({'debug_raw_view_enabled': 'true'});
      final freshContainer = ProviderContainer();
      addTearDown(freshContainer.dispose);

      final enabled = await freshContainer.read(debugViewProvider.future);

      expect(enabled, isTrue);
    });

    test('initializes to false when stored value is false', () async {
      FlutterSecureStorage.setMockInitialValues({'debug_raw_view_enabled': 'false'});
      final freshContainer = ProviderContainer();
      addTearDown(freshContainer.dispose);

      final enabled = await freshContainer.read(debugViewProvider.future);

      expect(enabled, isFalse);
    });

    test('setEnabled(true) updates state to true', () async {
      await container.read(debugViewProvider.future);

      await container.read(debugViewProvider.notifier).setEnabled(true);

      expect(container.read(debugViewProvider).value, isTrue);
    });

    test('setEnabled(false) updates state to false', () async {
      await container.read(debugViewProvider.future);
      await container.read(debugViewProvider.notifier).setEnabled(true);

      await container.read(debugViewProvider.notifier).setEnabled(false);

      expect(container.read(debugViewProvider).value, isFalse);
    });

    test('setEnabled persists value to secure storage', () async {
      await container.read(debugViewProvider.future);

      await container.read(debugViewProvider.notifier).setEnabled(true);

      const storage = FlutterSecureStorage();
      final stored = await storage.read(key: 'debug_raw_view_enabled');
      expect(stored, 'true');
    });

    test('setEnabled(false) persists false to secure storage', () async {
      await container.read(debugViewProvider.future);
      await container.read(debugViewProvider.notifier).setEnabled(true);

      await container.read(debugViewProvider.notifier).setEnabled(false);

      const storage = FlutterSecureStorage();
      final stored = await storage.read(key: 'debug_raw_view_enabled');
      expect(stored, 'false');
    });
  });
}
