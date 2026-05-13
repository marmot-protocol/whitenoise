import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rust_lib_whitenoise/src/rust/api/error.dart';
import 'package:rust_lib_whitenoise/src/rust/api/groups.dart' show GroupType, RequiredProposal;
import 'package:rust_lib_whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/hooks/use_leave_group.dart';

import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

class _MockApi extends MockWnApi {
  bool shouldThrow = false;
  bool shouldThrowOnProposals = false;
  bool wasLeaveCalled = false;
  int leaveCallCount = 0;
  int proposalsCallCount = 0;
  String? passedPubkey;
  String? passedGroupId;
  Completer<void>? leaveCompleter;
  List<RequiredProposal> requiredProposals = [RequiredProposal.selfRemove];
  Completer<List<RequiredProposal>>? proposalsCompleter;

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
}

void main() {
  final mockApi = _MockApi();

  setUpAll(() {
    RustLib.initMock(api: mockApi);
  });

  setUp(() {
    mockApi.shouldThrow = false;
    mockApi.shouldThrowOnProposals = false;
    mockApi.wasLeaveCalled = false;
    mockApi.leaveCallCount = 0;
    mockApi.proposalsCallCount = 0;
    mockApi.passedPubkey = null;
    mockApi.passedGroupId = null;
    mockApi.leaveCompleter = null;
    mockApi.requiredProposals = [RequiredProposal.selfRemove];
    mockApi.proposalsCompleter = null;
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

  group('canLeave initial state', () {
    testWidgets('is false when featureEnabled is false', (tester) async {
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
      expect(hook().canLeave, isFalse);
    });

    testWidgets('is false when group is a DM', (tester) async {
      final hook = await mountHook(
        tester,
        () => useLeaveGroupEnabled(groupType: GroupType.directMessage),
      );

      await tester.pumpAndSettle();
      expect(hook().canLeave, isFalse);
    });

    testWidgets('is false when group is pending confirmation', (tester) async {
      final hook = await mountHook(
        tester,
        () => useLeaveGroupEnabled(pendingConfirmation: true),
      );

      await tester.pumpAndSettle();
      expect(hook().canLeave, isFalse);
    });

    testWidgets('is false when user already left (selfRemoved)', (tester) async {
      final hook = await mountHook(
        tester,
        () => useLeaveGroupEnabled(selfRemoved: true),
      );

      await tester.pumpAndSettle();
      expect(hook().canLeave, isFalse);
    });

    testWidgets('is true when featureEnabled and group is leavable', (tester) async {
      final hook = await mountHook(tester, useLeaveGroupEnabled);

      await tester.pumpAndSettle();
      expect(hook().canLeave, isTrue);
    });
  });

  group('groupRequiredProposals not called when ineligible', () {
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

    testWidgets('resets canLeave immediately when featureEnabled changes to false', (tester) async {
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
      expect(hookState!.canLeave, isTrue);

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
      expect(hookState!.canLeave, isFalse);
    });
  });

  group('canLeave Nostr capabilities', () {
    testWidgets('is false when group lacks selfRemove capability', (tester) async {
      mockApi.requiredProposals = [];
      final hook = await mountHook(tester, useLeaveGroupEnabled);

      await tester.pumpAndSettle();
      expect(hook().canLeave, isFalse);
    });

    testWidgets('is false while proposals are loading', (tester) async {
      mockApi.proposalsCompleter = Completer<List<RequiredProposal>>();
      final hook = await mountHook(tester, useLeaveGroupEnabled);

      await tester.pump();
      expect(hook().canLeave, isFalse);

      mockApi.proposalsCompleter!.complete([RequiredProposal.selfRemove]);
      await tester.pumpAndSettle();
    });

    testWidgets('is true once selfRemove capability is confirmed', (tester) async {
      mockApi.requiredProposals = [RequiredProposal.selfRemove];
      final hook = await mountHook(tester, useLeaveGroupEnabled);

      await tester.pumpAndSettle();
      expect(hook().canLeave, isTrue);
    });

    testWidgets('is false when proposals fetch throws', (tester) async {
      mockApi.shouldThrowOnProposals = true;
      final hook = await mountHook(tester, useLeaveGroupEnabled);

      await tester.pumpAndSettle();
      expect(hook().canLeave, isFalse);
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

  testWidgets('leaveGroup error resets loading and canLeave stays true', (tester) async {
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
    expect(hook().canLeave, isTrue);
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

  testWidgets('leaveGroup is a no-op when canLeave is false', (tester) async {
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
    expect(hook().canLeave, isFalse);

    await hook().leaveGroup();

    expect(mockApi.wasLeaveCalled, isFalse);
    expect(hook().isLoading, isFalse);
  });
}
