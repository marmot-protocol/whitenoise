import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:whitenoise/constants/feature_flags.dart';

final featureFlagProvider = Provider.family<bool, FeatureFlag>(
  (ref, flag) => featureFlagValue(flag),
);
