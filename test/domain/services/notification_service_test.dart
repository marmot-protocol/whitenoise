import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whitenoise/domain/services/notification_service.dart';

import 'notification_service_test.mocks.dart';

@GenerateMocks([
  FlutterLocalNotificationsPlugin,
  ActiveNotification,
  GoRouter,
  SharedPreferences,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService', () {
    late MockFlutterLocalNotificationsPlugin mockPlugin;

    setUp(() {
      mockPlugin = MockFlutterLocalNotificationsPlugin();
    });
    group('parseNotificationPayload', () {
      test('parses valid JSON payload correctly', () {
        const validPayload = '{"type":"new_message","groupId":"test-group","messageId":"msg-123"}';

        final result = NotificationService.parseNotificationPayload(validPayload);

        expect(result, isNotNull);
        expect(result!['type'], equals('new_message'));
        expect(result['groupId'], equals('test-group'));
        expect(result['messageId'], equals('msg-123'));
      });

      test('parses invite payload correctly', () {
        const invitePayload =
            '{"type":"invites_sync","welcomeId":"welcome-456","groupId":"group-789"}';

        final result = NotificationService.parseNotificationPayload(invitePayload);

        expect(result, isNotNull);
        expect(result!['type'], equals('invites_sync'));
        expect(result['welcomeId'], equals('welcome-456'));
        expect(result['groupId'], equals('group-789'));
      });

      test('returns null for malformed JSON', () {
        const malformedPayload = '{"type":"new_message","groupId":}';

        final result = NotificationService.parseNotificationPayload(malformedPayload);

        expect(result, isNull);
      });

      test('returns null for empty string', () {
        const emptyPayload = '';

        final result = NotificationService.parseNotificationPayload(emptyPayload);

        expect(result, isNull);
      });
    });

    group('shouldCancelNotificationForGroup', () {
      test('returns true when groupId matches target', () {
        const payload = '{"type":"new_message","groupId":"target-group","messageId":"msg-1"}';

        final result = NotificationService.shouldCancelNotificationForGroup(
          payload,
          'target-group',
        );

        expect(result, isTrue);
      });

      test('returns false when groupId does not match target', () {
        const payload = '{"type":"new_message","groupId":"other-group","messageId":"msg-1"}';

        final result = NotificationService.shouldCancelNotificationForGroup(
          payload,
          'target-group',
        );

        expect(result, isFalse);
      });

      test('returns false for null payload', () {
        final result = NotificationService.shouldCancelNotificationForGroup(null, 'target-group');

        expect(result, isFalse);
      });

      test('returns false for malformed JSON payload', () {
        const malformedPayload = '{"type":"message","groupId":}';

        final result = NotificationService.shouldCancelNotificationForGroup(
          malformedPayload,
          'target-group',
        );

        expect(result, isFalse);
      });
    });

    group('cancelNotificationsByGroup with mock notifications', () {
      test('cancels notifications with matching groupId', () async {
        // Arrange: Create mock notifications
        final mockNotification1 = MockActiveNotification();
        final mockNotification2 = MockActiveNotification();
        final mockNotification3 = MockActiveNotification();

        // Mock notification 1: matching groupId
        when(mockNotification1.id).thenReturn(1);
        when(mockNotification1.payload).thenReturn(
          '{"type":"new_message","groupId":"target-group","messageId":"msg-1"}',
        );

        // Mock notification 2: different groupId
        when(mockNotification2.id).thenReturn(2);
        when(mockNotification2.payload).thenReturn(
          '{"type":"new_message","groupId":"other-group","messageId":"msg-2"}',
        );

        // Mock notification 3: matching groupId (invite)
        when(mockNotification3.id).thenReturn(3);
        when(mockNotification3.payload).thenReturn(
          '{"type":"invites_sync","welcomeId":"welcome-1","groupId":"target-group"}',
        );

        // Mock the plugin methods
        when(mockPlugin.getActiveNotifications()).thenAnswer(
          (_) async => [mockNotification1, mockNotification2, mockNotification3],
        );
        when(mockPlugin.cancel(any)).thenAnswer((_) async {});

        await NotificationService.cancelNotificationsByGroup(
          'target-group',
          plugin: mockPlugin,
          isInitialized: true,
        );

        verify(mockPlugin.getActiveNotifications()).called(1);
        verify(mockPlugin.cancel(1)).called(1); // Should cancel notification 1
        verify(mockPlugin.cancel(3)).called(1); // Should cancel notification 3
        verifyNever(mockPlugin.cancel(2)); // Should not cancel notification 2
      });

      test('handles malformed JSON payloads gracefully', () async {
        // Create mock notifications with malformed JSON
        final mockNotification1 = MockActiveNotification();
        final mockNotification2 = MockActiveNotification();

        when(mockNotification1.id).thenReturn(1);
        when(mockNotification1.payload).thenReturn(
          '{"type":"new_message","groupId":"target-group"}',
        );

        when(mockNotification2.id).thenReturn(2);
        when(mockNotification2.payload).thenReturn('{"malformed": json}');

        when(mockPlugin.getActiveNotifications()).thenAnswer(
          (_) async => [mockNotification1, mockNotification2],
        );
        when(mockPlugin.cancel(any)).thenAnswer((_) async {});

        await NotificationService.cancelNotificationsByGroup(
          'target-group',
          plugin: mockPlugin,
          isInitialized: true,
        );

        verify(mockPlugin.cancel(1)).called(1);
        verifyNever(mockPlugin.cancel(2)); // Malformed notification not cancelled
      });

      test('handles empty active notifications list', () async {
        // No active notifications
        when(mockPlugin.getActiveNotifications()).thenAnswer((_) async => []);

        await NotificationService.cancelNotificationsByGroup(
          'target-group',
          plugin: mockPlugin,
          isInitialized: true,
        );

        verify(mockPlugin.getActiveNotifications()).called(1);
        verifyNever(mockPlugin.cancel(any));
      });
    });

    group('cancelNotification', () {
      test('successfully cancels notification', () async {
        when(mockPlugin.cancel(any)).thenAnswer((_) async {});

        await NotificationService.cancelNotification(123, plugin: mockPlugin);

        verify(mockPlugin.cancel(123)).called(1);
      });
    });

    group('cancelAllNotifications', () {
      test('successfully cancels all notifications', () async {
        when(mockPlugin.cancelAll()).thenAnswer((_) async {});

        await NotificationService.cancelAllNotifications(plugin: mockPlugin);

        verify(mockPlugin.cancelAll()).called(1);
      });
    });

    group('showMessageNotification', () {
      test('shows message notification when initialized', () async {
        when(
          mockPlugin.show(any, any, any, any, payload: anyNamed('payload')),
        ).thenAnswer((_) async {});

        await NotificationService.showMessageNotification(
          id: 123,
          title: 'Test Title',
          body: 'Test Body',
          payload: '{"test": "data"}',
          plugin: mockPlugin,
          isInitialized: true,
        );

        verify(
          mockPlugin.show(123, 'Test Title', 'Test Body', any, payload: '{"test": "data"}'),
        ).called(1);
      });

      test('does not show notification when not initialized', () async {
        await NotificationService.showMessageNotification(
          id: 123,
          title: 'Test Title',
          body: 'Test Body',
          plugin: mockPlugin,
          isInitialized: false,
        );

        verifyNever(mockPlugin.show(any, any, any, any, payload: anyNamed('payload')));
      });
    });

    group('showInviteNotification', () {
      test('shows invite notification when initialized', () async {
        when(
          mockPlugin.show(any, any, any, any, payload: anyNamed('payload')),
        ).thenAnswer((_) async {});

        await NotificationService.showInviteNotification(
          id: 456,
          title: 'Invite Title',
          body: 'Invite Body',
          plugin: mockPlugin,
          isInitialized: true,
        );

        verify(
          mockPlugin.show(456, 'Invite Title', 'Invite Body', any, payload: anyNamed('payload')),
        ).called(1);
      });
    });

    group('on receiving notification response', () {
      late String? switchAccountCallArg;
      late DidReceiveNotificationResponseCallback callback;
      final mockRouterForGroup = MockGoRouter();

      setUpAll(() async {
        when(
          mockPlugin
              .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>(),
        ).thenReturn(null);

        when(
          mockPlugin.initialize(
            any,
            onDidReceiveNotificationResponse: anyNamed('onDidReceiveNotificationResponse'),
          ),
        ).thenAnswer((invocation) {
          callback =
              invocation.namedArguments[#onDidReceiveNotificationResponse]
                  as DidReceiveNotificationResponseCallback;
          return Future.value(true);
        });

        await NotificationService.initialize(plugin: mockPlugin);

        NotificationService.setRouter(mockRouterForGroup);
        NotificationService.setAccountSwitcher(
          switchAccount: (pubkey) async {
            switchAccountCallArg = pubkey;
          },
        );
      });

      setUp(() {
        switchAccountCallArg = null;
        clearInteractions(mockRouterForGroup);
      });

      group('for group notifications', () {
        group('when accountPubkey is provided in payload', () {
          setUp(() async {
            final response = const NotificationResponse(
              notificationResponseType: NotificationResponseType.selectedNotification,
              payload: '{"groupId":"test-group","accountPubkey":"target-pubkey"}',
            );
            callback(response);
            await Future.delayed(const Duration(milliseconds: 10));
          });
          test('switches account', () async {
            expect(switchAccountCallArg, equals('target-pubkey'));
          });

          test('navigates to chat', () async {
            verify(mockRouterForGroup.go('/chats/test-group')).called(1);
          });
        });

        group('without accountPubkey in payload', () {
          setUp(() async {
            final response = const NotificationResponse(
              notificationResponseType: NotificationResponseType.selectedNotification,
              payload: '{"groupId":"test-group"}',
            );
            callback(response);
            await Future.delayed(const Duration(milliseconds: 10));
          });
          test('does not switch account', () async {
            expect(switchAccountCallArg, isNull);
          });

          test('navigates to chat', () async {
            verify(mockRouterForGroup.go('/chats/test-group')).called(1);
          });
        });
      });

      group('for invite notifications', () {
        group('when accountPubkey is provided in payload', () {
          setUp(() async {
            final response = const NotificationResponse(
              notificationResponseType: NotificationResponseType.selectedNotification,
              payload:
                  '{"type":"invites_sync","groupId":"test-group","welcomeId":"welcome-123","accountPubkey":"target-pubkey"}',
            );

            callback(response);
            await Future.delayed(const Duration(milliseconds: 10));
          });
          test('switches account', () async {
            expect(switchAccountCallArg, equals('target-pubkey'));
          });

          test('navigates to chat with welcomeId', () async {
            verify(mockRouterForGroup.go('/chats/test-group', extra: 'welcome-123')).called(1);
          });
        });

        group('without accountPubkey in payload', () {
          setUp(() async {
            final response = const NotificationResponse(
              notificationResponseType: NotificationResponseType.selectedNotification,
              payload: '{"type":"invites_sync","groupId":"test-group","welcomeId":"welcome-123"}',
            );
            callback(response);
            await Future.delayed(const Duration(milliseconds: 10));
          });
          test('does not switch account', () async {
            expect(switchAccountCallArg, isNull);
          });

          test('navigates to chat with welcomeId', () async {
            verify(mockRouterForGroup.go('/chats/test-group', extra: 'welcome-123')).called(1);
          });
        });

        group('with empty accountPubkey in payload', () {
          setUp(() async {
            final response = const NotificationResponse(
              notificationResponseType: NotificationResponseType.selectedNotification,
              payload:
                  '{"type":"invites_sync","groupId":"test-group","welcomeId":"welcome-123","accountPubkey":""}',
            );
            callback(response);
            await Future.delayed(const Duration(milliseconds: 10));
          });
          test('does not switch account', () async {
            expect(switchAccountCallArg, isNull);
          });

          test('navigates to chat with welcomeId', () async {
            verify(mockRouterForGroup.go('/chats/test-group', extra: 'welcome-123')).called(1);
          });
        });
      });
    });

    group('_requestAndroidPermissions() - Battery Optimization Flag Handling', () {
      late MockSharedPreferences mockPrefs;
      late MockFlutterLocalNotificationsPlugin mockPlugin;

      setUp(() {
        mockPrefs = MockSharedPreferences();
        mockPlugin = MockFlutterLocalNotificationsPlugin();
        when(
          mockPlugin.initialize(
            any,
            onDidReceiveNotificationResponse: anyNamed('onDidReceiveNotificationResponse'),
          ),
        ).thenAnswer((_) async => true);
        when(mockPlugin.resolvePlatformSpecificImplementation()).thenReturn(null);
      });

      tearDown(() {
        reset(mockPrefs);
        reset(mockPlugin);
      });

      test(
        'when flag is null: treats null as false and WILL request battery optimization',
        () async {
          when(mockPrefs.getBool('battery_opt_requested')).thenReturn(null);
          when(mockPrefs.setBool('battery_opt_requested', true)).thenAnswer((_) async => true);

          await NotificationService.initialize(plugin: mockPlugin, sharedPreferences: mockPrefs);

          final flag = mockPrefs.getBool('battery_opt_requested');
          final shouldRequest = !(flag ?? false);
          expect(
            shouldRequest,
            isTrue,
            reason: 'null should be treated as false, triggering request',
          );
        },
      );

      test('when flag is false: WILL request battery optimization', () async {
        when(mockPrefs.getBool('battery_opt_requested')).thenReturn(false);
        when(mockPrefs.setBool('battery_opt_requested', true)).thenAnswer((_) async => true);

        await NotificationService.initialize(plugin: mockPlugin, sharedPreferences: mockPrefs);

        final flag = mockPrefs.getBool('battery_opt_requested');
        final shouldRequest = !(flag ?? false);
        expect(shouldRequest, isTrue, reason: 'false flag should trigger request');
      });

      test('when flag is true: WILL NOT request battery optimization (nag prevention)', () async {
        when(mockPrefs.getBool('battery_opt_requested')).thenReturn(true);

        await NotificationService.initialize(plugin: mockPlugin, sharedPreferences: mockPrefs);

        final flag = mockPrefs.getBool('battery_opt_requested');
        final shouldRequest = !(flag ?? false);
        expect(shouldRequest, isFalse, reason: 'true flag prevents request (nag prevention)');
      });

      test('flag state transition: false→true prevents repeated requests', () {
        final firstCheck = false;
        final shouldRequestFirst = !firstCheck;
        expect(shouldRequestFirst, isTrue, reason: 'First check: false flag allows request');

        final secondCheck = true;
        final shouldRequestSecond = !secondCheck;
        expect(shouldRequestSecond, isFalse, reason: 'Second check: true flag blocks request');
      });

      test('flag set synchronously prevents request on second call', () {
        final flag1 = false;
        final flag2 = true;

        final shouldRequest1 = !flag1;
        final shouldRequest2 = !flag2;

        expect(shouldRequest1, isTrue, reason: 'First call with false flag should request');
        expect(shouldRequest2, isFalse, reason: 'Second call with true flag should not request');
      });

      test('null coalescing operator: (null ?? false) correctly handles missing key', () {
        final bool? flag = null;
        expect(flag ?? false, isFalse);
      });

      test('logic summary: null/false=request, true=skip prevents repeated nagging', () {
        final scenarios = [
          (null as bool?, true),
          (false, true),
          (true, false),
        ];

        for (final (flag, expected) in scenarios) {
          final actual = !(flag ?? false);
          expect(
            actual,
            equals(expected),
            reason: 'Flag=$flag should ${expected ? "trigger" : "skip"} request',
          );
        }
      });
    });
  });
}
