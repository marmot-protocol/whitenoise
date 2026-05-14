import 'package:flutter/material.dart' show Locale, WidgetsBinding;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise_frb/src/rust/api.dart' as rust_api;
import 'package:whitenoise_frb/src/rust/api/utils.dart' as rust_utils;
import 'package:whitenoise/l10n/generated/app_localizations.dart';

final _logger = Logger('LocaleNotifier');

sealed class LocaleSetting {
  const LocaleSetting();
}

class SystemLocale extends LocaleSetting {
  const SystemLocale();

  @override
  bool operator ==(Object other) => other is SystemLocale;

  @override
  int get hashCode => runtimeType.hashCode;
}

class SpecificLocale extends LocaleSetting {
  final Locale locale;
  const SpecificLocale(this.locale);

  @override
  bool operator ==(Object other) =>
      other is SpecificLocale &&
      other.locale.languageCode == locale.languageCode &&
      other.locale.scriptCode == locale.scriptCode;

  @override
  int get hashCode => Object.hash(locale.languageCode, locale.scriptCode);
}

class LocaleNotifier extends AsyncNotifier<LocaleSetting> {
  @override
  Future<LocaleSetting> build() async {
    try {
      final appSettings = await rust_api.getAppSettings();
      final rustLanguage = await rust_api.appSettingsLanguage(appSettings: appSettings);
      return _rustLanguageToSetting(rustLanguage);
    } catch (e) {
      _logger.warning('Failed to load locale settings, using system default: $e');
      return const SystemLocale();
    }
  }

  Future<void> setLocale(LocaleSetting setting) async {
    state = AsyncData(setting);
    try {
      final rustLanguage = _settingToRustLanguage(setting);
      await rust_api.updateLanguage(language: rustLanguage);
      _logger.info('Locale updated to: $setting');
    } catch (e) {
      _logger.warning('Failed to persist locale settings: $e');
    }
  }

  Locale resolveLocale() {
    final currentState = state.value ?? const SystemLocale();
    return switch (currentState) {
      SystemLocale() => _resolveSystemLocale(),
      SpecificLocale(locale: final locale) => locale,
    };
  }

  LocaleSetting _rustLanguageToSetting(rust_api.Language language) {
    final code = rust_utils.languageToString(language: language);
    if (code == 'system') {
      return const SystemLocale();
    }
    final locale = _localeFromLanguageCode(code);
    final isSupported = AppLocalizations.supportedLocales.any((l) {
      return l.languageCode == locale.languageCode && l.scriptCode == locale.scriptCode;
    });
    if (isSupported) {
      return SpecificLocale(locale);
    }
    return const SystemLocale();
  }

  rust_api.Language _settingToRustLanguage(LocaleSetting setting) {
    return switch (setting) {
      SystemLocale() => rust_utils.languageSystem(),
      SpecificLocale(locale: final locale) => _localeToRustLanguage(locale),
    };
  }

  Locale _localeFromLanguageCode(String code) {
    return switch (code) {
      'zh_Hant' => const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
      'zh_Hans' => const Locale('zh'),
      _ => Locale(code),
    };
  }

  rust_api.Language _localeToRustLanguage(Locale locale) {
    return switch ((locale.languageCode, locale.scriptCode)) {
      ('zh', 'Hant') => rust_utils.languageChineseTraditional(),
      ('zh', _) => rust_utils.languageChineseSimplified(),
      ('en', _) => rust_utils.languageEnglish(),
      ('es', _) => rust_utils.languageSpanish(),
      ('fr', _) => rust_utils.languageFrench(),
      ('de', _) => rust_utils.languageGerman(),
      ('it', _) => rust_utils.languageItalian(),
      ('pt', _) => rust_utils.languagePortuguese(),
      ('ru', _) => rust_utils.languageRussian(),
      ('tr', _) => rust_utils.languageTurkish(),
      _ => rust_utils.languageEnglish(),
    };
  }

