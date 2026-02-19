import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/hooks/use_chat_messages.dart' show ChatMessageQuoteData;
import 'package:whitenoise/src/rust/api/media_files.dart';
import 'package:whitenoise/src/rust/api/messages.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/widgets/chat_message_media.dart';
import 'package:whitenoise/widgets/chat_message_quote.dart';
import 'package:whitenoise/widgets/wn_message_bubble.dart';
import 'package:whitenoise/widgets/wn_message_reactions.dart';

import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

ChatMessageQuoteData _replyPreview({
  String messageId = 'original-msg',
  String authorPubkey = testPubkeyB,
  FlutterMetadata? authorMetadata,
  String content = 'Original message content',
  MediaFile? mediaFile,
  bool isNotFound = false,
}) => (
  messageId: messageId,
  authorPubkey: authorPubkey,
  authorMetadata:
      authorMetadata ??
      const FlutterMetadata(displayName: 'Original Author', name: 'author', custom: {}),
  content: content,
  mediaFile: mediaFile,
  isNotFound: isNotFound,
);

MediaFile _mediaFile(String id) => MediaFile(
  id: id,
  mlsGroupId: testGroupId,
  accountPubkey: testPubkeyA,
  filePath: '/test/path/$id.jpg',
  originalFileHash: 'hash$id',
  encryptedFileHash: 'encrypted$id',
  mimeType: 'image/jpeg',
  mediaType: 'image',
  blossomUrl: 'https://example.com/$id',
  nostrKey: 'nostr$id',
  createdAt: DateTime(2024),
);

ChatMessage _message({
  String content = 'Hello world',
  bool isDeleted = false,
  bool isReply = false,
  String? replyToId,
  ReactionSummary reactions = const ReactionSummary(byEmoji: [], userReactions: []),
  List<MediaFile> mediaAttachments = const [],
}) => ChatMessage(
  id: 'msg1',
  pubkey: testPubkeyA,
  content: content,
  createdAt: DateTime(2024),
  tags: const [],
  isReply: isReply,
  replyToId: replyToId,
  isDeleted: isDeleted,
  contentTokens: const [],
  reactions: reactions,
  mediaAttachments: mediaAttachments,
  kind: 9,
);

