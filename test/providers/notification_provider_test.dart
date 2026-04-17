import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/providers/notification_provider.dart';
import 'package:whitenoise/services/notification_service.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';

import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockWnApi mockApi;

  setUpAll(() {
    mockApi = MockWnApi();
    RustLib.initMock(api: mockApi);
  });

  group('notificationListenerProvider', () {
    late ProviderContainer container;

    setUp(() {
      mockApi.reset();
      container = ProviderContainer();
    });

    tearDown(() => container.dispose());

    test('can be read without error', () {
      expect(() => container.read(notificationListenerProvider), returnsNormally);
    });
  });

  group('notificationServiceProvider', () {
    test('creates a NotificationService', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = container.read(notificationServiceProvider);

      expect(service, isA<NotificationService>());
    });
  });

  group('routePendingTap', () {
    const tap = PendingNotificationTap(
      groupId: 'group-1',
      isInvite: false,
      receiverPubkey: 'pubkey-1',
    );

    test('is a no-op when pending is null', () async {
      String? switched;
      await routePendingTap(
        pending: null,
        isMounted: true,
        currentActivePubkey: 'someone',
        switchToProfile: (pk) async {
          switched = pk;
        },
      );

      expect(switched, isNull);
    });

    test('is a no-op when not mounted', () async {
      String? switched;
      await routePendingTap(
        pending: tap,
        isMounted: false,
        currentActivePubkey: 'someone-else',
        switchToProfile: (pk) async {
          switched = pk;
        },
      );

      expect(switched, isNull);
    });

    test('routes the tap when mounted and payload present', () async {
      String? switched;
      await routePendingTap(
        pending: tap,
        isMounted: true,
        currentActivePubkey: 'someone-else',
        switchToProfile: (pk) async {
          switched = pk;
        },
      );

      expect(switched, tap.receiverPubkey);
    });
  });

  group('handleNotificationTap', () {
    test('switches profile when current pubkey differs from target', () async {
      String? switched;

      await handleNotificationTap(
        currentActivePubkey: testPubkeyA,
        switchToProfile: (pk) async {
          switched = pk;
        },
        groupId: testGroupId,
        isInvite: false,
        receiverPubkey: testPubkeyB,
      );

      expect(switched, testPubkeyB);
    });

    test('does not switch profile when current pubkey matches target', () async {
      String? switched;

      await handleNotificationTap(
        currentActivePubkey: testPubkeyA,
        switchToProfile: (pk) async {
          switched = pk;
        },
        groupId: testGroupId,
        isInvite: false,
        receiverPubkey: testPubkeyA,
      );

      expect(switched, isNull);
    });

    test('switches profile when no active pubkey', () async {
      String? switched;

      await handleNotificationTap(
        currentActivePubkey: null,
        switchToProfile: (pk) async {
          switched = pk;
        },
        groupId: testGroupId,
        isInvite: false,
        receiverPubkey: testPubkeyA,
      );

      expect(switched, testPubkeyA);
    });
  });
}
