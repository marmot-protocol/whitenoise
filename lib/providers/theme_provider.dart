import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:rust_lib_whitenoise/src/rust/api.dart' as rust_api;
import 'package:rust_lib_whitenoise/src/rust/api/utils.dart' as rust_utils;

final _logger = Logger('ThemeNotifier');

class ThemeNotifier extends AsyncNotifier<ThemeMode> {
  @override
  Future<ThemeMode> build() async {
    try {
      final appSettings = await rust_api.getAppSettings();
      final rustThemeMode = await rust_api.appSettingsThemeMode(appSettings: appSettings);
      return _rustToFlutterThemeMode(rustThemeMode);
    } catch (e) {
      _logger.warning('Failed to load theme settings, using system default: $e');
      return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = AsyncData(mode);
    try {
      final rustMode = _flutterToRustThemeMode(mode);
      await rust_api.updateThemeMode(themeMode: rustMode);
      _logger.info('Theme mode updated to: $mode');
    } catch (e) {
      _logger.warning('Failed to persist theme settings: $e');
    }
  }

  ThemeMode _rustToFlutterThemeMode(rust_api.ThemeMode rustMode) {
    final modeString = rust_utils.themeModeToString(themeMode: rustMode);
    switch (modeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  rust_api.ThemeMode _flutterToRustThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return rust_utils.themeModeLight();
      case ThemeMode.dark:
        return rust_utils.themeModeDark();
      case ThemeMode.system:
        return rust_utils.themeModeSystem();
    }
  }
}

final themeProvider = AsyncNotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);
