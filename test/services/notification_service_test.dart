import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/services/notification_service.dart';

class _MockNotificationsPlugin implements FlutterLocalNotificationsPlugin {
  final List<String> calls = [];
  void Function(NotificationResponse)? tapCallback;
  int? lastShownId;
  String? lastShownTitle;
  String? lastShownBody;
  String? lastPayload;
  int? lastCancelledId;

  @override
  Future<bool?> initialize(
    InitializationSettings initializationSettings, {
    onDidReceiveNotificationResponse,
    onDidReceiveBackgroundNotificationResponse,
  }) async {
    calls.add('initialize');
    tapCallback = onDidReceiveNotificationResponse;
    return true;
  }

  @override
  Future<void> show(
    int id,
    String? title,
    String? body,
    NotificationDetails? notificationDetails, {
    String? payload,
  }) async {
    calls.add('show');
    lastShownId = id;
    lastShownTitle = title;
    lastShownBody = body;
    lastPayload = payload;
  }

  @override
  Future<void> cancel(int id, {String? tag}) async {
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
        await service.show(groupId: 'g', title: 't', body: 'b');
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
        await service.show(groupId: 'g1', title: 'Title', body: 'Body');
        expect(mockPlugin.calls, contains('show'));
      });

      test('passes title and body', () async {
        await service.show(groupId: 'g1', title: 'Alice', body: 'Hello');
        expect(mockPlugin.lastShownTitle, 'Alice');
        expect(mockPlugin.lastShownBody, 'Hello');
      });

      test('skips when not initialized', () async {
        final uninitService = NotificationService(
          plugin: _MockNotificationsPlugin(),
          enabled: true,
        );
        await uninitService.show(groupId: 'g1', title: 't', body: 'b');
        expect(mockPlugin.calls, isNot(contains('show')));
      });

      test('payload contains message trigger by default', () async {
        await service.show(groupId: 'g1', title: 't', body: 'b');
        expect(mockPlugin.lastPayload, 'g1|message');
      });

      test('payload contains invite trigger', () async {
        await service.show(groupId: 'g1', title: 't', body: 'b', isInvite: true);
        expect(mockPlugin.lastPayload, 'g1|invite');
      });

      test('uses consistent notification ID for same groupId', () async {
        await service.show(groupId: 'g1', title: 't1', body: 'b1');
        final firstId = mockPlugin.lastShownId;
        await service.show(groupId: 'g1', title: 't2', body: 'b2');
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
        await service.show(groupId: 'g1', title: 't', body: 'b');
        final showId = mockPlugin.lastShownId;
        await service.cancelForGroup('g1');
        expect(mockPlugin.lastCancelledId, showId);
      });
    });

    group('notification tap', () {
      late _MockNotificationsPlugin mockPlugin;
      String? tappedGroupId;
      bool? tappedIsInvite;

      setUp(() async {
        mockPlugin = _MockNotificationsPlugin();
        tappedGroupId = null;
        tappedIsInvite = null;
        final service = NotificationService(
          plugin: mockPlugin,
          enabled: true,
          onNotificationTap: (groupId, isInvite) {
            tappedGroupId = groupId;
            tappedIsInvite = isInvite;
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
        mockPlugin.tapCallback!(response(payload: 'group123|message'));
        expect(tappedGroupId, 'group123');
        expect(tappedIsInvite, isFalse);
      });

      test('calls onNotificationTap for invite payload', () {
        mockPlugin.tapCallback!(response(payload: 'group456|invite'));
        expect(tappedGroupId, 'group456');
        expect(tappedIsInvite, isTrue);
      });

      test('ignores null payload', () {
        mockPlugin.tapCallback!(response());
        expect(tappedGroupId, isNull);
      });

      test('ignores malformed payload', () {
        mockPlugin.tapCallback!(response(payload: 'no-separator'));
        expect(tappedGroupId, isNull);
      });

      test('ignores tap when no callback provided', () async {
        final noCallbackPlugin = _MockNotificationsPlugin();
        final service = NotificationService(
          plugin: noCallbackPlugin,
          enabled: true,
        );
        await service.initialize();
        noCallbackPlugin.tapCallback!(response(payload: 'g|message'));
        expect(tappedGroupId, isNull);
      });
    });
  });
}