  Locale _resolveSystemLocale() {
    final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
    for (final locale in AppLocalizations.supportedLocales) {
      if (locale.languageCode == deviceLocale.languageCode &&
          locale.scriptCode == deviceLocale.scriptCode) {
        return Locale.fromSubtags(
          languageCode: deviceLocale.languageCode,
          scriptCode: deviceLocale.scriptCode,
        );
      }
    }
    final isLanguageSupported = AppLocalizations.supportedLocales.any(
      (locale) => locale.languageCode == deviceLocale.languageCode,
    );
    return isLanguageSupported ? Locale(deviceLocale.languageCode) : const Locale('en');
  }
}

final localeProvider = AsyncNotifierProvider<LocaleNotifier, LocaleSetting>(LocaleNotifier.new);

String getLanguageDisplayName(String languageCode) {
  return switch (languageCode) {
    'de' => 'Deutsch',
    'en' => 'English',
    'es' => 'Español',
    'fr' => 'Français',
    'it' => 'Italiano',
    'pt' => 'Português',
    'ru' => 'Русский',
    'tr' => 'Türkçe',
    'zh_Hans' || 'zh-Hans' => '简体中文',
    'zh_Hant' || 'zh-Hant' => '繁體中文',
    'zh' => '简体中文',
    _ => languageCode,
  };
}

String getLocaleDisplayName(Locale locale) {
  if (locale.languageCode == 'zh' && locale.scriptCode == 'Hant') {
    return '繁體中文';
  }
  return getLanguageDisplayName(locale.languageCode);
}

class LocaleFormatters {
  final String _localeCode;

  LocaleFormatters(this._localeCode);

  String formatDateShort(DateTime date) {
    return DateFormat.yMd(_localeCode).format(date);
  }

  String formatDateMedium(DateTime date) {
    return DateFormat.yMMMd(_localeCode).format(date);
  }

  String formatDateLong(DateTime date) {
    return DateFormat.yMMMMd(_localeCode).format(date);
  }

  String formatTime(DateTime time) {
    return DateFormat.jm(_localeCode).format(time);
  }

  String formatDateTime(DateTime dateTime) {
    return '${formatDateMedium(dateTime)} ${formatTime(dateTime)}';
  }

  String formatRelativeTime(DateTime dateTime, AppLocalizations l10n) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return l10n.timeJustNow;
    } else if (difference.inMinutes < 60) {
      return l10n.timeMinutesAgo(difference.inMinutes);
    } else if (difference.inHours < 24) {
      return l10n.timeHoursAgo(difference.inHours);
    } else if (difference.inDays < 7) {
      return l10n.timeDaysAgo(difference.inDays);
    } else {
      return formatDateMedium(dateTime);
    }
  }

  String formatNumber(num number) {
    return NumberFormat.decimalPattern(_localeCode).format(number);
  }

  String formatCurrency(num amount, {String? symbol}) {
    final format = NumberFormat.currency(
      locale: _localeCode,
      symbol: symbol ?? '',
      decimalDigits: 2,
    );
    return format.format(amount).trim();
  }

  String formatCompact(num number) {
    return NumberFormat.compact(locale: _localeCode).format(number);
  }

  String formatPercent(double value) {
    return NumberFormat.percentPattern(_localeCode).format(value);
  }
}

final localeFormattersProvider = Provider<LocaleFormatters>((ref) {
  final localeSetting = ref.watch(localeProvider).value ?? const SystemLocale();
  final localeCode = switch (localeSetting) {
    SystemLocale() => _resolveSystemLanguageCode(),
    SpecificLocale(locale: final locale) => locale.languageCode,
  };
  return LocaleFormatters(localeCode);
});

String _resolveSystemLanguageCode() {
  final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
  final isSupported = AppLocalizations.supportedLocales.any(
    (l) => l.languageCode == deviceLocale.languageCode,
  );
  return isSupported ? deviceLocale.languageCode : 'en';
}
