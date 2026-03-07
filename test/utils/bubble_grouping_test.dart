import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/src/rust/api/messages.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/utils/bubble_grouping.dart';
import 'package:whitenoise/widgets/wn_message_bubble.dart' show BubbleLeadingVariant;

import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

ChatMessage _msg(String pubkey, DateTime createdAt, {bool isDeleted = false}) => ChatMessage(
  id: pubkey + createdAt.toIso8601String(),
  pubkey: pubkey,
  content: 'test',
  createdAt: createdAt,
  tags: const [],
  isReply: false,
  isDeleted: isDeleted,
  contentTokens: const [],
  reactions: const ReactionSummary(byEmoji: [], userReactions: []),
  mediaAttachments: const [],
  kind: 9,
);

void main() {
  setUpAll(() => RustLib.initMock(api: MockWnApi()));

  final base = DateTime(2024, 1, 1, 12);

  group('leadingVariant', () {
    test('own message returns none', () {
      expect(
        leadingVariant(isOwnMessage: true, showTail: false, isGroupChat: false),
        BubbleLeadingVariant.none,
      );
    });

    test('own message in group returns none', () {
      expect(
        leadingVariant(isOwnMessage: true, showTail: false, isGroupChat: true),
        BubbleLeadingVariant.none,
      );
    });

    test('incoming with tail returns none', () {
      expect(
        leadingVariant(isOwnMessage: false, showTail: true, isGroupChat: false),
        BubbleLeadingVariant.none,
      );
    });

    test('incoming without tail in DM returns tail', () {
      expect(
        leadingVariant(isOwnMessage: false, showTail: false, isGroupChat: false),
        BubbleLeadingVariant.tail,
      );
    });

    test('incoming without tail in group returns avatar', () {
      expect(
        leadingVariant(isOwnMessage: false, showTail: false, isGroupChat: true),
        BubbleLeadingVariant.avatar,
      );
    });
  });

  group('shouldShowAvatar', () {
    test('returns false for own message regardless of context', () {
      final msg = _msg(testPubkeyA, base);
      expect(
        shouldShowAvatar(
          current: msg,
          next: null,
          isOwnMessage: true,
          isGroupChat: true,
        ),
        isFalse,
      );
    });

    test('returns false in DM even for incoming', () {
      final msg = _msg(testPubkeyB, base);
      expect(
        shouldShowAvatar(
          current: msg,
          next: null,
          isOwnMessage: false,
          isGroupChat: false,
        ),
        isFalse,
      );
    });

    test('returns true for newest incoming message in group (next is null)', () {
      final msg = _msg(testPubkeyB, base);
      expect(
        shouldShowAvatar(
          current: msg,
          next: null,
          isOwnMessage: false,
          isGroupChat: true,
        ),
        isTrue,
      );
    });

    test('returns true when next message is from different sender in group', () {
      final current = _msg(testPubkeyB, base);
      final next = _msg(testPubkeyC, base.add(const Duration(minutes: 1)));
      expect(
        shouldShowAvatar(
          current: current,
          next: next,
          isOwnMessage: false,
          isGroupChat: true,
        ),
        isTrue,
      );
    });

    test('returns false when same sender within 5 min in group', () {
      final current = _msg(testPubkeyB, base);
      final next = _msg(testPubkeyB, base.add(const Duration(minutes: 2)));
      expect(
        shouldShowAvatar(
          current: current,
          next: next,
          isOwnMessage: false,
          isGroupChat: true,
        ),
        isFalse,
      );
    });

    test('returns true when same sender at exactly 5 min in group', () {
      final current = _msg(testPubkeyB, base);
      final next = _msg(testPubkeyB, base.add(const Duration(minutes: 5)));
      expect(
        shouldShowAvatar(
          current: current,
          next: next,
          isOwnMessage: false,
          isGroupChat: true,
        ),
        isTrue,
      );
    });
  });

  group('shouldShowTail', () {
    test('returns true when next is null (last/only message)', () {
      final msg = _msg(testPubkeyB, base);
      expect(shouldShowTail(current: msg, next: null), isTrue);
    });

    test('returns true when next is from different sender', () {
      final current = _msg(testPubkeyB, base);
      final next = _msg(testPubkeyC, base.add(const Duration(minutes: 1)));
      expect(shouldShowTail(current: current, next: next), isTrue);
    });

    test('returns false when same sender within 5 min', () {
      final current = _msg(testPubkeyB, base);
      final next = _msg(testPubkeyB, base.add(const Duration(minutes: 2)));
      expect(shouldShowTail(current: current, next: next), isFalse);
    });

    test('returns true when same sender at exactly 5 min', () {
      final current = _msg(testPubkeyB, base);
      final next = _msg(testPubkeyB, base.add(const Duration(minutes: 5)));
      expect(shouldShowTail(current: current, next: next), isTrue);
    });

    group('when next message is deleted', () {
      test('returns true for non-deleted current', () {
        final current = _msg(testPubkeyB, base);
        final next = _msg(testPubkeyB, base.add(const Duration(minutes: 1)), isDeleted: true);
        expect(shouldShowTail(current: current, next: next), isTrue);
      });

      test('returns false when both are deleted', () {
        final current = _msg(testPubkeyB, base, isDeleted: true);
        final next = _msg(testPubkeyB, base.add(const Duration(minutes: 1)), isDeleted: true);
        expect(shouldShowTail(current: current, next: next), isFalse);
      });
    });

    group('when current message is deleted', () {
      test('returns true when next is not deleted', () {
        final current = _msg(testPubkeyB, base, isDeleted: true);
        final next = _msg(testPubkeyB, base.add(const Duration(minutes: 1)));
        expect(shouldShowTail(current: current, next: next), isTrue);
      });

      test('returns false when both are deleted', () {
        final current = _msg(testPubkeyB, base, isDeleted: true);
        final next = _msg(testPubkeyB, base.add(const Duration(minutes: 1)), isDeleted: true);
        expect(shouldShowTail(current: current, next: next), isFalse);
      });
    });
  });

  group('shouldShowAvatar – deleted messages', () {
    test('returns true when current is not deleted but next is', () {
      final current = _msg(testPubkeyB, base);
      final next = _msg(testPubkeyB, base.add(const Duration(minutes: 1)), isDeleted: true);
      expect(
        shouldShowAvatar(
          current: current,
          next: next,
          isOwnMessage: false,
          isGroupChat: true,
        ),
        isTrue,
      );
    });

    test('returns true when current is deleted but next is not', () {
      final current = _msg(testPubkeyB, base, isDeleted: true);
      final next = _msg(testPubkeyB, base.add(const Duration(minutes: 1)));
      expect(
        shouldShowAvatar(
          current: current,
          next: next,
          isOwnMessage: false,
          isGroupChat: true,
        ),
        isTrue,
      );
    });

    test('returns false when both are deleted same sender within 5 min', () {
      final current = _msg(testPubkeyB, base, isDeleted: true);
      final next = _msg(testPubkeyB, base.add(const Duration(minutes: 1)), isDeleted: true);
      expect(
        shouldShowAvatar(
          current: current,
          next: next,
          isOwnMessage: false,
          isGroupChat: true,
        ),
        isFalse,
      );
    });
  });
}
