import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart' show ScreenUtilInit;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:whitenoise/hooks/use_chat_messages.dart' show ChatMessageQuoteData;
import 'package:whitenoise/l10n/generated/app_localizations.dart';
import 'package:whitenoise/screens/start_chat_screen.dart';
import 'package:whitenoise/src/rust/api/markdown.dart';
import 'package:whitenoise/src/rust/api/media_files.dart';
import 'package:whitenoise/src/rust/api/messages.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/widgets/chat_message_bubble.dart';
import 'package:whitenoise/widgets/chat_message_media.dart';
import 'package:whitenoise/widgets/chat_message_quote.dart';
import 'package:whitenoise/widgets/media_modal.dart';
import 'package:whitenoise/widgets/wn_avatar.dart';
import 'package:whitenoise/widgets/wn_chat_status.dart';
import 'package:whitenoise/widgets/wn_message_bubble.dart';
import 'package:whitenoise/widgets/wn_reaction.dart';

import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

ChatMessageQuoteData _replyPreview({
  String messageId = 'original-msg',
  String authorPubkey = testPubkeyB,
  FlutterMetadata? authorMetadata,
  String content = 'Original message content',
  MarkdownDocument? contentTokens,
  MediaFile? mediaFile,
  bool isNotFound = false,
}) => (
  messageId: messageId,
  authorPubkey: authorPubkey,
  authorMetadata:
      authorMetadata ??
      const FlutterMetadata(displayName: 'Original Author', name: 'author', custom: {}),
  content: content,
  contentTokens: contentTokens,
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
  DateTime? createdAt,
  DeliveryStatus? deliveryStatus,
}) => ChatMessage(
  id: 'msg1',
  pubkey: testPubkeyA,
  content: content,
  createdAt: createdAt ?? DateTime(2024),
  tags: const [],
  isReply: isReply,
  replyToId: replyToId,
  isDeleted: isDeleted,
  contentTokens: const MarkdownDocument(blocks: []),
  reactions: reactions,
  mediaAttachments: mediaAttachments,
  kind: 9,
  deliveryStatus: deliveryStatus,
);

