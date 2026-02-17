import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/l10n/generated/app_localizations_en.dart';
import 'package:whitenoise/providers/active_chat_provider.dart';
import 'package:whitenoise/providers/locale_provider.dart';
import 'package:whitenoise/providers/notification_provider.dart';
import 'package:whitenoise/services/notification_service.dart';
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

  @override
  Future<FlutterMetadata> crateApiUsersUserMetadata({
    required bool blockingDataSync,
    required String pubkey,
  }) async {
    if (shouldFailMetadataFetch) throw Exception('Network error');
    return metadataByPubkey[pubkey] ?? const FlutterMetadata(custom: {});
  }
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

  group('Notification formatting', () {
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

  group('Notification formatting with receiver name (multi-account)', () {
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

  group('handleNotificationUpdate', () {
    late _MockNotificationService mockNotificationService;
    late ProviderContainer container;

    setUp(() {
      mockApi.reset();
      mockApi.accounts = [];
      mockApi.metadataByPubkey = {};
      mockApi.shouldFailMetadataFetch = false;
      mockNotificationService = _MockNotificationService();
      container = ProviderContainer();
    });

    tearDown(() => container.dispose());

    Future<Ref> captureRef() async {
      late Ref capturedRef;
      final refProvider = Provider<void>((ref) {
        capturedRef = ref;
      });
      container.read(refProvider);
      await container.read(localeProvider.future);
      return capturedRef;
    }

    test('shows notification for a new DM message', () async {
      final ref = await captureRef();
      final update = NotificationUpdate(
        trigger: NotificationTrigger.newMessage,
        mlsGroupId: testGroupId,
        isDm: true,
        receiver: const NotificationUser(pubkey: testPubkeyA),
        sender: const NotificationUser(pubkey: testPubkeyB, displayName: 'Alice'),
        content: 'Hello there',
        timestamp: DateTime.now(),
      );

      await handleNotificationUpdate(update, mockNotificationService, ref);

      expect(mockNotificationService.showCalls, hasLength(1));
      final call = mockNotificationService.showCalls.first;
      expect(call.groupId, testGroupId);
      expect(call.title, 'Alice');
      expect(call.body, 'Hello there');
      expect(call.receiverPubkey, testPubkeyA);
      expect(call.isInvite, isFalse);
    });

    test('shows notification for a new group message', () async {
      final ref = await captureRef();
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

      await handleNotificationUpdate(update, mockNotificationService, ref);

      expect(mockNotificationService.showCalls, hasLength(1));
      final call = mockNotificationService.showCalls.first;
      expect(call.groupId, testGroupId);
      expect(call.title, 'Dev Team');
      expect(call.body, 'Bob: Hey everyone');
      expect(call.isInvite, isFalse);
    });

    test('shows notification for a DM invite', () async {
      final ref = await captureRef();
      final update = NotificationUpdate(
        trigger: NotificationTrigger.groupInvite,
        mlsGroupId: testGroupId,
        isDm: true,
        receiver: const NotificationUser(pubkey: testPubkeyA),
        sender: const NotificationUser(pubkey: testPubkeyB, displayName: 'Carol'),
        content: '',
        timestamp: DateTime.now(),
      );

      await handleNotificationUpdate(update, mockNotificationService, ref);

      expect(mockNotificationService.showCalls, hasLength(1));
      final call = mockNotificationService.showCalls.first;
      expect(call.title, 'Carol');
      expect(call.body, 'Has invited you to a secure chat');
      expect(call.isInvite, isTrue);
    });

    test('shows notification for a group invite', () async {
      final ref = await captureRef();
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

      await handleNotificationUpdate(update, mockNotificationService, ref);

      expect(mockNotificationService.showCalls, hasLength(1));
      final call = mockNotificationService.showCalls.first;
      expect(call.title, 'New Project');
      expect(call.body, 'Dave has invited you to a secure chat');
      expect(call.isInvite, isTrue);
    });

    test('skips notification when active chat matches group', () async {
      container.read(activeChatProvider.notifier).set(testGroupId);
      final ref = await captureRef();

      final update = NotificationUpdate(
        trigger: NotificationTrigger.newMessage,
        mlsGroupId: testGroupId,
        isDm: true,
        receiver: const NotificationUser(pubkey: testPubkeyA),
        sender: const NotificationUser(pubkey: testPubkeyB, displayName: 'Alice'),
        content: 'Hello',
        timestamp: DateTime.now(),
      );

      await handleNotificationUpdate(update, mockNotificationService, ref);

      expect(mockNotificationService.showCalls, isEmpty);
    });

    test('shows notification when active chat is different group', () async {
      container.read(activeChatProvider.notifier).set(otherTestGroupId);
      final ref = await captureRef();

      final update = NotificationUpdate(
        trigger: NotificationTrigger.newMessage,
        mlsGroupId: testGroupId,
        isDm: true,
        receiver: const NotificationUser(pubkey: testPubkeyA),
        sender: const NotificationUser(pubkey: testPubkeyB, displayName: 'Alice'),
        content: 'Hello',
        timestamp: DateTime.now(),
      );

      await handleNotificationUpdate(update, mockNotificationService, ref);

      expect(mockNotificationService.showCalls, hasLength(1));
    });

    test('shows notification when no active chat is set', () async {
      final ref = await captureRef();

      final update = NotificationUpdate(
        trigger: NotificationTrigger.newMessage,
        mlsGroupId: testGroupId,
        isDm: true,
        receiver: const NotificationUser(pubkey: testPubkeyA),
        sender: const NotificationUser(pubkey: testPubkeyB, displayName: 'Alice'),
        content: 'Hello',
        timestamp: DateTime.now(),
      );

      await handleNotificationUpdate(update, mockNotificationService, ref);

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
      final ref = await captureRef();

      final update = NotificationUpdate(
        trigger: NotificationTrigger.newMessage,
        mlsGroupId: testGroupId,
        isDm: true,
        receiver: const NotificationUser(pubkey: testPubkeyA, displayName: 'MyAccount'),
        sender: const NotificationUser(pubkey: testPubkeyB, displayName: 'Alice'),
        content: 'Hello',
        timestamp: DateTime.now(),
      );

      await handleNotificationUpdate(update, mockNotificationService, ref);

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
        final ref = await captureRef();

        final update = NotificationUpdate(
          trigger: NotificationTrigger.newMessage,
          mlsGroupId: testGroupId,
          isDm: true,
          receiver: const NotificationUser(pubkey: testPubkeyA),
          sender: const NotificationUser(pubkey: testPubkeyB, displayName: 'Alice'),
          content: 'Hello',
          timestamp: DateTime.now(),
        );

        await handleNotificationUpdate(update, mockNotificationService, ref);

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
      final ref = await captureRef();

      final update = NotificationUpdate(
        trigger: NotificationTrigger.newMessage,
        mlsGroupId: testGroupId,
        isDm: true,
        receiver: const NotificationUser(pubkey: testPubkeyA, displayName: 'MyAccount'),
        sender: const NotificationUser(pubkey: testPubkeyB, displayName: 'Alice'),
        content: 'Hello',
        timestamp: DateTime.now(),
      );

      await handleNotificationUpdate(update, mockNotificationService, ref);

      expect(mockNotificationService.showCalls, hasLength(1));
      expect(mockNotificationService.showCalls.first.title, 'Alice');
    });

    test('does not include receiver name with zero accounts', () async {
      final ref = await captureRef();

      final update = NotificationUpdate(
        trigger: NotificationTrigger.newMessage,
        mlsGroupId: testGroupId,
        isDm: true,
        receiver: const NotificationUser(pubkey: testPubkeyA),
        sender: const NotificationUser(pubkey: testPubkeyB, displayName: 'Alice'),
        content: 'Hello',
        timestamp: DateTime.now(),
      );

      await handleNotificationUpdate(update, mockNotificationService, ref);

      expect(mockNotificationService.showCalls, hasLength(1));
      expect(mockNotificationService.showCalls.first.title, 'Alice');
    });

    test('passes correct receiverPubkey to show', () async {
      final ref = await captureRef();

      final update = NotificationUpdate(
        trigger: NotificationTrigger.newMessage,
        mlsGroupId: testGroupId,
        isDm: true,
        receiver: const NotificationUser(pubkey: testPubkeyC),
        sender: const NotificationUser(pubkey: testPubkeyB, displayName: 'Alice'),
        content: 'Hello',
        timestamp: DateTime.now(),
      );

      await handleNotificationUpdate(update, mockNotificationService, ref);

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
      final ref = await captureRef();

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

      await handleNotificationUpdate(update, mockNotificationService, ref);

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
      final ref = await captureRef();

      final update = NotificationUpdate(
        trigger: NotificationTrigger.groupInvite,
        mlsGroupId: testGroupId,
        isDm: true,
        receiver: const NotificationUser(pubkey: testPubkeyA),
        sender: const NotificationUser(pubkey: _senderPubkey),
        content: '',
        timestamp: DateTime.now(),
      );

      await handleNotificationUpdate(update, mockNotificationService, ref);

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
      final ref = await captureRef();

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

      await handleNotificationUpdate(update, mockNotificationService, ref);

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
      final ref = await captureRef();

      final update = NotificationUpdate(
        trigger: NotificationTrigger.newMessage,
        mlsGroupId: testGroupId,
        isDm: true,
        receiver: const NotificationUser(pubkey: testPubkeyA),
        sender: const NotificationUser(pubkey: _senderPubkey),
        content: 'Hello there',
        timestamp: DateTime.now(),
      );

      await handleNotificationUpdate(update, mockNotificationService, ref);

      expect(mockNotificationService.showCalls, hasLength(1));
      final call = mockNotificationService.showCalls.first;
      expect(call.title, 'Alice');
      expect(call.body, 'Hello there');
    });

    test('falls back to Unknown user when metadata fetch fails', () async {
      mockApi.shouldFailMetadataFetch = true;
      final ref = await captureRef();

      final update = NotificationUpdate(
        trigger: NotificationTrigger.groupInvite,
        mlsGroupId: testGroupId,
        isDm: true,
        receiver: const NotificationUser(pubkey: testPubkeyA),
        sender: const NotificationUser(pubkey: _senderPubkey),
        content: '',
        timestamp: DateTime.now(),
      );

      await handleNotificationUpdate(update, mockNotificationService, ref);

      expect(mockNotificationService.showCalls, hasLength(1));
      final call = mockNotificationService.showCalls.first;
      expect(call.title, 'Unknown user');
    });

    test('falls back to Unknown user when metadata has no name fields', () async {
      mockApi.metadataByPubkey[_senderPubkey] = const FlutterMetadata(
        picture: 'https://example.com/avatar.png',
        custom: {},
      );
      final ref = await captureRef();

      final update = NotificationUpdate(
        trigger: NotificationTrigger.groupInvite,
        mlsGroupId: testGroupId,
        isDm: true,
        receiver: const NotificationUser(pubkey: testPubkeyA),
        sender: const NotificationUser(pubkey: _senderPubkey),
        content: '',
        timestamp: DateTime.now(),
      );

      await handleNotificationUpdate(update, mockNotificationService, ref);

      expect(mockNotificationService.showCalls, hasLength(1));
      final call = mockNotificationService.showCalls.first;
      expect(call.title, 'Unknown user');
    });

    test('skips metadata fetch when sender displayName is already set', () async {
      mockApi.metadataByPubkey[_senderPubkey] = const FlutterMetadata(
        displayName: 'Should Not Be Used',
        custom: {},
      );
      final ref = await captureRef();

      final update = NotificationUpdate(
        trigger: NotificationTrigger.newMessage,
        mlsGroupId: testGroupId,
        isDm: true,
        receiver: const NotificationUser(pubkey: testPubkeyA),
        sender: const NotificationUser(pubkey: _senderPubkey, displayName: 'Alice'),
        content: 'Hello',
        timestamp: DateTime.now(),
      );

      await handleNotificationUpdate(update, mockNotificationService, ref);

      expect(mockNotificationService.showCalls, hasLength(1));
      final call = mockNotificationService.showCalls.first;
      expect(call.title, 'Alice');
    });
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
}
