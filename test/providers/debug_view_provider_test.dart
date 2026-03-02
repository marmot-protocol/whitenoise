import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/providers/debug_view_provider.dart';

class _FailingWriteStorage extends FlutterSecureStoragePlatform {
  final Map<String, String> data;
  _FailingWriteStorage(this.data);

  @override
  Future<bool> containsKey({
    required String key,
    required Map<String, String> options,
  }) async => data.containsKey(key);

  @override
  Future<void> delete({
    required String key,
    required Map<String, String> options,
  }) async => data.remove(key);

  @override
  Future<void> deleteAll({required Map<String, String> options}) async => data.clear();

  @override
  Future<String?> read({
    required String key,
    required Map<String, String> options,
  }) async => data[key];

  @override
  Future<Map<String, String>> readAll({required Map<String, String> options}) async => data;

  @override
  Future<void> write({
    required String key,
    required String value,
    required Map<String, String> options,
  }) async => throw Exception('Storage write failed');
}

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

    test('setEnabled catches storage write failure and preserves state', () async {
      await container.read(debugViewProvider.future);

      FlutterSecureStoragePlatform.instance = _FailingWriteStorage({});

      await container.read(debugViewProvider.notifier).setEnabled(true);

      expect(container.read(debugViewProvider).value, isTrue);

      FlutterSecureStorage.setMockInitialValues({});
    });
  });
}