void main() {
  setUpAll(() => RustLib.initMock(api: MockWnApi()));

  group('WnMessageBubble', () {
    testWidgets('displays message content', (tester) async {
      await mountWidget(
        WnMessageBubble(message: _message(content: 'Test message'), isOwnMessage: false),
        tester,
      );

      expect(find.text('Test message'), findsOneWidget);
    });

    group('own message', () {
      testWidgets('aligns to the right', (tester) async {
        await mountWidget(
          WnMessageBubble(message: _message(), isOwnMessage: true),
          tester,
        );

        final align = tester.widget<Align>(find.byType(Align));
        expect(align.alignment, Alignment.centerRight);
      });
    });

    group('other user message', () {
      testWidgets('aligns to the left', (tester) async {
        await mountWidget(
          WnMessageBubble(message: _message(), isOwnMessage: false),
          tester,
        );

        final align = tester.widget<Align>(find.byType(Align));
        expect(align.alignment, Alignment.centerLeft);
      });
    });

    group('deleted message', () {
      testWidgets('renders nothing', (tester) async {
        await mountWidget(
          WnMessageBubble(message: _message(isDeleted: true), isOwnMessage: false),
          tester,
        );

        expect(find.byType(SizedBox), findsOneWidget);
      });
    });

    group('onLongPress', () {
      testWidgets('calls callback when long pressed', (tester) async {
        var called = false;
        await mountWidget(
          WnMessageBubble(
            message: _message(),
            isOwnMessage: false,
            onLongPress: () => called = true,
          ),
          tester,
        );

        await tester.longPress(find.byType(GestureDetector));

        expect(called, isTrue);
      });
    });

    group('reactions', () {
      testWidgets('does not show reactions when empty', (tester) async {
        await mountWidget(
          WnMessageBubble(message: _message(), isOwnMessage: false),
          tester,
        );

        expect(find.byType(WnMessageReactions), findsNothing);
      });

      testWidgets('shows reactions when present', (tester) async {
        final reactions = ReactionSummary(
          byEmoji: [
            EmojiReaction(
              emoji: '👍',
              count: BigInt.from(2),
              users: const [testPubkeyC, testPubkeyD],
            ),
          ],
          userReactions: const [],
        );
        await mountWidget(
          WnMessageBubble(message: _message(reactions: reactions), isOwnMessage: false),
          tester,
        );

        expect(find.byType(WnMessageReactions), findsOneWidget);
        expect(find.text('👍'), findsOneWidget);
      });

      testWidgets('passes currentUserPubkey to reactions', (tester) async {
        final reactions = ReactionSummary(
          byEmoji: [
            EmojiReaction(emoji: '👍', count: BigInt.one, users: const [testPubkeyB]),
          ],
          userReactions: const [],
        );
        await mountWidget(
          WnMessageBubble(
            message: _message(reactions: reactions),
            isOwnMessage: false,
            currentUserPubkey: testPubkeyB,
          ),
          tester,
        );

        final reactionBubbles = tester.widget<WnMessageReactions>(find.byType(WnMessageReactions));
        expect(reactionBubbles.currentUserPubkey, testPubkeyB);
      });

      testWidgets('passes onReaction to reactions', (tester) async {
        final reactions = ReactionSummary(
          byEmoji: [
            EmojiReaction(emoji: '👍', count: BigInt.one, users: const [testPubkeyC]),
          ],
          userReactions: const [],
        );
        String? tappedEmoji;
        await mountWidget(
          WnMessageBubble(
            message: _message(reactions: reactions),
            isOwnMessage: false,
            currentUserPubkey: testPubkeyB,
            onReaction: (emoji) => tappedEmoji = emoji,
          ),
          tester,
        );

        await tester.tap(find.text('👍'));
        await tester.pump();

        expect(tappedEmoji, '👍');
      });
    });

    group('reply preview', () {
      testWidgets('shows reply preview when replyPreview is provided', (tester) async {
        await mountWidget(
          WnMessageBubble(
            message: _message(isReply: true, replyToId: 'original-msg'),
            isOwnMessage: false,
            replyPreview: _replyPreview(),
          ),
          tester,
        );

        expect(find.byType(ChatMessageQuote), findsOneWidget);
        expect(find.text('Original Author'), findsOneWidget);
        expect(find.text('Original message content'), findsOneWidget);
      });

      testWidgets('hides reply preview when replyPreview is null', (tester) async {
        await mountWidget(
          WnMessageBubble(
            message: _message(isReply: true, replyToId: 'original-msg'),
            isOwnMessage: false,
          ),
          tester,
        );

        expect(find.byType(ChatMessageQuote), findsNothing);
      });

      testWidgets('hides reply preview when replyPreview is null even with isReply', (
        tester,
      ) async {
        await mountWidget(
          WnMessageBubble(
            message: _message(),
            isOwnMessage: false,
          ),
          tester,
        );

        expect(find.byType(ChatMessageQuote), findsNothing);
      });

      testWidgets('shows reply preview with author from metadata', (tester) async {
        await mountWidget(
          WnMessageBubble(
            message: _message(isReply: true, replyToId: 'original-msg'),
            isOwnMessage: false,
            replyPreview: _replyPreview(
              authorMetadata: const FlutterMetadata(
                displayName: 'Custom Author',
                name: 'custom',
                custom: {},
              ),
            ),
          ),
          tester,
        );

        expect(find.byType(ChatMessageQuote), findsOneWidget);
        expect(find.text('Custom Author'), findsOneWidget);
      });

      testWidgets('reply preview does not have cancel button', (tester) async {
        await mountWidget(
          WnMessageBubble(
            message: _message(isReply: true, replyToId: 'original-msg'),
            isOwnMessage: false,
            replyPreview: _replyPreview(),
          ),
          tester,
        );

        expect(find.byKey(const Key('cancel_quote_button')), findsNothing);
      });

      testWidgets('passes onReplyTap to ChatMessageQuote', (tester) async {
        var tapCalled = false;
        await mountWidget(
          WnMessageBubble(
            message: _message(isReply: true, replyToId: 'original-msg'),
            isOwnMessage: false,
            replyPreview: _replyPreview(),
            onReplyTap: () => tapCalled = true,
          ),
          tester,
        );

        await tester.tap(find.byKey(const Key('message_quote_tap_area')));
        await tester.pumpAndSettle();

        expect(tapCalled, isTrue);
      });

      testWidgets('no tap area when onReplyTap is null', (tester) async {
        await mountWidget(
          WnMessageBubble(
            message: _message(isReply: true, replyToId: 'original-msg'),
            isOwnMessage: false,
            replyPreview: _replyPreview(),
          ),
          tester,
        );

        expect(find.byKey(const Key('message_quote_tap_area')), findsNothing);
      });
    });

    group('maxWidth', () {
      Finder findBubbleConstrainedBox() => find.descendant(
        of: find.byType(WnMessageBubble),
        matching: find.byType(ConstrainedBox),
      );

      testWidgets('defaults to 3/4 of screen width', (tester) async {
        await mountWidget(
          WnMessageBubble(message: _message(), isOwnMessage: false),
          tester,
        );

        final constrainedBox = tester.widget<ConstrainedBox>(
          findBubbleConstrainedBox().first,
        );
        expect(constrainedBox.constraints.maxWidth, 390 * 0.75);
      });

      testWidgets('uses explicit maxWidth when provided', (tester) async {
        await mountWidget(
          WnMessageBubble(message: _message(), isOwnMessage: false, maxWidth: 200),
          tester,
        );

        final constrainedBox = tester.widget<ConstrainedBox>(
          findBubbleConstrainedBox().first,
        );
        expect(constrainedBox.constraints.maxWidth, 200);
      });

      testWidgets('allows full width when maxWidth is infinity', (tester) async {
        await mountWidget(
          WnMessageBubble(
            message: _message(),
            isOwnMessage: false,
            maxWidth: double.infinity,
          ),
          tester,
        );

        final constrainedBox = tester.widget<ConstrainedBox>(
          findBubbleConstrainedBox().first,
        );
        expect(constrainedBox.constraints.maxWidth, double.infinity);
      });
    });

    group('media attachments', () {
      testWidgets('shows media grid when mediaAttachments is not empty', (tester) async {
        await mountWidget(
          WnMessageBubble(
            message: _message(mediaAttachments: [_mediaFile('1')]),
            isOwnMessage: false,
          ),
          tester,
        );

        expect(find.byKey(const Key('message_media')), findsOneWidget);
        expect(find.byType(ChatMessageMedia), findsOneWidget);
      });

      testWidgets('does not show media grid when mediaAttachments is empty', (tester) async {
        await mountWidget(
          WnMessageBubble(message: _message(), isOwnMessage: false),
          tester,
        );

        expect(find.byKey(const Key('message_media')), findsNothing);
        expect(find.byType(ChatMessageMedia), findsNothing);
      });

      testWidgets('shows both media and text when both present', (tester) async {
        await mountWidget(
          WnMessageBubble(
            message: _message(
              content: 'Caption text',
              mediaAttachments: [_mediaFile('1')],
            ),
            isOwnMessage: false,
          ),
          tester,
        );

        expect(find.byType(ChatMessageMedia), findsOneWidget);
        expect(find.text('Caption text'), findsOneWidget);
      });

      testWidgets('hides message text when content is empty', (tester) async {
        await mountWidget(
          WnMessageBubble(
            message: _message(
              content: '',
              mediaAttachments: [_mediaFile('1')],
            ),
            isOwnMessage: false,
          ),
          tester,
        );

        expect(find.byType(ChatMessageMedia), findsOneWidget);
        expect(find.text(''), findsNothing);
      });

      testWidgets('media grid has onMediaTap callback configured', (tester) async {
        await mountWidget(
          WnMessageBubble(
            message: _message(mediaAttachments: [_mediaFile('1')]),
            isOwnMessage: false,
          ),
          tester,
        );

        final mediaGrid = tester.widget<ChatMessageMedia>(find.byType(ChatMessageMedia));
        expect(mediaGrid.onMediaTap, isNotNull);
      });

      testWidgets('accepts senderName and senderPictureUrl', (tester) async {
        await mountWidget(
          WnMessageBubble(
            message: _message(mediaAttachments: [_mediaFile('1')]),
            isOwnMessage: false,
            senderName: 'Alice',
            senderPictureUrl: 'https://example.com/avatar.jpg',
          ),
          tester,
        );

        expect(find.byType(ChatMessageMedia), findsOneWidget);
      });
    });
  });
}
