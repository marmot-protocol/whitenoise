// test/localization_service_test.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/services/localization_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const fakeTranslationsJson = '''
  {
    "settings": {
      "title": "Settings",
      "subtitle": "Configure your app"
    },
    "greeting": "Hello {name}"
  }
  ''';

  setUpAll(() {
    // Mock asset loading for lib/locales/*.json
    final encoded = utf8.encode(fakeTranslationsJson);
    final byteData = ByteData.view(Uint8List.fromList(encoded).buffer);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
      'flutter/assets',
      (ByteData? message) async {
        // In a real test you might inspect [message] to choose different JSON
        // based on the requested asset path. For now we return the same JSON
        // for any requested locale.
        return byteData;
      },
    );
  });

  setUp(() {
    // Reset device locale override before each test
    LocalizationService.resetDeviceLocaleOverride();
  });

  group('LocalizationService.supportedLocales & supportedLocaleObjects', () {
    test('supportedLocales contains system and en', () {
      final locales = LocalizationService.supportedLocales;

      expect(locales.containsKey('system'), isTrue);
      expect(locales.containsKey('en'), isTrue);
      expect(locales.containsKey('es'), isTrue);
    });

    test('supportedLocaleObjects excludes "system"', () {
      final objects = LocalizationService.supportedLocaleObjects;

      expect(objects.any((l) => l.languageCode == 'system'), isFalse);

      final supported = LocalizationService.supportedLocales;
      for (final locale in objects) {
        expect(supported.containsKey(locale.languageCode), isTrue);
        expect(locale.languageCode, isNot('system'));
      }
    });
  });
  group('LocalizationService.load', () {
    test('loads valid locale and sets currentLocale', () async {
      final result = await LocalizationService.load(const Locale('en'));

      expect(result, isTrue);
      expect(LocalizationService.currentLocale, 'en');
      expect(LocalizationService.currentLocaleObject.languageCode, 'en');
    });

    test('falls back to fallbackLocale when locale is unsupported', () async {
      final result = await LocalizationService.load(const Locale('xx'));

      expect(result, isTrue);
      expect(LocalizationService.currentLocale, 'en'); // fallback
    });
  });

  group('LocalizationService.translate, hasKey, getSection', () {
    setUp(() async {
      await LocalizationService.load(const Locale('en'));
    });

    test('translate returns value for nested key', () {
      final text = LocalizationService.translate('settings.title');

      expect(text, 'Settings');
    });

    test('translate with params replaces placeholders', () {
      final text = LocalizationService.translate('greeting', params: {'name': 'Abdul'});

      expect(text, 'Hello Abdul');
    });

    test('translate returns key when path not found', () {
      final text = LocalizationService.translate('settings.unknown');

      expect(text, 'settings.unknown');
    });

    test('hasKey is true for existing key', () {
      final exists = LocalizationService.hasKey('settings.title');

      expect(exists, isTrue);
    });

    test('hasKey is false for non-existing key', () {
      final exists = LocalizationService.hasKey('settings.missing');

      expect(exists, isFalse);
    });

    test('getSection returns flattened map for section', () {
      final section = LocalizationService.getSection('settings');

      expect(section.length, 2);
      expect(section['title'], 'Settings');
      expect(section['subtitle'], 'Configure your app');
    });

    test('getSection returns empty map for invalid section', () {
      final section = LocalizationService.getSection('unknown');

      expect(section, isEmpty);
    });
  });
  group('LocalizationService.setLocale', () {
    test('setLocale loads supported locale and updates currentLocale', () async {
      final result = await LocalizationService.setLocale('en');

      expect(result, isTrue);
      expect(LocalizationService.currentLocale, 'en');
    });

    test('setLocale returns false for unsupported locale', () async {
      final result = await LocalizationService.setLocale('xx');

      expect(result, isFalse);
    });
  });
  //
}
