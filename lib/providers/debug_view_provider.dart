import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';

const _storageKey = 'debug_raw_view_enabled';

final _logger = Logger('DebugViewNotifier');

class DebugViewNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    try {
      const storage = FlutterSecureStorage();
      final value = await storage.read(key: _storageKey);
      return value == 'true';
    } catch (e) {
      _logger.warning('Failed to load debug view setting: $e');
      return false;
    }
  }

  Future<void> setEnabled(bool enabled) async {
    state = AsyncData(enabled);
    try {
      const storage = FlutterSecureStorage();
      await storage.write(key: _storageKey, value: enabled.toString());
    } catch (e) {
      _logger.warning('Failed to persist debug view setting: $e');
    }
  }
}

final debugViewProvider = AsyncNotifierProvider<DebugViewNotifier, bool>(DebugViewNotifier.new);
