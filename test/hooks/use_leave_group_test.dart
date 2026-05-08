import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/hooks/use_leave_group.dart';
import 'package:whitenoise/src/rust/api/error.dart';
import 'package:whitenoise/src/rust/api/groups.dart' show GroupType, RequiredProposal;
import 'package:whitenoise/src/rust/frb_generated.dart';

import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

class _MockApi extends MockWnApi {
  bool shouldThrow = false;
  bool shouldThrowOnProposals = false;
  bool shouldThrowOnAdmins = false;
  bool wasLeaveCalled = false;
  int leaveCallCount = 0;
  int proposalsCallCount = 0;
  String? passedPubkey;
  String? passedGroupId;
  Completer<void>? leaveCompleter;
  List<RequiredProposal> requiredProposals = [RequiredProposal.selfRemove];
  Completer<List<RequiredProposal>>? proposalsCompleter;
  List<String> adminPubkeys = [];
  int selfDemoteCount = 0;
  bool shouldThrowOnSelfDemote = false;

  @override
  Future<void> crateApiGroupsLeaveGroup({
    required String pubkey,
    required String groupId,
  }) async {
    wasLeaveCalled = true;
    leaveCallCount++;
    passedPubkey = pubkey;
    passedGroupId = groupId;

    if (leaveCompleter != null) {
      await leaveCompleter!.future;
    }

    if (shouldThrow) {
      throw const ApiError.other(message: 'Failed to leave group');
    }
  }

  @override
  Future<List<RequiredProposal>> crateApiGroupsGroupRequiredProposals({
    required String accountPubkey,
    required String groupId,
  }) async {
    proposalsCallCount++;
    if (shouldThrowOnProposals) {
      throw const ApiError.other(message: 'Failed to fetch proposals');
    }
    if (proposalsCompleter != null) {
      return proposalsCompleter!.future;
    }
    return requiredProposals;
  }

  @override
  Future<List<String>> crateApiGroupsGroupAdmins({
    required String pubkey,
    required String groupId,
  }) async {
    if (shouldThrowOnAdmins) {
      throw const ApiError.other(message: 'Failed to fetch admins');
    }
    return adminPubkeys;
  }

  @override
  Future<void> crateApiGroupsSelfDemote({
    required String pubkey,
    required String groupId,
  }) async {
    selfDemoteCount++;
    if (shouldThrowOnSelfDemote) {
      throw const ApiError.other(message: 'Failed to self-demote');
    }
  }
}

