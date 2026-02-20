import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/src/rust/api/messages.dart';
import 'package:whitenoise/widgets/wn_message_bubble.dart' show MessageDirection;
import 'package:whitenoise/widgets/wn_message_reactions.dart';
import '../test_helpers.dart';

void main() {
  group('WnMessageReactions', () {
    testWidgets('renders nothing when reactions are empty', (tester) async {
      await mountWidget(
        const WnMessageReactions(
          reactions: [],
          direction: MessageDirection.incoming,
        ),
        tester,
      );

      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('displays single reaction emoji', (tester) async {
      await mountWidget(
        WnMessageReactions(
          reactions: [
            EmojiReaction(emoji: '👍', count: BigInt.one, users: const ['user1']),
          ],
          direction: MessageDirection.incoming,
        ),
        tester,
      );

      expect(find.text('👍'), findsOneWidget);
    });

    testWidgets('displays count when greater than 1', (tester) async {
      await mountWidget(
        WnMessageReactions(
          reactions: [
            EmojiReaction(emoji: '👍', count: BigInt.from(3), users: const ['u1', 'u2', 'u3']),
          ],
          direction: MessageDirection.incoming,
        ),
        tester,
      );

      expect(find.text('👍'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('does not display count when count is 1', (tester) async {
      await mountWidget(
        WnMessageReactions(
          reactions: [
            EmojiReaction(emoji: '👍', count: BigInt.one, users: const ['user1']),
          ],
          direction: MessageDirection.incoming,
        ),
        tester,
      );

      expect(find.text('👍'), findsOneWidget);
      expect(find.text('1'), findsNothing);
    });

    testWidgets('displays 99+ for counts over 99', (tester) async {
      await mountWidget(
        WnMessageReactions(
          reactions: [
            EmojiReaction(emoji: '👍', count: BigInt.from(150), users: const []),
          ],
          direction: MessageDirection.incoming,
        ),
        tester,
      );

      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('displays multiple reactions', (tester) async {
      await mountWidget(
        WnMessageReactions(
          reactions: [
            EmojiReaction(emoji: '👍', count: BigInt.from(2), users: const ['u1', 'u2']),
            EmojiReaction(emoji: '❤️', count: BigInt.one, users: const ['u3']),
          ],
          direction: MessageDirection.incoming,
        ),
        tester,
      );

      expect(find.text('👍'), findsOneWidget);
      expect(find.text('❤️'), findsOneWidget);
    });

    testWidgets('limits visible reactions to 3', (tester) async {
      await mountWidget(
        WnMessageReactions(
          reactions: [
            EmojiReaction(emoji: '👍', count: BigInt.one, users: const ['u1']),
            EmojiReaction(emoji: '❤️', count: BigInt.one, users: const ['u2']),
            EmojiReaction(emoji: '😂', count: BigInt.one, users: const ['u3']),
            EmojiReaction(emoji: '🔥', count: BigInt.one, users: const ['u4']),
          ],
          direction: MessageDirection.incoming,
        ),
        tester,
      );

      expect(find.text('👍'), findsOneWidget);
      expect(find.text('❤️'), findsOneWidget);
      expect(find.text('😂'), findsOneWidget);
      expect(find.text('🔥'), findsNothing);
      expect(find.text('...'), findsOneWidget);
    });

    testWidgets('does not show overflow indicator when exactly 3 reactions', (tester) async {
      await mountWidget(
        WnMessageReactions(
          reactions: [
            EmojiReaction(emoji: '👍', count: BigInt.one, users: const ['u1']),
            EmojiReaction(emoji: '❤️', count: BigInt.one, users: const ['u2']),
            EmojiReaction(emoji: '😂', count: BigInt.one, users: const ['u3']),
          ],
          direction: MessageDirection.incoming,
        ),
        tester,
      );

      expect(find.text('...'), findsNothing);
    });

    group('outgoing direction', () {
      testWidgets('renders reaction pill with outgoing styling', (tester) async {
        await mountWidget(
          WnMessageReactions(
            reactions: [
              EmojiReaction(emoji: '👍', count: BigInt.one, users: const ['u1']),
            ],
            direction: MessageDirection.outgoing,
          ),
          tester,
        );

        expect(find.text('👍'), findsOneWidget);
      });
    });

    group('onReaction', () {
      testWidgets('calls onReaction when user taps pill they have not reacted to', (tester) async {
        String? tappedEmoji;
        await mountWidget(
          WnMessageReactions(
            reactions: [
              EmojiReaction(emoji: '👍', count: BigInt.one, users: const ['other_user']),
            ],
            direction: MessageDirection.incoming,
            currentUserPubkey: 'current_user',
            onReaction: (emoji) => tappedEmoji = emoji,
          ),
          tester,
        );

        await tester.tap(find.text('👍'));
        await tester.pump();

        expect(tappedEmoji, '👍');
      });

      testWidgets('calls onReaction when user taps pill they already reacted to', (
        tester,
      ) async {
        String? tappedEmoji;
        await mountWidget(
          WnMessageReactions(
            reactions: [
              EmojiReaction(emoji: '👍', count: BigInt.one, users: const ['current_user']),
            ],
            direction: MessageDirection.incoming,
            currentUserPubkey: 'current_user',
            onReaction: (emoji) => tappedEmoji = emoji,
          ),
          tester,
        );

        await tester.tap(find.text('👍'));
        await tester.pump();

        expect(tappedEmoji, '👍');
      });

      testWidgets('when onReaction is null nothing happens on tap', (tester) async {
        await mountWidget(
          WnMessageReactions(
            reactions: [
              EmojiReaction(emoji: '👍', count: BigInt.one, users: const ['other_user']),
            ],
            direction: MessageDirection.incoming,
            currentUserPubkey: 'current_user',
          ),
          tester,
        );
        await tester.tap(find.text('👍'));
        await tester.pump();
        expect(find.text('👍'), findsOneWidget);
      });

      testWidgets('allows reaction when currentUserPubkey is null', (tester) async {
        String? tappedEmoji;
        await mountWidget(
          WnMessageReactions(
            reactions: [
              EmojiReaction(emoji: '👍', count: BigInt.one, users: const ['other_user']),
            ],
            direction: MessageDirection.incoming,
            onReaction: (emoji) => tappedEmoji = emoji,
          ),
          tester,
        );

        await tester.tap(find.text('👍'));
        await tester.pump();

        expect(tappedEmoji, '👍');
      });
    });
  });
}
