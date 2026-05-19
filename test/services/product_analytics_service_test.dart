import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/services/product_analytics_service.dart';
import 'package:whitenoise/src/rust/api/product_analytics.dart';

void main() {
  group('ProductAnalyticsService', () {
    late _FakeProductAnalyticsApi api;
    late ProductAnalyticsService service;

    setUp(() {
      api = _FakeProductAnalyticsApi();
      service = ProductAnalyticsService(
        readSettings: api.readSettings,
        setEnabled: api.setEnabled,
        track: api.track,
        flush: api.flush,
        consentVersion: api.consentVersion,
      );
    });

    test('reads disabled settings by default', () async {
      final settings = await service.settings();

      expect(settings.enabled, isFalse);
      expect(settings.consentVersion, 'product-analytics-v1');
    });

    test('onboarding opt-in enables analytics with the Rust consent version', () async {
      api.nextConsentVersion = 'product-analytics-v2';

      await service.setAnalyticsEnabled(true);

      expect(api.setEnabledCalls, [
        (enabled: true, consentVersion: 'product-analytics-v2'),
      ]);
      expect(api.trackedEvents, isEmpty);
    });

    test('settings opt-out disables analytics with the Rust consent version', () async {
      api.nextConsentVersion = 'product-analytics-v2';

      await service.setAnalyticsEnabled(false);

      expect(api.setEnabledCalls, [
        (enabled: false, consentVersion: 'product-analytics-v2'),
      ]);
      expect(api.trackedEvents, isEmpty);
    });

    test('trims the Rust consent version before updating consent', () async {
      api.nextConsentVersion = '  product-analytics-v2  ';

      await service.setAnalyticsEnabled(true);

      expect(api.setEnabledCalls, [
        (enabled: true, consentVersion: 'product-analytics-v2'),
      ]);
    });

    test(
      'tracks only Flutter-owned typed Rust events and never talks to Aptabase directly',
      () async {
        await service.trackAppStarted(platform: AnalyticsPlatform.android);
        await service.trackAppForegrounded(platform: AnalyticsPlatform.ios);
        await service.trackAppBackgrounded(platform: AnalyticsPlatform.android);
        await service.trackOnboardingStarted();
        await service.trackOnboardingCompleted();

        expect(api.trackedEvents.map((event) => event.name), [
          ProductAnalyticsEventName.appStarted,
          ProductAnalyticsEventName.appForegrounded,
          ProductAnalyticsEventName.appBackgrounded,
          ProductAnalyticsEventName.onboardingStarted,
          ProductAnalyticsEventName.onboardingCompleted,
        ]);
        expect(api.trackedEvents.first.stringProps, [
          const ProductAnalyticsStringProp(key: 'platform', value: 'android'),
        ]);
        expect(api.trackedEvents[1].stringProps, [
          const ProductAnalyticsStringProp(key: 'platform', value: 'ios'),
        ]);
        expect(api.trackedEvents.last.stringProps, isEmpty);
      },
    );

    test('swallows analytics failures so product flows can continue', () async {
      api.shouldThrow = true;

      final settings = await service.settings();
      await service.setAnalyticsEnabled(true);
      await service.trackOnboardingCompleted();
      await service.flush();

      expect(settings.enabled, isFalse);
      expect(api.setEnabledCalls, isEmpty);
    });
  });
}

class _FakeProductAnalyticsApi {
  bool shouldThrow = false;
  String nextConsentVersion = 'product-analytics-v1';
  final setEnabledCalls = <({bool enabled, String consentVersion})>[];
  final trackedEvents = <ProductAnalyticsEvent>[];

  Future<String> consentVersion() async {
    if (shouldThrow) throw Exception('consent version failed');
    return nextConsentVersion;
  }

  Future<ProductAnalyticsSettings> readSettings() async {
    if (shouldThrow) throw Exception('settings failed');
    return ProductAnalyticsSettings(
      enabled: false,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      consentVersion: nextConsentVersion,
    );
  }

  Future<ProductAnalyticsSettings> setEnabled({
    required bool enabled,
    required String consentVersion,
  }) async {
    if (shouldThrow) throw Exception('set enabled failed');
    setEnabledCalls.add((enabled: enabled, consentVersion: consentVersion));
    return ProductAnalyticsSettings(
      enabled: enabled,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      consentVersion: consentVersion,
    );
  }

  Future<ProductAnalyticsTrackStatus> track({
    required ProductAnalyticsEvent event,
  }) async {
    if (shouldThrow) throw Exception('track failed');
    trackedEvents.add(event);
    return ProductAnalyticsTrackStatus.queued;
  }

  Future<ProductAnalyticsFlushStatus> flush() async {
    if (shouldThrow) throw Exception('flush failed');
    return ProductAnalyticsFlushStatus.flushed;
  }
}
