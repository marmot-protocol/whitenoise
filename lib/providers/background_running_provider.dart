import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/utils/platform_storage.dart';

const _storageKey = 'background_running_enabled';

final _logger = Logger('BackgroundRunningNotifier');

/// Tri-state preference for background running:
///   - null  → user has not been asked yet (prompt will be shown)
///   - true  → user opted in (battery optimisation exemption requested)
///   - false → user dismissed / opted out (no prompt, no exemption)
class BackgroundRunningNotifier extends AsyncNotifier<bool?> {
  @override
  Future<bool?> build() async {
    if (!Platform.isAndroid) return null;
    try {
      const storage = PlatformStorage();
      final value = await storage.read(key: _storageKey);
      if (value == null) return null;
      return value == 'true';
    } catch (e) {
      _logger.warning('Failed to load background running preference: $e');
      return null;
    }
  }

  Future<void> setEnabled(bool enabled) async {
    state = AsyncData(enabled);
    try {
      const storage = PlatformStorage();
      await storage.write(key: _storageKey, value: enabled.toString());
      _logger.info('Background running preference set to $enabled');
    } catch (e) {
      _logger.warning('Failed to persist background running preference: $e');
    }
  }

  /// Called when the user dismisses the prompt without choosing.
  Future<void> dismiss() => setEnabled(false);
}

final backgroundRunningProvider =
    AsyncNotifierProvider<BackgroundRunningNotifier, bool?>(
  BackgroundRunningNotifier.new,
);
