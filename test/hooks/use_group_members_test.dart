import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/hooks/use_group_members.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

Group _testGroup() {
  return Group(
    mlsGroupId: testGroupId,
    nostrGroupId: testNostrGroupId,
    name: 'Test Group',
    description: 'A test group',
    adminPubkeys: [testPubkeyA],
    epoch: BigInt.zero,
    state: GroupState.active,
  );
}

class _MockApi extends MockWnApi {
  Completer<List<String>>? membersCompleter;
  Completer<List<String>>? adminsCompleter;
  Completer<void>? addMembersCompleter;
  Completer<void>? removeMembersCompleter;
  Completer<void>? updateGroupDataCompleter;
  Exception? membersError;
  Exception? adminsError;
  Exception? addMembersError;
  Exception? removeMembersError;
  Exception? updateGroupDataError;
  List<String> membersList = [];
  List<String> adminsList = [];
  final membersCalls = <({String pubkey, String groupId})>[];
  final adminsCalls = <({String pubkey, String groupId})>[];
  final addMembersCalls = <({String pubkey, String groupId, List<String> members})>[];
  final removeMembersCalls = <({String pubkey, String groupId, List<String> members})>[];
  final updateGroupDataCalls =
      <({Group group, String accountPubkey, FlutterGroupDataUpdate data})>[];

  @override
  Future<List<String>> crateApiGroupsGroupMembers({
    required String pubkey,
    required String groupId,
  }) async {
    membersCalls.add((pubkey: pubkey, groupId: groupId));
    if (membersError != null) throw membersError!;
    if (membersCompleter != null) return membersCompleter!.future;
    return membersList;
  }

  @override
  Future<List<String>> crateApiGroupsGroupAdmins({
    required String pubkey,
    required String groupId,
  }) async {
    adminsCalls.add((pubkey: pubkey, groupId: groupId));
    if (adminsError != null) throw adminsError!;
    if (adminsCompleter != null) return adminsCompleter!.future;
    return adminsList;
  }

  @override
  Future<Group> crateApiGroupsGetGroup({
    required String accountPubkey,
    required String groupId,
  }) async {
    return _testGroup();
  }

  @override
  Future<void> crateApiGroupsAddMembersToGroup({
    required String pubkey,
    required String groupId,
    required List<String> memberPubkeys,
  }) async {
    addMembersCalls.add((pubkey: pubkey, groupId: groupId, members: memberPubkeys));
    if (addMembersCompleter != null) await addMembersCompleter!.future;
    if (addMembersError != null) throw addMembersError!;
  }

  @override
  Future<void> crateApiGroupsRemoveMembersFromGroup({
    required String pubkey,
    required String groupId,
    required List<String> memberPubkeys,
  }) async {
    removeMembersCalls.add((pubkey: pubkey, groupId: groupId, members: memberPubkeys));
    if (removeMembersCompleter != null) await removeMembersCompleter!.future;
    if (removeMembersError != null) throw removeMembersError!;
  }

  @override
  Future<void> crateApiGroupsGroupUpdateGroupData({
    required Group that,
    required String accountPubkey,
    required FlutterGroupDataUpdate groupData,
  }) async {
    updateGroupDataCalls.add((group: that, accountPubkey: accountPubkey, data: groupData));
    if (updateGroupDataCompleter != null) await updateGroupDataCompleter!.future;
    if (updateGroupDataError != null) throw updateGroupDataError!;
  }

  @override
  void reset() {
    super.reset();
    membersCompleter = null;
    adminsCompleter = null;
    addMembersCompleter = null;
    removeMembersCompleter = null;
    updateGroupDataCompleter = null;
    membersError = null;
    adminsError = null;
    addMembersError = null;
    removeMembersError = null;
    updateGroupDataError = null;
    membersList = [];
    adminsList = [];
    membersCalls.clear();
    adminsCalls.clear();
    addMembersCalls.clear();
    removeMembersCalls.clear();
    updateGroupDataCalls.clear();
  }
}

final _api = _MockApi();

