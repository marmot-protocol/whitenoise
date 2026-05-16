import 'dart:async';
import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/l10n/generated/app_localizations_en.dart';
import 'package:whitenoise/services/notification_service.dart';
import 'package:whitenoise/services/notification_subscription.dart';
import 'package:whitenoise/src/rust/api/accounts.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/src/rust/api/notifications.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';

import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

const _receiverPubkey = '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
const _senderPubkey = 'fedcba9876543210fedcba9876543210fedcba9876543210fedcba9876543210';

class _MockNotificationService extends NotificationService {
  _MockNotificationService() : super(enabled: false);

  int initializeCalls = 0;
  int requestPermissionCalls = 0;
  bool shouldFailInitialize = false;
  final List<
    ({
      String groupId,
      String title,
      String body,
      String receiverPubkey,
      bool isInvite,
    })
  >
  showCalls = [];

  @override
  Future<void> initialize() async {
    initializeCalls++;
    if (shouldFailInitialize) throw Exception('initialize failed');
  }

  @override
  Future<bool> requestPermission() async {
    requestPermissionCalls++;
    return true;
  }

  @override
  Future<void> show({
    required String groupId,
    required String title,
    required String body,
    required String receiverPubkey,
    bool isInvite = false,
  }) async {
    showCalls.add((
      groupId: groupId,
      title: title,
      body: body,
      receiverPubkey: receiverPubkey,
      isInvite: isInvite,
    ));
  }
}

class _MockApi extends MockWnApi {
  Map<String, FlutterMetadata> metadataByPubkey = {};
  bool shouldFailMetadataFetch = false;
  bool shouldFailGetAccounts = false;
  StreamController<NotificationUpdate>? streamController;

  @override
  Future<FlutterMetadata> crateApiUsersUserMetadata({
    required bool blockingDataSync,
    required String pubkey,
  }) async {
    if (shouldFailMetadataFetch) throw Exception('Network error');
    return metadataByPubkey[pubkey] ?? const FlutterMetadata(custom: {});
  }

  @override
  Stream<NotificationUpdate> crateApiNotificationsSubscribeToNotifications() {
    streamController = StreamController<NotificationUpdate>.broadcast();
    return streamController!.stream;
  }

  @override
  Future<List<Account>> crateApiAccountsGetAccounts() async {
    if (shouldFailGetAccounts) throw Exception('getAccounts failed');
    return super.crateApiAccountsGetAccounts();
  }
}

NotificationSubscription _newSubscription(
  NotificationService notificationService, {
  String? activeChatId,
  Locale locale = const Locale('en'),
  bool enabled = true,
  bool requestPermissionOnStart = true,
}) {
  return NotificationSubscription(
    notificationService: notificationService,
    getActiveChatId: () => activeChatId,
    getLocale: () => locale,
    enabled: enabled,
    requestPermissionOnStart: requestPermissionOnStart,
  );
}

