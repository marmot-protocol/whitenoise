import 'dart:convert' show utf8;

import 'package:crypto/crypto.dart' show sha256;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/providers/auth_provider.dart';

const _storageKeyPrefix = 'analytics_onboarding_resolved';

final analyticsOnboardingResolutionServiceProvider = Provider<AnalyticsOnboardingResolutionService>(
  (ref) {
    return AnalyticsOnboardingResolutionService(ref.read(secureStorageProvider));
  },
);

final analyticsOnboardingResolvedProvider = FutureProvider.family<bool, String>((ref, pubkey) {
  return ref.read(analyticsOnboardingResolutionServiceProvider).isResolved(pubkey);
});

class AnalyticsOnboardingResolutionService {
  AnalyticsOnboardingResolutionService(this._storage);

  final FlutterSecureStorage _storage;
  final _logger = Logger('AnalyticsOnboardingResolutionService');

  Future<bool> isResolved(String pubkey) async {
    try {
      final value = await _storage.read(key: _storageKey(pubkey));
      return value == 'true';
    } catch (e, st) {
      _logger.warning('Failed to read analytics onboarding resolution', e, st);
      return false;
    }
  }

  Future<void> markResolved(String pubkey) async {
    try {
      await _storage.write(key: _storageKey(pubkey), value: 'true');
    } catch (e, st) {
      _logger.warning('Failed to persist analytics onboarding resolution', e, st);
    }
  }

  String _storageKey(String pubkey) {
    final accountDigest = sha256.convert(utf8.encode(pubkey)).toString();
    return '${_storageKeyPrefix}_$accountDigest';
  }
}