void main() {
  late GroupMembersState Function() getState;

  setUpAll(() => RustLib.initMock(api: _api));
  setUp(() => _api.reset());

  Future<void> pump(
    WidgetTester tester, {
    required String accountPubkey,
    required String groupId,
  }) async {
    getState = await mountHook(
      tester,
      () => useGroupMembers(
        accountPubkey: accountPubkey,
        groupId: groupId,
      ),
    );
  }

  group('useGroupMembers', () {
    group('loading state', () {
      testWidgets('isLoading is true while fetching', (tester) async {
        _api.membersCompleter = Completer();
        _api.adminsCompleter = Completer();
        await pump(tester, accountPubkey: testPubkeyA, groupId: testGroupId);

        expect(getState().isLoading, isTrue);
        expect(getState().members, isEmpty);
        expect(getState().admins, isEmpty);
      });

      testWidgets('isLoading becomes false after fetch completes', (tester) async {
        _api.membersList = [testPubkeyB, testPubkeyC];
        _api.adminsList = [testPubkeyA];
        await pump(tester, accountPubkey: testPubkeyA, groupId: testGroupId);
        await tester.pumpAndSettle();

        expect(getState().isLoading, isFalse);
        expect(getState().members, [testPubkeyB, testPubkeyC]);
        expect(getState().admins, [testPubkeyA]);
      });
    });

    group('fetch members and admins', () {
      testWidgets('calls API with correct parameters', (tester) async {
        await pump(tester, accountPubkey: testPubkeyA, groupId: testGroupId);
        await tester.pumpAndSettle();

        expect(_api.membersCalls.length, 1);
        expect(_api.membersCalls[0].pubkey, testPubkeyA);
        expect(_api.membersCalls[0].groupId, testGroupId);
        expect(_api.adminsCalls.length, 1);
        expect(_api.adminsCalls[0].pubkey, testPubkeyA);
        expect(_api.adminsCalls[0].groupId, testGroupId);
      });

      testWidgets('sets error when fetch fails', (tester) async {
        _api.membersError = Exception('Network error');
        await pump(tester, accountPubkey: testPubkeyA, groupId: testGroupId);
        await tester.pumpAndSettle();

        expect(getState().isLoading, isFalse);
        expect(getState().error, 'failedToFetchGroupMembers');
      });

      testWidgets('returns empty lists initially', (tester) async {
        await pump(tester, accountPubkey: testPubkeyA, groupId: testGroupId);
        await tester.pumpAndSettle();

        expect(getState().members, isEmpty);
        expect(getState().admins, isEmpty);
      });
    });

    group('addMembers', () {
      testWidgets('calls API with correct parameters', (tester) async {
        _api.membersList = [testPubkeyA];
        await pump(tester, accountPubkey: testPubkeyA, groupId: testGroupId);
        await tester.pumpAndSettle();

        await getState().addMembers([testPubkeyB, testPubkeyC]);
        await tester.pump();

        expect(_api.addMembersCalls.length, 1);
        expect(_api.addMembersCalls[0].pubkey, testPubkeyA);
        expect(_api.addMembersCalls[0].groupId, testGroupId);
        expect(_api.addMembersCalls[0].members, [testPubkeyB, testPubkeyC]);
      });

      testWidgets('updates members list after adding', (tester) async {
        _api.membersList = [testPubkeyA];
        await pump(tester, accountPubkey: testPubkeyA, groupId: testGroupId);
        await tester.pumpAndSettle();

        expect(getState().members, [testPubkeyA]);

        await getState().addMembers([testPubkeyB]);
        await tester.pump();

        expect(getState().members, [testPubkeyA, testPubkeyB]);
      });

      testWidgets('deduplicates when adding existing members', (tester) async {
        _api.membersList = [testPubkeyA, testPubkeyB];
        await pump(tester, accountPubkey: testPubkeyA, groupId: testGroupId);
        await tester.pumpAndSettle();

        await getState().addMembers([testPubkeyB, testPubkeyC]);
        await tester.pump();

        expect(getState().members, [testPubkeyA, testPubkeyB, testPubkeyC]);
      });

      testWidgets('isActionLoading is true during add', (tester) async {
        _api.addMembersCompleter = Completer();
        await pump(tester, accountPubkey: testPubkeyA, groupId: testGroupId);
        await tester.pumpAndSettle();

        final future = getState().addMembers([testPubkeyB]);
        await tester.pump();

        expect(getState().isActionLoading, isTrue);

        _api.addMembersCompleter!.complete();
        await future;
        await tester.pump();

        expect(getState().isActionLoading, isFalse);
      });

      testWidgets('sets error on failure', (tester) async {
        _api.addMembersError = Exception('Failed');
        await pump(tester, accountPubkey: testPubkeyA, groupId: testGroupId);
        await tester.pumpAndSettle();

        await getState().addMembers([testPubkeyB]);
        await tester.pump();

        expect(getState().error, 'failedToAddMembers');
      });
    });

    group('removeMembers', () {
      testWidgets('calls API with correct parameters', (tester) async {
        _api.membersList = [testPubkeyA, testPubkeyB, testPubkeyC];
        await pump(tester, accountPubkey: testPubkeyA, groupId: testGroupId);
        await tester.pumpAndSettle();

        await getState().removeMembers([testPubkeyB]);
        await tester.pump();

        expect(_api.removeMembersCalls.length, 1);
        expect(_api.removeMembersCalls[0].pubkey, testPubkeyA);
        expect(_api.removeMembersCalls[0].groupId, testGroupId);
        expect(_api.removeMembersCalls[0].members, [testPubkeyB]);
      });

      testWidgets('updates members list after removing', (tester) async {
        _api.membersList = [testPubkeyA, testPubkeyB, testPubkeyC];
        await pump(tester, accountPubkey: testPubkeyA, groupId: testGroupId);
        await tester.pumpAndSettle();

        expect(getState().members, [testPubkeyA, testPubkeyB, testPubkeyC]);

        await getState().removeMembers([testPubkeyB]);
        await tester.pump();

        expect(getState().members, [testPubkeyA, testPubkeyC]);
      });

      testWidgets('isActionLoading is true during remove', (tester) async {
        _api.removeMembersCompleter = Completer();
        _api.membersList = [testPubkeyA, testPubkeyB];
        await pump(tester, accountPubkey: testPubkeyA, groupId: testGroupId);
        await tester.pumpAndSettle();

        final future = getState().removeMembers([testPubkeyB]);
        await tester.pump();

        expect(getState().isActionLoading, isTrue);

        _api.removeMembersCompleter!.complete();
        await future;
        await tester.pump();

        expect(getState().isActionLoading, isFalse);
      });

      testWidgets('sets error on failure', (tester) async {
        _api.removeMembersError = Exception('Failed');
        _api.membersList = [testPubkeyA, testPubkeyB];
        await pump(tester, accountPubkey: testPubkeyA, groupId: testGroupId);
        await tester.pumpAndSettle();

        await getState().removeMembers([testPubkeyB]);
        await tester.pump();

        expect(getState().error, 'failedToRemoveFromGroup');
      });
    });

    group('makeAdmin', () {
      testWidgets('calls updateGroupData with new admin list', (tester) async {
        _api.adminsList = [testPubkeyA];
        _api.membersList = [testPubkeyA, testPubkeyB];
        await pump(tester, accountPubkey: testPubkeyA, groupId: testGroupId);
        await tester.pumpAndSettle();

        await getState().makeAdmin(testPubkeyB);
        await tester.pump();

        expect(_api.updateGroupDataCalls.length, 1);
        expect(_api.updateGroupDataCalls[0].accountPubkey, testPubkeyA);
        expect(_api.updateGroupDataCalls[0].data.admins, [testPubkeyA, testPubkeyB]);
      });

      testWidgets('updates admins list after making admin', (tester) async {
        _api.adminsList = [testPubkeyA];
        _api.membersList = [testPubkeyA, testPubkeyB];
        await pump(tester, accountPubkey: testPubkeyA, groupId: testGroupId);
        await tester.pumpAndSettle();

        expect(getState().admins, [testPubkeyA]);

        await getState().makeAdmin(testPubkeyB);
        await tester.pump();

        expect(getState().admins, [testPubkeyA, testPubkeyB]);
      });

      testWidgets('deduplicates when making existing admin', (tester) async {
        _api.adminsList = [testPubkeyA, testPubkeyB];
        _api.membersList = [testPubkeyA, testPubkeyB];
        await pump(tester, accountPubkey: testPubkeyA, groupId: testGroupId);
        await tester.pumpAndSettle();

        await getState().makeAdmin(testPubkeyB);
        await tester.pump();

        expect(getState().admins, [testPubkeyA, testPubkeyB]);
      });

      testWidgets('isActionLoading is true during makeAdmin', (tester) async {
        _api.updateGroupDataCompleter = Completer();
        _api.adminsList = [testPubkeyA];
        await pump(tester, accountPubkey: testPubkeyA, groupId: testGroupId);
        await tester.pumpAndSettle();

        final future = getState().makeAdmin(testPubkeyB);
        await tester.pump();

        expect(getState().isActionLoading, isTrue);

        _api.updateGroupDataCompleter!.complete();
        await future;
        await tester.pump();

        expect(getState().isActionLoading, isFalse);
      });

      testWidgets('sets error on failure', (tester) async {
        _api.updateGroupDataError = Exception('Failed');
        _api.adminsList = [testPubkeyA];
        await pump(tester, accountPubkey: testPubkeyA, groupId: testGroupId);
        await tester.pumpAndSettle();

        await getState().makeAdmin(testPubkeyB);
        await tester.pump();

        expect(getState().error, 'failedToMakeAdmin');
      });
    });

    group('removeAdmin', () {
      testWidgets('calls updateGroupData with updated admin list', (tester) async {
        _api.adminsList = [testPubkeyA, testPubkeyB];
        _api.membersList = [testPubkeyA, testPubkeyB];
        await pump(tester, accountPubkey: testPubkeyA, groupId: testGroupId);
        await tester.pumpAndSettle();

        await getState().removeAdmin(testPubkeyB);
        await tester.pump();

        expect(_api.updateGroupDataCalls.length, 1);
        expect(_api.updateGroupDataCalls[0].data.admins, [testPubkeyA]);
      });

      testWidgets('updates admins list after removing admin', (tester) async {
        _api.adminsList = [testPubkeyA, testPubkeyB];
        _api.membersList = [testPubkeyA, testPubkeyB];
        await pump(tester, accountPubkey: testPubkeyA, groupId: testGroupId);
        await tester.pumpAndSettle();

        expect(getState().admins, [testPubkeyA, testPubkeyB]);

        await getState().removeAdmin(testPubkeyB);
        await tester.pump();

        expect(getState().admins, [testPubkeyA]);
      });

      testWidgets('isActionLoading is true during removeAdmin', (tester) async {
        _api.updateGroupDataCompleter = Completer();
        _api.adminsList = [testPubkeyA, testPubkeyB];
        await pump(tester, accountPubkey: testPubkeyA, groupId: testGroupId);
        await tester.pumpAndSettle();

        final future = getState().removeAdmin(testPubkeyB);
        await tester.pump();

        expect(getState().isActionLoading, isTrue);

        _api.updateGroupDataCompleter!.complete();
        await future;
        await tester.pump();

        expect(getState().isActionLoading, isFalse);
      });

      testWidgets('sets error on failure', (tester) async {
        _api.updateGroupDataError = Exception('Failed');
        _api.adminsList = [testPubkeyA, testPubkeyB];
        await pump(tester, accountPubkey: testPubkeyA, groupId: testGroupId);
        await tester.pumpAndSettle();

        await getState().removeAdmin(testPubkeyB);
        await tester.pump();

        expect(getState().error, 'failedToRemoveAdmin');
      });
    });

    group('clearError', () {
      testWidgets('clears error state', (tester) async {
        _api.addMembersError = Exception('Failed');
        await pump(tester, accountPubkey: testPubkeyA, groupId: testGroupId);
        await tester.pumpAndSettle();

        await getState().addMembers([testPubkeyB]);
        await tester.pump();

        expect(getState().error, isNotNull);

        getState().clearError();
        await tester.pump();

        expect(getState().error, isNull);
      });
    });
  });
}
