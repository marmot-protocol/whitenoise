import 'dart:async' show StreamSubscription, unawaited;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/services/push_registration_service.dart';
import 'package:whitenoise/services/push_token_service.dart';

final _logger = Logger('PushRegistrationProvider');

final pushTokenSourceProvider = Provider<PushTokenSource>((ref) {
  final service = PushTokenService();
  ref.onDispose(service.dispose);
  return service;
});

final pushRegistrationConfigProvider = Provider<PushRegistrationConfig>(
  (_) => PushRegistrationConfig.defaults(),
);

final pushRegistrationServiceProvider = Provider<PushRegistrationSyncer>((ref) {
  return PushRegistrationService(
    tokenSource: ref.watch(pushTokenSourceProvider),
    config: ref.watch(pushRegistrationConfigProvider),
  );
});

class PushRegistrationStatusNotifier extends Notifier<PushRegistrationSyncResult?> {
  @override
  PushRegistrationSyncResult? build() => null;

  void setResult(PushRegistrationSyncResult result) {
    state = result;
  }
}

final pushRegistrationStatusProvider =
    NotifierProvider<PushRegistrationStatusNotifier, PushRegistrationSyncResult?>(
      PushRegistrationStatusNotifier.new,
    );

final pushRegistrationControllerProvider = Provider.autoDispose<void>((ref) {
  final accountPubkey = ref.watch(authProvider).value;
  if (accountPubkey == null) return;

  final service = ref.read(pushRegistrationServiceProvider);
  unawaited(_syncCurrentPushToken(ref, service, accountPubkey));

  late final StreamSubscription<ProviderPushToken> subscription;
  subscription = service.tokenUpdates.listen(
    (token) {
      unawaited(_syncPushToken(ref, service, accountPubkey, token));
    },
    onError: (Object error, StackTrace stackTrace) {
      _logger.warning('Push token update stream failed', error, stackTrace);
    },
  );

  ref.onDispose(() {
    unawaited(subscription.cancel());
  });
});

Future<void> _syncCurrentPushToken(
  Ref ref,
  PushRegistrationSyncer service,
  String accountPubkey,
) async {
  try {
    final result = await service.syncCurrentToken(accountPubkey);
    _storeResult(ref, result);
  } catch (error, stackTrace) {
    _logger.warning('Current push token sync failed', error, stackTrace);
    _storeResult(
      ref,
      PushRegistrationSyncResult(
        status: PushRegistrationSyncStatus.failed,
        error: error,
      ),
    );
  }
}

Future<void> _syncPushToken(
  Ref ref,
  PushRegistrationSyncer service,
  String accountPubkey,
  ProviderPushToken token,
) async {
  try {
    final result = await service.syncToken(accountPubkey, token);
    _storeResult(ref, result);
  } catch (error, stackTrace) {
    _logger.warning('Push token update sync failed', error, stackTrace);
    _storeResult(
      ref,
      PushRegistrationSyncResult(
        status: PushRegistrationSyncStatus.failed,
        error: error,
      ),
    );
  }
}

void _storeResult(Ref ref, PushRegistrationSyncResult result) {
  if (!ref.mounted) return;
  ref.read(pushRegistrationStatusProvider.notifier).setResult(result);
}