void main() {
  final l10n = AppLocalizationsEn();
  late _MockApi mockApi;

  setUpAll(() {
    mockApi = _MockApi();
    RustLib.initMock(api: mockApi);
  });

  setUp(() {
    mockApi.metadataByPubkey = {};
    mockApi.shouldFailMetadataFetch = false;
  });

  group('formatNotification', () {
    test('formats DM new message correctly', () {
      final update = NotificationUpdate(
        trigger: NotificationTrigger.newMessage,
        mlsGroupId: 'group123',
        isDm: true,
        receiver: const NotificationUser(pubkey: _receiverPubkey),
        sender: const NotificationUser(pubkey: _senderPubkey, displayName: 'Alice'),
        content: 'Hello there',
        timestamp: DateTime.now(),
      );

      final (title, body, isInvite) = formatNotification(update, l10n);

      expect(title, equals('Alice'));
      expect(body, equals('Hello there'));
      expect(isInvite, isFalse);
    });

    test('formats group new message correctly', () {
      final update = NotificationUpdate(
        trigger: NotificationTrigger.newMessage,
        mlsGroupId: 'group123',
        groupName: 'Friends Group',
        isDm: false,
        receiver: const NotificationUser(pubkey: _receiverPubkey),
        sender: const NotificationUser(pubkey: _senderPubkey, displayName: 'Bob'),
        content: 'Hey everyone',
        timestamp: DateTime.now(),
      );

      final (title, body, isInvite) = formatNotification(update, l10n);

      expect(title, equals('Friends Group'));
      expect(body, equals('Bob: Hey everyone'));
      expect(isInvite, isFalse);
    });

    test('formats DM invite correctly', () {
      final update = NotificationUpdate(
        trigger: NotificationTrigger.groupInvite,
        mlsGroupId: 'group123',
        isDm: true,
        receiver: const NotificationUser(pubkey: _receiverPubkey),
        sender: const NotificationUser(pubkey: _senderPubkey, displayName: 'Carol'),
        content: '',
        timestamp: DateTime.now(),
      );

      final (title, body, isInvite) = formatNotification(update, l10n);

      expect(title, equals('Carol'));
      expect(body, equals('Has invited you to a secure chat'));
      expect(isInvite, isTrue);
    });

    test('formats group invite correctly', () {
      final update = NotificationUpdate(
        trigger: NotificationTrigger.groupInvite,
        mlsGroupId: 'group123',
        groupName: 'New Project',
        isDm: false,
        receiver: const NotificationUser(pubkey: _receiverPubkey),
        sender: const NotificationUser(pubkey: _senderPubkey, displayName: 'Dave'),
        content: '',
        timestamp: DateTime.now(),
      );

      final (title, body, isInvite) = formatNotification(update, l10n);

      expect(title, equals('New Project'));
      expect(body, equals('Dave has invited you to a secure chat'));
      expect(isInvite, isTrue);
    });

    test('uses Unknown user for sender without display name', () {
      final update = NotificationUpdate(
        trigger: NotificationTrigger.newMessage,
        mlsGroupId: 'group123',
        isDm: true,
        receiver: const NotificationUser(pubkey: _receiverPubkey),
        sender: const NotificationUser(pubkey: _senderPubkey),
        content: 'Anonymous message',
        timestamp: DateTime.now(),
      );

      final (title, _, _) = formatNotification(update, l10n);

      expect(title, equals('Unknown user'));
    });

    test('uses Unknown group for group without name', () {
      final update = NotificationUpdate(
        trigger: NotificationTrigger.newMessage,
        mlsGroupId: 'group123',
        isDm: false,
        receiver: const NotificationUser(pubkey: _receiverPubkey),
        sender: const NotificationUser(pubkey: _senderPubkey, displayName: 'Eve'),
        content: 'Hello',
        timestamp: DateTime.now(),
      );

      final (title, _, _) = formatNotification(update, l10n);

      expect(title, equals('Unknown group'));
    });

    test('uses Unknown group for group invite without name', () {
      final update = NotificationUpdate(
        trigger: NotificationTrigger.groupInvite,
        mlsGroupId: 'group123',
        isDm: false,
        receiver: const NotificationUser(pubkey: _receiverPubkey),
        sender: const NotificationUser(pubkey: _senderPubkey, displayName: 'Frank'),
        content: '',
        timestamp: DateTime.now(),
      );

      final (title, body, isInvite) = formatNotification(update, l10n);

      expect(title, equals('Unknown group'));
      expect(body, equals('Frank has invited you to a secure chat'));
      expect(isInvite, isTrue);
    });

    test('uses Unknown user for DM invite without sender name', () {
      final update = NotificationUpdate(
        trigger: NotificationTrigger.groupInvite,
        mlsGroupId: 'group123',
        isDm: true,
        receiver: const NotificationUser(pubkey: _receiverPubkey),
        sender: const NotificationUser(pubkey: _senderPubkey),
        content: '',
        timestamp: DateTime.now(),
      );

      final (title, body, isInvite) = formatNotification(update, l10n);

      expect(title, equals('Unknown user'));
      expect(body, equals('Has invited you to a secure chat'));
      expect(isInvite, isTrue);
    });

    test('uses resolved senderName when provided for DM invite', () {
      final update = NotificationUpdate(
        trigger: NotificationTrigger.groupInvite,
        mlsGroupId: 'group123',
        isDm: true,
        receiver: const NotificationUser(pubkey: _receiverPubkey),
        sender: const NotificationUser(pubkey: _senderPubkey),
        content: '',
        timestamp: DateTime.now(),
      );

      final (title, body, isInvite) = formatNotification(
        update,
        l10n,
        senderName: 'ResolvedName',
      );

      expect(title, equals('ResolvedName'));
      expect(body, equals('Has invited you to a secure chat'));
      expect(isInvite, isTrue);
    });

    test('uses resolved senderName for group invite subtitle', () {
      final update = NotificationUpdate(
        trigger: NotificationTrigger.groupInvite,
        mlsGroupId: 'group123',
        groupName: 'Dev Team',
        isDm: false,
        receiver: const NotificationUser(pubkey: _receiverPubkey),
        sender: const NotificationUser(pubkey: _senderPubkey),
        content: '',
        timestamp: DateTime.now(),
      );

      final (title, body, isInvite) = formatNotification(
        update,
        l10n,
        senderName: 'ResolvedSender',
      );

      expect(title, equals('Dev Team'));
      expect(body, equals('ResolvedSender has invited you to a secure chat'));
      expect(isInvite, isTrue);
    });

    test('prefers senderName parameter over sender displayName', () {
      final update = NotificationUpdate(
        trigger: NotificationTrigger.newMessage,
        mlsGroupId: 'group123',
        isDm: true,
        receiver: const NotificationUser(pubkey: _receiverPubkey),
        sender: const NotificationUser(pubkey: _senderPubkey, displayName: 'Alice'),
        content: 'Hello',
        timestamp: DateTime.now(),
      );

      final (title, _, _) = formatNotification(
        update,
        l10n,
        senderName: 'Bob',
      );

      expect(title, equals('Bob'));
    });
  });

  group('formatNotification with receiver name (multi-account)', () {
    test('appends receiver name to DM message title', () {
      final update = NotificationUpdate(
        trigger: NotificationTrigger.newMessage,
        mlsGroupId: 'group123',
        isDm: true,
        receiver: const NotificationUser(pubkey: _receiverPubkey, displayName: 'MyAccount'),
        sender: const NotificationUser(pubkey: _senderPubkey, displayName: 'Alice'),
        content: 'Hello there',
        timestamp: DateTime.now(),
      );

      final (title, body, isInvite) = formatNotification(
        update,
        l10n,
        receiverName: 'MyAccount',
      );

      expect(title, equals('Alice (MyAccount)'));
      expect(body, equals('Hello there'));
      expect(isInvite, isFalse);
    });

    test('appends receiver name to group message title', () {
      final update = NotificationUpdate(
        trigger: NotificationTrigger.newMessage,
        mlsGroupId: 'group123',
        groupName: 'Friends Group',
        isDm: false,
        receiver: const NotificationUser(pubkey: _receiverPubkey, displayName: 'MyAccount'),
        sender: const NotificationUser(pubkey: _senderPubkey, displayName: 'Bob'),
        content: 'Hey everyone',
        timestamp: DateTime.now(),
      );

      final (title, body, isInvite) = formatNotification(
        update,
        l10n,
        receiverName: 'MyAccount',
      );

      expect(title, equals('Friends Group (MyAccount)'));
      expect(body, equals('Bob: Hey everyone'));
      expect(isInvite, isFalse);
    });

    test('appends receiver name to DM invite title', () {
      final update = NotificationUpdate(
        trigger: NotificationTrigger.groupInvite,
        mlsGroupId: 'group123',
        isDm: true,
        receiver: const NotificationUser(pubkey: _receiverPubkey, displayName: 'MyAccount'),
        sender: const NotificationUser(pubkey: _senderPubkey, displayName: 'Carol'),
        content: '',
        timestamp: DateTime.now(),
      );

      final (title, body, isInvite) = formatNotification(
        update,
        l10n,
        receiverName: 'MyAccount',
      );

      expect(title, equals('Carol (MyAccount)'));
      expect(body, equals('Has invited you to a secure chat'));
      expect(isInvite, isTrue);
    });

    test('appends receiver name to group invite title', () {
      final update = NotificationUpdate(
        trigger: NotificationTrigger.groupInvite,
        mlsGroupId: 'group123',
        groupName: 'New Project',
        isDm: false,
        receiver: const NotificationUser(pubkey: _receiverPubkey, displayName: 'MyAccount'),
        sender: const NotificationUser(pubkey: _senderPubkey, displayName: 'Dave'),
        content: '',
        timestamp: DateTime.now(),
      );

      final (title, body, isInvite) = formatNotification(
        update,
        l10n,
        receiverName: 'MyAccount',
      );

      expect(title, equals('New Project (MyAccount)'));
      expect(body, equals('Dave has invited you to a secure chat'));
      expect(isInvite, isTrue);
    });

    test('does not append receiver name when not provided', () {
      final update = NotificationUpdate(
        trigger: NotificationTrigger.newMessage,
        mlsGroupId: 'group123',
        isDm: true,
        receiver: const NotificationUser(pubkey: _receiverPubkey, displayName: 'MyAccount'),
        sender: const NotificationUser(pubkey: _senderPubkey, displayName: 'Alice'),
        content: 'Hello',
        timestamp: DateTime.now(),
      );

      final (title, _, _) = formatNotification(update, l10n);

      expect(title, equals('Alice'));
    });
  });

  group('NotificationSubscription.handleUpdate', () {
    late _MockNotificationService mockNotificationService;

    setUp(() {
      mockApi.reset();
      mockApi.accounts = [];
      mockApi.metadataByPubkey = {};
      mockApi.shouldFailMetadataFetch = false;
      mockNotificationService = _MockNotificationService();
    });

    test('shows notification for a new DM message', () async {
      final update = NotificationUpdate(
        trigger: NotificationTrigger.newMessage,
        mlsGroupId: testGroupId,
        isDm: true,
        receiver: const NotificationUser(pubkey: testPubkeyA),
        sender: const NotificationUser(pubkey: testPubkeyB, displayName: 'Alice'),
        content: 'Hello there',
        timestamp: DateTime.now(),
      );

      await _newSubscription(mockNotificationService).handleUpdate(update);

      expect(mockNotificationService.showCalls, hasLength(1));
      final call = mockNotificationService.showCalls.first;
      expect(call.groupId, testGroupId);
      expect(call.title, 'Alice');
      expect(call.body, 'Hello there');
      expect(call.receiverPubkey, testPubkeyA);
      expect(call.isInvite, isFalse);
    });

    test('shows notification for a new group message', () async {
      final update = NotificationUpdate(
        trigger: NotificationTrigger.newMessage,
        mlsGroupId: testGroupId,
        groupName: 'Dev Team',
        isDm: false,
        receiver: const NotificationUser(pubkey: testPubkeyA),
        sender: const NotificationUser(pubkey: testPubkeyB, displayName: 'Bob'),
        content: 'Hey everyone',
        timestamp: DateTime.now(),
      );

      await _newSubscription(mockNotificationService).handleUpdate(update);

      expect(mockNotificationService.showCalls, hasLength(1));
      final call = mockNotificationService.showCalls.first;
      expect(call.groupId, testGroupId);
      expect(call.title, 'Dev Team');
      expect(call.body, 'Bob: Hey everyone');
      expect(call.isInvite, isFalse);
    });

    test('shows notification for a DM invite', () async {
      final update = NotificationUpdate(
        trigger: NotificationTrigger.groupInvite,
        mlsGroupId: testGroupId,
        isDm: true,
        receiver: const NotificationUser(pubkey: testPubkeyA),
        sender: const NotificationUser(pubkey: testPubkeyB, displayName: 'Carol'),
        content: '',
        timestamp: DateTime.now(),
      );

      await _newSubscription(mockNotificationService).handleUpdate(update);

      expect(mockNotificationService.showCalls, hasLength(1));
      final call = mockNotificationService.showCalls.first;
      expect(call.title, 'Carol');
      expect(call.body, 'Has invited you to a secure chat');
      expect(call.isInvite, isTrue);
    });

    test('shows notification for a group invite', () async {
      final update = NotificationUpdate(
        trigger: NotificationTrigger.groupInvite,
        mlsGroupId: testGroupId,
        groupName: 'New Project',
        isDm: false,
        receiver: const NotificationUser(pubkey: testPubkeyA),
        sender: const NotificationUser(pubkey: testPubkeyB, displayName: 'Dave'),
        content: '',
        timestamp: DateTime.now(),
      );

      await _newSubscription(mockNotificationService).handleUpdate(update);

      expect(mockNotificationService.showCalls, hasLength(1));
      final call = mockNotificationService.showCalls.first;
      expect(call.title, 'New Project');
      expect(call.body, 'Dave has invited you to a secure chat');
      expect(call.isInvite, isTrue);
    });

    test('skips notification when active chat matches group', () async {
      final update = NotificationUpdate(
        trigger: NotificationTrigger.newMessage,
        mlsGroupId: testGroupId,
        isDm: true,
        receiver: const NotificationUser(pubkey: testPubkeyA),
        sender: const NotificationUser(pubkey: testPubkeyB, displayName: 'Alice'),
        content: 'Hello',
        timestamp: DateTime.now(),
      );

      await _newSubscription(
        mockNotificationService,
        activeChatId: testGroupId,
      ).handleUpdate(update);

      expect(mockNotificationService.showCalls, isEmpty);
    });

    test('skips new message notification from blocked sender', () async {
      mockApi.blockedPubkeys.add(testPubkeyB);
      final update = NotificationUpdate(
        trigger: NotificationTrigger.newMessage,
        mlsGroupId: testGroupId,
        isDm: false,
        receiver: const NotificationUser(pubkey: testPubkeyA),
        sender: const NotificationUser(pubkey: testPubkeyB, displayName: 'Alice'),
        content: 'Hello',
        timestamp: DateTime.now(),
      );

      await _newSubscription(mockNotificationService).handleUpdate(update);

      expect(mockNotificationService.showCalls, isEmpty);
    });

    test('skips invite notification from blocked sender', () async {
      mockApi.blockedPubkeys.add(testPubkeyB);
      final update = NotificationUpdate(
        trigger: NotificationTrigger.groupInvite,
        mlsGroupId: testGroupId,
        isDm: true,
        receiver: const NotificationUser(pubkey: testPubkeyA),
        sender: const NotificationUser(pubkey: testPubkeyB, displayName: 'Alice'),
        content: '',
        timestamp: DateTime.now(),
      );

      await _newSubscription(mockNotificationService).handleUpdate(update);

      expect(mockNotificationService.showCalls, isEmpty);
    });

    test('shows notification when active chat is different group', () async {
      final update = NotificationUpdate(
        trigger: NotificationTrigger.newMessage,
        mlsGroupId: testGroupId,
        isDm: true,
        receiver: const NotificationUser(pubkey: testPubkeyA),
        sender: const NotificationUser(pubkey: testPubkeyB, displayName: 'Alice'),
        content: 'Hello',
        timestamp: DateTime.now(),
      );

      await _newSubscription(
        mockNotificationService,
        activeChatId: otherTestGroupId,
      ).handleUpdate(update);

      expect(mockNotificationService.showCalls, hasLength(1));
    });

    test('shows notification when no active chat is set', () async {
      final update = NotificationUpdate(
        trigger: NotificationTrigger.newMessage,
        mlsGroupId: testGroupId,
        isDm: true,
        receiver: const NotificationUser(pubkey: testPubkeyA),
        sender: const NotificationUser(pubkey: testPubkeyB, displayName: 'Alice'),
        content: 'Hello',
        timestamp: DateTime.now(),
      );

      await _newSubscription(mockNotificationService).handleUpdate(update);

      expect(mockNotificationService.showCalls, hasLength(1));
    });

    test('includes receiver name when multiple accounts exist', () async {
      mockApi.accounts = [
        Account(
          pubkey: testPubkeyA,
          accountType: AccountType.local,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Account(
          pubkey: testPubkeyB,
          accountType: AccountType.local,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final update = NotificationUpdate(
        trigger: NotificationTrigger.newMessage,
        mlsGroupId: testGroupId,
        isDm: true,
        receiver: const NotificationUser(pubkey: testPubkeyA, displayName: 'MyAccount'),
        sender: const NotificationUser(pubkey: testPubkeyB, displayName: 'Alice'),
        content: 'Hello',
        timestamp: DateTime.now(),
      );

      await _newSubscription(mockNotificationService).handleUpdate(update);

      expect(mockNotificationService.showCalls, hasLength(1));
      expect(mockNotificationService.showCalls.first.title, 'Alice (MyAccount)');
    });

    test(
      'uses Unknown user as receiver name when display name is null with multiple accounts',
      () async {
        mockApi.accounts = [
          Account(
            pubkey: testPubkeyA,
            accountType: AccountType.local,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Account(
            pubkey: testPubkeyB,
            accountType: AccountType.local,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        final update = NotificationUpdate(
          trigger: NotificationTrigger.newMessage,
          mlsGroupId: testGroupId,
          isDm: true,
          receiver: const NotificationUser(pubkey: testPubkeyA),
          sender: const NotificationUser(pubkey: testPubkeyB, displayName: 'Alice'),
          content: 'Hello',
          timestamp: DateTime.now(),
        );

        await _newSubscription(mockNotificationService).handleUpdate(update);

        expect(mockNotificationService.showCalls, hasLength(1));
        expect(mockNotificationService.showCalls.first.title, 'Alice (Unknown user)');
      },
    );

    test('does not include receiver name with single account', () async {
      mockApi.accounts = [
        Account(
          pubkey: testPubkeyA,
          accountType: AccountType.local,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final update = NotificationUpdate(
        trigger: NotificationTrigger.newMessage,
        mlsGroupId: testGroupId,
        isDm: true,
        receiver: const NotificationUser(pubkey: testPubkeyA, displayName: 'MyAccount'),
        sender: const NotificationUser(pubkey: testPubkeyB, displayName: 'Alice'),
        content: 'Hello',
        timestamp: DateTime.now(),
      );

      await _newSubscription(mockNotificationService).handleUpdate(update);

      expect(mockNotificationService.showCalls, hasLength(1));
      expect(mockNotificationService.showCalls.first.title, 'Alice');
    });

    test('does not include receiver name with zero accounts', () async {
      final update = NotificationUpdate(
        trigger: NotificationTrigger.newMessage,
        mlsGroupId: testGroupId,
        isDm: true,
        receiver: const NotificationUser(pubkey: testPubkeyA),
        sender: const NotificationUser(pubkey: testPubkeyB, displayName: 'Alice'),
        content: 'Hello',
        timestamp: DateTime.now(),
      );

      await _newSubscription(mockNotificationService).handleUpdate(update);

      expect(mockNotificationService.showCalls, hasLength(1));
      expect(mockNotificationService.showCalls.first.title, 'Alice');
    });

    test('passes correct receiverPubkey to show', () async {
      final update = NotificationUpdate(
        trigger: NotificationTrigger.newMessage,
        mlsGroupId: testGroupId,
        isDm: true,
        receiver: const NotificationUser(pubkey: testPubkeyC),
        sender: const NotificationUser(pubkey: testPubkeyB, displayName: 'Alice'),
        content: 'Hello',
        timestamp: DateTime.now(),
      );

      await _newSubscription(mockNotificationService).handleUpdate(update);

      expect(mockNotificationService.showCalls.first.receiverPubkey, testPubkeyC);
    });

    test('includes receiver name in group invite with multiple accounts', () async {
      mockApi.accounts = [
        Account(
          pubkey: testPubkeyA,
          accountType: AccountType.local,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Account(
          pubkey: testPubkeyB,
          accountType: AccountType.local,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final update = NotificationUpdate(
        trigger: NotificationTrigger.groupInvite,
        mlsGroupId: testGroupId,
        groupName: 'Team Chat',
        isDm: false,
        receiver: const NotificationUser(pubkey: testPubkeyA, displayName: 'MyAccount'),
        sender: const NotificationUser(pubkey: testPubkeyB, displayName: 'Dave'),
        content: '',
        timestamp: DateTime.now(),
      );

      await _newSubscription(mockNotificationService).handleUpdate(update);

      expect(mockNotificationService.showCalls, hasLength(1));
      final call = mockNotificationService.showCalls.first;
      expect(call.title, 'Team Chat (MyAccount)');
      expect(call.body, 'Dave has invited you to a secure chat');
      expect(call.isInvite, isTrue);
    });

    test('resolves sender name from metadata when displayName is null', () async {
      mockApi.metadataByPubkey[_senderPubkey] = const FlutterMetadata(
        displayName: 'Carol',
        custom: {},
      );

      final update = NotificationUpdate(
        trigger: NotificationTrigger.groupInvite,
        mlsGroupId: testGroupId,
        isDm: true,
        receiver: const NotificationUser(pubkey: testPubkeyA),
        sender: const NotificationUser(pubkey: _senderPubkey),
        content: '',
        timestamp: DateTime.now(),
      );

      await _newSubscription(mockNotificationService).handleUpdate(update);

      expect(mockNotificationService.showCalls, hasLength(1));
      final call = mockNotificationService.showCalls.first;
      expect(call.title, 'Carol');
      expect(call.body, 'Has invited you to a secure chat');
      expect(call.isInvite, isTrue);
    });

    test('resolves sender name for group invite when displayName is null', () async {
      mockApi.metadataByPubkey[_senderPubkey] = const FlutterMetadata(
        name: 'dave_nostr',
        custom: {},
      );

      final update = NotificationUpdate(
        trigger: NotificationTrigger.groupInvite,
        mlsGroupId: testGroupId,
        groupName: 'Dev Team',
        isDm: false,
        receiver: const NotificationUser(pubkey: testPubkeyA),
        sender: const NotificationUser(pubkey: _senderPubkey),
        content: '',
        timestamp: DateTime.now(),
      );

      await _newSubscription(mockNotificationService).handleUpdate(update);

      expect(mockNotificationService.showCalls, hasLength(1));
      final call = mockNotificationService.showCalls.first;
      expect(call.title, 'Dev Team');
      expect(call.body, 'dave_nostr has invited you to a secure chat');
      expect(call.isInvite, isTrue);
    });

    test('resolves sender name for new message when displayName is null', () async {
      mockApi.metadataByPubkey[_senderPubkey] = const FlutterMetadata(
        displayName: 'Alice',
        custom: {},
      );

      final update = NotificationUpdate(
        trigger: NotificationTrigger.newMessage,
        mlsGroupId: testGroupId,
        isDm: true,
        receiver: const NotificationUser(pubkey: testPubkeyA),
        sender: const NotificationUser(pubkey: _senderPubkey),
        content: 'Hello there',
        timestamp: DateTime.now(),
      );

      await _newSubscription(mockNotificationService).handleUpdate(update);

      expect(mockNotificationService.showCalls, hasLength(1));
      final call = mockNotificationService.showCalls.first;
      expect(call.title, 'Alice');
      expect(call.body, 'Hello there');
    });

    test('falls back to Unknown user when metadata fetch fails', () async {
      mockApi.shouldFailMetadataFetch = true;

      final update = NotificationUpdate(
        trigger: NotificationTrigger.groupInvite,
        mlsGroupId: testGroupId,
        isDm: true,
        receiver: const NotificationUser(pubkey: testPubkeyA),
        sender: const NotificationUser(pubkey: _senderPubkey),
        content: '',
        timestamp: DateTime.now(),
      );

      await _newSubscription(mockNotificationService).handleUpdate(update);

      expect(mockNotificationService.showCalls, hasLength(1));
      final call = mockNotificationService.showCalls.first;
      expect(call.title, 'Unknown user');
    });

    test('falls back to Unknown user when metadata has no name fields', () async {
      mockApi.metadataByPubkey[_senderPubkey] = const FlutterMetadata(
        picture: 'https://example.com/avatar.png',
        custom: {},
      );

      final update = NotificationUpdate(
        trigger: NotificationTrigger.groupInvite,
        mlsGroupId: testGroupId,
        isDm: true,
        receiver: const NotificationUser(pubkey: testPubkeyA),
        sender: const NotificationUser(pubkey: _senderPubkey),
        content: '',
        timestamp: DateTime.now(),
      );

      await _newSubscription(mockNotificationService).handleUpdate(update);

      expect(mockNotificationService.showCalls, hasLength(1));
      final call = mockNotificationService.showCalls.first;
      expect(call.title, 'Unknown user');
    });

    test('skips metadata fetch when sender displayName is already set', () async {
      mockApi.metadataByPubkey[_senderPubkey] = const FlutterMetadata(
        displayName: 'Should Not Be Used',
        custom: {},
      );

      final update = NotificationUpdate(
        trigger: NotificationTrigger.newMessage,
        mlsGroupId: testGroupId,
        isDm: true,
        receiver: const NotificationUser(pubkey: testPubkeyA),
        sender: const NotificationUser(pubkey: _senderPubkey, displayName: 'Alice'),
        content: 'Hello',
        timestamp: DateTime.now(),
      );

      await _newSubscription(mockNotificationService).handleUpdate(update);

      expect(mockNotificationService.showCalls, hasLength(1));
      final call = mockNotificationService.showCalls.first;
      expect(call.title, 'Alice');
    });
  });

  group('NotificationSubscription lifecycle', () {
    late _MockNotificationService mockNotificationService;

    setUp(() {
      mockApi.reset();
      mockApi.accounts = [];
      mockApi.metadataByPubkey = {};
      mockApi.streamController = null;
      mockNotificationService = _MockNotificationService();
    });

    test('isRunning is false before start', () {
      final sub = _newSubscription(mockNotificationService);

      expect(sub.isRunning, isFalse);
    });

    test('stop is a no-op when never started', () async {
      final sub = _newSubscription(mockNotificationService);

      await sub.stop();

      expect(sub.isRunning, isFalse);
    });

    test('start is a no-op when disabled', () async {
      final sub = _newSubscription(mockNotificationService, enabled: false);

      await sub.start();

      expect(sub.isRunning, isFalse);
      expect(mockNotificationService.initializeCalls, 0);
    });

    test('start initializes notification service and subscribes to stream', () async {
      final sub = _newSubscription(mockNotificationService);

      await sub.start();

      expect(sub.isRunning, isTrue);
      expect(mockNotificationService.initializeCalls, 1);
      expect(mockNotificationService.requestPermissionCalls, 1);
      expect(mockApi.streamController, isNotNull);

      await sub.stop();
    });

    test('start can subscribe without requesting notification permission', () async {
      final sub = _newSubscription(
        mockNotificationService,
        requestPermissionOnStart: false,
      );

      await sub.start();

      expect(sub.isRunning, isTrue);
      expect(mockNotificationService.initializeCalls, 1);
      expect(mockNotificationService.requestPermissionCalls, 0);
      expect(mockApi.streamController, isNotNull);

      await sub.stop();
    });

    test('double-start is a no-op', () async {
      final sub = _newSubscription(mockNotificationService);

      await sub.start();
      final firstController = mockApi.streamController;
      await sub.start();

      expect(identical(firstController, mockApi.streamController), isTrue);
      expect(mockNotificationService.initializeCalls, 1);

      await sub.stop();
    });

    test('stop cancels an active subscription', () async {
      final sub = _newSubscription(mockNotificationService);
      await sub.start();
      expect(sub.isRunning, isTrue);

      await sub.stop();

      expect(sub.isRunning, isFalse);
    });

    test('start subscribes and show() receives events emitted on the stream', () async {
      final sub = _newSubscription(mockNotificationService);
      await sub.start();

      mockApi.streamController!.add(
        NotificationUpdate(
          trigger: NotificationTrigger.newMessage,
          mlsGroupId: testGroupId,
          isDm: true,
          receiver: const NotificationUser(pubkey: testPubkeyA),
          sender: const NotificationUser(pubkey: testPubkeyB, displayName: 'Alice'),
          content: 'Streamed hello',
          timestamp: DateTime.now(),
        ),
      );
      // Allow the stream's microtask + async handler to complete.
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(mockNotificationService.showCalls, hasLength(1));
      expect(mockNotificationService.showCalls.first.body, 'Streamed hello');

      await sub.stop();
    });

    test('stop prevents further events from being shown', () async {
      final sub = _newSubscription(mockNotificationService);
      await sub.start();
      await sub.stop();

      mockApi.streamController!.add(
        NotificationUpdate(
          trigger: NotificationTrigger.newMessage,
          mlsGroupId: testGroupId,
          isDm: true,
          receiver: const NotificationUser(pubkey: testPubkeyA),
          sender: const NotificationUser(pubkey: testPubkeyB, displayName: 'Alice'),
          content: 'Should not be shown',
          timestamp: DateTime.now(),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(mockNotificationService.showCalls, isEmpty);
    });

    test('swallows errors from a failing _handleUpdate', () async {
      mockApi.shouldFailGetAccounts = true;

      final sub = _newSubscription(mockNotificationService);
      await sub.start();

      // An emitted update triggers _handleUpdate, which calls getAccounts and
      // throws. The listener's try/catch logs the error without propagating.
      mockApi.streamController!.add(
        NotificationUpdate(
          trigger: NotificationTrigger.newMessage,
          mlsGroupId: testGroupId,
          isDm: true,
          receiver: const NotificationUser(pubkey: testPubkeyA),
          sender: const NotificationUser(pubkey: testPubkeyB, displayName: 'Alice'),
          content: 'Will fail',
          timestamp: DateTime.now(),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(sub.isRunning, isTrue);
      expect(mockNotificationService.showCalls, isEmpty);

      await sub.stop();
    });

    test('handles stream error without cancelling the subscription', () async {
      final sub = _newSubscription(mockNotificationService);
      await sub.start();

      mockApi.streamController!.addError('transient stream failure');
      await Future<void>.delayed(Duration.zero);

      // Broadcast-stream listeners don't auto-cancel on error.
      expect(sub.isRunning, isTrue);

      await sub.stop();
    });

    test('logs on stream done', () async {
      final sub = _newSubscription(mockNotificationService);
      await sub.start();

      await mockApi.streamController!.close();
      await Future<void>.delayed(Duration.zero);

      // The stream is closed; subscription still logically exists until stop().
      await sub.stop();
    });

    test('outer catch handles failure during initialize', () async {
      mockNotificationService.shouldFailInitialize = true;

      final sub = _newSubscription(mockNotificationService);
      await sub.start();

      expect(sub.isRunning, isFalse);
    });

    test('default enabled is false on unsupported host platforms', () async {
      // On non-mobile test platforms, constructing without `enabled` defaults
      // to false, so start() should be a no-op.
      final sub = NotificationSubscription(
        notificationService: mockNotificationService,
        getActiveChatId: () => null,
        getLocale: () => const Locale('en'),
      );

      await sub.start();

      expect(sub.isRunning, isFalse);
    });
  });
}
