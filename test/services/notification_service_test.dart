import 'dart:convert' show jsonDecode, jsonEncode;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/services/notification_service.dart';

const _pubkey1 = '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
const _pubkey2 = 'fedcba9876543210fedcba9876543210fedcba9876543210fedcba9876543210';

class _MockAndroidPlugin extends AndroidFlutterLocalNotificationsPlugin {
  bool? permissionResult = true;

  @override
  Future<bool?> requestNotificationsPermission() async => permissionResult;
}

class _MockNotificationsPlugin implements FlutterLocalNotificationsPlugin {
  final List<String> calls = [];
  void Function(NotificationResponse)? tapCallback;
  int? lastShownId;
  String? lastShownTitle;
  String? lastShownBody;
  String? lastPayload;
  int? lastCancelledId;
  AndroidFlutterLocalNotificationsPlugin? androidPlugin;

  @override
  T? resolvePlatformSpecificImplementation<T extends FlutterLocalNotificationsPlatform>() {
    if (T == AndroidFlutterLocalNotificationsPlugin) {
      return androidPlugin as T?;
    }
    return null;
  }

  @override
  Future<bool?> initialize({
    required InitializationSettings settings,
    onDidReceiveNotificationResponse,
    onDidReceiveBackgroundNotificationResponse,
  }) async {
    calls.add('initialize');
    tapCallback = onDidReceiveNotificationResponse;
    return true;
  }

  @override
  Future<void> show({
    required int id,
    String? title,
    String? body,
    NotificationDetails? notificationDetails,
    String? payload,
  }) async {
    calls.add('show');
    lastShownId = id;
    lastShownTitle = title;
    lastShownBody = body;
    lastPayload = payload;
  }

