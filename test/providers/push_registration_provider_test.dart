import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/providers/push_registration_provider.dart';
import 'package:whitenoise/services/push_registration_service.dart';
import 'package:whitenoise/services/push_token_service.dart';
import 'package:whitenoise/src/rust/api/notifications.dart';

import '../test_helpers.dart';

void main() {
  group('pushRegistrationControllerProvider', () {
    late _FakePushRegistrationSyncer syncer;

    setUp(() {
      syncer = _FakePushRegistrationSyncer();
    });

    tearDown(() {
      syncer.dispose();
    });

    test('does nothing when no account is active', () async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => _TestAuthNotifier(null)),
          pushRegistrationServiceProvider.overrideWithValue(syncer),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authProvider.future);
      final subscription = container.listen(
        pushRegistrationControllerProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);
      await Future<void>.delayed(Duration.zero);

      expect(syncer.currentSyncCalls, isEmpty);
      expect(container.read(pushRegistrationStatusProvider), isNull);
    });

    test('syncs current native token when an account is active', () async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => _TestAuthNotifier(testPubkeyA)),
          pushRegistrationServiceProvider.overrideWithValue(syncer),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authProvider.future);
      final subscription = container.listen(
        pushRegistrationControllerProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);
      await Future<void>.delayed(Duration.zero);

      expect(syncer.currentSyncCalls, [testPubkeyA]);
      expect(
        container.read(pushRegistrationStatusProvider)?.status,
        PushRegistrationSyncStatus.registered,
      );
    });

    test(
      'syncs pushed native token refreshes for the active account',
      () async {
        final container = ProviderContainer(
          overrides: [
            authProvider.overrideWith(() => _TestAuthNotifier(testPubkeyA)),
            pushRegistrationServiceProvider.overrideWithValue(syncer),
          ],
        );
        addTearDown(container.dispose);

        await container.read(authProvider.future);
        final subscription = container.listen(
          pushRegistrationControllerProvider,
          (_, _) {},
        );
        addTearDown(subscription.close);
        await Future<void>.delayed(Duration.zero);

        const token = ProviderPushToken(
          platform: PushPlatform.apns,
          rawToken: 'apns-token',
        );
        syncer.emit(token);
        await Future<void>.delayed(Duration.zero);

        expect(syncer.tokenSyncCalls, [(testPubkeyA, token)]);
        expect(
          container.read(pushRegistrationStatusProvider)?.status,
          PushRegistrationSyncStatus.registered,
        );
      },
    );

    test('stores failed status when current token sync throws', () async {
      syncer.throwOnCurrentSync = true;
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => _TestAuthNotifier(testPubkeyA)),
          pushRegistrationServiceProvider.overrideWithValue(syncer),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authProvider.future);
      final subscription = container.listen(
        pushRegistrationControllerProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(pushRegistrationStatusProvider)?.status,
        PushRegistrationSyncStatus.failed,
      );
    });

    test('stores failed status when token refresh sync throws', () async {
      syncer.throwOnTokenSync = true;
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => _TestAuthNotifier(testPubkeyA)),
          pushRegistrationServiceProvider.overrideWithValue(syncer),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authProvider.future);
      final subscription = container.listen(
        pushRegistrationControllerProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);
      await Future<void>.delayed(Duration.zero);

      syncer.emit(
        const ProviderPushToken(
          platform: PushPlatform.apns,
          rawToken: 'apns-token',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(pushRegistrationStatusProvider)?.status,
        PushRegistrationSyncStatus.failed,
      );
    });
  });
}

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier(this.pubkey);

  final String? pubkey;

  @override
  Future<String?> build() async => pubkey;
}

class _FakePushRegistrationSyncer implements PushRegistrationSyncer {
  final _updates = StreamController<ProviderPushToken>.broadcast();

  final currentSyncCalls = <String>[];
  final tokenSyncCalls = <(String, ProviderPushToken)>[];
  bool throwOnCurrentSync = false;
  bool throwOnTokenSync = false;
  PushRegistrationSyncResult result = const PushRegistrationSyncResult(
    status: PushRegistrationSyncStatus.registered,
  );

  @override
  Stream<ProviderPushToken> get tokenUpdates => _updates.stream;

  @override
  Future<PushRegistrationSyncResult> syncCurrentToken(
    String accountPubkey,
  ) async {
    if (throwOnCurrentSync) throw StateError('current sync failed');
    currentSyncCalls.add(accountPubkey);
    return result;
  }

  @override
  Future<PushRegistrationSyncResult> syncToken(
    String accountPubkey,
    ProviderPushToken token,
  ) async {
    if (throwOnTokenSync) throw StateError('token sync failed');
    tokenSyncCalls.add((accountPubkey, token));
    return result;
  }

  void emit(ProviderPushToken token) {
    _updates.add(token);
  }

  void dispose() {
    _updates.close();
  }
}
