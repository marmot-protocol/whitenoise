import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/providers/analytics_onboarding_provider.dart';
import 'package:whitenoise/providers/auth_provider.dart';

import '../mocks/mock_secure_storage.dart';
import '../test_helpers.dart';

void main() {
  group('AnalyticsOnboardingResolutionService', () {
    test('defaults to unresolved', () async {
      final service = AnalyticsOnboardingResolutionService(MockSecureStorage());

      final resolved = await service.isResolved(testPubkeyA);

      expect(resolved, isFalse);
    });

    test('persists resolution per account', () async {
      final storage = MockSecureStorage();
      final service = AnalyticsOnboardingResolutionService(storage);

      await service.markResolved(testPubkeyA);

      expect(await service.isResolved(testPubkeyA), isTrue);
      expect(await service.isResolved(testPubkeyB), isFalse);
    });

    test('returns unresolved when storage read fails', () async {
      final storage = MockSecureStorage()..shouldThrowOnRead = true;
      final service = AnalyticsOnboardingResolutionService(storage);

      final resolved = await service.isResolved(testPubkeyA);

      expect(resolved, isFalse);
    });

    test('does not throw when storage write fails', () async {
      final storage = MockSecureStorage()..shouldThrowOnWrite = true;
      final service = AnalyticsOnboardingResolutionService(storage);

      await service.markResolved(testPubkeyA);

      storage.shouldThrowOnWrite = false;
      expect(await service.isResolved(testPubkeyA), isFalse);
    });

    test('provider reads persisted resolution from secure storage', () async {
      final storage = MockSecureStorage();
      final container = ProviderContainer(
        overrides: [secureStorageProvider.overrideWithValue(storage)],
      );
      addTearDown(container.dispose);

      await container.read(analyticsOnboardingResolutionServiceProvider).markResolved(testPubkeyA);

      final resolved = await container.read(
        analyticsOnboardingResolvedProvider(testPubkeyA).future,
      );

      expect(resolved, isTrue);
    });
  });
}
