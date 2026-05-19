import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whitenoise/services/product_analytics_service.dart';
import 'package:whitenoise/src/rust/api/product_analytics.dart' as rust_analytics;

class ProductAnalyticsSettingsNotifier
    extends AsyncNotifier<rust_analytics.ProductAnalyticsSettings> {
  int _setEnabledRequestId = 0;

  @override
  Future<rust_analytics.ProductAnalyticsSettings> build() {
    return ref.read(productAnalyticsServiceProvider).settings();
  }

  Future<void> setEnabled(bool enabled) async {
    final requestId = ++_setEnabledRequestId;
    final current = state.value;
    if (requestId == _setEnabledRequestId && current != null) {
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

    final analyticsService = ref.read(productAnalyticsServiceProvider);
    final settings = await analyticsService.setAnalyticsEnabled(enabled);
    if (requestId == _setEnabledRequestId) {
      state = AsyncData(settings);
    }
  }
}

final productAnalyticsSettingsProvider =
    AsyncNotifierProvider<
      ProductAnalyticsSettingsNotifier,
      rust_analytics.ProductAnalyticsSettings
    >(ProductAnalyticsSettingsNotifier.new);
