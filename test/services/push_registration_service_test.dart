import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/services/push_registration_service.dart';
import 'package:whitenoise/services/push_token_service.dart';
import 'package:whitenoise/src/rust/api/notifications.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';

import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockWnApi mockApi;
  late _FakePushTokenSource tokenSource;

  setUpAll(() {
    mockApi = MockWnApi();
    RustLib.initMock(api: mockApi);
  });

  setUp(() {
    mockApi.reset();
    tokenSource = _FakePushTokenSource();
  });

  tearDown(() {
    tokenSource.dispose();
  });

  group('PushRegistrationConfig', () {
    test('normalizes blank relay hints to null', () {
      const config = PushRegistrationConfig(
        serverPubkey: testPubkeyB,
        relayHint: ' ',
      );

      expect(config.normalizedRelayHint, isNull);
      expect(config.isConfigured, isTrue);
    });

    test('uses staging push server pubkey and default relay hint for staging flavor', () {
      final config = PushRegistrationConfig.defaults(flavor: 'staging');

      expect(config.serverPubkey, PushRegistrationConfig.stagingServerPubkey);
      expect(config.relayHint, PushRegistrationConfig.defaultRelayHint);
    });

    test('uses production push server pubkey and default relay hint for production flavor', () {
      final config = PushRegistrationConfig.defaults(flavor: 'production');

      expect(config.serverPubkey, PushRegistrationConfig.productionServerPubkey);
      expect(config.relayHint, PushRegistrationConfig.defaultRelayHint);
    });

    test('leaves unknown flavors unconfigured', () {
      final config = PushRegistrationConfig.defaults();

      expect(config.serverPubkey, isEmpty);
      expect(config.isConfigured, isFalse);
      expect(config.relayHint, PushRegistrationConfig.defaultRelayHint);
    });

    test('honors explicit server and relay overrides', () {
      final config = PushRegistrationConfig.defaults(
        flavor: 'staging',
        serverPubkeyOverride: testPubkeyB,
        relayHintOverride: ' wss://relay.example.com ',
      );

      expect(config.serverPubkey, testPubkeyB);
      expect(config.normalizedRelayHint, 'wss://relay.example.com');
    });
  });

  group('PushRegistrationService', () {
    test('skips sync when MIP-05 server pubkey is not configured', () async {
      final service = PushRegistrationService(
        tokenSource: tokenSource,
        config: const PushRegistrationConfig(serverPubkey: ''),
      );

      final result = await service.syncCurrentToken(testPubkeyA);

      expect(result.status, PushRegistrationSyncStatus.notConfigured);
      expect(mockApi.upsertPushRegistrationCallCount, 0);
      expect(tokenSource.getTokenCallCount, 0);
    });

    test('skips sync when native token is unavailable', () async {
      final service = PushRegistrationService(
        tokenSource: tokenSource,
        config: const PushRegistrationConfig(serverPubkey: testPubkeyB),
      );

      final result = await service.syncCurrentToken(testPubkeyA);

      expect(result.status, PushRegistrationSyncStatus.tokenUnavailable);
      expect(mockApi.upsertPushRegistrationCallCount, 0);
      expect(tokenSource.getTokenCallCount, 1);
    });

    test('passes native token to Rust push registration API', () async {
      tokenSource.token = const ProviderPushToken(
        platform: PushPlatform.fcm,
        rawToken: 'fcm-token',
      );
      final service = PushRegistrationService(
        tokenSource: tokenSource,
        config: const PushRegistrationConfig(
          serverPubkey: testPubkeyB,
          relayHint: ' wss://push.example.com ',
        ),
      );

      final result = await service.syncCurrentToken(testPubkeyA);

      expect(result.status, PushRegistrationSyncStatus.registered);
      expect(tokenSource.requestPermissionCallCount, 1);
      expect(mockApi.upsertPushRegistrationCallCount, 1);
      expect(mockApi.lastPushRegistrationPubkey, testPubkeyA);
      expect(mockApi.lastPushRegistrationPlatform, PushPlatform.fcm);
      expect(mockApi.lastPushRegistrationRawToken, 'fcm-token');
      expect(mockApi.lastPushRegistrationServerPubkey, testPubkeyB);
      expect(mockApi.lastPushRegistrationRelayHint, 'wss://push.example.com');
    });

    test(
      'syncToken returns failed result when Rust rejects registration',
      () async {
        mockApi.shouldFailUpsertPushRegistration = true;
        final service = PushRegistrationService(
          tokenSource: tokenSource,
          config: const PushRegistrationConfig(serverPubkey: testPubkeyB),
        );

        final result = await service.syncToken(
          testPubkeyA,
          const ProviderPushToken(
            platform: PushPlatform.apns,
            rawToken: 'apns-token',
          ),
        );

        expect(result.status, PushRegistrationSyncStatus.failed);
        expect(result.error, isNotNull);
        expect(mockApi.upsertPushRegistrationCallCount, 1);
      },
    );
  });
}

class _FakePushTokenSource implements PushTokenSource {
  final _updates = StreamController<ProviderPushToken>.broadcast();

  ProviderPushToken? token;
  int getTokenCallCount = 0;
  int requestPermissionCallCount = 0;

  @override
  Stream<ProviderPushToken> get tokenUpdates => _updates.stream;

  @override
  Future<ProviderPushToken?> getProviderPushToken() async {
    getTokenCallCount++;
    return token;
  }

  @override
  Future<bool> requestNotificationPermission() async {
    requestPermissionCallCount++;
    return true;
  }

  void dispose() {
    _updates.close();
  }
}
