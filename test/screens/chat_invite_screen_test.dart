import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/screens/chat_info_screen.dart';
import 'package:whitenoise/screens/chat_list_screen.dart';
import 'package:whitenoise/screens/chat_screen.dart';
import 'package:whitenoise/screens/wip_screen.dart';
import 'package:whitenoise/src/rust/api/account_groups.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/src/rust/api/messages.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/widgets/chat_message_quote.dart';
import 'package:whitenoise/widgets/wn_avatar.dart';
import 'package:whitenoise/widgets/wn_message_bubble.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart';

import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

const _testPubkey = testPubkeyA;
const _testGroupId = testGroupId;
const _groupIdColor = AvatarColor.violet;
const _otherPubkeyColor = AvatarColor.amber;

ChatMessage _message(
  String id, {
  bool isDeleted = false,
  bool isReply = false,
  String? replyToId,
  String pubkey = testPubkeyB,
  String content = '',
}) => ChatMessage(
  id: id,
  pubkey: pubkey,
  content: content.isEmpty ? 'Message $id' : content,
  createdAt: DateTime(2024),
  tags: const [],
  isReply: isReply,
  replyToId: replyToId,
  isDeleted: isDeleted,
  contentTokens: const [],
  reactions: const ReactionSummary(byEmoji: [], userReactions: []),
  mediaAttachments: const [],
  kind: 9,
);

AccountGroup _accountGroup() => AccountGroup(
  accountPubkey: _testPubkey,
  mlsGroupId: _testGroupId,
  createdAt: PlatformInt64Util.from(0),
  updatedAt: PlatformInt64Util.from(0),
);

class _MockApi extends MockWnApi {
  StreamController<MessageStreamItem>? controller;
  List<ChatMessage> initialMessages = [];
  String groupName = 'Test Group';
  bool acceptCalled = false;
  bool declineCalled = false;
  Exception? errorToThrow;
  FlutterMetadata? userMetadataResponse;
  bool isDm = false;
  List<String> groupMembers = [];

  @override
  void reset() {
    super.reset();
    controller?.close();
    controller = null;
    initialMessages = [];
    groupName = 'Test Group';
    acceptCalled = false;
    declineCalled = false;
    errorToThrow = null;
    userMetadataResponse = null;
    isDm = false;
    groupMembers = [];
  }

  void emitMessage(ChatMessage message) {
    controller?.add(
      MessageStreamItem.update(
        update: MessageUpdate(trigger: UpdateTrigger.newMessage, message: message),
      ),
    );
  }

  @override
  Future<FlutterMetadata> crateApiUsersUserMetadata({
    required String pubkey,
    required bool blockingDataSync,
  }) async {
    return userMetadataResponse ?? const FlutterMetadata(displayName: 'Author', custom: {});
  }

  @override
  Stream<MessageStreamItem> crateApiMessagesSubscribeToGroupMessages({
    required String groupId,
  }) {
    controller?.close();
    controller = StreamController<MessageStreamItem>.broadcast();
    Future.microtask(() {
      controller?.add(
        MessageStreamItem.initialSnapshot(messages: initialMessages),
      );
    });
    return controller!.stream;
  }

  @override
  Future<Group> crateApiGroupsGetGroup({
    required String accountPubkey,
    required String groupId,
  }) async {
    return Group(
      mlsGroupId: groupId,
      nostrGroupId: '',
      name: groupName,
      description: '',
      adminPubkeys: const [],
      epoch: BigInt.zero,
      state: GroupState.active,
    );
  }

  @override
  Future<bool> crateApiGroupsGroupIsDirectMessageType({
    required Group that,
    required String accountPubkey,
  }) async => isDm;

  @override
  Future<List<String>> crateApiGroupsGroupMembers({
    required String pubkey,
    required String groupId,
  }) async => groupMembers;

  @override
  Future<AccountGroup> crateApiAccountGroupsAcceptAccountGroup({
    required String accountPubkey,
    required String mlsGroupId,
  }) async {
    acceptCalled = true;
    if (errorToThrow != null) throw errorToThrow!;
    return _accountGroup();
  }

  @override
  Future<AccountGroup> crateApiAccountGroupsDeclineAccountGroup({
    required String accountPubkey,
    required String mlsGroupId,
  }) async {
    declineCalled = true;
    if (errorToThrow != null) throw errorToThrow!;
    return _accountGroup();
  }
}

class _MockAuthNotifier extends AuthNotifier {
  @override
  Future<String?> build() async => _testPubkey;
}

final _api = _MockApi();

