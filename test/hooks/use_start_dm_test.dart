import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/hooks/use_start_dm.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';

import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

const _accountPubkey = testPubkeyA;
const _peerPubkey = testPubkeyB;
const _existingGroupId = testGroupId;
const _newGroupId = otherTestGroupId;

class _MockApi extends MockWnApi {
  String? dmGroupWithPeerResult;
  Exception? dmGroupWithPeerError;
  Completer<String?>? dmGroupWithPeerCompleter;
  int dmGroupWithPeerCallCount = 0;

  Group? createdGroup;
  Exception? createGroupError;
  Completer<Group>? createGroupCompleter;
  final createGroupCalls =
      <({String creatorPubkey, List<String> memberPubkeys, GroupType groupType})>[];

  @override
  Future<String?> crateApiAccountGroupsGetDmGroupWithPeer({
    required String accountPubkey,
    required String peerPubkey,
  }) async {
    dmGroupWithPeerCallCount++;
    if (dmGroupWithPeerCompleter != null) return dmGroupWithPeerCompleter!.future;
    if (dmGroupWithPeerError != null) throw dmGroupWithPeerError!;
    return dmGroupWithPeerResult;
  }

  @override
  Future<Group> crateApiGroupsCreateGroup({
    required String creatorPubkey,
    required List<String> memberPubkeys,
    required List<String> adminPubkeys,
    required String groupName,
    required String groupDescription,
    required GroupType groupType,
  }) async {
    createGroupCalls.add((
      creatorPubkey: creatorPubkey,
      memberPubkeys: memberPubkeys,
      groupType: groupType,
    ));
    if (createGroupCompleter != null) return createGroupCompleter!.future;
    if (createGroupError != null) throw createGroupError!;
    return createdGroup ??
        Group(
          mlsGroupId: _newGroupId,
          nostrGroupId: testNostrGroupId,
          name: '',
          description: '',
          adminPubkeys: const [],
          epoch: BigInt.zero,
          state: GroupState.active,
        );
  }

  @override
  void reset() {
    super.reset();
    dmGroupWithPeerResult = null;
    dmGroupWithPeerError = null;
    dmGroupWithPeerCompleter = null;
    dmGroupWithPeerCallCount = 0;
    createdGroup = null;
    createGroupError = null;
    createGroupCompleter = null;
    createGroupCalls.clear();
  }
}

final _api = _MockApi();

void main() {
  setUpAll(() => RustLib.initMock(api: _api));
  setUp(() => _api.reset());

  group('useStartDm', () {
    testWidgets('initial state has isLoading false', (tester) async {
      final getResult = await mountHook(
        tester,
        () => useStartDm(accountPubkey: _accountPubkey, peerPubkey: _peerPubkey),
      );

      final state = getResult();
      expect(state.isLoading, isFalse);
    });

    testWidgets('returns existing DM groupId when DM already exists', (tester) async {
      _api.dmGroupWithPeerResult = _existingGroupId;

      final getResult = await mountHook(
        tester,
        () => useStartDm(accountPubkey: _accountPubkey, peerPubkey: _peerPubkey),
      );

      final state = getResult();
      final groupId = await state.startDm();

      expect(groupId, _existingGroupId);
      expect(_api.createGroupCalls, isEmpty);
      expect(_api.dmGroupWithPeerCallCount, 1);
    });

    testWidgets('creates new DM when no existing DM found', (tester) async {
      final getResult = await mountHook(
        tester,
        () => useStartDm(accountPubkey: _accountPubkey, peerPubkey: _peerPubkey),
      );

      final state = getResult();
      final groupId = await state.startDm();

      expect(groupId, _newGroupId);
      expect(_api.createGroupCalls.length, 1);
      expect(_api.createGroupCalls[0].creatorPubkey, _accountPubkey);
      expect(_api.createGroupCalls[0].memberPubkeys, [_peerPubkey]);
      expect(_api.createGroupCalls[0].groupType, GroupType.directMessage);
    });

    testWidgets('rethrows error when getDmGroupWithPeer fails', (tester) async {
      _api.dmGroupWithPeerError = Exception('Network error');

      final getResult = await mountHook(
        tester,
        () => useStartDm(accountPubkey: _accountPubkey, peerPubkey: _peerPubkey),
      );

      final state = getResult();
      expect(() => state.startDm(), throwsException);
    });

    testWidgets('rethrows error when createGroup fails', (tester) async {
      _api.createGroupError = Exception('Network error');

      final getResult = await mountHook(
        tester,
        () => useStartDm(accountPubkey: _accountPubkey, peerPubkey: _peerPubkey),
      );

      final state = getResult();
      expect(() => state.startDm(), throwsException);
    });

    testWidgets('sets isLoading during startDm execution', (tester) async {
      _api.dmGroupWithPeerCompleter = Completer();

      final getResult = await mountHook(
        tester,
        () => useStartDm(accountPubkey: _accountPubkey, peerPubkey: _peerPubkey),
      );

      expect(getResult().isLoading, isFalse);

      final future = getResult().startDm();
      await tester.pump();

      expect(getResult().isLoading, isTrue);

      _api.dmGroupWithPeerCompleter!.complete(null);
      await future;
      await tester.pump();

      expect(getResult().isLoading, isFalse);
    });

    testWidgets('resets isLoading on error', (tester) async {
      _api.dmGroupWithPeerError = Exception('fail');

      final getResult = await mountHook(
        tester,
        () => useStartDm(accountPubkey: _accountPubkey, peerPubkey: _peerPubkey),
      );

      try {
        await getResult().startDm();
      } catch (_) {}
      await tester.pump();

      expect(getResult().isLoading, isFalse);
    });
  });
}
