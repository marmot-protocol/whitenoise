import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/src/rust/api/messages.dart';
import 'package:whitenoise/utils/search_context.dart';

import '../test_helpers.dart';

ChatMessage _msg(String id, {DateTime? createdAt}) => ChatMessage(
  id: id,
  pubkey: testPubkeyA,
  content: 'Message $id',
  createdAt: createdAt ?? DateTime(2024),
  tags: const [],
  isReply: false,
  isDeleted: false,
  contentTokens: const [],
  reactions: const ReactionSummary(byEmoji: [], userReactions: []),
  mediaAttachments: const [],
  kind: 1,
);

SearchResult _result(String id, {DateTime? createdAt, int position = 0}) => SearchResult(
  message: _msg(id, createdAt: createdAt),
  highlightSpans: const [HighlightSpan(start: 0, end: 7)],
  position: BigInt.from(position),
);

void main() {
  group('buildSearchDisplayList', () {
    test('returns empty list when results are empty', () {
      final items = buildSearchDisplayList(
        results: [],
        contextWindows: [],
      );
      expect(items, isEmpty);
    });

    test('single match with context shows context before match', () {
      final ctx1 = _msg('c1');
      final ctx2 = _msg('c2');
      final match = _result('m1');

      final items = buildSearchDisplayList(
        results: [match],
        contextWindows: [
          [ctx1, ctx2, match.message],
        ],
      );

      expect(items.length, 3);
      expect(items[0].type, SearchDisplayItemType.context);
      expect(items[0].message!.id, 'c1');
      expect(items[1].type, SearchDisplayItemType.context);
      expect(items[1].message!.id, 'c2');
      expect(items[2].type, SearchDisplayItemType.match);
      expect(items[2].message!.id, 'm1');
      expect(items[2].matchIndex, 0);
      expect(items[2].highlightSpans, isNotEmpty);
    });

    test('two distant matches produce separator between groups', () {
      final result1 = _result('m1');
      final result2 = _result('m2');

      final items = buildSearchDisplayList(
        results: [result1, result2],
        contextWindows: [
          [_msg('a1'), result1.message],
          [_msg('b1'), result2.message],
        ],
      );

      expect(items.length, 5);
      expect(items[0].message!.id, 'a1');
      expect(items[1].message!.id, 'm1');
      expect(items[1].isMatch, isTrue);
      expect(items[2].isSeparator, isTrue);
      expect(items[3].message!.id, 'b1');
      expect(items[4].message!.id, 'm2');
      expect(items[4].isMatch, isTrue);
    });

    test('overlapping windows merge into one group', () {
      final shared = _msg('shared');
      final result1 = _result('m1');
      final result2 = _result('m2');

      final items = buildSearchDisplayList(
        results: [result1, result2],
        contextWindows: [
          [_msg('a1'), result1.message, shared],
          [shared, result2.message],
        ],
      );

      expect(items.where((i) => i.isSeparator).length, 0);
      final messages = items.where((i) => !i.isSeparator).toList();
      expect(messages.length, 4);
      expect(messages[0].message!.id, 'a1');
      expect(messages[1].message!.id, 'm1');
      expect(messages[1].isMatch, isTrue);
      expect(messages[2].message!.id, 'shared');
      expect(messages[3].message!.id, 'm2');
      expect(messages[3].isMatch, isTrue);
    });

    test('preserves match indices from original results list', () {
      final result1 = _result('m1');
      final result2 = _result('m2');

      final items = buildSearchDisplayList(
        results: [result1, result2],
        contextWindows: [
          [result1.message],
          [result2.message],
        ],
      );

      final matches = items.where((i) => i.isMatch).toList();
      expect(matches.length, 2);
      expect(matches[0].matchIndex, 0);
      expect(matches[1].matchIndex, 1);
    });

    test('separator has no message', () {
      final result1 = _result('m1');
      final result2 = _result('m2');

      final items = buildSearchDisplayList(
        results: [result1, result2],
        contextWindows: [
          [result1.message],
          [result2.message],
        ],
      );

      final separators = items.where((i) => i.isSeparator).toList();
      expect(separators.length, 1);
      expect(separators[0].message, isNull);
      expect(separators[0].highlightSpans, isNull);
      expect(separators[0].matchIndex, isNull);
    });

    test('empty context windows fall back to match-only items', () {
      final result1 = _result('m1');

      final items = buildSearchDisplayList(
        results: [result1],
        contextWindows: [[]],
      );

      expect(items.length, 1);
      expect(items[0].isMatch, isTrue);
      expect(items[0].message!.id, 'm1');
    });

    test('match-only with no context windows falls back correctly', () {
      final result1 = _result('m1');
      final result2 = _result('m2');

      final items = buildSearchDisplayList(
        results: [result1, result2],
        contextWindows: [],
      );

      expect(items.length, 3);
      expect(items[0].isMatch, isTrue);
      expect(items[0].message!.id, 'm1');
      expect(items[1].isSeparator, isTrue);
      expect(items[2].isMatch, isTrue);
      expect(items[2].message!.id, 'm2');
    });
  });
}