void main() {
  final mockApi = _MockApi();

  setUpAll(() {
    RustLib.initMock(api: mockApi);
  });

  setUp(() {
    mockApi.shouldThrow = false;
    mockApi.shouldThrowOnProposals = false;
    mockApi.shouldThrowOnAdmins = false;
    mockApi.wasLeaveCalled = false;
    mockApi.leaveCallCount = 0;
    mockApi.proposalsCallCount = 0;
    mockApi.passedPubkey = null;
    mockApi.passedGroupId = null;
    mockApi.leaveCompleter = null;
    mockApi.requiredProposals = [RequiredProposal.selfRemove];
    mockApi.proposalsCompleter = null;
    mockApi.adminPubkeys = [];
    mockApi.selfDemoteCount = 0;
    mockApi.shouldThrowOnSelfDemote = false;
  });

  LeaveGroupState useLeaveGroupEnabled({
    GroupType groupType = GroupType.group,
    bool pendingConfirmation = false,
    bool selfRemoved = false,
  }) => useLeaveGroup(
    accountPubkey: testPubkeyA,
    groupId: testGroupId,
    featureEnabled: true,
    groupType: groupType,
    pendingConfirmation: pendingConfirmation,
    selfRemoved: selfRemoved,
  );

  group('visibility == hidden', () {
    testWidgets('is hidden when featureEnabled is false', (tester) async {
      final hook = await mountHook(
        tester,
        () => useLeaveGroup(
          accountPubkey: testPubkeyA,
          groupId: testGroupId,
          featureEnabled: false,
          groupType: GroupType.group,
          pendingConfirmation: false,
          selfRemoved: false,
        ),
      );

      await tester.pump();
      expect(hook().visibility, LeaveGroupVisibility.hidden);
      expect(hook().message, isNull);
    });

    testWidgets('is hidden when group is a DM', (tester) async {
      final hook = await mountHook(
        tester,
        () => useLeaveGroupEnabled(groupType: GroupType.directMessage),
      );

      await tester.pumpAndSettle();
      expect(hook().visibility, LeaveGroupVisibility.hidden);
      expect(hook().message, isNull);
    });

    testWidgets('is hidden when group is pending confirmation', (tester) async {
      final hook = await mountHook(
        tester,
        () => useLeaveGroupEnabled(pendingConfirmation: true),
      );

      await tester.pumpAndSettle();
      expect(hook().visibility, LeaveGroupVisibility.hidden);
      expect(hook().message, isNull);
    });

    testWidgets('is hidden when user already left (selfRemoved)', (tester) async {
      final hook = await mountHook(
        tester,
        () => useLeaveGroupEnabled(selfRemoved: true),
      );

      await tester.pumpAndSettle();
      expect(hook().visibility, LeaveGroupVisibility.hidden);
      expect(hook().message, isNull);
    });
  });

  group('visibility == disabled', () {
    testWidgets('disabled with noCapabilities when group lacks selfRemove', (tester) async {
      mockApi.requiredProposals = [];
      final hook = await mountHook(tester, useLeaveGroupEnabled);

      await tester.pumpAndSettle();
      expect(hook().visibility, LeaveGroupVisibility.disabled);
      expect(hook().message, LeaveGroupMessage.noCapabilities);
    });

    testWidgets('disabled with lastAdminWarning when user is only admin', (tester) async {
      mockApi.requiredProposals = [RequiredProposal.selfRemove];
      mockApi.adminPubkeys = [testPubkeyA];
      final hook = await mountHook(tester, useLeaveGroupEnabled);

      await tester.pumpAndSettle();
      expect(hook().visibility, LeaveGroupVisibility.disabled);
      expect(hook().message, LeaveGroupMessage.lastAdminWarning);
    });

    testWidgets('disabled with noCapabilities while proposals are loading', (tester) async {
      mockApi.proposalsCompleter = Completer<List<RequiredProposal>>();
      final hook = await mountHook(tester, useLeaveGroupEnabled);

      await tester.pump();
      expect(hook().visibility, LeaveGroupVisibility.disabled);
      expect(hook().message, LeaveGroupMessage.noCapabilities);

      mockApi.proposalsCompleter!.complete([RequiredProposal.selfRemove]);
      await tester.pumpAndSettle();
    });

    testWidgets('disabled with fetchError when proposals fetch throws', (tester) async {
      mockApi.shouldThrowOnProposals = true;
      final hook = await mountHook(tester, useLeaveGroupEnabled);

      await tester.pumpAndSettle();
      expect(hook().visibility, LeaveGroupVisibility.disabled);
      expect(hook().message, LeaveGroupMessage.fetchError);
    });

    testWidgets('proposals failure shows fetchError even when admins succeeds', (
      tester,
    ) async {
      mockApi.shouldThrowOnProposals = true;
      mockApi.adminPubkeys = [testPubkeyB];
      final hook = await mountHook(tester, useLeaveGroupEnabled);

      await tester.pumpAndSettle();
      expect(hook().visibility, LeaveGroupVisibility.disabled);
      expect(hook().message, LeaveGroupMessage.fetchError);
    });
  });

  group('visibility == visible', () {
    testWidgets('visible with defaultWarning when eligible non-admin', (tester) async {
      mockApi.requiredProposals = [RequiredProposal.selfRemove];
      mockApi.adminPubkeys = [testPubkeyB];
      final hook = await mountHook(tester, useLeaveGroupEnabled);

      await tester.pumpAndSettle();
      expect(hook().visibility, LeaveGroupVisibility.visible);
      expect(hook().message, LeaveGroupMessage.defaultWarning);
    });

    testWidgets('visible with defaultWarning when eligible non-last admin', (tester) async {
      mockApi.requiredProposals = [RequiredProposal.selfRemove];
      mockApi.adminPubkeys = [testPubkeyA, testPubkeyB];
      final hook = await mountHook(tester, useLeaveGroupEnabled);

      await tester.pumpAndSettle();
      expect(hook().visibility, LeaveGroupVisibility.visible);
      expect(hook().message, LeaveGroupMessage.defaultWarning);
    });

    testWidgets('visible with defaultWarning when eligible with no admins list', (tester) async {
      mockApi.requiredProposals = [RequiredProposal.selfRemove];
      mockApi.adminPubkeys = [];
      final hook = await mountHook(tester, useLeaveGroupEnabled);

      await tester.pumpAndSettle();
      expect(hook().visibility, LeaveGroupVisibility.visible);
      expect(hook().message, LeaveGroupMessage.defaultWarning);
    });

    testWidgets('admins failure does not reset hasNostrCapabilities when proposals succeeds', (
      tester,
    ) async {
      mockApi.requiredProposals = [RequiredProposal.selfRemove];
      mockApi.shouldThrowOnAdmins = true;
      final hook = await mountHook(tester, useLeaveGroupEnabled);

      await tester.pumpAndSettle();
      expect(hook().visibility, LeaveGroupVisibility.visible);
      expect(hook().message, LeaveGroupMessage.defaultWarning);
    });
  });

  group('fetch skipped for hidden cases', () {
    testWidgets('skips fetch when featureEnabled is false', (tester) async {
      await mountHook(
        tester,
        () => useLeaveGroup(
          accountPubkey: testPubkeyA,
          groupId: testGroupId,
          featureEnabled: false,
          groupType: GroupType.group,
          pendingConfirmation: false,
          selfRemoved: false,
        ),
      );

      await tester.pumpAndSettle();
      expect(mockApi.proposalsCallCount, 0);
    });

    testWidgets('skips fetch when group is a DM', (tester) async {
      await mountHook(tester, () => useLeaveGroupEnabled(groupType: GroupType.directMessage));

      await tester.pumpAndSettle();
      expect(mockApi.proposalsCallCount, 0);
    });

    testWidgets('skips fetch when group is pending confirmation', (tester) async {
      await mountHook(tester, () => useLeaveGroupEnabled(pendingConfirmation: true));

      await tester.pumpAndSettle();
      expect(mockApi.proposalsCallCount, 0);
    });

    testWidgets('skips fetch when user already left (selfRemoved)', (tester) async {
      await mountHook(tester, () => useLeaveGroupEnabled(selfRemoved: true));

      await tester.pumpAndSettle();
      expect(mockApi.proposalsCallCount, 0);
    });

    testWidgets('resets immediately when featureEnabled changes to false', (tester) async {
      LeaveGroupState? hookState;

      setUpTestView(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (_) {
              hookState = useLeaveGroup(
                accountPubkey: testPubkeyA,
                groupId: testGroupId,
                featureEnabled: true,
                groupType: GroupType.group,
                pendingConfirmation: false,
                selfRemoved: false,
              );
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(hookState!.visibility, isNot(LeaveGroupVisibility.hidden));

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (_) {
              hookState = useLeaveGroup(
                accountPubkey: testPubkeyA,
                groupId: testGroupId,
                featureEnabled: false,
                groupType: GroupType.group,
                pendingConfirmation: false,
                selfRemoved: false,
              );
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pump();
      expect(hookState!.visibility, LeaveGroupVisibility.hidden);
    });
  });

  testWidgets('initial state is not loading', (tester) async {
    final hook = await mountHook(tester, useLeaveGroupEnabled);

    await tester.pumpAndSettle();
    expect(hook().isLoading, isFalse);
    expect(mockApi.wasLeaveCalled, isFalse);
  });

  testWidgets('leaveGroup success sets loading true then false', (tester) async {
    mockApi.leaveCompleter = Completer<void>();

    final hook = await mountHook(tester, useLeaveGroupEnabled);
    await tester.pumpAndSettle();

    final future = hook().leaveGroup();

    await tester.pump();
    expect(hook().isLoading, isTrue);

    mockApi.leaveCompleter!.complete();
    await future;

    await tester.pump();
    expect(hook().isLoading, isFalse);
    expect(mockApi.wasLeaveCalled, isTrue);
    expect(mockApi.passedPubkey, testPubkeyA);
    expect(mockApi.passedGroupId, testGroupId);
  });

  testWidgets('leaveGroup error resets loading and visibility stays visible', (tester) async {
    mockApi.leaveCompleter = Completer<void>();
    mockApi.shouldThrow = true;

    final hook = await mountHook(tester, useLeaveGroupEnabled);
    await tester.pumpAndSettle();

    final future = hook().leaveGroup();

    await tester.pump();
    expect(hook().isLoading, isTrue);

    mockApi.leaveCompleter!.complete();
    await expectLater(future, throwsA(isA<ApiError>()));

    await tester.pump();
    expect(hook().isLoading, isFalse);
    expect(hook().visibility, LeaveGroupVisibility.visible);
    expect(mockApi.wasLeaveCalled, isTrue);
  });

  testWidgets('prevents re-entrant leaveGroup calls', (tester) async {
    mockApi.leaveCompleter = Completer<void>();

    final hook = await mountHook(tester, useLeaveGroupEnabled);
    await tester.pumpAndSettle();

    final future1 = hook().leaveGroup();
    final future2 = hook().leaveGroup();
    final future3 = hook().leaveGroup();

    await tester.pump();
    expect(hook().isLoading, isTrue);

    mockApi.leaveCompleter!.complete();
    await Future.wait<void>([future1, future2, future3]);

    await tester.pump();
    expect(hook().isLoading, isFalse);
    expect(mockApi.leaveCallCount, 1);
  });

  testWidgets('does not crash if unmounted during leaveGroup', (tester) async {
    mockApi.leaveCompleter = Completer<void>();

    final hook = await mountHook(tester, useLeaveGroupEnabled);
    await tester.pumpAndSettle();

    final future = hook().leaveGroup();
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    mockApi.leaveCompleter!.complete();
    await future;
    expect(hook().isLoading, isTrue);
  });

  testWidgets('leaveGroup is a no-op when visibility is hidden', (tester) async {
    final hook = await mountHook(
      tester,
      () => useLeaveGroup(
        accountPubkey: testPubkeyA,
        groupId: testGroupId,
        featureEnabled: false,
        groupType: GroupType.group,
        pendingConfirmation: false,
        selfRemoved: false,
      ),
    );

    await tester.pumpAndSettle();
    expect(hook().visibility, LeaveGroupVisibility.hidden);

    await hook().leaveGroup();

    expect(mockApi.wasLeaveCalled, isFalse);
    expect(hook().isLoading, isFalse);
  });

  testWidgets('leaveGroup is a no-op when visibility is disabled', (tester) async {
    mockApi.requiredProposals = [];
    final hook = await mountHook(tester, useLeaveGroupEnabled);

    await tester.pumpAndSettle();
    expect(hook().visibility, LeaveGroupVisibility.disabled);

    await hook().leaveGroup();

    expect(mockApi.wasLeaveCalled, isFalse);
    expect(hook().isLoading, isFalse);
  });

  group('admin leave behavior', () {
    testWidgets('selfDemote then leaveGroup called when user is admin', (tester) async {
      mockApi.requiredProposals = [RequiredProposal.selfRemove];
      mockApi.adminPubkeys = [testPubkeyA, testPubkeyB];

      final hook = await mountHook(tester, useLeaveGroupEnabled);
      await tester.pumpAndSettle();

      expect(hook().visibility, LeaveGroupVisibility.visible);

      await hook().leaveGroup();
      await tester.pumpAndSettle();

      expect(mockApi.selfDemoteCount, 1);
      expect(mockApi.wasLeaveCalled, isTrue);
    });

    testWidgets('leaveGroup called without selfDemote when user is not admin', (tester) async {
      mockApi.requiredProposals = [RequiredProposal.selfRemove];
      mockApi.adminPubkeys = [testPubkeyB];

      final hook = await mountHook(tester, useLeaveGroupEnabled);
      await tester.pumpAndSettle();

      await hook().leaveGroup();
      await tester.pumpAndSettle();

      expect(mockApi.selfDemoteCount, 0);
      expect(mockApi.wasLeaveCalled, isTrue);
    });

    testWidgets('error from selfDemote propagates, leave is not called, loading resets', (
      tester,
    ) async {
      mockApi.requiredProposals = [RequiredProposal.selfRemove];
      mockApi.adminPubkeys = [testPubkeyA, testPubkeyB];
      mockApi.shouldThrowOnSelfDemote = true;

      final hook = await mountHook(tester, useLeaveGroupEnabled);
      await tester.pumpAndSettle();

      final future = hook().leaveGroup();
      await expectLater(future, throwsA(isA<ApiError>()));
      await tester.pump();

      expect(hook().isLoading, isFalse);
      expect(mockApi.wasLeaveCalled, isFalse);
    });

    testWidgets('error from leaveGroup after selfDemote propagates and resets loading', (
      tester,
    ) async {
      mockApi.requiredProposals = [RequiredProposal.selfRemove];
      mockApi.adminPubkeys = [testPubkeyA, testPubkeyB];
      mockApi.shouldThrow = true;

      final hook = await mountHook(tester, useLeaveGroupEnabled);
      await tester.pumpAndSettle();

      final future = hook().leaveGroup();
      await expectLater(future, throwsA(isA<ApiError>()));
      await tester.pump();

      expect(hook().isLoading, isFalse);
      expect(mockApi.selfDemoteCount, 1);
      expect(mockApi.wasLeaveCalled, isTrue);
    });
  });
}