void main() {
  setUpAll(() => RustLib.initMock(api: MockWnApi()));

  group('ChatMessageBubble', () {
    testWidgets('renders WnMessageBubble', (tester) async {
      await mountWidget(
        ChatMessageBubble(message: _message(), isOwnMessage: false),
        tester,
      );

      expect(find.byType(WnMessageBubble), findsOneWidget);
    });

    testWidgets('displays message content', (tester) async {
      await mountWidget(
        ChatMessageBubble(message: _message(content: 'Test message'), isOwnMessage: false),
        tester,
      );

      expect(find.textContaining('Test message'), findsOneWidget);
    });

    group('own message', () {
      testWidgets('aligns to the right', (tester) async {
        await mountWidget(
          ChatMessageBubble(message: _message(), isOwnMessage: true),
          tester,
        );

        final align = tester.widget<Align>(find.byType(Align).first);
        expect(align.alignment, Alignment.centerRight);
      });
    });

    group('other user message', () {
      testWidgets('aligns to the left', (tester) async {
        await mountWidget(
          ChatMessageBubble(message: _message(), isOwnMessage: false),
          tester,
        );

        final align = tester.widget<Align>(find.byType(Align).first);
        expect(align.alignment, Alignment.centerLeft);
      });
    });

    group('deleted message', () {
      testWidgets('renders deleted message style when message is deleted', (tester) async {
        await mountWidget(
          ChatMessageBubble(message: _message(isDeleted: true), isOwnMessage: false),
          tester,
        );

        expect(
          find.textContaining('This message was deleted.', findRichText: true),
          findsOneWidget,
        );
      });

      testWidgets('hides original message body', (tester) async {
        await mountWidget(
          ChatMessageBubble(message: _message(isDeleted: true), isOwnMessage: false),
          tester,
        );

        expect(find.textContaining('Hello world', findRichText: true), findsNothing);
      });
    });

    group('retried message', () {
      testWidgets('renders SizedBox.shrink when delivery status is Retried', (tester) async {
        await mountWidget(
          ChatMessageBubble(
            message: _message(deliveryStatus: const DeliveryStatus.retried()),
            isOwnMessage: true,
          ),
          tester,
        );

        expect(find.byType(SizedBox), findsOneWidget);
        expect(find.byType(WnMessageBubble), findsNothing);
      });

      testWidgets('renders WnMessageBubble when delivery status is Retried for non-own message', (
        tester,
      ) async {
        await mountWidget(
          ChatMessageBubble(
            message: _message(deliveryStatus: const DeliveryStatus.retried()),
            isOwnMessage: false,
          ),
          tester,
        );

        expect(find.byType(WnMessageBubble), findsOneWidget);
      });
    });

    group('onLongPress', () {
      testWidgets('calls callback when long pressed', (tester) async {
        var called = false;
        await mountWidget(
          ChatMessageBubble(
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
      testWidgets('does not show reactions when message has none', (tester) async {
        await mountWidget(
          ChatMessageBubble(message: _message(), isOwnMessage: false),
          tester,
        );

        expect(find.byType(WnReaction), findsNothing);
      });

      testWidgets('shows one WnReaction per emoji', (tester) async {
        final reactions = ReactionSummary(
          byEmoji: [
            EmojiReaction(emoji: '👍', count: BigInt.from(2), users: const [testPubkeyC]),
            EmojiReaction(emoji: '❤️', count: BigInt.one, users: const [testPubkeyD]),
          ],
          userReactions: const [],
        );
        await mountWidget(
          ChatMessageBubble(message: _message(reactions: reactions), isOwnMessage: false),
          tester,
        );

        expect(find.byType(WnReaction), findsNWidgets(2));
        expect(find.text('👍'), findsOneWidget);
        expect(find.text('❤️'), findsOneWidget);
      });

      testWidgets('marks reaction selected when currentUserPubkey is in users', (tester) async {
        final reactions = ReactionSummary(
          byEmoji: [
            EmojiReaction(emoji: '👍', count: BigInt.one, users: const [testPubkeyB]),
          ],
          userReactions: const [],
        );
        await mountWidget(
          ChatMessageBubble(
            message: _message(reactions: reactions),
            isOwnMessage: false,
            currentUserPubkey: testPubkeyB,
          ),
          tester,
        );

        final widget = tester.widget<WnReaction>(find.byType(WnReaction));
        expect(widget.isSelected, isTrue);
      });

      testWidgets('passes onReaction callback', (tester) async {
        final reactions = ReactionSummary(
          byEmoji: [
            EmojiReaction(emoji: '👍', count: BigInt.one, users: const [testPubkeyC]),
          ],
          userReactions: const [],
        );
        String? tappedEmoji;
        await mountWidget(
          ChatMessageBubble(
            message: _message(reactions: reactions),
            isOwnMessage: false,
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
      testWidgets('shows ChatMessageQuote when replyPreview provided', (tester) async {
        await mountWidget(
          ChatMessageBubble(
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

      testWidgets('does not show quote when replyPreview is null', (tester) async {
        await mountWidget(
          ChatMessageBubble(
            message: _message(isReply: true, replyToId: 'original-msg'),
            isOwnMessage: false,
          ),
          tester,
        );

        expect(find.byType(ChatMessageQuote), findsNothing);
      });

      testWidgets('reply preview does not have cancel button', (tester) async {
        await mountWidget(
          ChatMessageBubble(
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
          ChatMessageBubble(
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
          ChatMessageBubble(
            message: _message(isReply: true, replyToId: 'original-msg'),
            isOwnMessage: false,
            replyPreview: _replyPreview(),
          ),
          tester,
        );

        expect(find.byKey(const Key('message_quote_tap_area')), findsNothing);
      });
    });

    group('max bubble width', () {
      const expectedMaxWidth = testDesignWidth * 0.8;

      Finder findBubbleConstrainedBox() => find.descendant(
        of: find.byType(WnMessageBubble),
        matching: find.byType(ConstrainedBox),
      );

      testWidgets('is 80% of viewport width', (tester) async {
        await mountWidget(
          ChatMessageBubble(message: _message(), isOwnMessage: false),
          tester,
        );

        final constrainedBox = tester.widget<ConstrainedBox>(
          findBubbleConstrainedBox().first,
        );
        expect(constrainedBox.constraints.maxWidth, expectedMaxWidth);
      });
    });

    group('timestamp', () {
      testWidgets('renders HH:mm', (tester) async {
        final createdAt = DateTime(2024, 1, 15, 14, 30);
        await mountWidget(
          ChatMessageBubble(message: _message(createdAt: createdAt), isOwnMessage: false),
          tester,
        );

        expect(find.text('14:30'), findsOneWidget);
      });

      testWidgets('zero-pads hours and minutes', (tester) async {
        final createdAt = DateTime(2024, 1, 15, 9, 5);
        await mountWidget(
          ChatMessageBubble(message: _message(createdAt: createdAt), isOwnMessage: false),
          tester,
        );

        expect(find.text('09:05'), findsOneWidget);
      });

      testWidgets('formats using local time', (tester) async {
        final utcTime = DateTime.utc(2024, 1, 15, 14, 30);
        final local = utcTime.toLocal();
        final expectedH = local.hour.toString().padLeft(2, '0');
        final expectedM = local.minute.toString().padLeft(2, '0');
        await mountWidget(
          ChatMessageBubble(message: _message(createdAt: utcTime), isOwnMessage: false),
          tester,
        );

        expect(find.text('$expectedH:$expectedM'), findsOneWidget);
      });
    });

    group('showTail', () {
      testWidgets('passes showTail true to WnMessageBubble by default', (tester) async {
        await mountWidget(
          ChatMessageBubble(message: _message(), isOwnMessage: false),
          tester,
        );

        final bubble = tester.widget<WnMessageBubble>(find.byType(WnMessageBubble));
        expect(bubble.showTail, isTrue);
      });

      testWidgets('passes showTail false when specified', (tester) async {
        await mountWidget(
          ChatMessageBubble(message: _message(), isOwnMessage: false, showTail: false),
          tester,
        );

        final bubble = tester.widget<WnMessageBubble>(find.byType(WnMessageBubble));
        expect(bubble.showTail, isFalse);
      });

      testWidgets('timestamp is shown when showTail is true', (tester) async {
        final createdAt = DateTime(2024, 1, 15, 14, 30);
        await mountWidget(
          ChatMessageBubble(message: _message(createdAt: createdAt), isOwnMessage: false),
          tester,
        );

        expect(find.text('14:30'), findsOneWidget);
      });

      testWidgets('timestamp is hidden when showTail is false', (tester) async {
        final createdAt = DateTime(2024, 1, 15, 14, 30);
        await mountWidget(
          ChatMessageBubble(
            message: _message(createdAt: createdAt),
            isOwnMessage: false,
            showTail: false,
          ),
          tester,
        );

        expect(find.text('14:30'), findsNothing);
      });

      testWidgets('shows status when delivery status is failed even if showTail is false', (
        tester,
      ) async {
        final createdAt = DateTime(2024, 1, 15, 14, 30);
        await mountWidget(
          ChatMessageBubble(
            message: _message(
              createdAt: createdAt,
              deliveryStatus: const DeliveryStatus.failed(reason: 'timeout'),
            ),
            isOwnMessage: true,
            showTail: false,
          ),
          tester,
        );

        final bubble = tester.widget<WnMessageBubble>(find.byType(WnMessageBubble));
        expect(bubble.showTail, isFalse);
        expect(find.text('14:30'), findsOneWidget);
      });
    });

    group('leadingVariant', () {
      WnMessageBubble getBubble(WidgetTester tester) =>
          tester.widget<WnMessageBubble>(find.byType(WnMessageBubble));

      testWidgets('own message: always none variant', (tester) async {
        await mountWidget(
          ChatMessageBubble(message: _message(), isOwnMessage: true, showTail: false),
          tester,
        );

        expect(getBubble(tester).leadingVariant, BubbleLeadingVariant.none);
      });

      testWidgets('incoming with tail: none variant', (tester) async {
        await mountWidget(
          ChatMessageBubble(message: _message(), isOwnMessage: false),
          tester,
        );

        expect(getBubble(tester).leadingVariant, BubbleLeadingVariant.none);
      });

      testWidgets('incoming without tail in DM: tail variant', (tester) async {
        await mountWidget(
          ChatMessageBubble(
            message: _message(),
            isOwnMessage: false,
            showTail: false,
          ),
          tester,
        );

        expect(getBubble(tester).leadingVariant, BubbleLeadingVariant.tail);
      });

      testWidgets('incoming without tail in group: avatar variant', (tester) async {
        await mountWidget(
          ChatMessageBubble(
            message: _message(),
            isOwnMessage: false,
            showTail: false,
            isGroupChat: true,
          ),
          tester,
        );

        expect(getBubble(tester).leadingVariant, BubbleLeadingVariant.avatar);
      });
    });

    group('media attachments', () {
      testWidgets('shows ChatMessageMedia when message has media', (tester) async {
        await mountWidget(
          ChatMessageBubble(
            message: _message(mediaAttachments: [_mediaFile('1')]),
            isOwnMessage: false,
          ),
          tester,
        );

        expect(find.byKey(const Key('message_media')), findsOneWidget);
        expect(find.byType(ChatMessageMedia), findsOneWidget);
      });

      testWidgets('does not show media when message has none', (tester) async {
        await mountWidget(
          ChatMessageBubble(message: _message(), isOwnMessage: false),
          tester,
        );

        expect(find.byKey(const Key('message_media')), findsNothing);
        expect(find.byType(ChatMessageMedia), findsNothing);
      });

      testWidgets('shows both media and text when both present', (tester) async {
        await mountWidget(
          ChatMessageBubble(
            message: _message(content: 'Caption text', mediaAttachments: [_mediaFile('1')]),
            isOwnMessage: false,
          ),
          tester,
        );

        expect(find.byType(ChatMessageMedia), findsOneWidget);
        expect(find.textContaining('Caption text'), findsOneWidget);
      });

      testWidgets('media grid has onMediaTap callback configured', (tester) async {
        await mountWidget(
          ChatMessageBubble(
            message: _message(mediaAttachments: [_mediaFile('1')]),
            isOwnMessage: false,
          ),
          tester,
        );

        final mediaGrid = tester.widget<ChatMessageMedia>(find.byType(ChatMessageMedia));
        expect(mediaGrid.onMediaTap, isNotNull);
      });

      testWidgets('onMediaTap opens MediaModal with expected arguments', (
        tester,
      ) async {
        await mountWidget(
          ChatMessageBubble(
            message: _message(mediaAttachments: [_mediaFile('1')]),
            isOwnMessage: false,
            senderName: 'Alice',
            senderPictureUrl: 'https://example.com/avatar.jpg',
          ),
          tester,
        );

        final media = tester.widget<ChatMessageMedia>(find.byType(ChatMessageMedia));
        media.onMediaTap!(0);
        await tester.pumpAndSettle();

        final mediaModal = tester.widget<MediaModal>(find.byType(MediaModal));
        expect(mediaModal.mediaFiles, [_mediaFile('1')]);
        expect(mediaModal.initialIndex, 0);
        expect(mediaModal.senderName, 'Alice');
        expect(mediaModal.senderPictureUrl, 'https://example.com/avatar.jpg');
        expect(mediaModal.senderPubkey, testPubkeyA);
        expect(mediaModal.timestamp, DateTime(2024));
      });

      testWidgets('accepts senderName and senderPictureUrl', (tester) async {
        await mountWidget(
          ChatMessageBubble(
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

    group('delivery status', () {
      testWidgets('maps Sending to sending status for own message', (tester) async {
        await mountWidget(
          ChatMessageBubble(
            message: _message(deliveryStatus: const DeliveryStatus.sending()),
            isOwnMessage: true,
          ),
          tester,
        );

        final bubble = tester.widget<WnMessageBubble>(find.byType(WnMessageBubble));
        expect(bubble.deliveryStatus, ChatStatusType.sending);
      });

      testWidgets('maps Sent to sent status for own message', (tester) async {
        await mountWidget(
          ChatMessageBubble(
            message: _message(deliveryStatus: DeliveryStatus.sent(relayCount: BigInt.from(2))),
            isOwnMessage: true,
          ),
          tester,
        );

        final bubble = tester.widget<WnMessageBubble>(find.byType(WnMessageBubble));
        expect(bubble.deliveryStatus, ChatStatusType.sent);
      });

      testWidgets('maps Failed to failed status for own message', (tester) async {
        await mountWidget(
          ChatMessageBubble(
            message: _message(deliveryStatus: const DeliveryStatus.failed(reason: 'timeout')),
            isOwnMessage: true,
          ),
          tester,
        );

        final bubble = tester.widget<WnMessageBubble>(find.byType(WnMessageBubble));
        expect(bubble.deliveryStatus, ChatStatusType.failed);
      });

      testWidgets('does not pass delivery status for other user messages', (tester) async {
        await mountWidget(
          ChatMessageBubble(
            message: _message(deliveryStatus: const DeliveryStatus.sending()),
            isOwnMessage: false,
          ),
          tester,
        );

        final bubble = tester.widget<WnMessageBubble>(find.byType(WnMessageBubble));
        expect(bubble.deliveryStatus, isNull);
      });

      testWidgets('passes onRetry as onStatusTap when status is failed', (tester) async {
        var retryCalled = false;
        await mountWidget(
          ChatMessageBubble(
            message: _message(deliveryStatus: const DeliveryStatus.failed(reason: 'timeout')),
            isOwnMessage: true,
            onRetry: () => retryCalled = true,
          ),
          tester,
        );

        final bubble = tester.widget<WnMessageBubble>(find.byType(WnMessageBubble));
        expect(bubble.onStatusTap, isNotNull);
        bubble.onStatusTap!();
        expect(retryCalled, isTrue);
      });

      testWidgets('does not pass onStatusTap when status is not failed', (tester) async {
        await mountWidget(
          ChatMessageBubble(
            message: _message(deliveryStatus: const DeliveryStatus.sending()),
            isOwnMessage: true,
            onRetry: () {},
          ),
          tester,
        );

        final bubble = tester.widget<WnMessageBubble>(find.byType(WnMessageBubble));
        expect(bubble.onStatusTap, isNull);
      });
    });

    group('avatar', () {
      testWidgets('shows WnAvatar when showAvatar is true and not own message', (tester) async {
        await mountWidget(
          ChatMessageBubble(
            message: _message(),
            isOwnMessage: false,
            showAvatar: true,
            senderName: 'Trent Reznor',
          ),
          tester,
        );

        expect(find.byType(WnAvatar), findsOneWidget);
      });

      testWidgets('does not show avatar when showAvatar is false', (tester) async {
        await mountWidget(
          ChatMessageBubble(
            message: _message(),
            isOwnMessage: false,
            senderName: 'Trent Reznor',
          ),
          tester,
        );

        expect(find.byType(WnAvatar), findsNothing);
      });

      testWidgets('does not show avatar for own message even if showAvatar is true', (
        tester,
      ) async {
        await mountWidget(
          ChatMessageBubble(
            message: _message(),
            isOwnMessage: true,
            showAvatar: true,
            senderName: 'Me',
          ),
          tester,
        );

        expect(find.byType(WnAvatar), findsNothing);
      });

      testWidgets('shows sender name when showAvatar is true for incoming', (tester) async {
        await mountWidget(
          ChatMessageBubble(
            message: _message(),
            isOwnMessage: false,
            showAvatar: true,
            senderName: 'Trent Reznor',
          ),
          tester,
        );

        expect(find.text('Trent Reznor'), findsOneWidget);
      });

      testWidgets('does not show sender name when showAvatar is false', (tester) async {
        await mountWidget(
          ChatMessageBubble(
            message: _message(),
            isOwnMessage: false,
            senderName: 'Trent Reznor',
          ),
          tester,
        );

        expect(find.text('Trent Reznor'), findsNothing);
      });
    });

    group('markdown link tap handling', () {
      late _MockUrlLauncher launcher;
      late UrlLauncherPlatform originalLauncher;

      setUp(() {
        originalLauncher = UrlLauncherPlatform.instance;
        launcher = _MockUrlLauncher();
        UrlLauncherPlatform.instance = launcher;
      });

      tearDown(() {
        UrlLauncherPlatform.instance = originalLauncher;
      });

      ChatMessage withDoc(MarkdownDocument doc) => _message(content: 'x').copyWithDocument(doc);

      testWidgets('strikethrough in the AST renders with lineThrough decoration', (tester) async {
        // Mirror the production shape: raw content is '~~hello~~' but the
        // contentTokens AST contains Strikethrough[Text('hello')]. The bubble
        // must render the document (visible 'hello' with lineThrough), not
        // the raw markdown source.
        await mountWidget(
          ChatMessageBubble(
            message: _message(content: '~~hello~~').copyWithDocument(
              const MarkdownDocument(
                blocks: [
                  MarkdownBlock.paragraph(
                    inlines: [
                      MarkdownInline.strikethrough(
                        children: [MarkdownInline.text(content: 'hello')],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            isOwnMessage: false,
          ),
          tester,
        );
        final span = tester.widget<RichText>(find.byType(RichText).first).text as TextSpan;
        final struck = _findTextSpan(span, (s) => s.text == 'hello');
        expect(
          struck,
          isNotNull,
          reason: 'expected document text to be rendered, not raw markdown',
        );
        expect(struck!.style?.decoration, TextDecoration.lineThrough);
        // The raw markdown source must NOT appear as visible text.
        expect(_findTextSpan(span, (s) => s.text == '~~hello~~'), isNull);
      });

      testWidgets('safe link tap calls launchUrl externally', (tester) async {
        await mountWidget(
          ChatMessageBubble(
            message: withDoc(
              const MarkdownDocument(
                blocks: [
                  MarkdownBlock.paragraph(
                    inlines: [
                      MarkdownInline.link(
                        dest: 'https://example.com',
                        children: [MarkdownInline.text(content: 'here')],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            isOwnMessage: false,
          ),
          tester,
        );
        final span = tester.widget<RichText>(find.byType(RichText).first).text as TextSpan;
        final link = _firstTextSpanWithRecognizer(span);
        (link.recognizer as TapGestureRecognizer).onTap!();
        await tester.pump();
        expect(launcher.calls, hasLength(1));
        expect(launcher.calls.first.url, 'https://example.com');
        expect(launcher.calls.first.options.mode, PreferredLaunchMode.externalApplication);
      });

      testWidgets('javascript: link tap is silently ignored at the renderer layer', (tester) async {
        await mountWidget(
          ChatMessageBubble(
            message: withDoc(
              const MarkdownDocument(
                blocks: [
                  MarkdownBlock.paragraph(
                    inlines: [
                      MarkdownInline.link(
                        dest: 'javascript:alert(1)',
                        children: [MarkdownInline.text(content: 'bad')],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            isOwnMessage: false,
          ),
          tester,
        );
        final span = tester.widget<RichText>(find.byType(RichText).first).text as TextSpan;
        final link = _findTextSpan(
          span,
          (s) =>
              s.text == 'bad' || (s.children?.any((c) => (c as TextSpan).text == 'bad') ?? false),
        );
        expect(link?.recognizer, isNull);
        expect(launcher.calls, isEmpty);
      });

      testWidgets('npub mention tap opens StartChatScreen as shade', (tester) async {
        await _mountBubbleWithRouter(
          tester,
          ChatMessageBubble(
            message: withDoc(
              const MarkdownDocument(
                blocks: [
                  MarkdownBlock.paragraph(
                    inlines: [
                      MarkdownInline.nostrMention(
                        entity: MarkdownNostrEntity(
                          hrp: MarkdownNostrHrp.npub,
                          bech32: testNpubA,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            isOwnMessage: false,
          ),
        );
        final span = tester.widget<RichText>(find.byType(RichText).first).text as TextSpan;
        final entity = _firstTextSpanWithRecognizer(span);
        (entity.recognizer as TapGestureRecognizer).onTap!();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        tester.takeException();
        expect(launcher.calls, isEmpty);
        expect(find.byType(StartChatScreen), findsOneWidget);
        expect(
          tester.widget<StartChatScreen>(find.byType(StartChatScreen)).asShade,
          isTrue,
        );
      });

      testWidgets('whitenoise://chat/<id> tap navigates via GoRouter', (tester) async {
        await _mountBubbleWithRouter(
          tester,
          ChatMessageBubble(
            message: withDoc(
              const MarkdownDocument(
                blocks: [
                  MarkdownBlock.paragraph(
                    inlines: [
                      MarkdownInline.autolink(
                        url: 'whitenoise://chat/$testGroupId',
                        kind: MarkdownAutolinkKind.uri,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            isOwnMessage: false,
          ),
        );
        final span = tester.widget<RichText>(find.byType(RichText).first).text as TextSpan;
        final link = _firstTextSpanWithRecognizer(span);
        (link.recognizer as TapGestureRecognizer).onTap!();
        await tester.pumpAndSettle();
        expect(launcher.calls, isEmpty);
        expect(find.byKey(const ValueKey('chat_route_$testGroupId')), findsOneWidget);
      });

      testWidgets('whitenoise://user/<npub> tap opens StartChatScreen as shade', (tester) async {
        await _mountBubbleWithRouter(
          tester,
          ChatMessageBubble(
            message: withDoc(
              const MarkdownDocument(
                blocks: [
                  MarkdownBlock.paragraph(
                    inlines: [
                      MarkdownInline.autolink(
                        url: 'whitenoise://user/$testNpubA',
                        kind: MarkdownAutolinkKind.uri,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            isOwnMessage: false,
          ),
        );
        final span = tester.widget<RichText>(find.byType(RichText).first).text as TextSpan;
        final link = _firstTextSpanWithRecognizer(span);
        (link.recognizer as TapGestureRecognizer).onTap!();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        // StartChatScreen reads accountPubkeyProvider which throws without auth in tests.
        // The shade still pushes onto the navigator — drain the expected build error
        // so the framework doesn't flag it.
        tester.takeException();
        expect(launcher.calls, isEmpty);
        expect(find.byKey(const ValueKey('user_route_$testPubkeyA')), findsNothing);
        expect(find.byType(StartChatScreen), findsOneWidget);
        expect(
          tester.widget<StartChatScreen>(find.byType(StartChatScreen)).asShade,
          isTrue,
        );
      });

      testWidgets('unparseable whitenoise:// tap shows dismissable error dialog', (tester) async {
        await _mountBubbleWithRouter(
          tester,
          ChatMessageBubble(
            message: withDoc(
              const MarkdownDocument(
                blocks: [
                  MarkdownBlock.paragraph(
                    inlines: [
                      MarkdownInline.autolink(
                        url: 'whitenoise://garbage',
                        kind: MarkdownAutolinkKind.uri,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            isOwnMessage: false,
          ),
        );
        final span = tester.widget<RichText>(find.byType(RichText).first).text as TextSpan;
        final link = _firstTextSpanWithRecognizer(span);
        (link.recognizer as TapGestureRecognizer).onTap!();
        await tester.pumpAndSettle();
        expect(launcher.calls, isEmpty);
        expect(find.byKey(const Key('unsupported_deep_link_dialog')), findsOneWidget);
        await tester.tap(find.byType(TextButton));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('unsupported_deep_link_dialog')), findsNothing);
      });

      testWidgets('non-npub Nostr URI tap still launches nostr: URL externally', (tester) async {
        await mountWidget(
          ChatMessageBubble(
            message: withDoc(
              const MarkdownDocument(
                blocks: [
                  MarkdownBlock.paragraph(
                    inlines: [
                      MarkdownInline.nostrUri(
                        entity: MarkdownNostrEntity(
                          hrp: MarkdownNostrHrp.nevent,
                          bech32: 'nevent1xyz',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            isOwnMessage: false,
          ),
          tester,
        );
        final span = tester.widget<RichText>(find.byType(RichText).first).text as TextSpan;
        final entity = _firstTextSpanWithRecognizer(span);
        (entity.recognizer as TapGestureRecognizer).onTap!();
        await tester.pump();
        expect(launcher.calls, hasLength(1));
        expect(launcher.calls.first.url, 'nostr:nevent1xyz');
      });
    });
  });
}

Future<void> _mountBubbleWithRouter(WidgetTester tester, Widget bubble) async {
  setUpTestView(tester);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(body: bubble),
      ),
      GoRoute(
        path: '/chats/:groupId',
        builder: (_, state) => Scaffold(
          key: ValueKey('chat_route_${state.pathParameters['groupId']}'),
          body: const SizedBox(),
        ),
      ),
      GoRoute(
        path: '/start-chat/:pubkey',
        builder: (_, state) => Scaffold(
          key: ValueKey('user_route_${state.pathParameters['pubkey']}'),
          body: const SizedBox(),
        ),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      child: ScreenUtilInit(
        designSize: testDesignSize,
        builder: (_, _) => MaterialApp.router(
          locale: const Locale('en'),
          theme: testMaterialAppTheme,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    ),
  );
}

class _MockUrlLauncher extends UrlLauncherPlatform with MockPlatformInterfaceMixin {
  final List<({String url, LaunchOptions options})> calls = [];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    calls.add((url: url, options: options));
    return true;
  }
}

extension on ChatMessage {
  ChatMessage copyWithDocument(MarkdownDocument doc) => ChatMessage(
    id: id,
    pubkey: pubkey,
    content: content,
    createdAt: createdAt,
    tags: tags,
    isReply: isReply,
    replyToId: replyToId,
    isDeleted: isDeleted,
    contentTokens: doc,
    reactions: reactions,
    mediaAttachments: mediaAttachments,
    kind: kind,
    deliveryStatus: deliveryStatus,
  );
}

TextSpan _firstTextSpanWithRecognizer(InlineSpan span) {
  if (span is TextSpan) {
    if (span.recognizer != null) return span;
    for (final child in span.children ?? const <InlineSpan>[]) {
      final found = _findTextSpanWithRecognizer(child);
      if (found != null) return found;
    }
  }
  throw StateError('no TextSpan with recognizer');
}

TextSpan? _findTextSpanWithRecognizer(InlineSpan span) {
  if (span is TextSpan) {
    if (span.recognizer != null) return span;
    for (final child in span.children ?? const <InlineSpan>[]) {
      final found = _findTextSpanWithRecognizer(child);
      if (found != null) return found;
    }
  }
  return null;
}

TextSpan? _findTextSpan(InlineSpan span, bool Function(TextSpan) predicate) {
  if (span is TextSpan) {
    if (predicate(span)) return span;
    for (final child in span.children ?? const <InlineSpan>[]) {
      final found = _findTextSpan(child, predicate);
      if (found != null) return found;
    }
  }
  return null;
}