  @override
  Future<void> cancel({required int id, String? tag}) async {
    calls.add('cancel');
    lastCancelledId = id;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError('${invocation.memberName} is not stubbed');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService', () {
    group('when disabled', () {
      late NotificationService service;

      setUp(() {
        service = NotificationService(enabled: false);
      });

      test('initialize is no-op', () async {
        await service.initialize();
      });

      test('show is no-op', () async {
        await service.show(groupId: 'g', title: 't', body: 'b', receiverPubkey: _pubkey1);
      });

      test('cancelForGroup is no-op', () async {
        await service.cancelForGroup('g');
      });

      test('requestPermission returns false', () async {
        final result = await service.requestPermission();
        expect(result, isFalse);
      });
    });

    group('initialize', () {
      late _MockNotificationsPlugin mockPlugin;
      late NotificationService service;

      setUp(() {
        mockPlugin = _MockNotificationsPlugin();
        service = NotificationService(plugin: mockPlugin, enabled: true);
      });

      test('calls plugin initialize', () async {
        await service.initialize();
        expect(mockPlugin.calls, contains('initialize'));
      });

      test('second call is idempotent', () async {
        await service.initialize();
        await service.initialize();
        expect(mockPlugin.calls.where((c) => c == 'initialize').length, 1);
      });
    });

    group('show', () {
      late _MockNotificationsPlugin mockPlugin;
      late NotificationService service;

      setUp(() async {
        mockPlugin = _MockNotificationsPlugin();
        service = NotificationService(plugin: mockPlugin, enabled: true);
        await service.initialize();
      });

      test('calls plugin show', () async {
        await service.show(groupId: 'g1', title: 'Title', body: 'Body', receiverPubkey: _pubkey1);
        expect(mockPlugin.calls, contains('show'));
      });

      test('passes title and body', () async {
        await service.show(groupId: 'g1', title: 'Alice', body: 'Hello', receiverPubkey: _pubkey1);
        expect(mockPlugin.lastShownTitle, 'Alice');
        expect(mockPlugin.lastShownBody, 'Hello');
      });

      test('skips when not initialized', () async {
        final uninitMock = _MockNotificationsPlugin();
        final uninitService = NotificationService(
          plugin: uninitMock,
          enabled: true,
        );
        await uninitService.show(groupId: 'g1', title: 't', body: 'b', receiverPubkey: _pubkey1);
        expect(uninitMock.calls, isNot(contains('show')));
      });

      test('payload contains message trigger and receiver pubkey as JSON', () async {
        await service.show(groupId: 'g1', title: 't', body: 'b', receiverPubkey: _pubkey1);
        final data = jsonDecode(mockPlugin.lastPayload!) as Map<String, dynamic>;
        expect(data['groupId'], 'g1');
        expect(data['trigger'], 'message');
        expect(data['receiverPubkey'], _pubkey1);
      });

      test('payload contains invite trigger and receiver pubkey as JSON', () async {
        await service.show(
          groupId: 'g1',
          title: 't',
          body: 'b',
          receiverPubkey: _pubkey1,
          isInvite: true,
        );
        final data = jsonDecode(mockPlugin.lastPayload!) as Map<String, dynamic>;
        expect(data['groupId'], 'g1');
        expect(data['trigger'], 'invite');
        expect(data['receiverPubkey'], _pubkey1);
      });

      test('uses consistent notification ID for same groupId', () async {
        await service.show(groupId: 'g1', title: 't1', body: 'b1', receiverPubkey: _pubkey1);
        final firstId = mockPlugin.lastShownId;
        await service.show(groupId: 'g1', title: 't2', body: 'b2', receiverPubkey: _pubkey1);
        expect(mockPlugin.lastShownId, firstId);
      });
    });

    group('generateNotificationId', () {
      test('returns consistent ID for same input', () {
        final id1 = NotificationService.generateNotificationId('group-abc');
        final id2 = NotificationService.generateNotificationId('group-abc');
        expect(id1, id2);
      });

      test('returns different IDs for different inputs', () {
        final id1 = NotificationService.generateNotificationId('group-abc');
        final id2 = NotificationService.generateNotificationId('group-xyz');
        expect(id1, isNot(id2));
      });

      test('returns non-negative value', () {
        final id = NotificationService.generateNotificationId('any-group');
        expect(id, greaterThanOrEqualTo(0));
      });

      test('returns value within 31-bit range', () {
        final id = NotificationService.generateNotificationId('any-group');
        expect(id, lessThanOrEqualTo(0x7FFFFFFF));
      });
    });

    group('cancelForGroup', () {
      late _MockNotificationsPlugin mockPlugin;
      late NotificationService service;

      setUp(() {
        mockPlugin = _MockNotificationsPlugin();
        service = NotificationService(plugin: mockPlugin, enabled: true);
      });

      test('calls plugin cancel', () async {
        await service.cancelForGroup('g1');
        expect(mockPlugin.calls, contains('cancel'));
      });

      test('uses same ID as show for same groupId', () async {
        await service.initialize();
        await service.show(groupId: 'g1', title: 't', body: 'b', receiverPubkey: _pubkey1);
        final showId = mockPlugin.lastShownId;
        await service.cancelForGroup('g1');
        expect(mockPlugin.lastCancelledId, showId);
      });
    });

    group('requestPermission', () {
      test('returns false when platform implementation is null', () async {
        final mockPlugin = _MockNotificationsPlugin();
        final service = NotificationService(plugin: mockPlugin, enabled: true);
        await service.initialize();

        final result = await service.requestPermission();
        expect(result, isFalse);
      });

      test('returns true when permission is granted', () async {
        final androidPlugin = _MockAndroidPlugin();
        androidPlugin.permissionResult = true;
        final mockPlugin = _MockNotificationsPlugin();
        mockPlugin.androidPlugin = androidPlugin;
        final service = NotificationService(plugin: mockPlugin, enabled: true);
        await service.initialize();

        final result = await service.requestPermission();
        expect(result, isTrue);
      });

      test('returns false when permission is denied', () async {
        final androidPlugin = _MockAndroidPlugin();
        androidPlugin.permissionResult = false;
        final mockPlugin = _MockNotificationsPlugin();
        mockPlugin.androidPlugin = androidPlugin;
        final service = NotificationService(plugin: mockPlugin, enabled: true);
        await service.initialize();

        final result = await service.requestPermission();
        expect(result, isFalse);
      });

      test('returns false when permission result is null', () async {
        final androidPlugin = _MockAndroidPlugin();
        androidPlugin.permissionResult = null;
        final mockPlugin = _MockNotificationsPlugin();
        mockPlugin.androidPlugin = androidPlugin;
        final service = NotificationService(plugin: mockPlugin, enabled: true);
        await service.initialize();

        final result = await service.requestPermission();
        expect(result, isFalse);
      });
    });

    group('notification tap', () {
      late _MockNotificationsPlugin mockPlugin;
      String? tappedGroupId;
      bool? tappedIsInvite;
      String? tappedReceiverPubkey;

      setUp(() async {
        mockPlugin = _MockNotificationsPlugin();
        tappedGroupId = null;
        tappedIsInvite = null;
        tappedReceiverPubkey = null;
        final service = NotificationService(
          plugin: mockPlugin,
          enabled: true,
          onNotificationTap: (groupId, isInvite, receiverPubkey) {
            tappedGroupId = groupId;
            tappedIsInvite = isInvite;
            tappedReceiverPubkey = receiverPubkey;
          },
        );
        await service.initialize();
      });

      NotificationResponse response({String? payload}) {
        return NotificationResponse(
          notificationResponseType: NotificationResponseType.selectedNotification,
          payload: payload,
        );
      }

      test('calls onNotificationTap for message payload', () {
        final payload = jsonEncode({
          'groupId': 'group123',
          'trigger': 'message',
          'receiverPubkey': _pubkey1,
        });
        mockPlugin.tapCallback!(response(payload: payload));
        expect(tappedGroupId, 'group123');
        expect(tappedIsInvite, isFalse);
        expect(tappedReceiverPubkey, _pubkey1);
      });

      test('calls onNotificationTap for invite payload', () {
        final payload = jsonEncode({
          'groupId': 'group456',
          'trigger': 'invite',
          'receiverPubkey': _pubkey2,
        });
        mockPlugin.tapCallback!(response(payload: payload));
        expect(tappedGroupId, 'group456');
        expect(tappedIsInvite, isTrue);
        expect(tappedReceiverPubkey, _pubkey2);
      });

      test('handles groupId containing pipe characters', () {
        final payload = jsonEncode({
          'groupId': 'group|with|pipes',
          'trigger': 'message',
          'receiverPubkey': _pubkey1,
        });
        mockPlugin.tapCallback!(response(payload: payload));
        expect(tappedGroupId, 'group|with|pipes');
        expect(tappedIsInvite, isFalse);
        expect(tappedReceiverPubkey, _pubkey1);
      });

      test('ignores null payload', () {
        mockPlugin.tapCallback!(response());
        expect(tappedGroupId, isNull);
      });

      test('ignores non-JSON payload', () {
        mockPlugin.tapCallback!(response(payload: 'not-json'));
        expect(tappedGroupId, isNull);
      });

      test('ignores payload with missing groupId', () {
        final payload = jsonEncode({'trigger': 'message', 'receiverPubkey': _pubkey1});
        mockPlugin.tapCallback!(response(payload: payload));
        expect(tappedGroupId, isNull);
      });

      test('ignores payload with empty groupId', () {
        final payload = jsonEncode({
          'groupId': '',
          'trigger': 'message',
          'receiverPubkey': _pubkey1,
        });
        mockPlugin.tapCallback!(response(payload: payload));
        expect(tappedGroupId, isNull);
      });

      test('ignores payload with missing trigger', () {
        final payload = jsonEncode({'groupId': 'g1', 'receiverPubkey': _pubkey1});
        mockPlugin.tapCallback!(response(payload: payload));
        expect(tappedGroupId, isNull);
      });

      test('ignores payload with missing receiverPubkey', () {
        final payload = jsonEncode({'groupId': 'g1', 'trigger': 'message'});
        mockPlugin.tapCallback!(response(payload: payload));
        expect(tappedGroupId, isNull);
      });

      test('ignores payload with empty receiverPubkey', () {
        final payload = jsonEncode({
          'groupId': 'g1',
          'trigger': 'message',
          'receiverPubkey': '',
        });
        mockPlugin.tapCallback!(response(payload: payload));
        expect(tappedGroupId, isNull);
      });

      test('ignores payload with unknown trigger', () {
        final payload = jsonEncode({
          'groupId': 'g1',
          'trigger': 'unknown',
          'receiverPubkey': _pubkey1,
        });
        mockPlugin.tapCallback!(response(payload: payload));
        expect(tappedGroupId, isNull);
      });

      test('ignores tap when no callback provided', () async {
        final noCallbackPlugin = _MockNotificationsPlugin();
        final service = NotificationService(
          plugin: noCallbackPlugin,
          enabled: true,
        );
        await service.initialize();
        final payload = jsonEncode({
          'groupId': 'g',
          'trigger': 'message',
          'receiverPubkey': _pubkey1,
        });
        noCallbackPlugin.tapCallback!(response(payload: payload));
        expect(tappedGroupId, isNull);
      });
    });
  });
}
