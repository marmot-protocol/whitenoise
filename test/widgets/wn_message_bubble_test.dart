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
      testWidgets('renders nothing when deleted', (tester) async {
        await mountWidget(
          const WnMessageBubble(direction: MessageDirection.incoming, isDeleted: true),
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
    });

    group('max bubble width', () {
      // Viewport = 390px, column = viewport − 20px = 370px, max = 80% of 370 = 296px.
      const expectedMaxWidth = (390 - 20) * 0.8;

      Finder findBubbleConstrainedBox() => find.descendant(
        of: find.byType(WnMessageBubble),
        matching: find.byType(ConstrainedBox),
      );

      testWidgets('is 80% of (viewport − 20px)', (tester) async {
        await mountWidget(
          const WnMessageBubble(direction: MessageDirection.incoming, isDeleted: false),
          tester,
        );

        final constrainedBox = tester.widget<ConstrainedBox>(
          findBubbleConstrainedBox().first,
        );
        expect(constrainedBox.constraints.maxWidth, expectedMaxWidth);
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

        final padding = tester.widget<Padding>(
          find.descendant(of: find.byType(WnMessageBubble), matching: find.byType(Padding)).first,
        );
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

        final padding = tester.widget<Padding>(
          find.descendant(of: find.byType(WnMessageBubble), matching: find.byType(Padding)).first,
        );
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
            .widget<Padding>(
              find
                  .descendant(of: find.byType(WnMessageBubble), matching: find.byType(Padding))
                  .first,
            )
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
            .widget<Padding>(
              find
                  .descendant(of: find.byType(WnMessageBubble), matching: find.byType(Padding))
                  .first,
            )
            .padding
            .resolve(TextDirection.ltr)
            .left;

        expect(avatarIndent, greaterThan(tailIndent));
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
        'outgoing: timestamp right edge aligns with bubble right edge when reactions wrap',
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

          final containerRight = tester
              .getRect(
                find
                    .descendant(
                      of: find.byType(WnMessageBubble),
                      matching: find.byType(Container),
                    )
                    .first,
              )
              .right;
          final tsRight = tester.getRect(find.text('12:00')).right;
          expect(
            containerRight - tsRight,
            lessThan(50),
            reason: 'timestamp must be near the bubble right edge',
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

        final padding = tester.widget<Padding>(
          find.ancestor(of: find.byType(IntrinsicWidth), matching: find.byType(Padding)).first,
        );
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

        final padding = tester.widget<Padding>(
          find.ancestor(of: find.byType(IntrinsicWidth), matching: find.byType(Padding)).first,
        );
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
  });
}
