import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/providers/debug_view_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/screens/chat_info_screen.dart';
import 'package:whitenoise/screens/chat_list_screen.dart';
import 'package:whitenoise/screens/chat_raw_debug_screen.dart';
import 'package:whitenoise/screens/group_info_screen.dart';
import 'package:whitenoise/screens/message_actions_screen.dart';
import 'package:whitenoise/src/rust/api/drafts.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/src/rust/api/media_files.dart';
import 'package:whitenoise/src/rust/api/messages.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/widgets/chat_media_upload_preview.dart';
import 'package:whitenoise/widgets/chat_message_quote.dart';
import 'package:whitenoise/widgets/wn_avatar.dart';
import 'package:whitenoise/widgets/wn_message_bubble.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart';

import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

const _testPubkey = testPubkeyA;
const _testGroupId = testGroupId;

class _MockImagePickerPlatform extends ImagePickerPlatform with MockPlatformInterfaceMixin {
  List<XFile> filesToReturn = [];

  @override
  Future<List<XFile>> getMultiImageWithOptions({
    MultiImagePickerOptions options = const MultiImagePickerOptions(),
  }) async {
    return filesToReturn;
  }
}

class _MockTag implements Tag {
  final List<String> vec;
  _MockTag(this.vec);

  @override
  void dispose() {}

  @override
  bool get isDisposed => false;
}

ChatMessage _message(
  String id,
  DateTime createdAt, {
  String pubkey = testPubkeyB,
  bool isDeleted = false,
  bool isReply = false,
  String? replyToId,
  ReactionSummary reactions = const ReactionSummary(byEmoji: [], userReactions: []),
  DeliveryStatus? deliveryStatus,
}) => ChatMessage(
  id: id,
  pubkey: pubkey,
  content: 'Message $id',
  createdAt: createdAt,
  tags: const [],
  isReply: isReply,
  replyToId: replyToId,
  isDeleted: isDeleted,
  contentTokens: const [],
  reactions: reactions,
  mediaAttachments: const [],
  kind: 9,
  deliveryStatus: deliveryStatus,
);

class _MockApi extends MockWnApi {
  StreamController<MessageStreamItem>? controller;
  List<ChatMessage> initialMessages = [];
  String groupName = 'Test Group';
  final List<String> sentMessages = [];
  final List<({String groupId, int kind, List<Tag>? tags})> deletionCalls = [];
  final List<({String groupId, String message, int kind, List<Tag>? tags})> reactionCalls = [];
  final List<List<List<String>>> sentTextMessageTagVecs = [];
  final List<({String pubkey, String groupId, String eventId})> retryAttempts = [];
  Exception? sendError;
  Exception? deleteError;
  Exception? reactionError;
  Exception? retryError;
  int _sendCallCount = 0;
  bool isDm = false;
  List<String> groupMembers = [];
  Completer<MediaFile>? uploadCompleter;
  Map<String, FlutterMetadata>? metadataByPubkey;

  @override
  void reset() {
    super.reset();
    controller?.close();
    controller = null;
    initialMessages = [];
    groupName = 'Test Group';
    sentMessages.clear();
    deletionCalls.clear();
    reactionCalls.clear();
    retryAttempts.clear();
    sentTextMessageTagVecs.clear();
    sendError = null;
    deleteError = null;
    reactionError = null;
    retryError = null;
    _sendCallCount = 0;
    isDm = false;
    groupMembers = [];
    uploadCompleter = null;
    metadataByPubkey = null;
  }

  @override
  Future<void> crateApiMessagesRetryMessagePublish({
    required String pubkey,
    required String groupId,
    required String eventId,
  }) async {
    retryAttempts.add((pubkey: pubkey, groupId: groupId, eventId: eventId));
    if (retryError != null) throw retryError!;
  }

  @override
  Future<Tag> crateApiUtilsTagFromVec({required List<String> vec}) async {
    return _MockTag(vec);
  }

  void emitMessage(ChatMessage message) {
    controller?.add(
      MessageStreamItem.update(
        update: MessageUpdate(trigger: UpdateTrigger.newMessage, message: message),
      ),
    );
  }

