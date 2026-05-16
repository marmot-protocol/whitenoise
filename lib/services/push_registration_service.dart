import 'package:flutter/services.dart' show appFlavor;
import 'package:logging/logging.dart';
import 'package:whitenoise/services/push_token_service.dart';
import 'package:whitenoise/src/rust/api/notifications.dart' as notifications_api;

final _logger = Logger('PushRegistrationService');

class PushRegistrationConfig {
  const PushRegistrationConfig({required this.serverPubkey, this.relayHint});

  static const defaultRelayHint = 'wss://relay.primal.net';
  static const stagingServerPubkey =
      'e36667690baeef94b50fcefab2cb373ac701368dc0a261256f52ba9bda50145a';
  static const productionServerPubkey =
      '9a3d5dd77419f7f416c956c7878989cbe6a548e641916b4f63eb861b1ad40ef2';

  static const _serverPubkeyOverride = String.fromEnvironment(
    'WN_PUSH_SERVER_PUBKEY',
  );
  static const _relayHintOverride = String.fromEnvironment('WN_PUSH_RELAY_HINT');

  static PushRegistrationConfig defaults({
    String? flavor = appFlavor,
    String serverPubkeyOverride = _serverPubkeyOverride,
    String relayHintOverride = _relayHintOverride,
  }) {
    final override = serverPubkeyOverride.trim();
    final relayOverride = relayHintOverride.trim();
    return PushRegistrationConfig(
      serverPubkey: override.isNotEmpty ? override : serverPubkeyForFlavor(flavor),
      relayHint: relayOverride.isNotEmpty ? relayOverride : defaultRelayHint,
    );
  }

  static String serverPubkeyForFlavor(String? flavor) {
    return switch (flavor) {
      'staging' => stagingServerPubkey,
      'production' => productionServerPubkey,
      _ => '',
    };
  }

  final String serverPubkey;
  final String? relayHint;

  bool get isConfigured => serverPubkey.trim().isNotEmpty;

  String? get normalizedRelayHint {
    final value = relayHint?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }
}

enum PushRegistrationSyncStatus {
  registered,
  notConfigured,
  tokenUnavailable,
  failed,
}

class PushRegistrationSyncResult {
  const PushRegistrationSyncResult({
    required this.status,
    this.registration,
    this.error,
  });

  final PushRegistrationSyncStatus status;
  final notifications_api.PushRegistration? registration;
  final Object? error;
}

abstract class PushRegistrationSyncer {
  Stream<ProviderPushToken> get tokenUpdates;

  Future<PushRegistrationSyncResult> syncCurrentToken(String accountPubkey);

  Future<PushRegistrationSyncResult> syncToken(
    String accountPubkey,
    ProviderPushToken token,
  );
}

class PushRegistrationService implements PushRegistrationSyncer {
  const PushRegistrationService({
    required PushTokenSource tokenSource,
    required PushRegistrationConfig config,
  }) : _tokenSource = tokenSource,
       _config = config;

  final PushTokenSource _tokenSource;
  final PushRegistrationConfig _config;

  @override
  Stream<ProviderPushToken> get tokenUpdates => _tokenSource.tokenUpdates;

  @override
  Future<PushRegistrationSyncResult> syncCurrentToken(
    String accountPubkey,
  ) async {
    if (!_config.isConfigured) {
      _logger.info(
        'Push registration skipped: WN_PUSH_SERVER_PUBKEY is not configured',
      );
      return const PushRegistrationSyncResult(
        status: PushRegistrationSyncStatus.notConfigured,
      );
    }

    final token = await _tokenSource.getProviderPushToken();
    if (token == null) {
      _logger.info('Push registration skipped: provider token is unavailable');
      return const PushRegistrationSyncResult(
        status: PushRegistrationSyncStatus.tokenUnavailable,
      );
    }

    await _tokenSource.requestNotificationPermission();
    return syncToken(accountPubkey, token);
  }

  @override
  Future<PushRegistrationSyncResult> syncToken(
    String accountPubkey,
    ProviderPushToken token,
  ) async {
    if (!_config.isConfigured) {
      return const PushRegistrationSyncResult(
        status: PushRegistrationSyncStatus.notConfigured,
      );
    }

    try {
      final registration = await notifications_api.upsertPushRegistration(
        pubkey: accountPubkey,
        platform: token.platform,
        rawToken: token.rawToken,
        serverPubkey: _config.serverPubkey.trim(),
        relayHint: _config.normalizedRelayHint,
      );
      _logger.info('Push registration synced for ${token.platform.name}');
      return PushRegistrationSyncResult(
        status: PushRegistrationSyncStatus.registered,
        registration: registration,
      );
    } catch (error, stackTrace) {
      _logger.warning('Push registration sync failed', error, stackTrace);
      return PushRegistrationSyncResult(
        status: PushRegistrationSyncStatus.failed,
        error: error,
      );
    }
  }
}
