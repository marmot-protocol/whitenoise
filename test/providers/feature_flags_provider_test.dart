import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/constants/feature_flags.dart';
import 'package:whitenoise/providers/feature_flags_provider.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('featureFlagValue', () {
    test('leaveGroup is disabled by default', () {
      expect(featureFlagValue(FeatureFlag.leaveGroup), isFalse);
    });
  });

  group('featureFlagProvider', () {
    test('leaveGroup is disabled by default', () {
      expect(container.read(featureFlagProvider(FeatureFlag.leaveGroup)), isFalse);
    });

    test('returns same value as featureFlagValue', () {
      final providerValue = container.read(featureFlagProvider(FeatureFlag.leaveGroup));

      expect(providerValue, featureFlagValue(FeatureFlag.leaveGroup));
    });
  });
}
