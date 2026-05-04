enum FeatureFlag { leaveGroup }

const _featureFlagValues = {
  FeatureFlag.leaveGroup: bool.fromEnvironment('LEAVE_GROUP_ENABLED'),
};

bool featureFlagValue(FeatureFlag flag) => _featureFlagValues[flag] ?? false;
