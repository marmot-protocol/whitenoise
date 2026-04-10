import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/src/rust/api/chat_list.dart';
import 'package:whitenoise/src/rust/api/groups.dart' show GroupType;
import 'package:whitenoise/utils/chat_search.dart';

ChatSummary _chatSummary({required String id, String? name, GroupType? groupType}) => ChatSummary(
  mlsGroupId: id,
  name: name,
  groupType: groupType ?? GroupType.group,
  createdAt: DateTime(2024),
  pendingConfirmation: false,
  unreadCount: BigInt.zero,
);

final _chats = [
  _chatSummary(id: 'g1', name: 'Engineering Team', groupType: GroupType.group),
  _chatSummary(id: 'g2', name: 'Design Team', groupType: GroupType.group),
  _chatSummary(id: 'd1', name: 'Alice', groupType: GroupType.directMessage),
  _chatSummary(id: 'd2', name: 'Bob', groupType: GroupType.directMessage),
  _chatSummary(id: 'g3', groupType: GroupType.group),
];

void main() {
  group('filterChatsBySearchWithMessageMatches', () {
    test('returns all chats when query is empty', () {
      final results = filterChatsBySearchWithMessageMatches(_chats, '', {'g1'});
      expect(results, _chats);
    });

    test('returns all chats when query is whitespace only', () {
      final results = filterChatsBySearchWithMessageMatches(_chats, '   ', {'g1'});
      expect(results, _chats);
    });

    test('trims whitespace around query before matching', () {
      final results = filterChatsBySearchWithMessageMatches(
        _chats,
        '  Alice  ',
        <String>{},
      );
      expect(results.length, 1);
      expect(results.first.mlsGroupId, 'd1');
    });

    test('matches by name only', () {
      final results = filterChatsBySearchWithMessageMatches(
        _chats,
        'Alice',
        <String>{},
      );
      expect(results.length, 1);
      expect(results.first.mlsGroupId, 'd1');
    });

    test('matches by messageMatchedGroupIds even if name does not match', () {
      final results = filterChatsBySearchWithMessageMatches(
        _chats,
        'Zorro',
        {'g2', 'd2'},
      );
      expect(results.length, 2);
      expect(results.map((c) => c.mlsGroupId).toSet(), {'g2', 'd2'});
    });

    test('matches by both name and message content without duplicates', () {
      final results = filterChatsBySearchWithMessageMatches(
        _chats,
        'Alice',
        {'d1', 'g1'},
      );
      expect(results.length, 2);
      expect(results.map((c) => c.mlsGroupId).toSet(), {'d1', 'g1'});
    });

    test('returns empty when nothing matches', () {
      final results = filterChatsBySearchWithMessageMatches(
        _chats,
        'Zorro',
        <String>{},
      );
      expect(results, isEmpty);
    });

    test('preserves original order', () {
      final results = filterChatsBySearchWithMessageMatches(
        _chats,
        'xyzzy',
        {'d2', 'g1'},
      );
      expect(results.first.mlsGroupId, 'g1');
      expect(results.last.mlsGroupId, 'd2');
    });
  });
}
