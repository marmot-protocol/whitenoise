import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/src/rust/api/messages.dart';
import 'package:whitenoise/utils/chat_messages_search.dart';

ChatMessage _message({
  required String id,
  required String content,
  bool isDeleted = false,
}) => ChatMessage(
  id: id,
  pubkey: 'a' * 64,
  content: content,
  createdAt: DateTime(2024),
  tags: const [],
  isReply: false,
  isDeleted: isDeleted,
  contentTokens: const [],
  reactions: const ReactionSummary(byEmoji: [], userReactions: []),
  mediaAttachments: const [],
  kind: 1,
);

final _messages = [
  _message(id: 'm1', content: 'Hello world'),
  _message(id: 'm2', content: 'Good morning everyone'),
  _message(id: 'm3', content: 'Hello again'),
  _message(id: 'm4', content: 'Deleted message', isDeleted: true),
  _message(id: 'm5', content: 'Flutter is great'),
];

void main() {
  group('filterMessagesBySearch', () {
    group('empty query', () {
      test('returns all non-deleted messages when query is empty', () {
        final results = filterMessagesBySearch(_messages, '');
        expect(results.length, 4);
        expect(results.any((m) => m.isDeleted), isFalse);
      });
    });

    group('content matching', () {
      test('filters by exact content match', () {
        final results = filterMessagesBySearch(_messages, 'Flutter is great');
        expect(results.length, 1);
        expect(results.first.id, 'm5');
      });

      test('filters by partial content match', () {
        final results = filterMessagesBySearch(_messages, 'Hello');
        expect(results.length, 2);
        expect(results.map((m) => m.id).toList(), ['m1', 'm3']);
      });

      test('is case-insensitive', () {
        final results = filterMessagesBySearch(_messages, 'hello');
        expect(results.length, 2);
        expect(results.map((m) => m.id).toList(), ['m1', 'm3']);
      });

      test('returns empty list when no matches', () {
        expect(filterMessagesBySearch(_messages, 'zzznomatch'), isEmpty);
      });
    });

    group('deleted messages', () {
      test('excludes deleted messages from results', () {
        final results = filterMessagesBySearch(_messages, 'Deleted');
        expect(results, isEmpty);
      });

      test('excludes deleted messages even when query is empty', () {
        final results = filterMessagesBySearch(_messages, '');
        expect(results.any((m) => m.isDeleted), isFalse);
      });
    });

    group('edge cases', () {
      test('returns empty list when messages list is empty', () {
        expect(filterMessagesBySearch([], 'hello'), isEmpty);
      });

      test('preserves original order of matches', () {
        final results = filterMessagesBySearch(_messages, 'Hello');
        expect(results.first.id, 'm1');
        expect(results.last.id, 'm3');
      });
    });
  });
}
