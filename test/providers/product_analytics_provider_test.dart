import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/providers/product_analytics_provider.dart';
import 'package:whitenoise/services/product_analytics_service.dart';
import 'package:whitenoise/src/rust/api/product_analytics.dart';

void main() {
  group('ProductAnalyticsSettingsNotifier', () {
    test('ignores stale setEnabled responses', () async {
      final api = _DeferredProductAnalyticsApi();
      final container = ProviderContainer(
        overrides: [productAnalyticsServiceProvider.overrideWithValue(api.service())],
      );
      addTearDown(container.dispose);

      await container.read(productAnalyticsSettingsProvider.future);

      final first = container.read(productAnalyticsSettingsProvider.notifier).setEnabled(true);
      final second = container.read(productAnalyticsSettingsProvider.notifier).setEnabled(false);
      await Future<void>.delayed(Duration.zero);

      api.completeSetEnabledCall(1, enabled: false);
      await second;
      api.completeSetEnabledCall(0, enabled: true);
      await first;

      expect(container.read(productAnalyticsSettingsProvider).value?.enabled, isFalse);
    });
  });
}

class _DeferredProductAnalyticsApi {
  final _setEnabledCalls = <Completer<ProductAnalyticsSettings>>[];

  ProductAnalyticsService service() {
    return ProductAnalyticsService(
      readSettings: () async => _settings(enabled: false),
      setEnabled: ({required enabled, required consentVersion}) {
        final completer = Completer<ProductAnalyticsSettings>();
        _setEnabledCalls.add(completer);
        return completer.future;
      },
      track: ({required event}) async => ProductAnalyticsTrackStatus.queued,
      flush: () async => ProductAnalyticsFlushStatus.flushed,
      consentVersion: () async => 'product-analytics-v1',
    );
  }

  void completeSetEnabledCall(int index, {required bool enabled}) {
    _setEnabledCalls[index].complete(_settings(enabled: enabled));
  }

  ProductAnalyticsSettings _settings({required bool enabled}) {
    final now = DateTime(2026);
    return ProductAnalyticsSettings(
      enabled: enabled,
      createdAt: now,
      updatedAt: now,
      consentVersion: 'product-analytics-v1',
    );
  }
}
