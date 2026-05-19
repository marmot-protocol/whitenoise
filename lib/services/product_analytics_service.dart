import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/src/rust/api/product_analytics.dart' as rust_analytics;

const _fallbackConsentVersion = 'product-analytics-v1';

final productAnalyticsServiceProvider = Provider<ProductAnalyticsService>((ref) {
  return ProductAnalyticsService();
});

typedef ProductAnalyticsSettingsReader = Future<rust_analytics.ProductAnalyticsSettings> Function();
typedef ProductAnalyticsConsentVersionReader = Future<String> Function();
typedef ProductAnalyticsEnabledSetter =
    Future<rust_analytics.ProductAnalyticsSettings> Function({
      required bool enabled,
      required String consentVersion,
    });
typedef ProductAnalyticsEventTracker =
    Future<rust_analytics.ProductAnalyticsTrackStatus> Function({
      required rust_analytics.ProductAnalyticsEvent event,
    });
typedef ProductAnalyticsFlusher = Future<rust_analytics.ProductAnalyticsFlushStatus> Function();

enum AnalyticsPlatform {
  ios('ios'),
  android('android'),
  macos('macos'),
  linux('linux'),
  windows('windows'),
  web('web'),
  unknown('unknown')
  ;

  const AnalyticsPlatform(this.value);
  final String value;
}

AnalyticsPlatform analyticsPlatformForTarget([TargetPlatform? platform]) {
  if (kIsWeb) return AnalyticsPlatform.web;
  return switch (platform ?? defaultTargetPlatform) {
    TargetPlatform.android => AnalyticsPlatform.android,
    TargetPlatform.iOS => AnalyticsPlatform.ios,
    TargetPlatform.macOS => AnalyticsPlatform.macos,
    TargetPlatform.linux => AnalyticsPlatform.linux,
    TargetPlatform.windows => AnalyticsPlatform.windows,
    TargetPlatform.fuchsia => AnalyticsPlatform.unknown,
  };
}

class ProductAnalyticsService {
  ProductAnalyticsService({
    ProductAnalyticsSettingsReader? readSettings,
    ProductAnalyticsEnabledSetter? setEnabled,
    ProductAnalyticsEventTracker? track,
    ProductAnalyticsFlusher? flush,
    ProductAnalyticsConsentVersionReader? consentVersion,
  }) : _readSettings = readSettings ?? rust_analytics.productAnalyticsSettings,
       _setEnabled = setEnabled ?? rust_analytics.setProductAnalyticsEnabled,
       _track = track ?? rust_analytics.trackProductAnalyticsEvent,
       _flush = flush ?? rust_analytics.flushProductAnalytics,
       _consentVersion = consentVersion ?? rust_analytics.productAnalyticsConsentVersion;

  final ProductAnalyticsSettingsReader _readSettings;
  final ProductAnalyticsEnabledSetter _setEnabled;
  final ProductAnalyticsEventTracker _track;
  final ProductAnalyticsFlusher _flush;
  final ProductAnalyticsConsentVersionReader _consentVersion;
  final _logger = Logger('ProductAnalyticsService');

  Future<rust_analytics.ProductAnalyticsSettings> settings() async {
    try {
      return await _readSettings();
    } catch (e, st) {
      _logger.warning('Failed to read product analytics settings', e, st);
      return _disabledSettings(await _consentVersionOrFallback());
    }
  }

  Future<rust_analytics.ProductAnalyticsSettings> setAnalyticsEnabled(bool enabled) async {
    final consentVersion = await _consentVersionOrFallback();
    try {
      return await _setEnabled(
        enabled: enabled,
        consentVersion: consentVersion,
      );
    } catch (e, st) {
      _logger.warning('Failed to update product analytics consent', e, st);
      return _disabledSettings(consentVersion);
    }
  }

  Future<void> trackAppStarted({required AnalyticsPlatform platform}) {
    return _trackEvent(
      rust_analytics.ProductAnalyticsEventName.appStarted,
      stringProps: [_prop('platform', platform.value)],
    );
  }

  Future<void> trackAppForegrounded({required AnalyticsPlatform platform}) {
    return _trackEvent(
      rust_analytics.ProductAnalyticsEventName.appForegrounded,
      stringProps: [_prop('platform', platform.value)],
    );
  }

  Future<void> trackAppBackgrounded({required AnalyticsPlatform platform}) {
    return _trackEvent(
      rust_analytics.ProductAnalyticsEventName.appBackgrounded,
      stringProps: [_prop('platform', platform.value)],
    );
  }

  Future<void> trackOnboardingStarted() =>
      _trackEvent(rust_analytics.ProductAnalyticsEventName.onboardingStarted);

  Future<void> trackOnboardingCompleted() =>
      _trackEvent(rust_analytics.ProductAnalyticsEventName.onboardingCompleted);

  Future<void> flush() async {
    try {
      await _flush();
    } catch (e, st) {
      _logger.warning('Failed to flush product analytics', e, st);
    }
  }

  Future<void> _trackEvent(
    rust_analytics.ProductAnalyticsEventName name, {
    List<rust_analytics.ProductAnalyticsStringProp> stringProps = const [],
  }) async {
    try {
      await _track(
        event: rust_analytics.ProductAnalyticsEvent(
          name: name,
          stringProps: stringProps,
          numberProps: const [],
        ),
      );
    } catch (e, st) {
      _logger.fine('Product analytics event ignored: $name', e, st);
    }
  }

  Future<String> _consentVersionOrFallback() async {
    try {
      final version = await _consentVersion();
      return version.trim().isEmpty ? _fallbackConsentVersion : version;
    } catch (e, st) {
      _logger.warning('Failed to read product analytics consent version', e, st);
      return _fallbackConsentVersion;
    }
  }

  rust_analytics.ProductAnalyticsSettings _disabledSettings(String consentVersion) {
    final now = DateTime.now().toUtc();
    return rust_analytics.ProductAnalyticsSettings(
      enabled: false,
      createdAt: now,
      updatedAt: now,
      consentVersion: consentVersion,
    );
  }

  rust_analytics.ProductAnalyticsStringProp _prop(String key, String value) {
    return rust_analytics.ProductAnalyticsStringProp(key: key, value: value);
  }
}
