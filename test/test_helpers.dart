import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/config/providers/localization_provider.dart';
import 'package:whitenoise/config/providers/toast_message_provider.dart';
import 'package:whitenoise/config/states/localization_state.dart';
import 'package:whitenoise/config/states/toast_state.dart';
import 'package:whitenoise/services/localization_service.dart';

Future<void> initializeTestLocalization() async {
  await LocalizationService.load(const Locale('en'));
}

/// Mock toast notifier for tests that disables auto-dismiss to prevent timer issues
class MockToastMessageNotifier extends ToastMessageNotifier {
  @override
  void showToast({
    required String message,
    required ToastType type,
    int? durationMs,
    bool? autoDismiss,
    bool? showBelowAppBar,
  }) {
    // Force auto-dismiss to false to prevent timers in tests
    super.showToast(
      message: message,
      type: type,
      durationMs: durationMs,
      autoDismiss: false, // Always disable auto-dismiss in tests
      showBelowAppBar: showBelowAppBar,
    );
  }

  @override
  void showRawToast({
    required String message,
    required ToastType type,
    int? durationMs,
    bool? autoDismiss,
    bool? showBelowAppBar,
  }) {
    // Force auto-dismiss to false to prevent timers in tests
    super.showRawToast(
      message: message,
      type: type,
      durationMs: durationMs,
      autoDismiss: false, // Always disable auto-dismiss in tests
      showBelowAppBar: showBelowAppBar,
    );
  }
}

Widget createTestWidget(Widget child, {List<Override>? overrides}) {
  final defaultOverrides = [
    toastMessageProvider.overrideWith(() => MockToastMessageNotifier()),
  ];

  return ProviderScope(
    overrides: [...defaultOverrides, ...(overrides ?? [])],
    child: ScreenUtilInit(
      designSize: const Size(375, 812),
      builder:
          (context, _) => MaterialApp(
            home: Scaffold(body: child),
          ),
    ),
  );
}

/// ------------------------------------------------------------------
/// Fake notifier that we use ONLY in tests
/// It extends your real LocalizationNotifier, so the provider type matches.
/// ------------------------------------------------------------------
class FakeLocalizationNotifier extends LocalizationNotifier {
  FakeLocalizationNotifier({
    required String initialSelectedLanguage,
    Map<String, String>? supported,
  }) : _supportedLocales = supported ?? LocalizationService.supportedLocales {
    final deviceLocaleCode = LocalizationService.getDeviceLocale();

    state = LocalizationState(
      currentLocale: Locale(
        initialSelectedLanguage == 'system' ? deviceLocaleCode : initialSelectedLanguage,
      ),
      selectedLanguage: initialSelectedLanguage,
    );
  }

  final Map<String, String> _supportedLocales;

  String? lastChangedLocale;
  int changeLocaleCallCount = 0;

  @override
  Map<String, String> get supportedLocales => _supportedLocales;

  @override
  Future<bool> changeLocale(String localeCode) async {
    changeLocaleCallCount++;
    lastChangedLocale = localeCode;

    final deviceLocaleCode = LocalizationService.getDeviceLocale();

    state = state.copyWith(
      selectedLanguage: localeCode,
      currentLocale: Locale(
        localeCode == 'system' ? deviceLocaleCode : localeCode,
      ),
      isLoading: false,
      error: null,
    );

    // Always report success in the fake
    return true;
  }
}
