import 'package:flutter/foundation.dart' show TargetPlatform;
import 'package:flutter/widgets.dart' show Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/services/product_analytics_config.dart';
import 'package:whitenoise/src/rust/api/product_analytics.dart';

void main() {
  group('buildProductAnalyticsConfig', () {
    test('uses staging bundle metadata with the supplied staging Aptabase key', () {
      final config = buildProductAnalyticsConfig(
        const ProductAnalyticsConfigInput(
          appVersion: '2026.5.7+24',
          bundleIdentifier: 'org.parres.whitenoise.staging',
          locale: 'en-US',
          platform: TargetPlatform.android,
          logicalSize: Size(390, 844),
          isDebug: false,
          aptabaseHost: 'https://analytics.example.com',
          aptabaseAppKey: 'staging-app-key',
        ),
      );

      expect(config.appVersion, '2026.5.7+24');
      expect(config.bundleIdentifier, 'org.parres.whitenoise.staging');
      expect(config.locale, 'en-US');
      expect(config.osName, 'android');
      expect(config.deviceClass, ProductAnalyticsDeviceClass.phone);
      expect(config.isDebug, isFalse);
      final backend = config.backend as ProductAnalyticsBackend_Aptabase;
      expect(backend.config.host, 'https://analytics.example.com');
      expect(backend.config.appKey, 'staging-app-key');
    });

    test('uses production bundle metadata with the supplied production Aptabase key', () {
      final config = buildProductAnalyticsConfig(
        const ProductAnalyticsConfigInput(
          appVersion: '2026.5.7+24',
          bundleIdentifier: 'org.parres.whitenoise',
          locale: 'it',
          platform: TargetPlatform.iOS,
          logicalSize: Size(820, 1180),
          isDebug: false,
          aptabaseHost: 'https://analytics.example.com/',
          aptabaseAppKey: 'production-app-key',
        ),
      );

      expect(config.bundleIdentifier, 'org.parres.whitenoise');
      expect(config.locale, 'it');
      expect(config.osName, 'ios');
      expect(config.deviceClass, ProductAnalyticsDeviceClass.tablet);
      final backend = config.backend as ProductAnalyticsBackend_Aptabase;
      expect(backend.config.host, 'https://analytics.example.com');
      expect(backend.config.appKey, 'production-app-key');
    });

    test('disables analytics when Aptabase config is missing', () {
      final config = buildProductAnalyticsConfig(
        const ProductAnalyticsConfigInput(
          appVersion: '2026.5.7+24',
          bundleIdentifier: 'org.parres.whitenoise',
          locale: 'en',
          platform: TargetPlatform.android,
          logicalSize: Size(390, 844),
          isDebug: true,
          aptabaseHost: '',
          aptabaseAppKey: '',
        ),
      );

      expect(config.backend, const ProductAnalyticsBackend.disabled());
      expect(config.isDebug, isTrue);
      expect(config.deviceClass, ProductAnalyticsDeviceClass.phone);
    });

    test('marks desktop platforms as desktop device class', () {
      final config = buildProductAnalyticsConfig(
        const ProductAnalyticsConfigInput(
          appVersion: '2026.5.7+24',
          bundleIdentifier: 'org.parres.whitenoise',
          locale: 'en',
          platform: TargetPlatform.macOS,
          logicalSize: Size(1440, 900),
          isDebug: false,
          aptabaseHost: 'https://analytics.example.com',
          aptabaseAppKey: 'desktop-app-key',
        ),
      );

      expect(config.osName, 'macos');
      expect(config.deviceClass, ProductAnalyticsDeviceClass.desktop);
    });
  });
}
