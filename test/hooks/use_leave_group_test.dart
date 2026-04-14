import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/hooks/use_leave_group.dart';
import 'package:whitenoise/src/rust/api/error.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';

import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

class _MockApi extends MockWnApi {
  bool shouldThrow = false;
  bool wasLeaveCalled = false;
  int leaveCallCount = 0;
  String? passedPubkey;
  String? passedGroupId;
  Completer<void>? leaveCompleter;

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
}

void main() {
  final mockApi = _MockApi();

  setUpAll(() {
    RustLib.initMock(api: mockApi);
  });

  setUp(() {
    mockApi.shouldThrow = false;
    mockApi.wasLeaveCalled = false;
    mockApi.leaveCallCount = 0;
    mockApi.passedPubkey = null;
    mockApi.passedGroupId = null;
    mockApi.leaveCompleter = null;
  });

  testWidgets('initial state is not loading', (tester) async {
    final hook = await mountHook(
      tester,
      () => useLeaveGroup(
        accountPubkey: testPubkeyA,
        groupId: testGroupId,
      ),
    );

    expect(hook().isLoading, isFalse);
    expect(mockApi.wasLeaveCalled, isFalse);
  });

  testWidgets('leaveGroup success sets loading true then false', (
    tester,
  ) async {
    mockApi.leaveCompleter = Completer<void>();

    final hook = await mountHook(
      tester,
      () => useLeaveGroup(
        accountPubkey: testPubkeyA,
        groupId: testGroupId,
      ),
    );

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

  testWidgets('leaveGroup error throws and resets loading', (tester) async {
    mockApi.leaveCompleter = Completer<void>();
    mockApi.shouldThrow = true;

    final hook = await mountHook(
      tester,
      () => useLeaveGroup(
        accountPubkey: testPubkeyA,
        groupId: testGroupId,
      ),
    );

    final future = hook().leaveGroup();

    await tester.pump();
    expect(hook().isLoading, isTrue);

    mockApi.leaveCompleter!.complete();
    await expectLater(future, throwsA(isA<ApiError>()));

    await tester.pump();
    expect(hook().isLoading, isFalse);
    expect(mockApi.wasLeaveCalled, isTrue);
  });

  testWidgets('prevents re-entrant leaveGroup calls', (tester) async {
    mockApi.leaveCompleter = Completer<void>();

    final hook = await mountHook(
      tester,
      () => useLeaveGroup(
        accountPubkey: testPubkeyA,
        groupId: testGroupId,
      ),
    );

    // Call multiple times before the first one finishes
    final future1 = hook().leaveGroup();
    final future2 = hook().leaveGroup();
    final future3 = hook().leaveGroup();

    await tester.pump();
    expect(hook().isLoading, isTrue);

    mockApi.leaveCompleter!.complete();
    await Future.wait([future1, future2, future3]);

    await tester.pump();
    expect(hook().isLoading, isFalse);
    expect(mockApi.leaveCallCount, 1);
  });

  testWidgets('does not crash if unmounted during leaveGroup', (tester) async {
    mockApi.leaveCompleter = Completer<void>();

    final hook = await mountHook(
      tester,
      () => useLeaveGroup(
        accountPubkey: testPubkeyA,
        groupId: testGroupId,
      ),
    );

    final future = hook().leaveGroup();
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    mockApi.leaveCompleter!.complete();
    await future;
    expect(hook().isLoading, isTrue);
  });
}
