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
  group('filterChatsBySearch', () {
    group('empty query', () {
      test('returns all chats when query is empty', () {
        expect(filterChatsBySearch(_chats, ''), _chats);
      });
    });

    group('name matching', () {
      test('filters by exact name match', () {
        final results = filterChatsBySearch(_chats, 'Alice');
        expect(results.length, 1);
        expect(results.first.mlsGroupId, 'd1');
      });

      test('filters by partial name match', () {
        final results = filterChatsBySearch(_chats, 'Team');
        expect(results.length, 2);
        expect(results.map((c) => c.mlsGroupId).toList(), ['g1', 'g2']);
      });

      test('is case-insensitive', () {
        final results = filterChatsBySearch(_chats, 'alice');
        expect(results.length, 1);
        expect(results.first.mlsGroupId, 'd1');
      });

      test('returns empty list when no matches', () {
        expect(filterChatsBySearch(_chats, 'Zorro'), isEmpty);
      });

      test('excludes chats with null name', () {
        final results = filterChatsBySearch(_chats, 'Engineering');
        expect(results.every((c) => c.name != null), isTrue);
      });
    });

    group('edge cases', () {
      test('returns empty list when chats list is empty', () {
        expect(filterChatsBySearch([], 'Alice'), isEmpty);
      });

      test('preserves original order of matches', () {
        final results = filterChatsBySearch(_chats, 'Team');
        expect(results.first.mlsGroupId, 'g1');
        expect(results.last.mlsGroupId, 'g2');
      });

      test('matches DM chats by peer display name', () {
        final results = filterChatsBySearch(_chats, 'Bob');
        expect(results.length, 1);
        expect(results.first.groupType, GroupType.directMessage);
      });

      test('matches group chats by group name', () {
        final results = filterChatsBySearch(_chats, 'Engineering');
        expect(results.length, 1);
        expect(results.first.groupType, GroupType.group);
      });
    });
  });

  group('filterChatsBySearchWithMessageMatches', () {
    test('returns all chats when query is empty', () {
      final results = filterChatsBySearchWithMessageMatches(_chats, '', {'g1'});
      expect(results, _chats);
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
