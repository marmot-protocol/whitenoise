import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kDebugMode;
import 'package:flutter/widgets.dart' show Locale, Size, WidgetsBinding;
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:whitenoise/src/rust/api/product_analytics.dart';

const _aptabaseHost = String.fromEnvironment('APTABASE_HOST');
const _aptabaseAppKey = String.fromEnvironment('APTABASE_APP_KEY');
final _logger = Logger('ProductAnalyticsConfig');

class ProductAnalyticsConfigInput {
  const ProductAnalyticsConfigInput({
    required this.appVersion,
    required this.bundleIdentifier,
    required this.locale,
    required this.platform,
    required this.logicalSize,
    required this.isDebug,
    required this.aptabaseHost,
    required this.aptabaseAppKey,
  });

  final String appVersion;
  final String bundleIdentifier;
  final String locale;
  final TargetPlatform platform;
  final Size? logicalSize;
  final bool isDebug;
  final String aptabaseHost;
  final String aptabaseAppKey;
}

Future<ProductAnalyticsConfig> loadProductAnalyticsConfig() async {
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    final dispatcher = WidgetsBinding.instance.platformDispatcher;
    final view = dispatcher.views.isEmpty ? null : dispatcher.views.first;
    final logicalSize = view == null ? null : view.physicalSize / view.devicePixelRatio;

    return buildProductAnalyticsConfig(
      ProductAnalyticsConfigInput(
        appVersion: '${packageInfo.version}+${packageInfo.buildNumber}',
        bundleIdentifier: packageInfo.packageName,
        locale: localeToAnalyticsTag(dispatcher.locale),
        platform: defaultTargetPlatform,
        logicalSize: logicalSize,
        isDebug: kDebugMode,
        aptabaseHost: _aptabaseHost,
        aptabaseAppKey: _aptabaseAppKey,
      ),
    );
  } catch (e, st) {
    _logger.warning('Failed to load product analytics config metadata', e, st);
    return buildProductAnalyticsConfig(
      ProductAnalyticsConfigInput(
        appVersion: 'unknown',
        bundleIdentifier: 'unknown',
        locale: 'unknown',
        platform: defaultTargetPlatform,
        logicalSize: null,
        isDebug: kDebugMode,
        aptabaseHost: '',
        aptabaseAppKey: '',
      ),
    );
  }
}

ProductAnalyticsConfig buildProductAnalyticsConfig(ProductAnalyticsConfigInput input) {
  final host = normalizedAptabaseHost(input.aptabaseHost);
  final appKey = input.aptabaseAppKey.trim();
  final backend = host.isEmpty || appKey.isEmpty
      ? const ProductAnalyticsBackend.disabled()
      : ProductAnalyticsBackend.aptabase(
          config: AptabaseAnalyticsConfig(
            host: host,
            appKey: appKey,
          ),
        );

  return ProductAnalyticsConfig(
    backend: backend,
    appVersion: input.appVersion,
    bundleIdentifier: input.bundleIdentifier,
    deviceClass: deviceClassForPlatform(
      platform: input.platform,
      logicalSize: input.logicalSize,
    ),
    osName: osNameForPlatform(input.platform),
    locale: input.locale,
    isDebug: input.isDebug,
  );
}

String normalizedAptabaseHost(String host) {
  var normalized = host.trim();
  while (normalized.endsWith('/')) {
    normalized = normalized.substring(0, normalized.length - 1);
  }
  return normalized;
}

String localeToAnalyticsTag(Locale locale) {
  final scriptCode = locale.scriptCode;
  final countryCode = locale.countryCode;
  if (scriptCode != null && scriptCode.isNotEmpty) {
    return '${locale.languageCode}-$scriptCode';
  }
  if (countryCode != null && countryCode.isNotEmpty) {
    return '${locale.languageCode}-$countryCode';
  }
  return locale.languageCode;
}

String osNameForPlatform(TargetPlatform platform) {
  return switch (platform) {
    TargetPlatform.android => 'android',
    TargetPlatform.iOS => 'ios',
    TargetPlatform.macOS => 'macos',
    TargetPlatform.linux => 'linux',
    TargetPlatform.windows => 'windows',
    TargetPlatform.fuchsia => 'unknown',
  };
}

ProductAnalyticsDeviceClass deviceClassForPlatform({
  required TargetPlatform platform,
  required Size? logicalSize,
}) {
  return switch (platform) {
    TargetPlatform.macOS ||
    TargetPlatform.linux ||
    TargetPlatform.windows => ProductAnalyticsDeviceClass.desktop,
    TargetPlatform.android || TargetPlatform.iOS => _mobileDeviceClass(logicalSize),
    TargetPlatform.fuchsia => ProductAnalyticsDeviceClass.unknown,
  };
}

ProductAnalyticsDeviceClass _mobileDeviceClass(Size? logicalSize) {
  if (logicalSize == null || logicalSize.isEmpty) {
    return ProductAnalyticsDeviceClass.unknown;
  }
  return logicalSize.shortestSide >= 600
      ? ProductAnalyticsDeviceClass.tablet
      : ProductAnalyticsDeviceClass.phone;
}
