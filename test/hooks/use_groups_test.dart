import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/hooks/use_groups.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';

import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

Group _makeGroup({
  required String id,
  String name = 'Test Group',
  String description = '',
}) => Group(
  mlsGroupId: id,
  nostrGroupId: 'nostr_$id',
  name: name,
  description: description,
  adminPubkeys: [testPubkeyA],
  epoch: BigInt.zero,
  state: GroupState.active,
);

class _MockApi extends MockWnApi {
  List<Group> groupsList = [];
  bool isDmResult = false;
  Exception? activeGroupsError;
  Completer<List<Group>>? activeGroupsCompleter;

  @override
  Future<List<Group>> crateApiGroupsActiveGroups({required String pubkey}) async {
    if (activeGroupsCompleter != null) return activeGroupsCompleter!.future;
    if (activeGroupsError != null) throw activeGroupsError!;
    return groupsList;
  }

  @override
  Future<bool> crateApiGroupsGroupIsDirectMessageType({
    required Group that,
    required String accountPubkey,
  }) async {
    return isDmResult;
  }

  @override
  void reset() {
    super.reset();
    groupsList = [];
    isDmResult = false;
    activeGroupsError = null;
    activeGroupsCompleter = null;
  }
}

final _api = _MockApi();

void main() {
  setUpAll(() => RustLib.initMock(api: _api));
  setUp(() => _api.reset());

  group('useGroups', () {
    testWidgets('starts with isLoading true', (tester) async {
      _api.activeGroupsCompleter = Completer();
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
        _makeGroup(id: testGroupId, name: 'Group A'),
        _makeGroup(id: otherTestGroupId, name: 'Group B'),
      ];
      _api.isDmResult = false;

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
      _api.groupsList = [_makeGroup(id: testGroupId, name: 'DM Group')];
      _api.isDmResult = true;

      late GroupsState result;
      await mountHook(tester, () {
        result = useGroups(accountPubkey: testPubkeyA);
        return null;
      });
      await tester.pumpAndSettle();

      expect(result.groups, isEmpty);
    });

    testWidgets('sets error key on fetch failure', (tester) async {
      _api.activeGroupsError = Exception('Network error');

      late GroupsState result;
      await mountHook(tester, () {
        result = useGroups(accountPubkey: testPubkeyA);
        return null;
      });
      await tester.pumpAndSettle();

      expect(result.error, 'groupLoadError');
    });

    testWidgets('clearError clears the error', (tester) async {
      _api.activeGroupsError = Exception('Network error');

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

      _api.groupsList = [_makeGroup(id: testGroupId, name: 'New Group')];
      await result.refresh();
      await tester.pumpAndSettle();

      expect(result.groups, hasLength(1));
      expect(result.groups.first.name, 'New Group');
    });

    testWidgets('error is null on successful fetch', (tester) async {
      _api.groupsList = [_makeGroup(id: testGroupId)];

      late GroupsState result;
      await mountHook(tester, () {
        result = useGroups(accountPubkey: testPubkeyA);
        return null;
      });
      await tester.pumpAndSettle();

      expect(result.error, isNull);
    });
  });
}
