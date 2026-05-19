import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whitenoise/services/product_analytics_service.dart';
import 'package:whitenoise/src/rust/api/product_analytics.dart' as rust_analytics;

class ProductAnalyticsSettingsNotifier
    extends AsyncNotifier<rust_analytics.ProductAnalyticsSettings> {
  @override
  Future<rust_analytics.ProductAnalyticsSettings> build() {
    return ref.read(productAnalyticsServiceProvider).settings();
  }

  Future<void> setEnabled(bool enabled) async {
    final current = state.value;
    if (current != null) {
      final now = DateTime.now().toUtc();
      state = AsyncData(
        rust_analytics.ProductAnalyticsSettings(
          enabled: enabled,
          createdAt: current.createdAt,
          updatedAt: now,
          consentVersion: current.consentVersion,
        ),
      );
    }

    final settings = await ref.read(productAnalyticsServiceProvider).setAnalyticsEnabled(enabled);
    state = AsyncData(settings);
  }
}

final productAnalyticsSettingsProvider =
    AsyncNotifierProvider<
      ProductAnalyticsSettingsNotifier,
      rust_analytics.ProductAnalyticsSettings
    >(ProductAnalyticsSettingsNotifier.new);
