import 'dart:async';

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart' show PlatformInt64Util;
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/hooks/use_groups.dart';
import 'package:whitenoise/src/rust/api/account_groups.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';

import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

GroupWithInfoAndMembership _makeGroupWithInfo({
  required String id,
  String name = 'Test Group',
  String description = '',
  GroupType groupType = GroupType.group,
  GroupState groupState = GroupState.active,
}) {
  final now = DateTime.utc(2024);
  return GroupWithInfoAndMembership(
    group: Group(
      mlsGroupId: id,
      nostrGroupId: 'nostr_$id',
      name: name,
      description: description,
      adminPubkeys: [testPubkeyA],
      epoch: BigInt.zero,
      state: groupState,
    ),
    info: GroupInformation(
      mlsGroupId: id,
      groupType: groupType,
      createdAt: now,
      updatedAt: now,
    ),
    membership: AccountGroup(
      accountPubkey: testPubkeyA,
      mlsGroupId: id,
      createdAt: PlatformInt64Util.from(0),
      updatedAt: PlatformInt64Util.from(0),
    ),
  );
}

class _MockApi extends MockWnApi {
  List<GroupWithInfoAndMembership> groupsList = [];
  Exception? fetchError;
  Completer<List<GroupWithInfoAndMembership>>? fetchCompleter;

  @override
  Future<List<GroupWithInfoAndMembership>> crateApiGroupsVisibleGroupsWithInfo({
    required String accountPubkey,
  }) async {
    if (fetchCompleter != null) return fetchCompleter!.future;
    if (fetchError != null) throw fetchError!;
    return groupsList;
  }

  @override
  void reset() {
    super.reset();
    groupsList = [];
    fetchError = null;
    fetchCompleter = null;
  }
}

final _api = _MockApi();

void main() {
  setUpAll(() => RustLib.initMock(api: _api));
  setUp(() => _api.reset());

  group('useGroups', () {
    testWidgets('starts with isLoading true', (tester) async {
      _api.fetchCompleter = Completer();
      late GroupsState result;
      await mountHook(tester, () {
        result = useGroups(accountPubkey: testPubkeyA);
        return null;
      });
      expect(result.isLoading, isTrue);
    });

    testWidgets('isLoading becomes false after fetch completes', (tester) async {
      late GroupsState result;
      await mountHook(tester, () {
        result = useGroups(accountPubkey: testPubkeyA);
        return null;
      });
      await tester.pumpAndSettle();
      expect(result.isLoading, isFalse);
    });

    testWidgets('returns empty list when no groups', (tester) async {
      late GroupsState result;
      await mountHook(tester, () {
        result = useGroups(accountPubkey: testPubkeyA);
        return null;
      });
      await tester.pumpAndSettle();
      expect(result.groups, isEmpty);
    });

    testWidgets('returns non-DM groups', (tester) async {
      _api.groupsList = [
        _makeGroupWithInfo(id: testGroupId, name: 'Group A'),
        _makeGroupWithInfo(id: otherTestGroupId, name: 'Group B'),
      ];

      late GroupsState result;
      await mountHook(tester, () {
        result = useGroups(accountPubkey: testPubkeyA);
        return null;
      });
      await tester.pumpAndSettle();

      expect(result.groups, hasLength(2));
      expect(result.groups.map((g) => g.name), containsAll(['Group A', 'Group B']));
    });

    testWidgets('filters out DM groups', (tester) async {
      _api.groupsList = [
        _makeGroupWithInfo(id: testGroupId, name: 'DM Group', groupType: GroupType.directMessage),
      ];

      late GroupsState result;
      await mountHook(tester, () {
        result = useGroups(accountPubkey: testPubkeyA);
        return null;
      });
      await tester.pumpAndSettle();

      expect(result.groups, isEmpty);
    });

    testWidgets('sets error key on fetch failure', (tester) async {
      _api.fetchError = Exception('Network error');

      late GroupsState result;
      await mountHook(tester, () {
        result = useGroups(accountPubkey: testPubkeyA);
        return null;
      });
      await tester.pumpAndSettle();

      expect(result.error, 'groupLoadError');
    });

    testWidgets('clearError clears the error', (tester) async {
      _api.fetchError = Exception('Network error');

      late GroupsState result;
      await mountHook(tester, () {
        result = useGroups(accountPubkey: testPubkeyA);
        return null;
      });
      await tester.pumpAndSettle();

      expect(result.error, isNotNull);
      result.clearError();
      await tester.pump();
      expect(result.error, isNull);
    });

    testWidgets('refresh re-fetches groups', (tester) async {
      late GroupsState result;
      await mountHook(tester, () {
        result = useGroups(accountPubkey: testPubkeyA);
        return null;
      });
      await tester.pumpAndSettle();
      expect(result.groups, isEmpty);

      _api.groupsList = [_makeGroupWithInfo(id: testGroupId, name: 'New Group')];
      await result.refresh();
      await tester.pumpAndSettle();

      expect(result.groups, hasLength(1));
      expect(result.groups.first.name, 'New Group');
    });

    testWidgets('error is null on successful fetch', (tester) async {
      _api.groupsList = [_makeGroupWithInfo(id: testGroupId)];

      late GroupsState result;
      await mountHook(tester, () {
        result = useGroups(accountPubkey: testPubkeyA);
        return null;
      });
      await tester.pumpAndSettle();

      expect(result.error, isNull);
    });

    testWidgets('does not return inactive groups', (tester) async {
      _api.groupsList = [
        _makeGroupWithInfo(id: testGroupId, name: 'Active Group'),
        _makeGroupWithInfo(
          id: otherTestGroupId,
          name: 'Inactive Group',
          groupState: GroupState.inactive,
        ),
      ];

      late GroupsState result;
      await mountHook(tester, () {
        result = useGroups(accountPubkey: testPubkeyA);
        return null;
      });
      await tester.pumpAndSettle();

      expect(result.groups.map((g) => g.name), isNot(contains('Inactive Group')));
    });

    testWidgets('does not return pending groups', (tester) async {
      _api.groupsList = [
        _makeGroupWithInfo(id: testGroupId, name: 'Active Group'),
        _makeGroupWithInfo(
          id: otherTestGroupId,
          name: 'Pending Group',
          groupState: GroupState.pending,
        ),
      ];

      late GroupsState result;
      await mountHook(tester, () {
        result = useGroups(accountPubkey: testPubkeyA);
        return null;
      });
      await tester.pumpAndSettle();

      expect(result.groups.map((g) => g.name), isNot(contains('Pending Group')));
    });
  });
}