  @override
  Future<MessageWithTokens> crateApiMessagesSendMessageToGroup({
    required String pubkey,
    required String groupId,
    required String message,
    required int kind,
    List<Tag>? tags,
  }) async {
    _sendCallCount++;

    if (kind == 5) {
      if (deleteError != null) throw deleteError!;
      deletionCalls.add((groupId: groupId, kind: kind, tags: tags));
    } else if (kind == 7) {
      if (reactionError != null) throw reactionError!;
      reactionCalls.add((groupId: groupId, message: message, kind: kind, tags: tags));
    } else {
      if (sendError != null) throw sendError!;
      sentMessages.add(message);
      if (tags != null) {
        sentTextMessageTagVecs.add(tags.cast<_MockTag>().map((t) => t.vec).toList());
      }
    }
    return MessageWithTokens(
      id: 'mock_$_sendCallCount',
      pubkey: pubkey,
      kind: kind,
      createdAt: DateTime.now(),
      content: message,
      tokens: const [],
    );
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
  Future<FlutterMetadata> crateApiUsersUserMetadata({
    required bool blockingDataSync,
    required String pubkey,
  }) async {
    if (metadataByPubkey != null && metadataByPubkey!.containsKey(pubkey)) {
      return metadataByPubkey![pubkey]!;
    }
    return super.crateApiUsersUserMetadata(
      blockingDataSync: blockingDataSync,
      pubkey: pubkey,
    );
  }

  @override
  Future<Group> crateApiGroupsGetGroup({
    required String accountPubkey,
    required String groupId,
  }) {
    return Future.value(
      Group(
        mlsGroupId: groupId,
        nostrGroupId: 'nostr_$groupId',
        name: groupName,
        description: '',
        adminPubkeys: const [],
        epoch: BigInt.zero,
        state: GroupState.active,
      ),
    );
  }

  @override
  Future<String?> crateApiGroupsGetGroupImagePath({
    required String accountPubkey,
    required String groupId,
  }) {
    return Future.value('https://example.com/group.jpg');
  }

  @override
  Future<bool> crateApiGroupsGroupIsDirectMessageType({
    required Group that,
    required String accountPubkey,
  }) {
    return Future.value(isDm);
  }

  @override
  Future<List<String>> crateApiGroupsGroupMembers({
    required String pubkey,
    required String groupId,
  }) {
    return Future.value(groupMembers);
  }

  @override
  Future<MediaFile> crateApiMediaFilesUploadChatMedia({
    required String accountPubkey,
    required String groupId,
    required String filePath,
  }) async {
    if (uploadCompleter != null) {
      return uploadCompleter!.future;
    }
    return MediaFile(
      id: 'media_${filePath.hashCode}',
      mlsGroupId: groupId,
      accountPubkey: accountPubkey,
      filePath: filePath,
      encryptedFileHash: 'encrypted_hash',
      mimeType: 'image/jpeg',
      mediaType: 'image',
      blossomUrl: 'https://example.com/media',
      nostrKey: 'nostr_key',
      createdAt: DateTime(2024),
    );
  }
}

class _MockAuthNotifier extends AuthNotifier {
  @override
  Future<String?> build() async => _testPubkey;
}

class _MockDebugViewNotifier extends DebugViewNotifier {
  @override
  Future<bool> build() async => true;
}

final _api = _MockApi();

void main() {
  setUpAll(() {
    mockPathProvider();
    RustLib.initMock(api: _api);
  });
  setUp(() => _api.reset());

  Future<void> pumpChatScreen(WidgetTester tester) async {
    await mountTestApp(
      tester,
      overrides: [authProvider.overrideWith(() => _MockAuthNotifier())],
    );
    await tester.pumpAndSettle();
    Routes.goToChat(
      tester.element(find.byType(Scaffold)),
      _testGroupId,
    );
    await tester.pumpAndSettle();
  }

  group('ChatScreen', () {
    testWidgets('displays group name in header', (tester) async {
      _api.groupName = 'My Chat Group';
      await pumpChatScreen(tester);

      expect(find.text('My Chat Group'), findsOneWidget);
    });

    testWidgets('displays Unknown group when group name is empty', (tester) async {
      _api.groupName = '';
      await pumpChatScreen(tester);

      expect(find.text('Unknown group'), findsOneWidget);
    });

    testWidgets('displays disabled chat input', (tester) async {
      await pumpChatScreen(tester);

      expect(find.text('Message'), findsOneWidget);
    });

    testWidgets('displays back button', (tester) async {
      await pumpChatScreen(tester);

      expect(find.byKey(const Key('back_button')), findsOneWidget);
    });

    testWidgets('displays avatar', (tester) async {
      await pumpChatScreen(tester);

      expect(find.byType(WnAvatar), findsOneWidget);
    });

    group('avatar color', () {
      group('when group', () {
        testWidgets('uses group ID color', (tester) async {
          await pumpChatScreen(tester);

          final avatar = tester.widget<WnAvatar>(find.byType(WnAvatar));
          expect(avatar.color, AvatarColor.violet);
        });
      });

      group('when DM', () {
        setUp(() {
          _api.isDm = true;
          _api.groupMembers = [_testPubkey, testPubkeyC];
        });

        testWidgets('uses other member pubkey color', (tester) async {
          await pumpChatScreen(tester);

          final avatar = tester.widget<WnAvatar>(find.byType(WnAvatar));
          expect(avatar.color, AvatarColor.blue);
        });

        testWidgets('displays Unknown user when display name is null', (tester) async {
          _api.metadataByPubkey = {
            testPubkeyC: const FlutterMetadata(custom: {}),
          };
          await pumpChatScreen(tester);

          expect(find.text('Unknown user'), findsOneWidget);
        });
      });
    });

    group('with no messages', () {
      testWidgets('shows empty state', (tester) async {
        await pumpChatScreen(tester);

        expect(find.text('No messages yet'), findsOneWidget);
      });
    });

    group('with messages', () {
      testWidgets('displays messages', (tester) async {
        _api.initialMessages = [
          _message('m1', DateTime(2024, 1, 2)),
          _message('m2', DateTime(2024, 1, 3)),
        ];
        await pumpChatScreen(tester);

        expect(find.byType(WnMessageBubble), findsNWidgets(2));
      });

      testWidgets('displays message content', (tester) async {
        _api.initialMessages = [
          _message('m1', DateTime(2024, 1, 4)),
        ];
        await pumpChatScreen(tester);

        expect(find.textContaining('Message m1'), findsOneWidget);
      });

      testWidgets('does not display deleted message text', (tester) async {
        _api.initialMessages = [
          _message('m1', DateTime(2024, 1, 2)),
          _message('m2', DateTime(2024, 1, 3), isDeleted: true),
        ];
        await pumpChatScreen(tester);

        expect(find.textContaining('Message m2'), findsNothing);
      });
    });

    group('bubble grouping', () {
      Finder avatarsInBubbles() => find.descendant(
        of: find.byType(WnMessageBubble),
        matching: find.byType(WnAvatar),
      );

      testWidgets('same sender <5 min apart: only older message shows avatar', (tester) async {
        final base = DateTime(2024, 1, 1, 12);
        _api.initialMessages = [
          _message('m1', base),
          _message('m2', base.add(const Duration(minutes: 2))),
        ];
        await pumpChatScreen(tester);

        expect(avatarsInBubbles(), findsOneWidget);
      });

      testWidgets('same sender >=5 min apart: both messages show avatar', (tester) async {
        final base = DateTime(2024, 1, 1, 12);
        _api.initialMessages = [
          _message('m1', base),
          _message('m2', base.add(const Duration(minutes: 5))),
        ];
        await pumpChatScreen(tester);

        expect(avatarsInBubbles(), findsNWidgets(2));
      });

      testWidgets('different senders: both messages show avatar', (tester) async {
        final base = DateTime(2024, 1, 1, 12);
        _api.initialMessages = [
          _message('m1', base),
          _message('m2', base.add(const Duration(minutes: 1)), pubkey: testPubkeyC),
        ];
        await pumpChatScreen(tester);

        expect(avatarsInBubbles(), findsNWidgets(2));
      });

      testWidgets('own messages never show avatar', (tester) async {
        final base = DateTime(2024, 1, 1, 12);
        _api.initialMessages = [
          _message('m1', base, pubkey: _testPubkey),
          _message('m2', base.add(const Duration(minutes: 10)), pubkey: _testPubkey),
        ];
        await pumpChatScreen(tester);

        expect(avatarsInBubbles(), findsNothing);
      });

      testWidgets('single incoming message shows avatar', (tester) async {
        _api.initialMessages = [
          _message('m1', DateTime(2024)),
        ];
        await pumpChatScreen(tester);

        expect(avatarsInBubbles(), findsOneWidget);
      });

      testWidgets('same sender <5 min apart: only older message has tail', (tester) async {
        final base = DateTime(2024, 1, 1, 12);
        _api.initialMessages = [
          _message('m1', base),
          _message('m2', base.add(const Duration(minutes: 2))),
        ];
        await pumpChatScreen(tester);

        final tails = find.descendant(
          of: find.byType(WnMessageBubble),
          matching: find.byType(CustomPaint),
        );
        expect(tails, findsOneWidget);
      });

      testWidgets('same sender >=5 min apart: both messages have tail', (tester) async {
        final base = DateTime(2024, 1, 1, 12);
        _api.initialMessages = [
          _message('m1', base),
          _message('m2', base.add(const Duration(minutes: 5))),
        ];
        await pumpChatScreen(tester);

        final tails = find.descendant(
          of: find.byType(WnMessageBubble),
          matching: find.byType(CustomPaint),
        );
        expect(tails, findsNWidgets(2));
      });
    });

    group('navigation', () {
      testWidgets('back button navigates to chat list', (tester) async {
        await pumpChatScreen(tester);
        await tester.tap(find.byKey(const Key('back_button')));
        await tester.pumpAndSettle();
        expect(find.byType(ChatListScreen), findsOneWidget);
      });

      testWidgets('OS back navigates to chat list', (tester) async {
        await pumpChatScreen(tester);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(ChatListScreen), findsOneWidget);
      });

      testWidgets('avatar navigates to group info screen for group chat', (tester) async {
        await pumpChatScreen(tester);
        await tester.tap(find.byKey(const Key('header_avatar_tap_area')));
        await tester.pumpAndSettle();
        expect(find.byType(GroupInfoScreen), findsOneWidget);
      });

      testWidgets('avatar navigates to chat info screen for DM', (tester) async {
        _api.isDm = true;
        _api.groupMembers = [_testPubkey, testPubkeyC];
        await pumpChatScreen(tester);
        await tester.tap(find.byKey(const Key('header_avatar_tap_area')));
        await tester.pumpAndSettle();
        expect(find.byType(ChatInfoScreen), findsOneWidget);
      });

      testWidgets('name navigates to chat info screen for DM', (tester) async {
        _api.isDm = true;
        _api.groupMembers = [_testPubkey, testPubkeyC];
        await pumpChatScreen(tester);
        await tester.tap(find.byKey(const Key('header_name_tap_area')));
        await tester.pumpAndSettle();
        expect(find.byType(ChatInfoScreen), findsOneWidget);
      });
    });

    group('message sending', () {
      testWidgets('send button appears when text is entered', (tester) async {
        await pumpChatScreen(tester);
        await tester.enterText(find.byType(TextField), 'Hello');
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('send_button')), findsOneWidget);
      });

      testWidgets('input is cleared after sending', (tester) async {
        await pumpChatScreen(tester);
        await tester.enterText(find.byType(TextField), 'Hello');
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('send_button')));
        await tester.pumpAndSettle();

        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.controller!.text, isEmpty);
      });

      testWidgets('send button disappears after sending', (tester) async {
        await pumpChatScreen(tester);
        await tester.enterText(find.byType(TextField), 'Hello');
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('send_button')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('send_button')), findsNothing);
      });

      group('when sending fails', () {
        Future<void> attemptSend(WidgetTester tester) async {
          _api.sendError = Exception('Network error');
          await pumpChatScreen(tester);
          await tester.enterText(find.byType(TextField), 'Hello');
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('send_button')));
          await tester.pumpAndSettle();
        }

        testWidgets('input is not cleared', (tester) async {
          await attemptSend(tester);

          final textField = tester.widget<TextField>(find.byType(TextField));
          expect(textField.controller!.text, 'Hello');
        });

        testWidgets('shows system notice', (tester) async {
          await attemptSend(tester);

          expect(find.byType(WnSystemNotice), findsOneWidget);
          expect(find.text('Failed to send message. Please try again.'), findsOneWidget);
        });

        testWidgets('dismisses notice after auto-hide duration', (tester) async {
          await attemptSend(tester);
          expect(find.byType(WnSystemNotice), findsOneWidget);

          await tester.pump(const Duration(seconds: 3));
          await tester.pumpAndSettle();

          expect(find.byType(WnSystemNotice), findsNothing);
        });

        testWidgets('system notice is rendered inside WnSlate', (tester) async {
          await attemptSend(tester);

          final noticeFinder = find.byType(WnSystemNotice);
          expect(noticeFinder, findsOneWidget);
          expect(
            find.ancestor(
              of: noticeFinder,
              matching: find.byType(WnSlate),
            ),
            findsOneWidget,
          );
        });
      });
    });

    group('message reception', () {
      testWidgets('message bubble appears when stream emits update', (tester) async {
        await pumpChatScreen(tester);
        _api.emitMessage(_message('new_msg', DateTime.now()));
        await tester.pumpAndSettle();

        expect(find.textContaining('Message new_msg'), findsOneWidget);
      });
    });

    group('retry failed message', () {
      setUp(() {
        _api.initialMessages = [
          _message(
            'failed1',
            DateTime(2024),
            pubkey: _testPubkey,
            deliveryStatus: const DeliveryStatus.failed(reason: 'timeout'),
          ),
        ];
      });

      testWidgets('calls retryMessagePublish on tap', (tester) async {
        await pumpChatScreen(tester);
        await tester.tap(find.byKey(const Key('status_tap_area')));
        await tester.pumpAndSettle();

        expect(_api.retryAttempts.length, 1);
        expect(_api.retryAttempts.first.eventId, 'failed1');
      });

      testWidgets('shows system notice when retry fails', (tester) async {
        _api.retryError = Exception('retry failed');
        await pumpChatScreen(tester);
        await tester.tap(find.byKey(const Key('status_tap_area')));
        await tester.pumpAndSettle();

        expect(find.byType(WnSystemNotice), findsOneWidget);
        expect(find.text('Failed to send message. Please try again.'), findsOneWidget);
      });

      testWidgets('does not show retry for non-own messages', (tester) async {
        _api.initialMessages = [
          _message(
            'failed2',
            DateTime(2024),
            deliveryStatus: const DeliveryStatus.failed(reason: 'timeout'),
          ),
        ];
        await pumpChatScreen(tester);

        expect(find.byKey(const Key('status_tap_area')), findsNothing);
      });
    });

    group('focus management', () {
      testWidgets('tapping outside unfocuses input', (tester) async {
        await pumpChatScreen(tester);
        await tester.tap(find.byType(TextField));
        await tester.pumpAndSettle();

        await tester.tap(find.text('No messages yet'));
        await tester.pumpAndSettle();

        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.focusNode!.hasFocus, isFalse);
      });
    });

    group('auto-scroll', () {
      setUp(() {
        _api.initialMessages = List.generate(
          20,
          (i) => _message('m$i', DateTime(2024, 1, i + 1)),
        );
        _api.lastReadMessageId = 'm19';
      });

      ScrollPosition getScrollPosition(WidgetTester tester) {
        return Scrollable.of(tester.element(find.byType(WnMessageBubble).first)).position;
      }

      testWidgets('scrolls to bottom on initial load', (tester) async {
        await pumpChatScreen(tester);
        await tester.pumpAndSettle();

        final position = getScrollPosition(tester);
        expect(position.pixels, 0);
      });

      testWidgets('scrolls to bottom when own message arrives', (tester) async {
        await pumpChatScreen(tester);
        _api.emitMessage(_message('own', DateTime.now(), pubkey: _testPubkey));
        await tester.pumpAndSettle();

        final position = getScrollPosition(tester);
        expect(position.pixels, 0);
      });

      testWidgets('scrolls when at bottom and other message arrives', (tester) async {
        await pumpChatScreen(tester);
        await tester.pumpAndSettle();

        final position = getScrollPosition(tester);
        expect(position.pixels, 0);

        _api.emitMessage(_message('other', DateTime.now()));
        await tester.pumpAndSettle();

        expect(position.pixels, 0);
      });

      testWidgets('does not scroll when not at bottom and other message arrives', (tester) async {
        await pumpChatScreen(tester);
        await tester.pumpAndSettle();

        final position = getScrollPosition(tester);
        position.jumpTo(position.maxScrollExtent);
        await tester.pumpAndSettle();

        final positionBeforeMessage = position.pixels;

        _api.emitMessage(_message('other', DateTime.now()));
        await tester.pumpAndSettle();

        expect(position.pixels, positionBeforeMessage);
      });

      testWidgets('scrolls to bottom when input is focused', (tester) async {
        await pumpChatScreen(tester);
        await tester.pumpAndSettle();

        final position = getScrollPosition(tester);
        position.jumpTo(position.maxScrollExtent);
        await tester.pumpAndSettle();

        await tester.tap(find.byType(TextField));
        final animationDelay = const Duration(milliseconds: 400);
        await tester.pump(animationDelay);
        await tester.pumpAndSettle();

        expect(position.pixels, 0);
      });
    });

    group('message actions', () {
      Future<void> longPressMessage(WidgetTester tester, String messageId) async {
        final messageFinder = find.textContaining('Message $messageId');
        await tester.longPress(messageFinder);
        await tester.pumpAndSettle();
      }

      testWidgets('opens on long press', (tester) async {
        _api.initialMessages = [
          _message('m1', DateTime(2024)),
        ];
        await pumpChatScreen(tester);

        await longPressMessage(tester, 'm1');

        expect(find.byType(MessageActionsScreen), findsOneWidget);
      });

      testWidgets('shows Delete button for own message', (tester) async {
        _api.initialMessages = [
          _message('m1', DateTime(2024), pubkey: _testPubkey),
        ];
        await pumpChatScreen(tester);

        await longPressMessage(tester, 'm1');

        expect(find.text('Delete'), findsOneWidget);
      });

      testWidgets('hides Delete button for other user message', (tester) async {
        _api.initialMessages = [
          _message('m1', DateTime(2024), pubkey: 'other_user'),
        ];
        await pumpChatScreen(tester);

        await longPressMessage(tester, 'm1');

        expect(find.text('Delete'), findsNothing);
      });

      testWidgets('closes when tapping outside', (tester) async {
        _api.initialMessages = [
          _message('m1', DateTime(2024)),
        ];
        await pumpChatScreen(tester);

        await longPressMessage(tester, 'm1');

        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        expect(find.byType(MessageActionsScreen), findsNothing);
      });

      testWidgets('unfocuses text field when opening', (tester) async {
        _api.initialMessages = [
          _message('m1', DateTime(2024)),
        ];
        await pumpChatScreen(tester);

        await tester.tap(find.byType(TextField));
        await tester.pumpAndSettle();
        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.focusNode!.hasFocus, isTrue);

        await longPressMessage(tester, 'm1');

        expect(textField.focusNode!.hasFocus, isFalse);
      });

      testWidgets('unfocuses text field when closing message actions', (tester) async {
        _api.initialMessages = [
          _message('m1', DateTime(2024)),
        ];
        await pumpChatScreen(tester);

        await tester.tap(find.byType(TextField));
        await tester.pumpAndSettle();
        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.focusNode!.hasFocus, isTrue);

        await longPressMessage(tester, 'm1');
        expect(textField.focusNode!.hasFocus, isFalse);

        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        expect(find.byType(MessageActionsScreen), findsNothing);
        expect(textField.focusNode!.hasFocus, isFalse);
      });

      testWidgets('unfocuses text field after selecting reaction', (tester) async {
        _api.initialMessages = [
          _message('m1', DateTime(2024)),
        ];
        await pumpChatScreen(tester);

        await tester.tap(find.byType(TextField));
        await tester.pumpAndSettle();
        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.focusNode!.hasFocus, isTrue);

        await longPressMessage(tester, 'm1');
        expect(textField.focusNode!.hasFocus, isFalse);

        await tester.tap(find.text('❤'));
        await tester.pumpAndSettle();

        expect(find.byType(MessageActionsScreen), findsNothing);
        expect(textField.focusNode!.hasFocus, isFalse);
      });

      group('message deletion', () {
        testWidgets('calls API when Delete is tapped', (tester) async {
          _api.initialMessages = [
            _message('m1', DateTime(2024), pubkey: _testPubkey),
          ];
          await pumpChatScreen(tester);

          await longPressMessage(tester, 'm1');

          await tester.tap(find.text('Delete'));
          await tester.pumpAndSettle();

          expect(_api.deletionCalls.length, 1);
        });

        testWidgets('close messages actions after deletion', (tester) async {
          _api.initialMessages = [
            _message('m1', DateTime(2024), pubkey: _testPubkey),
          ];
          await pumpChatScreen(tester);

          await longPressMessage(tester, 'm1');

          await tester.tap(find.text('Delete'));
          await tester.pumpAndSettle();

          expect(find.byType(MessageActionsScreen), findsNothing);
        });

        testWidgets('sends deletion to correct group', (tester) async {
          _api.initialMessages = [
            _message('m1', DateTime(2024), pubkey: _testPubkey),
          ];
          await pumpChatScreen(tester);

          await longPressMessage(tester, 'm1');

          await tester.tap(find.text('Delete'));
          await tester.pumpAndSettle();

          expect(_api.deletionCalls.first.groupId, _testGroupId);
        });

        testWidgets('deletes expected message id', (tester) async {
          _api.initialMessages = [
            _message('msg_to_delete', DateTime(2024), pubkey: _testPubkey),
          ];
          await pumpChatScreen(tester);

          await longPressMessage(tester, 'msg_to_delete');

          await tester.tap(find.text('Delete'));
          await tester.pumpAndSettle();

          final tags = _api.deletionCalls.first.tags!.cast<_MockTag>();
          expect(tags[0].vec, ['e', 'msg_to_delete']);
        });

        testWidgets('shows system notice when deletion fails', (tester) async {
          _api.deleteError = Exception('Network error');
          _api.initialMessages = [
            _message('m1', DateTime(2024), pubkey: _testPubkey),
          ];
          await pumpChatScreen(tester);

          await longPressMessage(tester, 'm1');

          await tester.tap(find.text('Delete'));
          await tester.pumpAndSettle();

          expect(_api.deletionCalls.length, 0);
          expect(find.byType(WnSystemNotice), findsOneWidget);
          expect(find.text('Failed to delete message. Please try again.'), findsOneWidget);
          expect(find.byType(MessageActionsScreen), findsOneWidget);
        });
      });

      group('message reactions', () {
        testWidgets('calls API when reaction is tapped', (tester) async {
          _api.initialMessages = [
            _message('m1', DateTime(2024)),
          ];
          await pumpChatScreen(tester);

          await longPressMessage(tester, 'm1');

          await tester.tap(find.text('❤'));
          await tester.pumpAndSettle();

          expect(_api.reactionCalls.length, 1);
        });

        testWidgets('sends correct emoji as reaction', (tester) async {
          _api.initialMessages = [
            _message('m1', DateTime(2024)),
          ];
          await pumpChatScreen(tester);

          await longPressMessage(tester, 'm1');

          await tester.tap(find.text('🤣'));
          await tester.pumpAndSettle();

          expect(_api.reactionCalls.first.message, '🤣');
        });

        testWidgets('sends reaction to correct group', (tester) async {
          _api.initialMessages = [
            _message('m1', DateTime(2024)),
          ];
          await pumpChatScreen(tester);

          await longPressMessage(tester, 'm1');

          await tester.tap(find.text('❤'));
          await tester.pumpAndSettle();

          expect(_api.reactionCalls.first.groupId, _testGroupId);
        });

        testWidgets('includes message reference in reaction tags', (tester) async {
          _api.initialMessages = [
            _message('msg_to_react', DateTime(2024)),
          ];
          await pumpChatScreen(tester);

          await longPressMessage(tester, 'msg_to_react');

          await tester.tap(find.text('❤'));
          await tester.pumpAndSettle();

          final tags = _api.reactionCalls.first.tags!.cast<_MockTag>();
          expect(tags[0].vec, ['e', 'msg_to_react']);
        });

        testWidgets('closes message actions after sending reaction', (tester) async {
          _api.initialMessages = [
            _message('m1', DateTime(2024)),
          ];
          await pumpChatScreen(tester);

          await longPressMessage(tester, 'm1');

          await tester.tap(find.text('❤'));
          await tester.pumpAndSettle();

          expect(find.byType(MessageActionsScreen), findsNothing);
        });

        testWidgets('shows system notice when reaction fails', (tester) async {
          _api.reactionError = Exception('Network error');
          _api.initialMessages = [
            _message('m1', DateTime(2024)),
          ];
          await pumpChatScreen(tester);

          await longPressMessage(tester, 'm1');

          await tester.tap(find.text('❤'));
          await tester.pumpAndSettle();

          expect(_api.reactionCalls.length, 0);
          expect(find.byType(WnSystemNotice), findsOneWidget);
          expect(find.text('Failed to send reaction. Please try again.'), findsOneWidget);
          expect(find.byType(MessageActionsScreen), findsOneWidget);
        });
      });

      group('reaction deletion from message actions', () {
        ReactionSummary ownReaction(String emoji, String reactionId) => ReactionSummary(
          byEmoji: [
            EmojiReaction(emoji: emoji, count: BigInt.one, users: const [_testPubkey]),
          ],
          userReactions: [
            UserReaction(
              reactionId: reactionId,
              emoji: emoji,
              user: _testPubkey,
              createdAt: DateTime(2024),
            ),
          ],
        );

        testWidgets('calls delete API when tapping selected emoji', (tester) async {
          _api.initialMessages = [
            _message('m1', DateTime(2024), reactions: ownReaction('❤', 'reaction_1')),
          ];
          await pumpChatScreen(tester);

          await longPressMessage(tester, 'm1');
          await tester.tap(find.byKey(const Key('reaction_❤')));
          await tester.pumpAndSettle();

          expect(_api.deletionCalls.length, 1);
        });

        testWidgets('sends correct reaction ID in deletion tags', (tester) async {
          _api.initialMessages = [
            _message('m1', DateTime(2024), reactions: ownReaction('❤', 'reaction_to_remove')),
          ];
          await pumpChatScreen(tester);

          await longPressMessage(tester, 'm1');
          await tester.tap(find.byKey(const Key('reaction_❤')));
          await tester.pumpAndSettle();

          final tags = _api.deletionCalls.first.tags!.cast<_MockTag>();
          expect(tags[0].vec, ['e', 'reaction_to_remove']);
        });

        testWidgets('closes message actions after removing reaction', (tester) async {
          _api.initialMessages = [
            _message('m1', DateTime(2024), reactions: ownReaction('❤', 'reaction_1')),
          ];
          await pumpChatScreen(tester);

          await longPressMessage(tester, 'm1');
          await tester.tap(find.byKey(const Key('reaction_❤')));
          await tester.pumpAndSettle();

          expect(find.byType(MessageActionsScreen), findsNothing);
        });

        testWidgets('shows system notice when reaction removal fails', (tester) async {
          _api.deleteError = Exception('Network error');
          _api.initialMessages = [
            _message('m1', DateTime(2024), reactions: ownReaction('❤', 'reaction_1')),
          ];
          await pumpChatScreen(tester);

          await longPressMessage(tester, 'm1');
          await tester.tap(find.byKey(const Key('reaction_❤')));
          await tester.pumpAndSettle();

          expect(_api.deletionCalls.length, 0);
          expect(find.byType(WnSystemNotice), findsOneWidget);
          expect(find.text('Failed to remove reaction. Please try again.'), findsOneWidget);
          expect(find.byType(MessageActionsScreen), findsOneWidget);
        });
      });

      testWidgets('shows reply preview for reply message', (tester) async {
        _api.initialMessages = [
          _message('m1', DateTime(2024)),
          _message('m2', DateTime(2024, 1, 2), isReply: true, replyToId: 'm1'),
        ];
        await pumpChatScreen(tester);
        await longPressMessage(tester, 'm2');

        expect(
          find.descendant(
            of: find.byType(MessageActionsScreen),
            matching: find.byType(ChatMessageQuote),
          ),
          findsOneWidget,
        );
      });

      testWidgets('shows sender picture in avatar', (tester) async {
        _api.metadataByPubkey = {
          testPubkeyB: const FlutterMetadata(
            name: 'Sender',
            displayName: 'Sender',
            picture: 'https://example.com/avatar.jpg',
            custom: {},
          ),
        };
        _api.initialMessages = [
          _message('m1', DateTime(2024)),
        ];
        await pumpChatScreen(tester);
        await longPressMessage(tester, 'm1');

        final avatar = tester.widget<WnAvatar>(
          find.descendant(
            of: find.byType(MessageActionsScreen),
            matching: find.byType(WnAvatar),
          ),
        );
        expect(avatar.pictureUrl, 'https://example.com/avatar.jpg');
      });
    });

    group('replies', () {
      testWidgets('displays reply preview in bubble when message is a reply', (tester) async {
        _api.initialMessages = [
          _message('m1', DateTime(2024)),
          _message('m2', DateTime(2024, 1, 2), isReply: true, replyToId: 'm1', pubkey: _testPubkey),
        ];
        await pumpChatScreen(tester);

        expect(find.textContaining('Message m1'), findsWidgets);
        expect(find.textContaining('Message m2'), findsOneWidget);
        expect(find.byType(ChatMessageQuote), findsOneWidget);
      });

      testWidgets('swiping message bubble shows reply preview in input', (tester) async {
        _api.initialMessages = [
          _message('m1', DateTime(2024)),
        ];
        await pumpChatScreen(tester);
        expect(find.byType(ChatMessageQuote), findsNothing);

        await tester.fling(find.textContaining('Message m1'), const Offset(500, 0), 1000);
        await tester.pumpAndSettle();

        expect(find.byType(ChatMessageQuote), findsOneWidget);
        expect(find.textContaining('Message m1'), findsWidgets);
      });

      testWidgets('tapping Reply in message actions shows reply preview in input', (tester) async {
        _api.initialMessages = [
          _message('m1', DateTime(2024)),
        ];
        await pumpChatScreen(tester);
        expect(find.byType(ChatMessageQuote), findsNothing);

        await tester.longPress(find.textContaining('Message m1'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('reply_button')));
        await tester.pumpAndSettle();

        expect(find.byType(ChatMessageQuote), findsOneWidget);
        expect(find.textContaining('Message m1'), findsWidgets);
      });

      testWidgets('sending while replying includes reply reference in send', (tester) async {
        _api.initialMessages = [
          _message('m1', DateTime(2024)),
        ];
        await pumpChatScreen(tester);
        await tester.longPress(find.textContaining('Message m1'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('reply_button')));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'My reply');
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('send_button')));
        await tester.pumpAndSettle();

        expect(_api.sentMessages.last, 'My reply');
        expect(_api.sentTextMessageTagVecs, isNotEmpty);
        final tagVecs = _api.sentTextMessageTagVecs.last;
        expect(tagVecs.any((t) => t.isNotEmpty && t[0] == 'e'), isTrue);
      });

      testWidgets('cancel reply hides reply preview in input', (tester) async {
        _api.initialMessages = [
          _message('m1', DateTime(2024)),
        ];
        await pumpChatScreen(tester);
        await tester.longPress(find.textContaining('Message m1'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('reply_button')));
        await tester.pumpAndSettle();
        expect(find.byType(ChatMessageQuote), findsOneWidget);

        await tester.tap(find.byKey(const Key('cancel_quote_button')));
        await tester.pumpAndSettle();

        expect(find.byType(ChatMessageQuote), findsNothing);
      });

      testWidgets('hides reply preview when replied message is deleted', (tester) async {
        _api.initialMessages = [
          _message('m1', DateTime(2024)),
        ];
        await pumpChatScreen(tester);

        await tester.longPress(find.textContaining('Message m1'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('reply_button')));
        await tester.pumpAndSettle();

        expect(find.byType(ChatMessageQuote), findsOneWidget);

        _api.emitMessage(_message('m1', DateTime(2024), isDeleted: true));
        await tester.pumpAndSettle();

        expect(find.byType(ChatMessageQuote), findsNothing);
      });

      testWidgets('tapping reply preview scrolls to original message', (tester) async {
        _api.initialMessages = [
          ...List.generate(
            20,
            (i) => _message('m$i', DateTime(2024, 1, i + 1)),
          ),
          _message(
            'reply_msg',
            DateTime(2024, 1, 22),
            isReply: true,
            replyToId: 'm0',
            pubkey: _testPubkey,
          ),
        ];
        // Mark newest message as read so chat starts at bottom
        _api.lastReadMessageId = 'reply_msg';
        await pumpChatScreen(tester);
        await tester.pumpAndSettle();

        final position = Scrollable.of(tester.element(find.byType(WnMessageBubble).first)).position;
        expect(position.pixels, 0);

        await tester.tap(find.byKey(const Key('message_quote_tap_area')));
        await tester.pumpAndSettle();

        expect(position.pixels, greaterThan(0));
      });
    });

    group('draft restoration', () {
      Future<void> pumpChatScreenWithDraftSettle(WidgetTester tester) async {
        await pumpChatScreen(tester);
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
        await tester.pumpAndSettle();
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
        await tester.pumpAndSettle();
      }

      group('with draft content', () {
        setUp(() {
          _api.loadDraftResult = Draft(
            accountPubkey: _testPubkey,
            mlsGroupId: _testGroupId,
            content: 'unsent message',
            mediaAttachments: const [],
            createdAt: DateTime(2024),
            updatedAt: DateTime(2024),
          );
        });

        testWidgets('restores content into input field', (tester) async {
          await pumpChatScreenWithDraftSettle(tester);

          final textField = tester.widget<TextField>(find.byType(TextField));
          expect(textField.controller!.text, 'unsent message');
        });

        testWidgets('shows send button after restoring content', (tester) async {
          await pumpChatScreenWithDraftSettle(tester);

          expect(find.byKey(const Key('send_button')), findsOneWidget);
        });
      });

      group('when draft reply message not in list', () {
        setUp(() {
          _api.initialMessages = [];
          _api.loadDraftResult = Draft(
            accountPubkey: _testPubkey,
            mlsGroupId: _testGroupId,
            content: 'draft',
            replyToId: 'missing-id',
            mediaAttachments: const [],
            createdAt: DateTime(2024),
            updatedAt: DateTime(2024),
          );
        });

        testWidgets('does not show reply preview', (tester) async {
          await pumpChatScreenWithDraftSettle(tester);

          expect(find.byType(ChatMessageQuote), findsNothing);
        });
      });
    });

    group('reaction pills', () {
      testWidgets('appears when reaction event arrives', (tester) async {
        _api.initialMessages = [_message('m1', DateTime(2024))];
        await pumpChatScreen(tester);
        expect(find.text('🎉'), findsNothing);

        final reactions = ReactionSummary(
          byEmoji: [
            EmojiReaction(emoji: '🎉', count: BigInt.one, users: const ['other']),
          ],
          userReactions: const [],
        );
        _api.emitMessage(_message('m1', DateTime(2024), reactions: reactions));
        await tester.pumpAndSettle();

        expect(find.text('🎉'), findsWidgets);
      });

      group('when user has no reaction to the message', () {
        ReactionSummary reactionFromOther(String emoji) => ReactionSummary(
          byEmoji: [
            EmojiReaction(emoji: emoji, count: BigInt.one, users: const ['other']),
          ],
          userReactions: const [],
        );

        testWidgets('calls API when reaction pill is tapped', (tester) async {
          _api.initialMessages = [
            _message('m1', DateTime(2024), reactions: reactionFromOther('👍')),
          ];
          await pumpChatScreen(tester);

          await tester.tap(find.text('👍'));
          await tester.pumpAndSettle();

          expect(_api.reactionCalls.length, 1);
        });

        testWidgets('sends correct emoji from tapped pill', (tester) async {
          _api.initialMessages = [
            _message('m1', DateTime(2024), reactions: reactionFromOther('🔥')),
          ];
          await pumpChatScreen(tester);

          await tester.tap(find.text('🔥'));
          await tester.pumpAndSettle();

          expect(_api.reactionCalls.first.message, '🔥');
        });

        testWidgets('includes message reference in reaction tags', (tester) async {
          _api.initialMessages = [
            _message('msg_with_reaction', DateTime(2024), reactions: reactionFromOther('👍')),
          ];
          await pumpChatScreen(tester);

          await tester.tap(find.text('👍'));
          await tester.pumpAndSettle();

          final tags = _api.reactionCalls.first.tags!.cast<_MockTag>();
          expect(tags[0].vec, ['e', 'msg_with_reaction']);
        });
      });

      group('when user has a reaction to the message', () {
        testWidgets('calls delete API when tapping own reaction', (tester) async {
          final ownReaction = ReactionSummary(
            byEmoji: [
              EmojiReaction(emoji: '👍', count: BigInt.one, users: const [_testPubkey]),
            ],
            userReactions: [
              UserReaction(
                reactionId: 'reaction_to_delete',
                emoji: '👍',
                user: _testPubkey,
                createdAt: DateTime(2024),
              ),
            ],
          );
          _api.initialMessages = [_message('m1', DateTime(2024), reactions: ownReaction)];
          await pumpChatScreen(tester);

          await tester.tap(find.text('👍'));
          await tester.pumpAndSettle();

          expect(_api.deletionCalls.length, 1);
          final tags = _api.deletionCalls.first.tags!.cast<_MockTag>();
          expect(tags[0].vec, ['e', 'reaction_to_delete']);
        });
      });
    });

    group('unread indicator', () {
      setUp(() {
        _api.initialMessages = List.generate(
          20,
          (i) => _message('m$i', DateTime(2024, 1, i + 1)),
        );
        _api.lastReadMessageId = 'm19';
      });

      Future<ScrollPosition> scrollUpAndReceiveMessage(WidgetTester tester) async {
        await pumpChatScreen(tester);
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();

        final position = Scrollable.of(tester.element(find.byType(WnMessageBubble).first)).position;
        position.jumpTo(position.maxScrollExtent);
        await tester.pumpAndSettle();

        _api.emitMessage(_message('m_new', DateTime(2024, 2)));
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();
        return position;
      }

      testWidgets('hidden when no messages', (tester) async {
        _api.initialMessages = [];
        _api.lastReadMessageId = null;
        await pumpChatScreen(tester);
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('scroll_down_button')), findsNothing);
      });

      testWidgets('shows when scrolled up with unread messages', (tester) async {
        await scrollUpAndReceiveMessage(tester);

        expect(find.byKey(const Key('scroll_down_button')), findsOneWidget);
      });

      testWidgets('hidden when all messages are read', (tester) async {
        await pumpChatScreen(tester);
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();

        final position = Scrollable.of(tester.element(find.byType(WnMessageBubble).first)).position;
        position.jumpTo(position.maxScrollExtent);
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('scroll_down_button')), findsNothing);
      });

      testWidgets('tapping scrolls to bottom', (tester) async {
        final position = await scrollUpAndReceiveMessage(tester);
        expect(position.pixels, greaterThan(0));

        await tester.tap(find.byKey(const Key('scroll_down_button')));
        await tester.pumpAndSettle();

        expect(position.pixels, 0);
      });
    });

    group('mark as read', () {
      setUp(() {
        _api.initialMessages = List.generate(
          20,
          (i) => _message('m$i', DateTime(2024, 1, i + 1)),
        );
        _api.lastReadMessageId = 'm19';
      });

      testWidgets('marks incoming message as read when at bottom', (tester) async {
        await pumpChatScreen(tester);
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();

        _api.emitMessage(_message('m_new', DateTime(2024, 2)));
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();

        expect(_api.markedAsReadMessages, contains('m_new'));
      });

      testWidgets('does not mark message as read when scrolled up', (tester) async {
        await pumpChatScreen(tester);
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();

        final position = Scrollable.of(tester.element(find.byType(WnMessageBubble).first)).position;
        position.jumpTo(position.maxScrollExtent);
        await tester.pumpAndSettle();

        _api.emitMessage(_message('m_new', DateTime(2024, 2)));
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();

        expect(_api.markedAsReadMessages, isEmpty);
      });

      testWidgets('marks own message as read', (tester) async {
        await pumpChatScreen(tester);
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();

        final position = Scrollable.of(tester.element(find.byType(WnMessageBubble).first)).position;
        position.jumpTo(position.maxScrollExtent);
        await tester.pumpAndSettle();

        _api.emitMessage(_message('m_own', DateTime(2024, 2), pubkey: _testPubkey));
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();

        expect(_api.markedAsReadMessages, contains('m_own'));
      });
    });
    group('media attachment', () {
      testWidgets('displays attach button always when no media attached', (tester) async {
        await pumpChatScreen(tester);

        expect(find.byKey(const Key('add_button')), findsOneWidget);
      });

      testWidgets('unfocuses input when attach button is tapped', (tester) async {
        await pumpChatScreen(tester);
        await tester.tap(find.byType(TextField));
        await tester.pumpAndSettle();

        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.focusNode!.hasFocus, isTrue);

        await tester.tap(find.byKey(const Key('add_button')));
        await tester.pumpAndSettle();

        expect(textField.focusNode!.hasFocus, isFalse);
      });
    });

    group('message search', () {
      Future<void> openSearch(WidgetTester tester) async {
        _api.isDm = true;
        _api.groupMembers = [_testPubkey, testPubkeyC];
        await pumpChatScreen(tester);
        await tester.tap(find.byKey(const Key('header_avatar_tap_area')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('search_button')));
        await tester.pumpAndSettle();
      }

      testWidgets('search bar is hidden by default', (tester) async {
        await pumpChatScreen(tester);
        expect(find.byKey(const Key('chat_search_bar')), findsNothing);
        expect(find.byKey(const Key('chat_search_field')), findsNothing);
      });

      testWidgets('search bar appears after tapping search in chat info', (tester) async {
        await openSearch(tester);
        expect(find.byKey(const Key('chat_search_bar')), findsOneWidget);
        expect(find.byKey(const Key('chat_search_field')), findsOneWidget);
      });

      testWidgets('navigation bar is hidden when search query is empty', (tester) async {
        await openSearch(tester);
        expect(find.byKey(const Key('chat_search_navigation')), findsNothing);
      });

      testWidgets('navigation bar appears when search query is not empty', (tester) async {
        _api.initialMessages = [
          _message('m1', DateTime(2024)),
          _message('m2', DateTime(2024, 2)),
        ];
        await openSearch(tester);
        await tester.enterText(find.byKey(const Key('chat_search_field')), 'Message');
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('chat_search_navigation')), findsOneWidget);
      });

      testWidgets('shows no results when query has no matches', (tester) async {
        _api.initialMessages = [_message('m1', DateTime(2024))];
        await openSearch(tester);
        await tester.enterText(find.byKey(const Key('chat_search_field')), 'zzznomatch');
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('chat_search_match_count')), findsOneWidget);
        expect(find.text('No results'), findsOneWidget);
      });

      testWidgets('shows singular match count for one result', (tester) async {
        _api.initialMessages = [_message('m1', DateTime(2024))];
        await openSearch(tester);
        await tester.enterText(find.byKey(const Key('chat_search_field')), 'Message m1');
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('chat_search_match_count')), findsOneWidget);
        expect(find.text('1 of 1 match'), findsOneWidget);
      });

      testWidgets('shows plural match count for multiple results', (tester) async {
        _api.initialMessages = [
          _message('m1', DateTime(2024)),
          _message('m2', DateTime(2024, 2)),
        ];
        await openSearch(tester);
        await tester.enterText(find.byKey(const Key('chat_search_field')), 'Message');
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('chat_search_match_count')), findsOneWidget);
        expect(find.text('1 of 2 matches'), findsOneWidget);
      });

      testWidgets('shows prev and next navigation buttons', (tester) async {
        _api.initialMessages = [
          _message('m1', DateTime(2024)),
          _message('m2', DateTime(2024, 2)),
        ];
        await openSearch(tester);
        await tester.enterText(find.byKey(const Key('chat_search_field')), 'Message');
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('chat_search_prev_button')), findsOneWidget);
        expect(find.byKey(const Key('chat_search_next_button')), findsOneWidget);
      });

      testWidgets('tapping next button advances match index', (tester) async {
        _api.initialMessages = [
          _message('m1', DateTime(2024)),
          _message('m2', DateTime(2024, 2)),
        ];
        await openSearch(tester);
        await tester.enterText(find.byKey(const Key('chat_search_field')), 'Message');
        await tester.pumpAndSettle();
        expect(find.text('1 of 2 matches'), findsOneWidget);

        await tester.tap(find.byKey(const Key('chat_search_next_button')));
        await tester.pumpAndSettle();
        expect(find.text('2 of 2 matches'), findsOneWidget);
      });

      testWidgets('tapping prev button goes to previous match', (tester) async {
        _api.initialMessages = [
          _message('m1', DateTime(2024)),
          _message('m2', DateTime(2024, 2)),
        ];
        await openSearch(tester);
        await tester.enterText(find.byKey(const Key('chat_search_field')), 'Message');
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('chat_search_next_button')));
        await tester.pumpAndSettle();
        expect(find.text('2 of 2 matches'), findsOneWidget);

        await tester.tap(find.byKey(const Key('chat_search_prev_button')));
        await tester.pumpAndSettle();
        expect(find.text('1 of 2 matches'), findsOneWidget);
      });

      testWidgets('does not show no messages text when search is active with no results', (
        tester,
      ) async {
        await openSearch(tester);
        await tester.enterText(find.byKey(const Key('chat_search_field')), 'zzznomatch');
        await tester.pumpAndSettle();
        expect(find.text('No messages yet'), findsNothing);
      });

      testWidgets('closing search hides search bar', (tester) async {
        await openSearch(tester);
        expect(find.byKey(const Key('chat_search_bar')), findsOneWidget);

        await tester.tap(find.byKey(const Key('back_button')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('chat_search_bar')), findsNothing);
      });

      testWidgets('match index resets when query changes', (tester) async {
        _api.initialMessages = [
          _message('m1', DateTime(2024)),
          _message('m2', DateTime(2024, 2)),
        ];
        await openSearch(tester);
        await tester.enterText(find.byKey(const Key('chat_search_field')), 'Message');
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('chat_search_next_button')));
        await tester.pumpAndSettle();
        expect(find.text('2 of 2 matches'), findsOneWidget);

        await tester.enterText(find.byKey(const Key('chat_search_field')), 'Message m1');
        await tester.pumpAndSettle();
        expect(find.text('1 of 1 match'), findsOneWidget);
      });
    });

    group('attachment area with reply and media', () {
      late _MockImagePickerPlatform mockImagePicker;

      setUp(() {
        mockImagePicker = _MockImagePickerPlatform();
        ImagePickerPlatform.instance = mockImagePicker;
      });

      testWidgets('shows media upload preview when images are picked', (tester) async {
        mockImagePicker.filesToReturn = [XFile('/tmp/test_image.jpg')];
        _api.initialMessages = [_message('m1', DateTime(2024))];
        await pumpChatScreen(tester);

        await tester.tap(find.byKey(const Key('add_button')));
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
        await tester.pumpAndSettle();

        expect(find.byType(ChatMediaUploadPreview), findsOneWidget);
      });

      testWidgets('shows both reply preview and media preview with spacer', (tester) async {
        mockImagePicker.filesToReturn = [XFile('/tmp/test_image.jpg')];
        _api.initialMessages = [_message('m1', DateTime(2024))];
        await pumpChatScreen(tester);

        await tester.longPress(find.textContaining('Message m1'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('reply_button')));
        await tester.pumpAndSettle();

        expect(find.byType(ChatMessageQuote), findsOneWidget);

        await tester.tap(find.byKey(const Key('add_button')));
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
        await tester.pumpAndSettle();

        expect(find.byType(ChatMessageQuote), findsOneWidget);
        expect(find.byType(ChatMediaUploadPreview), findsOneWidget);
      });
    });

    group('debug view', () {
      Future<void> pumpChatScreenWithDebug(WidgetTester tester) async {
        await mountTestApp(
          tester,
          overrides: [
            authProvider.overrideWith(() => _MockAuthNotifier()),
            debugViewProvider.overrideWith(() => _MockDebugViewNotifier()),
          ],
        );
        await tester.pumpAndSettle();
        Routes.goToChat(
          tester.element(find.byType(Scaffold)),
          _testGroupId,
        );
        await tester.pumpAndSettle();
      }

      testWidgets('shows debug button when debug view is enabled', (tester) async {
        await pumpChatScreenWithDebug(tester);
        expect(find.byKey(const Key('chat_raw_debug_button')), findsOneWidget);
      });

      testWidgets('debug button navigates to raw debug screen', (tester) async {
        await pumpChatScreenWithDebug(tester);
        await tester.tap(find.byKey(const Key('chat_raw_debug_button')));
        await tester.pumpAndSettle();
        expect(find.byType(ChatRawDebugScreen), findsOneWidget);
      });
    });
  });
}
