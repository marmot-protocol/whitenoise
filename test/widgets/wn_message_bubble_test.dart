import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/widgets/wn_chat_status.dart';
import 'package:whitenoise/widgets/wn_message_bubble.dart';
import 'package:whitenoise/widgets/wn_reaction.dart';

import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

const _avatarKey = Key('test_avatar');

Finder _findTail() => find.descendant(
  of: find.byType(WnMessageBubble),
  matching: find.byType(CustomPaint),
);

void main() {
  setUpAll(() => RustLib.initMock(api: MockWnApi()));

  group('WnMessageBubble', () {
    testWidgets('displays content text', (tester) async {
      await mountWidget(
        const WnMessageBubble(
          direction: MessageDirection.incoming,
          isDeleted: false,
          content: 'Test message',
        ),
        tester,
      );

      expect(find.text('Test message'), findsOneWidget);
    });

    testWidgets('does not display text when content is null', (tester) async {
      await mountWidget(
        const WnMessageBubble(direction: MessageDirection.incoming, isDeleted: false),
        tester,
      );

      expect(find.byType(Text), findsNothing);
    });

    testWidgets('does not display text when content is empty', (tester) async {
      await mountWidget(
        const WnMessageBubble(
          direction: MessageDirection.incoming,
          isDeleted: false,
          content: '',
        ),
        tester,
      );

      expect(find.byType(Text), findsNothing);
    });

    group('outgoing message', () {
      testWidgets('aligns to the right', (tester) async {
        await mountWidget(
          const WnMessageBubble(direction: MessageDirection.outgoing, isDeleted: false),
          tester,
        );

        final align = tester.widget<Align>(find.byType(Align).first);
        expect(align.alignment, Alignment.centerRight);
      });
    });

    group('incoming message', () {
      testWidgets('aligns to the left', (tester) async {
        await mountWidget(
          const WnMessageBubble(direction: MessageDirection.incoming, isDeleted: false),
          tester,
        );

        final align = tester.widget<Align>(find.byType(Align).first);
        expect(align.alignment, Alignment.centerLeft);
      });
    });

    group('deleted message', () {
      testWidgets('renders deleted message style when deleted', (tester) async {
        await mountWidget(
          const WnMessageBubble(
            direction: MessageDirection.incoming,
            isDeleted: true,
            deletedLabel: 'This message was deleted.',
          ),
          tester,
        );

        expect(find.text('This message was deleted.'), findsOneWidget);
      });

      testWidgets('does not trigger onLongPress even when callback is provided', (tester) async {
        var called = false;
        await mountWidget(
          WnMessageBubble(
            direction: MessageDirection.incoming,
            isDeleted: true,
            deletedLabel: 'This message was deleted.',
            onLongPress: () => called = true,
          ),
          tester,
        );

        await tester.longPress(find.text('This message was deleted.'));
        await tester.pump();

        expect(called, isFalse);
      });

      testWidgets('is not swipeable even when onHorizontalDragEnd is provided', (tester) async {
        var called = false;
        await mountWidget(
          WnMessageBubble(
            direction: MessageDirection.incoming,
            isDeleted: true,
            deletedLabel: 'This message was deleted.',
            content: 'Deleted',
            onHorizontalDragEnd: () => called = true,
          ),
          tester,
        );

        await tester.drag(find.text('This message was deleted.'), const Offset(200, 0));
        await tester.pump();

        expect(called, isFalse);
      });
    });

    group('onLongPress', () {
      testWidgets('calls callback when long pressed', (tester) async {
        var called = false;
        await mountWidget(
          WnMessageBubble(
            direction: MessageDirection.incoming,
            isDeleted: false,
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
          const WnMessageBubble(direction: MessageDirection.incoming, isDeleted: false),
          tester,
        );

        expect(find.byType(WnReaction), findsNothing);
      });

      testWidgets('shows one WnReaction per reaction', (tester) async {
        final reactions = [
          EmojiReaction(emoji: '👍', count: BigInt.from(2), users: const [testPubkeyC]),
          EmojiReaction(emoji: '❤️', count: BigInt.one, users: const [testPubkeyD]),
        ];
        await mountWidget(
          WnMessageBubble(
            direction: MessageDirection.incoming,
            isDeleted: false,
            reactions: reactions,
          ),
          tester,
        );

        expect(find.byType(WnReaction), findsNWidgets(2));
        expect(find.text('👍'), findsOneWidget);
        expect(find.text('❤️'), findsOneWidget);
      });

      testWidgets('marks reaction as selected when currentUserPubkey is in users', (tester) async {
        final reactions = [
          EmojiReaction(emoji: '👍', count: BigInt.one, users: const [testPubkeyB]),
        ];
        await mountWidget(
          WnMessageBubble(
            direction: MessageDirection.incoming,
            isDeleted: false,
            reactions: reactions,
            currentUserPubkey: testPubkeyB,
          ),
          tester,
        );

        final widget = tester.widget<WnReaction>(find.byType(WnReaction));
        expect(widget.isSelected, isTrue);
      });

      testWidgets('reaction is not selected when currentUserPubkey not in users', (tester) async {
        final reactions = [
          EmojiReaction(emoji: '👍', count: BigInt.one, users: const [testPubkeyC]),
        ];
        await mountWidget(
          WnMessageBubble(
            direction: MessageDirection.incoming,
            isDeleted: false,
            reactions: reactions,
            currentUserPubkey: testPubkeyB,
          ),
          tester,
        );

        final widget = tester.widget<WnReaction>(find.byType(WnReaction));
        expect(widget.isSelected, isFalse);
      });

      testWidgets('tapping reaction calls onReaction with emoji', (tester) async {
        final reactions = [
          EmojiReaction(emoji: '👍', count: BigInt.one, users: const [testPubkeyC]),
        ];
        String? tappedEmoji;
        await mountWidget(
          WnMessageBubble(
            direction: MessageDirection.incoming,
            isDeleted: false,
            reactions: reactions,
            onReaction: (emoji) => tappedEmoji = emoji,
          ),
          tester,
        );

        await tester.tap(find.text('👍'));
        await tester.pump();

        expect(tappedEmoji, '👍');
      });

      testWidgets('uses outgoing type for outgoing direction', (tester) async {
        final reactions = [
          EmojiReaction(emoji: '👍', count: BigInt.one, users: const []),
        ];
        await mountWidget(
          WnMessageBubble(
            direction: MessageDirection.outgoing,
            isDeleted: false,
            reactions: reactions,
          ),
          tester,
        );

        final widget = tester.widget<WnReaction>(find.byType(WnReaction));
        expect(widget.type, WnReactionType.outgoing);
      });

      testWidgets('uses incoming type for incoming direction', (tester) async {
        final reactions = [
          EmojiReaction(emoji: '👍', count: BigInt.one, users: const []),
        ];
        await mountWidget(
          WnMessageBubble(
            direction: MessageDirection.incoming,
            isDeleted: false,
            reactions: reactions,
          ),
          tester,
        );

        final widget = tester.widget<WnReaction>(find.byType(WnReaction));
        expect(widget.type, WnReactionType.incoming);
      });

      testWidgets('renders reactions in order sent by rust crate', (
        tester,
      ) async {
        final reactions = [
          EmojiReaction(emoji: '🔥', count: BigInt.one, users: const []),
          EmojiReaction(emoji: '❤️', count: BigInt.one, users: const []),
          EmojiReaction(emoji: '👍', count: BigInt.one, users: const []),
        ];
        await mountWidget(
          WnMessageBubble(
            direction: MessageDirection.incoming,
            isDeleted: false,
            reactions: reactions,
          ),
          tester,
        );

        final widgets = tester.widgetList<WnReaction>(find.byType(WnReaction)).toList();
        final emojis = widgets.map((w) => w.emoji).toList();
        final expectedEmojis = ['🔥', '❤️', '👍'];
        expect(emojis, equals(expectedEmojis));
      });

      testWidgets('assigns ValueKey with emoji to each WnReaction for stable reconciliation', (
        tester,
      ) async {
        final reactions = [
          EmojiReaction(emoji: '👍', count: BigInt.one, users: const []),
          EmojiReaction(emoji: '❤️', count: BigInt.from(2), users: const []),
        ];
        await mountWidget(
          WnMessageBubble(
            direction: MessageDirection.incoming,
            isDeleted: false,
            reactions: reactions,
          ),
          tester,
        );

        expect(find.byKey(const ValueKey('👍')), findsOneWidget);
        expect(find.byKey(const ValueKey('❤️')), findsOneWidget);
      });
    });

    group('replyContent', () {
      testWidgets('shows reply widget when replyContent is provided', (tester) async {
        await mountWidget(
          const WnMessageBubble(
            direction: MessageDirection.incoming,
            isDeleted: false,
            replyContent: Text('reply widget'),
          ),
          tester,
        );

        expect(find.text('reply widget'), findsOneWidget);
      });

      testWidgets('does not show reply area when replyContent is null', (tester) async {
        await mountWidget(
          const WnMessageBubble(direction: MessageDirection.incoming, isDeleted: false),
          tester,
        );

        expect(find.byKey(const Key('cancel_quote_button')), findsNothing);
      });

      testWidgets('status row aligns to bubble right edge with wide reply', (tester) async {
        await mountWidget(
          const WnMessageBubble(
            direction: MessageDirection.outgoing,
            isDeleted: false,
            content: 'Hi',
            timestamp: '12:00',
            replyContent: SizedBox(width: 250, height: 30),
          ),
          tester,
        );

        final bubbleRect = tester.getRect(find.byType(WnMessageBubble));
        final statusRight = tester.getTopRight(find.byKey(const Key('chat_status_icon')));
        expect(statusRight.dx, closeTo(bubbleRect.right, 20));
      });
    });

    group('mediaContent', () {
      testWidgets('shows media widget when mediaContent is provided', (tester) async {
        await mountWidget(
          const WnMessageBubble(
            direction: MessageDirection.incoming,
            isDeleted: false,
            mediaContent: SizedBox(key: Key('media_widget'), width: 100, height: 100),
          ),
          tester,
        );

        expect(find.byKey(const Key('media_widget')), findsOneWidget);
      });

      testWidgets('does not show media area when mediaContent is null', (tester) async {
        await mountWidget(
          const WnMessageBubble(direction: MessageDirection.incoming, isDeleted: false),
          tester,
        );

        expect(find.byKey(const Key('media_widget')), findsNothing);
      });

      testWidgets('shows both media and content text when both provided', (tester) async {
        await mountWidget(
          const WnMessageBubble(
            direction: MessageDirection.incoming,
            isDeleted: false,
            content: 'Caption',
            mediaContent: SizedBox(key: Key('media_widget'), width: 100, height: 100),
          ),
          tester,
        );

        expect(find.byKey(const Key('media_widget')), findsOneWidget);
        expect(find.text('Caption'), findsOneWidget);
      });

      testWidgets('does not show text when content is empty but media present', (tester) async {
        await mountWidget(
          const WnMessageBubble(
            direction: MessageDirection.incoming,
            isDeleted: false,
            content: '',
            mediaContent: SizedBox(key: Key('media_widget'), width: 100, height: 100),
          ),
          tester,
        );

        expect(find.byKey(const Key('media_widget')), findsOneWidget);
        expect(find.text(''), findsNothing);
      });

      testWidgets('does not use IntrinsicWidth when mediaContent is provided', (tester) async {
        await mountWidget(
          const WnMessageBubble(
            direction: MessageDirection.incoming,
            isDeleted: false,
            mediaContent: SizedBox(key: Key('media_widget'), width: 100, height: 100),
          ),
          tester,
        );

        expect(find.byType(IntrinsicWidth), findsNothing);
      });

      testWidgets('uses IntrinsicWidth when mediaContent is null', (tester) async {
        await mountWidget(
          const WnMessageBubble(
            direction: MessageDirection.incoming,
            isDeleted: false,
            content: 'Hello',
          ),
          tester,
        );

        expect(find.byType(IntrinsicWidth), findsOneWidget);
      });
    });

    group('max bubble width', () {
      Finder findBubbleConstrainedBox() => find.descendant(
        of: find.byType(WnMessageBubble),
        matching: find.byType(ConstrainedBox),
      );

      testWidgets('is 80% of available width from parent constraints', (tester) async {
        await mountWidget(
          const WnMessageBubble(direction: MessageDirection.incoming, isDeleted: false),
          tester,
        );

        final constrainedBox = tester.widget<ConstrainedBox>(
          findBubbleConstrainedBox().first,
        );
        expect(constrainedBox.constraints.maxWidth, testDesignWidth * 0.8);
      });

      testWidgets('adapts to narrower parent constraint', (tester) async {
        const parentWidth = 300.0;
        await mountWidget(
          const SizedBox(
            width: parentWidth,
            child: WnMessageBubble(direction: MessageDirection.incoming, isDeleted: false),
          ),
          tester,
        );

        final constrainedBox = tester.widget<ConstrainedBox>(
          findBubbleConstrainedBox().first,
        );
        expect(constrainedBox.constraints.maxWidth, parentWidth * 0.8);
      });

      testWidgets('short text bubble is narrower than maxBubbleWidth', (tester) async {
        await mountWidget(
          const WnMessageBubble(
            direction: MessageDirection.outgoing,
            isDeleted: false,
            content: 'Hi',
            timestamp: '12:00',
          ),
          tester,
        );

        final containerRect = tester.getRect(
          find
              .descendant(
                of: find.byType(WnMessageBubble),
                matching: find.byType(Container),
              )
              .first,
        );
        final maxBubbleWidth = testDesignWidth * 0.8;
        expect(
          containerRect.width,
          lessThan(maxBubbleWidth),
          reason: 'short text bubble should shrink-wrap, not fill max width',
        );
      });
    });

    group('timestamp', () {
      testWidgets('renders timestamp string when provided with text', (tester) async {
        await mountWidget(
          const WnMessageBubble(
            direction: MessageDirection.incoming,
            isDeleted: false,
            content: 'Hello',
            timestamp: '12:29',
          ),
          tester,
        );

        expect(find.text('12:29'), findsOneWidget);
      });

      testWidgets('renders timestamp standalone when no text content', (tester) async {
        await mountWidget(
          const WnMessageBubble(
            direction: MessageDirection.incoming,
            isDeleted: false,
            timestamp: '12:29',
          ),
          tester,
        );

        expect(find.text('12:29'), findsOneWidget);
      });

      testWidgets('no timestamp rendered when not provided', (tester) async {
        await mountWidget(
          const WnMessageBubble(
            direction: MessageDirection.incoming,
            isDeleted: false,
            content: 'Hello',
          ),
          tester,
        );

        expect(find.text('12:29'), findsNothing);
      });

      testWidgets('renders timestamp for deleted message when showTail is true', (tester) async {
        await mountWidget(
          const WnMessageBubble(
            direction: MessageDirection.incoming,
            isDeleted: true,
            deletedLabel: 'This message was deleted.',
            showTail: true,
            timestamp: '12:29',
          ),
          tester,
        );

        expect(find.textContaining('12:29', findRichText: true), findsOneWidget);
      });

      testWidgets('does not render timestamp for deleted message when showTail is false', (
        tester,
      ) async {
        await mountWidget(
          const WnMessageBubble(
            direction: MessageDirection.incoming,
            isDeleted: true,
            deletedLabel: 'This message was deleted.',
            timestamp: '12:29',
          ),
          tester,
        );

        expect(find.textContaining('12:29', findRichText: true), findsNothing);
      });
    });

    group('chat status', () {
      testWidgets('shows status icon for outgoing bubble with timestamp', (tester) async {
        await mountWidget(
          const WnMessageBubble(
            direction: MessageDirection.outgoing,
            isDeleted: false,
            content: 'Hello',
            timestamp: '12:00',
          ),
          tester,
        );

        expect(find.byKey(const Key('chat_status_icon')), findsOneWidget);
        expect(find.byType(WnChatStatus), findsOneWidget);
      });

      testWidgets('status icon appears to the right of the timestamp text', (tester) async {
        await mountWidget(
          const WnMessageBubble(
            direction: MessageDirection.outgoing,
            isDeleted: false,
            content: 'Hello',
            timestamp: '12:00',
          ),
          tester,
        );

        final timestampPos = tester.getTopRight(find.text('12:00'));
        final statusPos = tester.getTopLeft(find.byKey(const Key('chat_status_icon')));
        expect(statusPos.dx, greaterThan(timestampPos.dx));
      });

      testWidgets('does not show status icon for incoming bubble with timestamp', (tester) async {
        await mountWidget(
          const WnMessageBubble(
            direction: MessageDirection.incoming,
            isDeleted: false,
            content: 'Hello',
            timestamp: '12:00',
          ),
          tester,
        );

        expect(find.byKey(const Key('chat_status_icon')), findsNothing);
        expect(find.byType(WnChatStatus), findsNothing);
      });

      testWidgets('does not show status icon for outgoing bubble without timestamp', (
        tester,
      ) async {
        await mountWidget(
          const WnMessageBubble(
            direction: MessageDirection.outgoing,
            isDeleted: false,
            content: 'Hello',
          ),
          tester,
        );

        expect(find.byKey(const Key('chat_status_icon')), findsNothing);
        expect(find.byType(WnChatStatus), findsNothing);
      });

      testWidgets('does not show status icon for deleted outgoing bubble', (tester) async {
        await mountWidget(
          const WnMessageBubble(
            direction: MessageDirection.outgoing,
            isDeleted: true,
            deletedLabel: 'This message was deleted.',
            showTail: true,
            timestamp: '12:00',
            content: 'Hello',
          ),
          tester,
        );

        expect(find.byKey(const Key('chat_status_icon')), findsNothing);
        expect(find.byType(WnChatStatus), findsNothing);
      });

      testWidgets('shows status icon for outgoing with timestamp only', (tester) async {
        await mountWidget(
          const WnMessageBubble(
            direction: MessageDirection.outgoing,
            isDeleted: false,
            timestamp: '12:00',
          ),
          tester,
        );

        expect(find.byType(WnChatStatus), findsOneWidget);
      });

      testWidgets('does not show status icon for incoming with timestamp only', (tester) async {
        await mountWidget(
          const WnMessageBubble(
            direction: MessageDirection.incoming,
            isDeleted: false,
            timestamp: '12:00',
          ),
          tester,
        );

        expect(find.byType(WnChatStatus), findsNothing);
      });
    });

    group('leadingVariant', () {
      testWidgets('none variant applies no left indent', (tester) async {
        await mountWidget(
          const WnMessageBubble(
            direction: MessageDirection.incoming,
            isDeleted: false,
            content: 'Hello',
          ),
          tester,
        );

        final padding = tester.widget<Padding>(find.byKey(const Key('bubble_outer_padding')));
        expect(padding.padding.resolve(TextDirection.ltr).left, 0.0);
      });

      testWidgets('tail variant applies tail-overhang left indent', (tester) async {
        await mountWidget(
          const WnMessageBubble(
            direction: MessageDirection.incoming,
            isDeleted: false,
            content: 'Hello',
            leadingVariant: BubbleLeadingVariant.tail,
          ),
          tester,
        );

        final padding = tester.widget<Padding>(find.byKey(const Key('bubble_outer_padding')));
        expect(padding.padding.resolve(TextDirection.ltr).left, greaterThan(0));
      });

      testWidgets('avatar variant applies larger left indent than tail', (tester) async {
        late double tailIndent;
        late double avatarIndent;

        await mountWidget(
          const WnMessageBubble(
            direction: MessageDirection.incoming,
            isDeleted: false,
            content: 'Hello',
            leadingVariant: BubbleLeadingVariant.tail,
          ),
          tester,
        );
        tailIndent = tester
            .widget<Padding>(find.byKey(const Key('bubble_outer_padding')))
            .padding
            .resolve(TextDirection.ltr)
            .left;

        await mountWidget(
          const WnMessageBubble(
            direction: MessageDirection.incoming,
            isDeleted: false,
            content: 'Hello',
            leadingVariant: BubbleLeadingVariant.avatar,
          ),
          tester,
        );
        avatarIndent = tester
            .widget<Padding>(find.byKey(const Key('bubble_outer_padding')))
            .padding
            .resolve(TextDirection.ltr)
            .left;

        expect(avatarIndent, greaterThan(tailIndent));
      });
    });

    group('trailingIndent', () {
      testWidgets('outgoing bubble without tail has trailing indent', (tester) async {
        await mountWidget(
          const WnMessageBubble(
            direction: MessageDirection.outgoing,
            isDeleted: false,
            content: 'Hello',
          ),
          tester,
        );

        final padding = tester.widget<Padding>(find.byKey(const Key('bubble_outer_padding')));
        expect(padding.padding.resolve(TextDirection.ltr).right, greaterThan(0));
      });

      testWidgets('outgoing bubble with tail has no trailing indent', (tester) async {
        await mountWidget(
          const WnMessageBubble(
            direction: MessageDirection.outgoing,
            isDeleted: false,
            showTail: true,
            content: 'Hello',
          ),
          tester,
        );

        final padding = tester.widget<Padding>(find.byKey(const Key('bubble_outer_padding')));
        expect(padding.padding.resolve(TextDirection.ltr).right, 0.0);
      });
    });

    group('bottom spacing', () {
      Finder findOuterPadding() => find.descendant(
        of: find.byType(WnMessageBubble),
        matching: find.byType(Padding),
      );

      testWidgets('applies 12h bottom margin when showTail is true', (tester) async {
        await mountWidget(
          const WnMessageBubble(
            direction: MessageDirection.incoming,
            isDeleted: false,
            showTail: true,
            content: 'Hello',
          ),
          tester,
        );

        final outer = tester.widget<Padding>(findOuterPadding().first);
        expect(outer.padding.resolve(TextDirection.ltr).bottom, greaterThan(0));
      });

      testWidgets('applies smaller bottom margin when showTail is false', (tester) async {
        await mountWidget(
          const WnMessageBubble(
            direction: MessageDirection.incoming,
            isDeleted: false,
            content: 'Hello',
          ),
          tester,
        );

        final outer = tester.widget<Padding>(findOuterPadding().first);
        expect(outer.padding.resolve(TextDirection.ltr).bottom, greaterThan(0));
      });

      testWidgets('tailed bubble has larger bottom margin than tailless', (tester) async {
        double bottomWithTail = 0;
        double bottomWithoutTail = 0;

        await mountWidget(
          const WnMessageBubble(
            direction: MessageDirection.incoming,
            isDeleted: false,
            showTail: true,
            content: 'Hello',
          ),
          tester,
        );
        bottomWithTail = tester
            .widget<Padding>(findOuterPadding().first)
            .padding
            .resolve(TextDirection.ltr)
            .bottom;

        await mountWidget(
          const WnMessageBubble(
            direction: MessageDirection.incoming,
            isDeleted: false,
            content: 'Hello',
          ),
          tester,
        );
        bottomWithoutTail = tester
            .widget<Padding>(findOuterPadding().first)
            .padding
            .resolve(TextDirection.ltr)
            .bottom;

        expect(bottomWithTail, greaterThan(bottomWithoutTail));
      });
    });

    group('two-row reactions layout', () {
      List<EmojiReaction> manyReactions() => [
        EmojiReaction(emoji: '👍', count: BigInt.one, users: const []),
        EmojiReaction(emoji: '❤️', count: BigInt.one, users: const []),
        EmojiReaction(emoji: '😂', count: BigInt.one, users: const []),
        EmojiReaction(emoji: '😮', count: BigInt.one, users: const []),
        EmojiReaction(emoji: '😢', count: BigInt.one, users: const []),
        EmojiReaction(emoji: '🎉', count: BigInt.one, users: const []),
        EmojiReaction(emoji: '🔥', count: BigInt.one, users: const []),
        EmojiReaction(emoji: '👏', count: BigInt.one, users: const []),
      ];

      testWidgets(
        'outgoing: timestamp is within bubble bounds when reactions wrap',
        (tester) async {
          await mountWidget(
            WnMessageBubble(
              direction: MessageDirection.outgoing,
              isDeleted: false,
              showTail: true,
              content: 'Hi',
              timestamp: '12:00',
              reactions: manyReactions(),
            ),
            tester,
          );

          final containerRect = tester.getRect(
            find
                .descendant(
                  of: find.byType(WnMessageBubble),
                  matching: find.byType(Container),
                )
                .first,
          );
          final tsRect = tester.getRect(find.text('12:00'));
          expect(
            containerRect.contains(tsRect.center),
            isTrue,
            reason: 'timestamp must be visible inside the bubble',
          );
        },
      );

      testWidgets(
        'outgoing with tail: tail bottom is flush with container bottom when reactions wrap',
        (tester) async {
          await mountWidget(
            WnMessageBubble(
              direction: MessageDirection.outgoing,
              isDeleted: false,
              showTail: true,
              content: 'Hi',
              timestamp: '12:00',
              reactions: manyReactions(),
            ),
            tester,
          );

          final containerBottom = tester
              .getRect(
                find
                    .descendant(
                      of: find.byType(WnMessageBubble),
                      matching: find.byType(Container),
                    )
                    .first,
              )
              .bottom;
          final tailBottom = tester.getRect(_findTail()).bottom;

          expect(
            (tailBottom - containerBottom).abs(),
            lessThanOrEqualTo(1.0),
            reason: 'tail must be flush with the bubble bottom — no gap',
          );
        },
      );

      testWidgets(
        'all reactions are rendered inside the bubble container bounds',
        (tester) async {
          await mountWidget(
            WnMessageBubble(
              direction: MessageDirection.outgoing,
              isDeleted: false,
              showTail: true,
              content: 'Hi',
              timestamp: '12:00',
              reactions: manyReactions(),
            ),
            tester,
          );

          final containerRect = tester.getRect(
            find
                .descendant(
                  of: find.byType(WnMessageBubble),
                  matching: find.byType(Container),
                )
                .first,
          );

          final reactionRects = tester
              .widgetList<WnReaction>(find.byType(WnReaction))
              .map((w) => tester.getRect(find.byWidget(w)))
              .toList();

          expect(reactionRects, isNotEmpty);
          for (final rect in reactionRects) {
            expect(
              containerRect.overlaps(rect),
              isTrue,
              reason: 'reaction at $rect must be inside container $containerRect',
            );
          }
        },
      );

      testWidgets(
        'outgoing: status aligns to bubble right edge when reactions are wider than text',
        (tester) async {
          await mountWidget(
            WnMessageBubble(
              direction: MessageDirection.outgoing,
              isDeleted: false,
              showTail: true,
              content: 'Hi',
              timestamp: '12:00',
              reactions: manyReactions(),
            ),
            tester,
          );

          final containerRect = tester.getRect(
            find
                .descendant(
                  of: find.byType(WnMessageBubble),
                  matching: find.byType(Container),
                )
                .first,
          );
          final statusRight = tester.getTopRight(find.byKey(const Key('chat_status_icon')));
          expect(statusRight.dx, closeTo(containerRect.right, 12));
        },
      );
    });

    group('tail', () {
      testWidgets('renders tail for incoming when showTail is true', (tester) async {
        await mountWidget(
          const WnMessageBubble(
            direction: MessageDirection.incoming,
            isDeleted: false,
            showTail: true,
            content: 'Hello',
          ),
          tester,
        );

        expect(_findTail(), findsOneWidget);
      });

      testWidgets('renders tail for outgoing when showTail is true', (tester) async {
        await mountWidget(
          const WnMessageBubble(
            direction: MessageDirection.outgoing,
            isDeleted: false,
            showTail: true,
            content: 'Hello',
          ),
          tester,
        );

        expect(_findTail(), findsOneWidget);
      });

      testWidgets('does not render tail when showTail is false', (tester) async {
        await mountWidget(
          const WnMessageBubble(
            direction: MessageDirection.incoming,
            isDeleted: false,
            content: 'Hello',
          ),
          tester,
        );

        expect(_findTail(), findsNothing);
      });
      testWidgets('incoming with tail squares bottom-left corner', (tester) async {
        await mountWidget(
          const WnMessageBubble(
            direction: MessageDirection.incoming,
            isDeleted: false,
            showTail: true,
            content: 'Hello',
          ),
          tester,
        );

        final container = tester.widget<Container>(
          find.descendant(of: find.byType(WnMessageBubble), matching: find.byType(Container)).first,
        );
        final radius = (container.decoration! as BoxDecoration).borderRadius! as BorderRadius;
        expect(radius.bottomLeft, Radius.zero);
        expect(radius.bottomRight, isNot(Radius.zero));
        expect(radius.topLeft, isNot(Radius.zero));
        expect(radius.topRight, isNot(Radius.zero));
      });

      testWidgets('outgoing with tail squares bottom-right corner', (tester) async {
        await mountWidget(
          const WnMessageBubble(
            direction: MessageDirection.outgoing,
            isDeleted: false,
            showTail: true,
            content: 'Hello',
          ),
          tester,
        );

        final container = tester.widget<Container>(
          find.descendant(of: find.byType(WnMessageBubble), matching: find.byType(Container)).first,
        );
        final radius = (container.decoration! as BoxDecoration).borderRadius! as BorderRadius;
        expect(radius.bottomRight, Radius.zero);
        expect(radius.bottomLeft, isNot(Radius.zero));
        expect(radius.topLeft, isNot(Radius.zero));
        expect(radius.topRight, isNot(Radius.zero));
      });

      testWidgets('no tail keeps all corners rounded', (tester) async {
        await mountWidget(
          const WnMessageBubble(
            direction: MessageDirection.incoming,
            isDeleted: false,
            content: 'Hello',
          ),
          tester,
        );

        final container = tester.widget<Container>(
          find.descendant(of: find.byType(WnMessageBubble), matching: find.byType(Container)).first,
        );
        final radius = (container.decoration! as BoxDecoration).borderRadius! as BorderRadius;
        expect(radius.bottomLeft, isNot(Radius.zero));
        expect(radius.bottomRight, isNot(Radius.zero));
        expect(radius.topLeft, isNot(Radius.zero));
        expect(radius.topRight, isNot(Radius.zero));
      });

      testWidgets('does not render tail when deleted', (tester) async {
        await mountWidget(
          const WnMessageBubble(
            direction: MessageDirection.incoming,
            isDeleted: true,
            deletedLabel: 'This message was deleted.',
            showTail: true,
          ),
          tester,
        );

        expect(_findTail(), findsNothing);
      });

      testWidgets('outgoing with tail has right overhang padding', (tester) async {
        await mountWidget(
          const WnMessageBubble(
            direction: MessageDirection.outgoing,
            isDeleted: false,
            showTail: true,
            content: 'Hello',
          ),
          tester,
        );

        final padding = tester.widget<Padding>(find.byKey(const Key('bubble_tail_padding')));
        expect(padding.padding.resolve(TextDirection.ltr).right, greaterThan(0));
      });

      testWidgets('outgoing without tail has no right overhang padding', (tester) async {
        await mountWidget(
          const WnMessageBubble(
            direction: MessageDirection.outgoing,
            isDeleted: false,
            content: 'Hello',
          ),
          tester,
        );

        final padding = tester.widget<Padding>(find.byKey(const Key('bubble_tail_padding')));
        expect(padding.padding.resolve(TextDirection.ltr).right, 0.0);
      });
    });

    group('avatar and sender name', () {
      testWidgets('renders avatar widget for incoming with avatar', (tester) async {
        await mountWidget(
          const WnMessageBubble(
            direction: MessageDirection.incoming,
            isDeleted: false,
            content: 'Hello',
            avatar: SizedBox(key: _avatarKey, width: 36, height: 36),
          ),
          tester,
        );

        expect(find.byKey(_avatarKey), findsOneWidget);
      });

      testWidgets('does not render avatar for outgoing even if avatar provided', (tester) async {
        await mountWidget(
          const WnMessageBubble(
            direction: MessageDirection.outgoing,
            isDeleted: false,
            content: 'Hello',
            avatar: SizedBox(key: _avatarKey, width: 36, height: 36),
          ),
          tester,
        );

        expect(find.byKey(_avatarKey), findsNothing);
      });

      testWidgets('renders sender name when provided for incoming', (tester) async {
        await mountWidget(
          const WnMessageBubble(
            direction: MessageDirection.incoming,
            isDeleted: false,
            content: 'Hello',
            senderName: 'Trent Reznor',
          ),
          tester,
        );

        expect(find.text('Trent Reznor'), findsOneWidget);
      });

      testWidgets('does not render sender name for outgoing', (tester) async {
        await mountWidget(
          const WnMessageBubble(
            direction: MessageDirection.outgoing,
            isDeleted: false,
            content: 'Hello',
            senderName: 'Trent Reznor',
          ),
          tester,
        );

        expect(find.text('Trent Reznor'), findsNothing);
      });

      testWidgets('does not render sender name when null', (tester) async {
        await mountWidget(
          const WnMessageBubble(
            direction: MessageDirection.incoming,
            isDeleted: false,
            content: 'Hello',
          ),
          tester,
        );

        expect(find.byKey(const Key('bubble_avatar_row')), findsNothing);
      });

      testWidgets('wraps in Row when avatar is provided for incoming', (tester) async {
        await mountWidget(
          const WnMessageBubble(
            direction: MessageDirection.incoming,
            isDeleted: false,
            content: 'Hello',
            avatar: SizedBox(key: _avatarKey, width: 36, height: 36),
          ),
          tester,
        );

        expect(find.byKey(const Key('bubble_avatar_row')), findsOneWidget);
      });

      testWidgets('no Row wrapper when no avatar', (tester) async {
        await mountWidget(
          const WnMessageBubble(
            direction: MessageDirection.incoming,
            isDeleted: false,
            content: 'Hello',
          ),
          tester,
        );

        expect(find.byKey(const Key('bubble_avatar_row')), findsNothing);
      });

      testWidgets('applies senderNameColor to sender name text', (tester) async {
        const nameColor = Color(0xFFFF0000);
        await mountWidget(
          const WnMessageBubble(
            direction: MessageDirection.incoming,
            isDeleted: false,
            content: 'Hello',
            senderName: 'Alice',
            senderNameColor: nameColor,
          ),
          tester,
        );

        final nameText = tester.widget<Text>(find.text('Alice'));
        expect(nameText.style?.color, nameColor);
      });
    });

    group('onStatusTap', () {
      testWidgets('calls onStatusTap when tapping timestamp row (text with timestamp)', (
        tester,
      ) async {
        var called = false;
        await mountWidget(
          WnMessageBubble(
            direction: MessageDirection.outgoing,
            isDeleted: false,
            content: 'Failed message',
            timestamp: '14:30',
            deliveryStatus: ChatStatusType.failed,
            onStatusTap: () => called = true,
          ),
          tester,
        );

        await tester.tap(find.byKey(const Key('status_tap_area')));
        await tester.pump();

        expect(called, isTrue);
      });

      testWidgets('calls onStatusTap when tapping standalone timestamp row', (tester) async {
        var called = false;
        await mountWidget(
          WnMessageBubble(
            direction: MessageDirection.outgoing,
            isDeleted: false,
            timestamp: '14:30',
            mediaContent: const SizedBox(width: 100, height: 100),
            deliveryStatus: ChatStatusType.failed,
            onStatusTap: () => called = true,
          ),
          tester,
        );

        await tester.tap(find.byKey(const Key('status_tap_area')));
        await tester.pump();

        expect(called, isTrue);
      });

      testWidgets('no tap area when onStatusTap is null', (tester) async {
        await mountWidget(
          const WnMessageBubble(
            direction: MessageDirection.outgoing,
            isDeleted: false,
            content: 'Normal message',
            timestamp: '14:30',
            deliveryStatus: ChatStatusType.sending,
          ),
          tester,
        );

        expect(find.byKey(const Key('status_tap_area')), findsNothing);
      });
    });

    group('deleted bubble border', () {
      testWidgets('has a shape decoration', (tester) async {
        await mountWidget(
          const WnMessageBubble(
            direction: MessageDirection.incoming,
            isDeleted: true,
            deletedLabel: 'Deleted',
          ),
          tester,
        );
        final container = tester.widget<Container>(
          find.byKey(const Key('deleted_bubble_border')),
        );
        expect(container.decoration, isA<ShapeDecoration>());
      });

      testWidgets('non-deleted bubble has no shape decoration', (tester) async {
        await mountWidget(
          const WnMessageBubble(
            direction: MessageDirection.incoming,
            isDeleted: false,
            content: 'Hello',
          ),
          tester,
        );
        expect(find.byKey(const Key('deleted_bubble_border')), findsNothing);
      });
    });

    group('onHorizontalDragEnd', () {
      testWidgets('calls callback when swiped (distance-based)', (tester) async {
        var called = false;
        await mountWidget(
          WnMessageBubble(
            direction: MessageDirection.incoming,
            isDeleted: false,
            content: 'Swipe me',
            onHorizontalDragEnd: () => called = true,
          ),
          tester,
        );

        await tester.drag(find.byType(GestureDetector).first, const Offset(200, 0));
        await tester.pump();

        expect(called, isTrue);
      });

      testWidgets('calls callback when swiped slowly (distance-based, not velocity-based)', (
        tester,
      ) async {
        var called = false;
        await mountWidget(
          WnMessageBubble(
            direction: MessageDirection.incoming,
            isDeleted: false,
            content: 'Swipe me slowly',
            onHorizontalDragEnd: () => called = true,
          ),
          tester,
        );

        await tester.timedDrag(
          find.byType(GestureDetector).first,
          const Offset(200, 0),
          const Duration(milliseconds: 500),
        );
        await tester.pump();

        expect(called, isTrue);
      });
    });
  });
}
