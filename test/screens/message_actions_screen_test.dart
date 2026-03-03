import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/hooks/use_chat_messages.dart' show ChatMessageQuoteData;
import 'package:whitenoise/l10n/generated/app_localizations.dart';
import 'package:whitenoise/screens/message_actions_screen.dart';
import 'package:whitenoise/src/rust/api/messages.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/widgets/wn_message_bubble.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart';

import '../test_helpers.dart';

ChatMessageQuoteData _replyPreview({
  String messageId = 'original-msg',
  String authorPubkey = testPubkeyB,
  String content = 'Original message content',
}) => (
  messageId: messageId,
  authorPubkey: authorPubkey,
  authorMetadata: const FlutterMetadata(displayName: 'Original Author', name: 'author', custom: {}),
  content: content,
  mediaFile: null,
  isNotFound: false,
);

ChatMessage _createTestMessage({
  String id = 'msg-1',
  String pubkey = testPubkeyA,
  String content = 'Test message content',
  ReactionSummary? reactions,
  bool isReply = false,
  String? replyToId,
}) {
  return ChatMessage(
    id: id,
    pubkey: pubkey,
    content: content,
    createdAt: DateTime.now(),
    tags: const [],
    isReply: isReply,
    replyToId: replyToId,
    isDeleted: false,
    contentTokens: const [],
    reactions: reactions ?? const ReactionSummary(byEmoji: [], userReactions: []),
    mediaAttachments: const [],
    kind: 9,
  );
}