void main() {
  setUpAll(() => RustLib.initMock(api: _api));
  setUp(() => _api.reset());

  Future<void> pumpInviteScreen(WidgetTester tester) async {
    await mountTestApp(
      tester,
      overrides: [authProvider.overrideWith(() => _MockAuthNotifier())],
    );
    await tester.pumpAndSettle();
    Routes.pushToInvite(tester.element(find.byType(Scaffold)), _testGroupId);
    await tester.pumpAndSettle();
  }

  group('ChatInviteScreen', () {
    group('display name', () {
      group('when group', () {
        testWidgets('shows group name', (tester) async {
          _api.groupName = 'My Group';
          await pumpInviteScreen(tester);

          expect(find.text('My Group'), findsWidgets);
        });

        testWidgets('shows Unknown group when group name is empty', (tester) async {
          _api.groupName = '';
          await pumpInviteScreen(tester);

          expect(find.text('Unknown group'), findsWidgets);
        });
      });

      group('when DM', () {
        setUp(() {
          _api.isDm = true;
          _api.groupMembers = [_testPubkey, testPubkeyB];
          _api.userMetadataResponse = const FlutterMetadata(
            displayName: 'Alice',
            custom: {},
          );
        });

        testWidgets('shows other member display name', (tester) async {
          await pumpInviteScreen(tester);

          expect(find.text('Alice'), findsWidgets);
        });

        testWidgets('shows Unknown user when member name is null', (tester) async {
          _api.userMetadataResponse = const FlutterMetadata(custom: {});
          await pumpInviteScreen(tester);

          expect(find.text('Unknown user'), findsWidgets);
        });
      });
    });

    testWidgets('displays back button', (tester) async {
      await pumpInviteScreen(tester);

      expect(find.byKey(const Key('back_button')), findsOneWidget);
    });

    testWidgets('renders two avatars', (tester) async {
      await pumpInviteScreen(tester);

      expect(find.byType(WnAvatar), findsNWidgets(2));
    });

    testWidgets('displays Accept button', (tester) async {
      await pumpInviteScreen(tester);

      expect(find.text('Accept'), findsOneWidget);
    });

    testWidgets('displays Decline button', (tester) async {
      await pumpInviteScreen(tester);

      expect(find.text('Decline'), findsOneWidget);
    });

    group('avatar color', () {
      group('when group', () {
        testWidgets('uses group ID', (tester) async {
          await pumpInviteScreen(tester);

          final avatars = tester.widgetList<WnAvatar>(find.byType(WnAvatar)).toList();
          expect(avatars.length, 2);
          for (final avatar in avatars) {
            expect(avatar.color, _groupIdColor);
          }
        });
      });

      group('when DM', () {
        setUp(() {
          _api.isDm = true;
          _api.groupMembers = [_testPubkey, testPubkeyB];
        });

        testWidgets('uses other member pubkey', (tester) async {
          await pumpInviteScreen(tester);

          final avatars = tester.widgetList<WnAvatar>(find.byType(WnAvatar)).toList();
          expect(avatars.length, 2);
          for (final avatar in avatars) {
            expect(avatar.color, _otherPubkeyColor);
          }
        });
      });
    });

    group('with no messages', () {
      testWidgets('shows empty state text', (tester) async {
        await pumpInviteScreen(tester);

        expect(find.text('You are invited to a secure chat'), findsOneWidget);
      });
    });

    group('with messages', () {
      setUp(() {
        _api.initialMessages = [_message('m1'), _message('m2')];
      });

      testWidgets('displays messages', (tester) async {
        await pumpInviteScreen(tester);

        expect(find.byType(WnMessageBubble), findsNWidgets(2));
      });

      testWidgets('hides empty state text', (tester) async {
        await pumpInviteScreen(tester);

        expect(find.text('You are invited to a secure chat'), findsNothing);
      });

      testWidgets('does not display deleted message text', (tester) async {
        _api.initialMessages = [_message('m1'), _message('m2', isDeleted: true)];
        await pumpInviteScreen(tester);

        expect(find.textContaining('Message m2'), findsNothing);
      });

      group('unread indicator', () {
        testWidgets('hidden when messages fit on screen', (tester) async {
          await pumpInviteScreen(tester);
          await tester.pumpAndSettle();

          expect(find.byKey(const Key('scroll_down_button')), findsNothing);
        });

        group('when scrolled away from bottom', () {
          setUp(() {
            _api.initialMessages = List.generate(20, (i) => _message('m$i'));
          });

          testWidgets('shows indicator', (tester) async {
            await pumpInviteScreen(tester);
            final listFinder = find.byType(ListView);
            await tester.drag(listFinder, const Offset(0, 500));
            await tester.pumpAndSettle();

            expect(find.byKey(const Key('scroll_down_button')), findsOneWidget);
          });

          testWidgets('tapping indicator scrolls to bottom', (tester) async {
            await pumpInviteScreen(tester);
            final listFinder = find.byType(ListView);
            await tester.drag(listFinder, const Offset(0, 500));
            await tester.pumpAndSettle();

            await tester.tap(find.byKey(const Key('scroll_down_button')));
            await tester.pumpAndSettle();

            expect(find.byKey(const Key('scroll_down_button')), findsNothing);
          });
        });
      });
    });

    group('message reception', () {
      testWidgets('message appears when stream emits update', (tester) async {
        await pumpInviteScreen(tester);
        _api.emitMessage(_message('new_msg'));
        await tester.pumpAndSettle();

        expect(find.textContaining('Message new_msg'), findsOneWidget);
      });
    });

    group('reply previews', () {
      testWidgets('displays reply preview when message is a reply', (tester) async {
        _api.initialMessages = [
          _message('m1', content: 'Original message'),
          _message('m2', isReply: true, replyToId: 'm1', content: 'Reply message'),
        ];
        await pumpInviteScreen(tester);

        expect(find.byType(ChatMessageQuote), findsOneWidget);
      });

      testWidgets('does not display reply preview for non-reply messages', (tester) async {
        _api.initialMessages = [_message('m1'), _message('m2')];
        await pumpInviteScreen(tester);

        expect(find.byType(ChatMessageQuote), findsNothing);
      });

      testWidgets('displays author name in reply preview', (tester) async {
        _api.userMetadataResponse = const FlutterMetadata(
          displayName: 'Reply Author',
          custom: {},
        );
        _api.initialMessages = [
          _message('m1', content: 'Original', pubkey: testPubkeyC),
          _message('m2', isReply: true, replyToId: 'm1'),
        ];
        await pumpInviteScreen(tester);

        final replyPreview = find.byType(ChatMessageQuote);
        expect(
          find.descendant(of: replyPreview, matching: find.text('Reply Author')),
          findsOneWidget,
        );
      });

      testWidgets('displays original message content in reply preview', (tester) async {
        _api.initialMessages = [
          _message('m1', content: 'Original message content'),
          _message('m2', isReply: true, replyToId: 'm1', content: 'Reply text'),
        ];
        await pumpInviteScreen(tester);

        final replyPreview = find.byType(ChatMessageQuote);
        expect(replyPreview, findsOneWidget);
        expect(
          find.descendant(of: replyPreview, matching: find.text('Original message content')),
          findsOneWidget,
        );
      });

      testWidgets('displays "Message not found" when reply target is missing', (tester) async {
        _api.initialMessages = [_message('m2', isReply: true, replyToId: 'nonexistent')];
        await pumpInviteScreen(tester);

        expect(find.byType(ChatMessageQuote), findsOneWidget);
        expect(find.text('Message not found'), findsOneWidget);
      });

      testWidgets('displays "Message not found" when reply target is deleted', (tester) async {
        _api.initialMessages = [
          _message('m1', isDeleted: true),
          _message('m2', isReply: true, replyToId: 'm1'),
        ];
        await pumpInviteScreen(tester);

        expect(find.byType(ChatMessageQuote), findsOneWidget);
        expect(find.text('Message not found'), findsOneWidget);
      });
    });

    group('sender info on messages', () {
      group('when group', () {
        setUp(() {
          _api.initialMessages = [_message('m1')];
        });

        testWidgets('shows sender name', (tester) async {
          await pumpInviteScreen(tester);

          expect(find.text('Author'), findsOneWidget);
        });

        testWidgets('shows sender avatar', (tester) async {
          await pumpInviteScreen(tester);

          expect(find.byType(WnAvatar), findsNWidgets(3));
        });

        testWidgets('shows Unknown user when metadata has no name', (tester) async {
          _api.userMetadataResponse = const FlutterMetadata(custom: {});
          await pumpInviteScreen(tester);

          expect(find.text('Unknown user'), findsOneWidget);
        });
      });

      group('when own message in group', () {
        setUp(() {
          _api.initialMessages = [_message('m1', pubkey: _testPubkey)];
        });

        testWidgets('does not show sender name or avatar', (tester) async {
          await pumpInviteScreen(tester);

          expect(find.byKey(const Key('bubble_avatar_row')), findsNothing);
        });
      });

      group('when DM', () {
        setUp(() {
          _api.isDm = true;
          _api.groupMembers = [_testPubkey, testPubkeyB];
          _api.initialMessages = [_message('m1')];
        });

        testWidgets('does not show sender avatar', (tester) async {
          await pumpInviteScreen(tester);

          expect(find.byType(WnAvatar), findsNWidgets(2));
        });
      });
    });

    group('accept action', () {
      testWidgets('calls acceptAccountGroup', (tester) async {
        await pumpInviteScreen(tester);
        await tester.tap(find.text('Accept'));
        await tester.pump();

        expect(_api.acceptCalled, isTrue);
      });

      testWidgets('navigates to chat on success', (tester) async {
        await pumpInviteScreen(tester);
        await tester.tap(find.text('Accept'));
        await tester.pumpAndSettle();

        expect(find.byType(ChatScreen), findsOneWidget);
      });

      testWidgets('shows system notice on error', (tester) async {
        _api.errorToThrow = Exception('Network error');
        await pumpInviteScreen(tester);
        await tester.tap(find.text('Accept'));
        await tester.pumpAndSettle();

        expect(find.byType(WnSystemNotice), findsOneWidget);
        expect(find.textContaining('Failed to accept'), findsOneWidget);
      });

      testWidgets('marks latest message as read', (tester) async {
        _api.initialMessages = [_message('m1'), _message('m2')];
        await pumpInviteScreen(tester);
        _api.markedAsReadMessages.clear();
        await tester.tap(find.text('Accept'));
        await tester.pumpAndSettle();

        expect(_api.markedAsReadMessages, contains('m2'));
      });

      testWidgets('does not mark as read when no messages', (tester) async {
        await pumpInviteScreen(tester);
        _api.markedAsReadMessages.clear();
        await tester.tap(find.text('Accept'));
        await tester.pumpAndSettle();

        expect(_api.markedAsReadMessages, isEmpty);
      });

      testWidgets('dismisses notice after auto-hide duration', (tester) async {
        _api.errorToThrow = Exception('Network error');
        await pumpInviteScreen(tester);
        await tester.tap(find.text('Accept'));
        await tester.pumpAndSettle();
        expect(find.byType(WnSystemNotice), findsOneWidget);

        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();

        expect(find.byType(WnSystemNotice), findsNothing);
      });
    });

    group('decline action', () {
      testWidgets('calls declineAccountGroup', (tester) async {
        await pumpInviteScreen(tester);
        await tester.tap(find.text('Decline'));
        await tester.pump();

        expect(_api.declineCalled, isTrue);
      });

      testWidgets('navigates to chat list on success', (tester) async {
        await pumpInviteScreen(tester);
        await tester.tap(find.text('Decline'));
        await tester.pumpAndSettle();

        expect(find.byType(ChatListScreen), findsOneWidget);
      });

      testWidgets('shows system notice on error', (tester) async {
        _api.errorToThrow = Exception('Network error');
        await pumpInviteScreen(tester);
        await tester.tap(find.text('Decline'));
        await tester.pumpAndSettle();

        expect(find.byType(WnSystemNotice), findsOneWidget);
        expect(find.textContaining('Failed to decline'), findsOneWidget);
      });
    });

    group('navigation', () {
      testWidgets('back button navigates to chat list', (tester) async {
        await pumpInviteScreen(tester);
        await tester.tap(find.byKey(const Key('back_button')));
        await tester.pumpAndSettle();

        expect(find.byType(ChatListScreen), findsOneWidget);
      });

      group('when DM', () {
        setUp(() {
          _api.isDm = true;
          _api.groupMembers = [_testPubkey, testPubkeyB];
        });

        testWidgets('header avatar navigates to chat info', (tester) async {
          await pumpInviteScreen(tester);
          await tester.tap(find.byKey(const Key('header_avatar_tap_area')));
          await tester.pumpAndSettle();

          expect(find.byType(ChatInfoScreen), findsOneWidget);
        });

        testWidgets('large avatar navigates to chat info', (tester) async {
          await pumpInviteScreen(tester);
          await tester.tap(find.byKey(const Key('large_avatar_tap_area')));
          await tester.pumpAndSettle();

          expect(find.byType(ChatInfoScreen), findsOneWidget);
        });
      });

      group('when group', () {
        testWidgets('header avatar navigates to WIP', (tester) async {
          await pumpInviteScreen(tester);
          await tester.tap(find.byKey(const Key('header_avatar_tap_area')));
          await tester.pumpAndSettle();

          expect(find.byType(WipScreen), findsOneWidget);
        });

        testWidgets('large avatar navigates to WIP', (tester) async {
          await pumpInviteScreen(tester);
          await tester.tap(find.byKey(const Key('large_avatar_tap_area')));
          await tester.pumpAndSettle();

          expect(find.byType(WipScreen), findsOneWidget);
        });
      });
    });
  });
}
