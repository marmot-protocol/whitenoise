import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/services/push_token_service.dart';
import 'package:whitenoise/src/rust/api/notifications.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channelName = 'org.parres.whitenoise/push_notifications';
  const channel = MethodChannel(channelName);

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      null,
    );
  });

  group('ProviderPushToken', () {
    test('fromMap parses APNS tokens', () {
      final token = ProviderPushToken.fromMap({
        'platform': 'apns',
        'rawToken': ' abc123 ',
      });

      expect(
        token,
        const ProviderPushToken(
          platform: PushPlatform.apns,
          rawToken: 'abc123',
        ),
      );
    });

    test('fromMap parses FCM tokens', () {
      final token = ProviderPushToken.fromMap({
        'platform': 'fcm',
        'rawToken': 'token-123',
      });

      expect(
        token,
        const ProviderPushToken(
          platform: PushPlatform.fcm,
          rawToken: 'token-123',
        ),
      );
    });

    test('fromMap rejects missing platform or token', () {
      expect(ProviderPushToken.fromMap({'platform': 'fcm'}), isNull);
      expect(ProviderPushToken.fromMap({'rawToken': 'token'}), isNull);
      expect(
        ProviderPushToken.fromMap({'platform': 'web', 'rawToken': 'token'}),
        isNull,
      );
      expect(
        ProviderPushToken.fromMap({'platform': 'fcm', 'rawToken': ' '}),
        isNull,
      );
    });
  });

  group('PushTokenService', () {
    test('returns null without touching channel when disabled', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (call) async {
          calls.add(call);
          return null;
        },
      );

      final service = PushTokenService();
      addTearDown(service.dispose);

      expect(await service.getProviderPushToken(), isNull);
      expect(calls, isEmpty);
    });

    test('returns token from native channel', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (call) async {
          expect(call.method, 'getProviderPushToken');
          return {'platform': 'fcm', 'rawToken': 'native-token'};
        },
      );

      final service = PushTokenService();
      addTearDown(service.dispose);

      expect(
        await service.getProviderPushToken(),
        const ProviderPushToken(
          platform: PushPlatform.fcm,
          rawToken: 'native-token',
        ),
      );
    });

    test(
      'returns false when permission request channel returns null',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          (call) async => null,
        );

        final service = PushTokenService();
        addTearDown(service.dispose);

        expect(await service.requestNotificationPermission(), isFalse);
      },
    );

    test('returns permission result from native channel', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (call) async {
          expect(call.method, 'requestNotificationPermission');
          return true;
        },
      );

      final service = PushTokenService();
      addTearDown(service.dispose);

      expect(await service.requestNotificationPermission(), isTrue);
    });

    test('returns null when native channel throws', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (_) async => throw PlatformException(code: 'unavailable'),
      );

      final service = PushTokenService();
      addTearDown(service.dispose);

      expect(await service.getProviderPushToken(), isNull);
    });

    test('returns false when permission channel throws', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (_) async => throw StateError('channel failed'),
      );

      final service = PushTokenService();
      addTearDown(service.dispose);

      expect(await service.requestNotificationPermission(), isFalse);
    });

    test('ignores unrelated native method calls', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final service = PushTokenService();
      addTearDown(service.dispose);

      var emitted = false;
      final subscription = service.tokenUpdates.listen((_) {
        emitted = true;
      });
      addTearDown(subscription.cancel);

      await service.handleNativeMethodCall(const MethodCall('ignored'));
      await service.handleNativeMethodCall(
        const MethodCall('providerPushTokenUpdated', {'platform': 'fcm'}),
      );
      await Future<void>.delayed(Duration.zero);

      expect(emitted, isFalse);
    });

    test('emits native token updates', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final service = PushTokenService();
      addTearDown(service.dispose);

      final nextToken = service.tokenUpdates.first;
      await service.handleNativeMethodCall(
        const MethodCall('providerPushTokenUpdated', {
          'platform': 'apns',
          'rawToken': 'updated-token',
        }),
      );

      expect(
        await nextToken,
        const ProviderPushToken(
          platform: PushPlatform.apns,
          rawToken: 'updated-token',
        ),
      );
    });
  });
}