void main() {
  group('MessageActionsModal', () {
    testWidgets('displays message content', (tester) async {
      await mountWidget(
        MessageActionsModal(
          message: _createTestMessage(content: 'Test message'),
          isOwnMessage: false,
          onReaction: (_) {},
          onEmojiPicker: () {},
          currentUserPubkey: testPubkeyA,
        ),
        tester,
      );

      expect(find.textContaining('Test message'), findsOneWidget);
    });

    testWidgets('does not show a header title', (tester) async {
      await mountWidget(
        MessageActionsModal(
          message: _createTestMessage(),
          isOwnMessage: false,
          onReaction: (_) {},
          onEmojiPicker: () {},
          currentUserPubkey: testPubkeyA,
        ),
        tester,
      );

      expect(find.text('Message actions'), findsNothing);
    });

    testWidgets('does not show a close button', (tester) async {
      await mountWidget(
        MessageActionsModal(
          message: _createTestMessage(),
          isOwnMessage: false,
          onReaction: (_) {},
          onEmojiPicker: () {},
          currentUserPubkey: testPubkeyA,
        ),
        tester,
      );

      expect(find.byKey(const Key('slate_close_button')), findsNothing);
    });

    group('Reply preview', () {
      testWidgets(
        'shows reply preview when message is a reply and getChatMessageQuote is provided',
        (tester) async {
          final replyData = _replyPreview(content: 'Quoted message');
          await mountWidget(
            MessageActionsModal(
              message: _createTestMessage(isReply: true, replyToId: 'original-msg'),
              isOwnMessage: false,
              onReaction: (_) {},
              onEmojiPicker: () {},
              currentUserPubkey: testPubkeyA,
              getChatMessageQuote: (_) => replyData,
            ),
            tester,
          );

          expect(find.text('Quoted message'), findsOneWidget);
          expect(find.text('Original Author'), findsOneWidget);
        },
      );

      testWidgets('does not show reply preview when message is not a reply', (tester) async {
        await mountWidget(
          MessageActionsModal(
            message: _createTestMessage(),
            isOwnMessage: false,
            onReaction: (_) {},
            onEmojiPicker: () {},
            currentUserPubkey: testPubkeyA,
            getChatMessageQuote: (_) => _replyPreview(),
          ),
          tester,
        );

        expect(find.byKey(const Key('quote_bar')), findsNothing);
      });

      testWidgets('does not show reply preview when getChatMessageQuote is not provided', (
        tester,
      ) async {
        await mountWidget(
          MessageActionsModal(
            message: _createTestMessage(isReply: true, replyToId: 'original-msg'),
            isOwnMessage: false,
            onReaction: (_) {},
            onEmojiPicker: () {},
            currentUserPubkey: testPubkeyA,
          ),
          tester,
        );

        expect(find.byKey(const Key('quote_bar')), findsNothing);
      });
    });

    group('Reply button', () {
      testWidgets('is visible when onReply is provided', (tester) async {
        await mountWidget(
          MessageActionsModal(
            message: _createTestMessage(),
            isOwnMessage: false,
            onReaction: (_) {},
            onEmojiPicker: () {},
            currentUserPubkey: testPubkeyA,
            onReply: () {},
          ),
          tester,
        );

        expect(find.byKey(const Key('reply_button')), findsOneWidget);
      });

      testWidgets('is hidden when onReply is null', (tester) async {
        await mountWidget(
          MessageActionsModal(
            message: _createTestMessage(),
            isOwnMessage: false,
            onReaction: (_) {},
            onEmojiPicker: () {},
            currentUserPubkey: testPubkeyA,
          ),
          tester,
        );

        expect(find.byKey(const Key('reply_button')), findsNothing);
      });

      testWidgets('calls onReply when tapped', (tester) async {
        var replyCalled = false;
        await mountWidget(
          MessageActionsModal(
            message: _createTestMessage(),
            isOwnMessage: false,
            onReaction: (_) {},
            onEmojiPicker: () {},
            currentUserPubkey: testPubkeyA,
            onReply: () => replyCalled = true,
          ),
          tester,
        );

        await tester.tap(find.byKey(const Key('reply_button')));
        await tester.pumpAndSettle();

        expect(replyCalled, isTrue);
      });
    });

    group('Copy button', () {
      testWidgets('is always visible', (tester) async {
        await mountWidget(
          MessageActionsModal(
            message: _createTestMessage(),
            isOwnMessage: false,
            onReaction: (_) {},
            onEmojiPicker: () {},
            currentUserPubkey: testPubkeyA,
          ),
          tester,
        );

        expect(find.byKey(const Key('copy_button')), findsOneWidget);
      });

      testWidgets('copies message content to clipboard when tapped', (tester) async {
        String? clipboardContent;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (MethodCall methodCall) async {
            if (methodCall.method == 'Clipboard.setData') {
              final args = methodCall.arguments as Map<dynamic, dynamic>;
              clipboardContent = args['text'] as String?;
            }
            return null;
          },
        );
        addTearDown(() {
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          );
        });

        await mountWidget(
          MessageActionsModal(
            message: _createTestMessage(content: 'Hello, world!'),
            isOwnMessage: false,
            onReaction: (_) {},
            onEmojiPicker: () {},
            currentUserPubkey: testPubkeyA,
          ),
          tester,
        );

        await tester.tap(find.byKey(const Key('copy_button')));
        await tester.pumpAndSettle();

        expect(clipboardContent, 'Hello, world!');
      });
    });

    group('Delete button', () {
      testWidgets('is visible when onDelete is provided', (tester) async {
        await mountWidget(
          MessageActionsModal(
            message: _createTestMessage(),
            isOwnMessage: true,
            onReaction: (_) {},
            onEmojiPicker: () {},
            currentUserPubkey: testPubkeyA,
            onDelete: () {},
          ),
          tester,
        );

        expect(find.byKey(const Key('delete_button')), findsOneWidget);
      });

      testWidgets('is hidden when onDelete is null', (tester) async {
        await mountWidget(
          MessageActionsModal(
            message: _createTestMessage(),
            isOwnMessage: false,
            onReaction: (_) {},
            onEmojiPicker: () {},
            currentUserPubkey: testPubkeyA,
          ),
          tester,
        );

        expect(find.byKey(const Key('delete_button')), findsNothing);
      });

      testWidgets('calls onDelete when tapped', (tester) async {
        var deleteCalled = false;
        await mountWidget(
          MessageActionsModal(
            message: _createTestMessage(),
            isOwnMessage: true,
            onReaction: (_) {},
            onEmojiPicker: () {},
            currentUserPubkey: testPubkeyA,
            onDelete: () => deleteCalled = true,
          ),
          tester,
        );

        await tester.tap(find.byKey(const Key('delete_button')));
        await tester.pumpAndSettle();

        expect(deleteCalled, isTrue);
      });
    });

    group('reactions', () {
      testWidgets('displays all reaction buttons', (tester) async {
        await mountWidget(
          MessageActionsModal(
            message: _createTestMessage(),
            isOwnMessage: false,
            onReaction: (_) {},
            onEmojiPicker: () {},
            currentUserPubkey: testPubkeyA,
          ),
          tester,
        );

        for (final emoji in MessageActionsModal.reactions) {
          expect(find.text(emoji), findsOneWidget);
        }
      });

      testWidgets('displays emoji picker button', (tester) async {
        await mountWidget(
          MessageActionsModal(
            message: _createTestMessage(),
            isOwnMessage: false,
            onReaction: (_) {},
            onEmojiPicker: () {},
            currentUserPubkey: testPubkeyA,
          ),
          tester,
        );

        expect(find.byKey(const Key('emoji_picker_button')), findsOneWidget);
      });

      testWidgets('reaction button calls onReaction with correct emoji when provided', (
        tester,
      ) async {
        String? receivedEmoji;
        await mountWidget(
          MessageActionsModal(
            message: _createTestMessage(),
            isOwnMessage: false,
            onReaction: (emoji) => receivedEmoji = emoji,
            onEmojiPicker: () {},
            currentUserPubkey: testPubkeyA,
          ),
          tester,
        );

        await tester.tap(find.text('🤣'));
        await tester.pumpAndSettle();

        expect(receivedEmoji, '🤣');
      });

      testWidgets('selected emoji shows filled background', (tester) async {
        await mountWidget(
          MessageActionsModal(
            message: _createTestMessage(),
            isOwnMessage: false,
            onReaction: (_) {},
            onEmojiPicker: () {},
            currentUserPubkey: testPubkeyA,
            selectedEmojis: const {'❤', '🤣'},
          ),
          tester,
        );

        final heartButton = find.byKey(const Key('reaction_❤'));
        final heartContainer = tester.widget<Container>(
          find.descendant(of: heartButton, matching: find.byType(Container)),
        );
        expect(heartContainer.decoration, isNotNull);

        final thumbsUpButton = find.byKey(const Key('reaction_👍'));
        final thumbsUpContainer = tester.widget<Container>(
          find.descendant(of: thumbsUpButton, matching: find.byType(Container)),
        );
        expect(thumbsUpContainer.decoration, isNull);
      });

      testWidgets('emoji picker button calls onEmojiPicker when tapped', (tester) async {
        var emojiPickerCalled = false;
        await mountWidget(
          MessageActionsModal(
            message: _createTestMessage(),
            isOwnMessage: false,
            onReaction: (_) {},
            onEmojiPicker: () => emojiPickerCalled = true,
            currentUserPubkey: testPubkeyA,
          ),
          tester,
        );

        await tester.tap(find.byKey(const Key('emoji_picker_button')));
        await tester.pumpAndSettle();

        expect(emojiPickerCalled, isTrue);
      });
    });

    group('own message', () {
      testWidgets('aligns message preview to the right', (tester) async {
        await mountWidget(
          MessageActionsModal(
            message: _createTestMessage(),
            isOwnMessage: true,
            onReaction: (_) {},
            onEmojiPicker: () {},
            currentUserPubkey: testPubkeyA,
          ),
          tester,
        );

        final align = tester.widget<Align>(
          find.descendant(of: find.byType(WnMessageBubble), matching: find.byType(Align)).first,
        );
        expect(align.alignment, Alignment.centerRight);
      });
    });

    group('other user message', () {
      testWidgets('aligns message preview to the left', (tester) async {
        await mountWidget(
          MessageActionsModal(
            message: _createTestMessage(),
            isOwnMessage: false,
            onReaction: (_) {},
            onEmojiPicker: () {},
            currentUserPubkey: testPubkeyA,
          ),
          tester,
        );

        final align = tester.widget<Align>(
          find.descendant(of: find.byType(WnMessageBubble), matching: find.byType(Align)).first,
        );
        expect(align.alignment, Alignment.centerLeft);
      });
    });
  });

  group('MessageActionsScreen.show()', () {
    Future<void> mountShowTest(
      WidgetTester tester, {
      required Widget Function(BuildContext context) builder,
    }) async {
      setUpTestView(tester);
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: testDesignSize,
          builder: (_, _) => MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: Builder(builder: (context) => builder(context))),
          ),
        ),
      );
    }

    testWidgets('opens a route with the message menu', (tester) async {
      await mountShowTest(
        tester,
        builder: (context) => ElevatedButton(
          onPressed: () => MessageActionsScreen.show(
            context,
            message: _createTestMessage(),
            pubkey: testPubkeyA,
            onAddReaction: (_) async {},
            onRemoveReaction: (_) async {},
          ),
          child: const Text('Show Menu'),
        ),
      );

      await tester.tap(find.text('Show Menu'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Test message content'), findsOneWidget);
    });

    testWidgets('copy button copies content and closes menu', (tester) async {
      String? clipboardContent;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'Clipboard.setData') {
            final args = methodCall.arguments as Map<dynamic, dynamic>;
            clipboardContent = args['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });

      await mountShowTest(
        tester,
        builder: (context) => ElevatedButton(
          onPressed: () => MessageActionsScreen.show(
            context,
            message: _createTestMessage(content: 'Copy this text'),
            pubkey: testPubkeyA,
            onAddReaction: (_) async {},
            onRemoveReaction: (_) async {},
          ),
          child: const Text('Show Menu'),
        ),
      );

      await tester.tap(find.text('Show Menu'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('copy_button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('copy_button')));
      await tester.pumpAndSettle();

      expect(clipboardContent, 'Copy this text');
      expect(find.text('Copy this text'), findsNothing);
    });

    testWidgets('shows delete button for own message', (tester) async {
      const myPubkey = testPubkeyA;
      await mountShowTest(
        tester,
        builder: (context) => ElevatedButton(
          onPressed: () => MessageActionsScreen.show(
            context,
            message: _createTestMessage(),
            pubkey: myPubkey,
            onAddReaction: (_) async {},
            onRemoveReaction: (_) async {},
            onDelete: () async {},
          ),
          child: const Text('Show Menu'),
        ),
      );

      await tester.tap(find.text('Show Menu'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('delete_button')), findsOneWidget);
    });

    testWidgets('hides delete button for other user message', (tester) async {
      await mountShowTest(
        tester,
        builder: (context) => ElevatedButton(
          onPressed: () => MessageActionsScreen.show(
            context,
            message: _createTestMessage(pubkey: testPubkeyB),
            pubkey: testPubkeyA,
            onAddReaction: (_) async {},
            onRemoveReaction: (_) async {},
            onDelete: () async {},
          ),
          child: const Text('Show Menu'),
        ),
      );

      await tester.tap(find.text('Show Menu'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('delete_button')), findsNothing);
    });

    testWidgets('hides delete button for own message when onDelete is null', (tester) async {
      const myPubkey = testPubkeyA;
      await mountShowTest(
        tester,
        builder: (context) => ElevatedButton(
          onPressed: () => MessageActionsScreen.show(
            context,
            message: _createTestMessage(),
            pubkey: myPubkey,
            onAddReaction: (_) async {},
            onRemoveReaction: (_) async {},
          ),
          child: const Text('Show Menu'),
        ),
      );

      await tester.tap(find.text('Show Menu'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('delete_button')), findsNothing);
    });

    testWidgets('tapping outside dismisses the menu', (tester) async {
      await mountShowTest(
        tester,
        builder: (context) => ElevatedButton(
          onPressed: () => MessageActionsScreen.show(
            context,
            message: _createTestMessage(),
            pubkey: testPubkeyA,
            onAddReaction: (_) async {},
            onRemoveReaction: (_) async {},
          ),
          child: const Text('Show Menu'),
        ),
      );

      await tester.tap(find.text('Show Menu'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Test message content'), findsOneWidget);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.textContaining('Test message content'), findsNothing);
    });

    testWidgets('calls onDelete and closes menu when delete button is tapped', (tester) async {
      var deleteCalled = false;
      const myPubkey = testPubkeyA;

      await mountShowTest(
        tester,
        builder: (context) => ElevatedButton(
          onPressed: () => MessageActionsScreen.show(
            context,
            message: _createTestMessage(),
            pubkey: myPubkey,
            onAddReaction: (_) async {},
            onRemoveReaction: (_) async {},
            onDelete: () async {
              deleteCalled = true;
            },
          ),
          child: const Text('Show Menu'),
        ),
      );

      await tester.tap(find.text('Show Menu'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Test message content'), findsOneWidget);

      await tester.tap(find.byKey(const Key('delete_button')));
      await tester.pumpAndSettle();

      expect(deleteCalled, isTrue);
      expect(find.textContaining('Test message content'), findsNothing);
    });

    testWidgets('aligns message preview right for own message', (tester) async {
      const myPubkey = testPubkeyA;
      await mountShowTest(
        tester,
        builder: (context) => ElevatedButton(
          onPressed: () => MessageActionsScreen.show(
            context,
            message: _createTestMessage(),
            pubkey: myPubkey,
            onAddReaction: (_) async {},
            onRemoveReaction: (_) async {},
          ),
          child: const Text('Show Menu'),
        ),
      );

      await tester.tap(find.text('Show Menu'));
      await tester.pumpAndSettle();

      final align = tester.widget<Align>(
        find.descendant(of: find.byType(WnMessageBubble), matching: find.byType(Align)).first,
      );
      expect(align.alignment, Alignment.centerRight);
    });

    testWidgets('aligns message preview left for other user message', (tester) async {
      await mountShowTest(
        tester,
        builder: (context) => ElevatedButton(
          onPressed: () => MessageActionsScreen.show(
            context,
            message: _createTestMessage(pubkey: testPubkeyB),
            pubkey: testPubkeyA,
            onAddReaction: (_) async {},
            onRemoveReaction: (_) async {},
          ),
          child: const Text('Show Menu'),
        ),
      );

      await tester.tap(find.text('Show Menu'));
      await tester.pumpAndSettle();

      final align = tester.widget<Align>(
        find.descendant(of: find.byType(WnMessageBubble), matching: find.byType(Align)).first,
      );
      expect(align.alignment, Alignment.centerLeft);
    });

    testWidgets('shows system notice when delete fails', (tester) async {
      const myPubkey = testPubkeyA;

      await mountShowTest(
        tester,
        builder: (context) => ElevatedButton(
          onPressed: () => MessageActionsScreen.show(
            context,
            message: _createTestMessage(),
            pubkey: myPubkey,
            onAddReaction: (_) async {},
            onRemoveReaction: (_) async {},
            onDelete: () async {
              throw Exception('Delete failed');
            },
          ),
          child: const Text('Show Menu'),
        ),
      );

      await tester.tap(find.text('Show Menu'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('delete_button')));
      await tester.pumpAndSettle();

      expect(find.byType(WnSystemNotice), findsOneWidget);
      expect(find.text('Failed to delete message. Please try again.'), findsOneWidget);
      expect(find.textContaining('Test message content'), findsOneWidget);
    });

    testWidgets('calls onAddReaction and closes menu when reaction button is tapped', (
      tester,
    ) async {
      String? receivedEmoji;

      await mountShowTest(
        tester,
        builder: (context) => ElevatedButton(
          onPressed: () => MessageActionsScreen.show(
            context,
            message: _createTestMessage(),
            pubkey: testPubkeyA,
            onAddReaction: (emoji) async {
              receivedEmoji = emoji;
            },
            onRemoveReaction: (_) async {},
          ),
          child: const Text('Show Menu'),
        ),
      );

      await tester.tap(find.text('Show Menu'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Test message content'), findsOneWidget);

      await tester.tap(find.text('❤'));
      await tester.pumpAndSettle();

      expect(receivedEmoji, '❤');
      expect(find.textContaining('Test message content'), findsNothing);
    });

    testWidgets('shows system notice when add reaction fails', (tester) async {
      await mountShowTest(
        tester,
        builder: (context) => ElevatedButton(
          onPressed: () => MessageActionsScreen.show(
            context,
            message: _createTestMessage(),
            pubkey: testPubkeyA,
            onAddReaction: (emoji) async {
              throw Exception('Reaction failed');
            },
            onRemoveReaction: (_) async {},
          ),
          child: const Text('Show Menu'),
        ),
      );

      await tester.tap(find.text('Show Menu'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Test message content'), findsOneWidget);

      await tester.tap(find.text('❤'));
      await tester.pumpAndSettle();

      expect(find.byType(WnSystemNotice), findsOneWidget);
      expect(find.text('Failed to send reaction. Please try again.'), findsOneWidget);
      expect(find.textContaining('Test message content'), findsOneWidget);
    });

    testWidgets('highlights emojis user has already reacted with', (tester) async {
      const myPubkey = testPubkeyA;
      final message = _createTestMessage(
        pubkey: testPubkeyB,
        reactions: ReactionSummary(
          byEmoji: [
            EmojiReaction(emoji: '❤', count: BigInt.one, users: const [myPubkey]),
          ],
          userReactions: [
            UserReaction(
              reactionId: 'reaction-1',
              user: myPubkey,
              emoji: '❤',
              createdAt: DateTime.now(),
            ),
          ],
        ),
      );

      await mountShowTest(
        tester,
        builder: (context) => ElevatedButton(
          onPressed: () => MessageActionsScreen.show(
            context,
            message: message,
            pubkey: myPubkey,
            onAddReaction: (_) async {},
            onRemoveReaction: (_) async {},
          ),
          child: const Text('Show Menu'),
        ),
      );

      await tester.tap(find.text('Show Menu'));
      await tester.pumpAndSettle();

      final heartButton = find.byKey(const Key('reaction_❤'));
      final heartContainer = tester.widget<Container>(
        find.descendant(of: heartButton, matching: find.byType(Container)),
      );
      expect(heartContainer.decoration, isNotNull);

      final thumbsUpButton = find.byKey(const Key('reaction_👍'));
      final thumbsUpContainer = tester.widget<Container>(
        find.descendant(of: thumbsUpButton, matching: find.byType(Container)),
      );
      expect(thumbsUpContainer.decoration, isNull);
    });

    testWidgets('calls onRemoveReaction when tapping already reacted emoji', (tester) async {
      const myPubkey = testPubkeyA;
      String? removedReactionId;
      final message = _createTestMessage(
        pubkey: testPubkeyB,
        reactions: ReactionSummary(
          byEmoji: [
            EmojiReaction(emoji: '❤', count: BigInt.one, users: const [myPubkey]),
          ],
          userReactions: [
            UserReaction(
              reactionId: 'reaction-to-remove',
              user: myPubkey,
              emoji: '❤',
              createdAt: DateTime.now(),
            ),
          ],
        ),
      );

      await mountShowTest(
        tester,
        builder: (context) => ElevatedButton(
          onPressed: () => MessageActionsScreen.show(
            context,
            message: message,
            pubkey: myPubkey,
            onAddReaction: (_) async {},
            onRemoveReaction: (reactionId) async {
              removedReactionId = reactionId;
            },
          ),
          child: const Text('Show Menu'),
        ),
      );

      await tester.tap(find.text('Show Menu'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('reaction_❤')));
      await tester.pumpAndSettle();

      expect(removedReactionId, 'reaction-to-remove');
      expect(find.textContaining('Test message content'), findsNothing);
    });

    testWidgets('shows system notice when remove reaction fails', (tester) async {
      const myPubkey = testPubkeyA;
      final message = _createTestMessage(
        pubkey: testPubkeyB,
        reactions: ReactionSummary(
          byEmoji: [
            EmojiReaction(emoji: '❤', count: BigInt.one, users: const [myPubkey]),
          ],
          userReactions: [
            UserReaction(
              reactionId: 'reaction-to-remove',
              user: myPubkey,
              emoji: '❤',
              createdAt: DateTime.now(),
            ),
          ],
        ),
      );

      await mountShowTest(
        tester,
        builder: (context) => ElevatedButton(
          onPressed: () => MessageActionsScreen.show(
            context,
            message: message,
            pubkey: myPubkey,
            onAddReaction: (_) async {},
            onRemoveReaction: (reactionId) async {
              throw Exception('Remove reaction failed');
            },
          ),
          child: const Text('Show Menu'),
        ),
      );

      await tester.tap(find.text('Show Menu'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('reaction_❤')));
      await tester.pumpAndSettle();

      expect(find.byType(WnSystemNotice), findsOneWidget);
      expect(find.text('Failed to remove reaction. Please try again.'), findsOneWidget);
      expect(find.textContaining('Test message content'), findsOneWidget);
    });

    testWidgets('dismisses notice after auto-hide duration', (tester) async {
      await mountShowTest(
        tester,
        builder: (context) => ElevatedButton(
          onPressed: () => MessageActionsScreen.show(
            context,
            message: _createTestMessage(),
            pubkey: testPubkeyA,
            onAddReaction: (emoji) async {
              throw Exception('Reaction failed');
            },
            onRemoveReaction: (_) async {},
          ),
          child: const Text('Show Menu'),
        ),
      );

      await tester.tap(find.text('Show Menu'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('❤'));
      await tester.pumpAndSettle();
      expect(find.byType(WnSystemNotice), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(find.byType(WnSystemNotice), findsNothing);
    });

    group('emoji picker', () {
      Future<void> openEmojiPicker(
        WidgetTester tester, {
        Future<void> Function(String)? onAddReaction,
      }) async {
        await mountShowTest(
          tester,
          builder: (context) => ElevatedButton(
            onPressed: () => MessageActionsScreen.show(
              context,
              message: _createTestMessage(),
              pubkey: testPubkeyA,
              onAddReaction: onAddReaction ?? (_) async {},
              onRemoveReaction: (_) async {},
            ),
            child: const Text('Show Menu'),
          ),
        );
        await tester.tap(find.text('Show Menu'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('emoji_picker_button')));
        await tester.pump();
      }

      testWidgets('emoji picker close button is hidden before opening', (tester) async {
        await mountShowTest(
          tester,
          builder: (context) => ElevatedButton(
            onPressed: () => MessageActionsScreen.show(
              context,
              message: _createTestMessage(),
              pubkey: testPubkeyA,
              onAddReaction: (_) async {},
              onRemoveReaction: (_) async {},
            ),
            child: const Text('Show Menu'),
          ),
        );
        await tester.tap(find.text('Show Menu'));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('emoji_picker_close_button')), findsNothing);
      });

      testWidgets('shows close button when emoji picker is opened', (tester) async {
        await openEmojiPicker(tester);
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('emoji_picker_close_button')), findsOneWidget);
      });

      testWidgets('hides close button after closing emoji picker', (tester) async {
        await openEmojiPicker(tester);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('emoji_picker_close_button')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('emoji_picker_close_button')), findsNothing);
      });

      testWidgets('menu remains visible when emoji picker is open', (tester) async {
        await openEmojiPicker(tester);
        await tester.pumpAndSettle();

        expect(find.textContaining('Test message content'), findsOneWidget);
      });

      testWidgets('selecting emoji invokes onAddReaction and closes screen', (tester) async {
        String? reactionCapturedEmoji;
        await openEmojiPicker(
          tester,
          onAddReaction: (emoji) async {
            reactionCapturedEmoji = emoji;
          },
        );
        await tester.pumpAndSettle();

        final emojiPicker = tester.widget<EmojiPicker>(find.byType(EmojiPicker));
        emojiPicker.onEmojiSelected!(Category.SMILEYS, const Emoji('😀', 'grinning face'));
        await tester.pumpAndSettle();

        expect(reactionCapturedEmoji, '😀');
        expect(find.textContaining('Test message content'), findsNothing);
        expect(find.byKey(const Key('emoji_picker_close_button')), findsNothing);
      });
    });

    testWidgets('defers onReply to post-frame callback', (tester) async {
      ChatMessage? repliedMessage;

      await mountShowTest(
        tester,
        builder: (context) => ElevatedButton(
          onPressed: () => MessageActionsScreen.show(
            context,
            message: _createTestMessage(),
            pubkey: testPubkeyA,
            onAddReaction: (_) async {},
            onRemoveReaction: (_) async {},
            onReply: (message) {
              repliedMessage = message;
            },
          ),
          child: const Text('Show Menu'),
        ),
      );

      await tester.tap(find.text('Show Menu'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('reply_button')));
      expect(repliedMessage, isNull);

      await tester.pump();
      expect(repliedMessage, isNotNull);
    });
  });
}
