import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:whitenoise/hooks/use_dropdown_controller.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/providers/locale_provider.dart';
import 'package:whitenoise/providers/theme_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_dropdown_selector.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';

class AppearanceScreen extends HookConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final currentThemeMode = ref.watch(themeProvider).value ?? ThemeMode.system;
    final currentLocaleSetting = ref.watch(localeProvider).value ?? const SystemLocale();
    final dropdownController = useDropdownController();

    final themeOptions = [
      WnDropdownOption(value: ThemeMode.system, label: context.l10n.themeSystem),
      WnDropdownOption(value: ThemeMode.light, label: context.l10n.themeLight),
      WnDropdownOption(value: ThemeMode.dark, label: context.l10n.themeDark),
    ];

    final languageOptions = [
      WnDropdownOption<LocaleSetting>(
        value: const SystemLocale(),
        label: context.l10n.languageSystem,
      ),
      ...AppLocalizations.supportedLocales.map(
        (locale) => WnDropdownOption<LocaleSetting>(
          value: SpecificLocale(locale),
          label: getLanguageDisplayName(locale.languageCode),
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: SafeArea(
        child: WnSlate(
          header: WnSlateNavigationHeader(
            title: context.l10n.appearanceTitle,
            onNavigate: () => Routes.goBack(context),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
            child: WnDropdownScope(
              controller: dropdownController,
              child: Column(
                spacing: 24.h,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WnDropdownSelector<ThemeMode>(
                    key: const Key('theme_dropdown'),
                    label: context.l10n.theme,
                    options: themeOptions,
                    value: currentThemeMode,
                    onChanged: (mode) => ref.read(themeProvider.notifier).setThemeMode(mode),
                  ),
                  WnDropdownSelector<LocaleSetting>(
                    key: const Key('language_dropdown'),
                    label: context.l10n.language,
                    options: languageOptions,
                    value: currentLocaleSetting,
                    onChanged: (setting) => ref.read(localeProvider.notifier).setLocale(setting),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
