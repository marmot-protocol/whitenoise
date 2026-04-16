import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/hooks/use_block_actions.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

class _MockApi extends MockWnApi {
  Completer<bool>? isBlockedCompleter;
  Completer<void>? blockCompleter;
  Completer<void>? unblockCompleter;
  Exception? isBlockedError;
  Exception? blockError;
  Exception? unblockError;
  final isBlockedCalls = <({String account, String target})>[];
  final blockCalls = <({String account, String target})>[];
  final unblockCalls = <({String account, String target})>[];
  final blockedPubkeys = <String>{};

  @override
  Future<bool> crateApiMuteListIsUserBlocked({
    required String accountPubkey,
    required String targetPubkey,
  }) async {
    isBlockedCalls.add((account: accountPubkey, target: targetPubkey));
    if (isBlockedError != null) throw isBlockedError!;
    if (isBlockedCompleter != null) return isBlockedCompleter!.future;
    return blockedPubkeys.contains(targetPubkey);
  }

  @override
  Future<void> crateApiMuteListBlockUser({
    required String accountPubkey,
    required String targetPubkey,
  }) async {
    blockCalls.add((account: accountPubkey, target: targetPubkey));
    if (blockCompleter != null) await blockCompleter!.future;
    if (blockError != null) throw blockError!;
  }

  @override
  Future<void> crateApiMuteListUnblockUser({
    required String accountPubkey,
    required String targetPubkey,
  }) async {
    unblockCalls.add((account: accountPubkey, target: targetPubkey));
    if (unblockCompleter != null) await unblockCompleter!.future;
    if (unblockError != null) throw unblockError!;
  }

  @override
  void reset() {
    super.reset();
    isBlockedCompleter = null;
    blockCompleter = null;
    unblockCompleter = null;
    isBlockedError = null;
    blockError = null;
    unblockError = null;
    isBlockedCalls.clear();
    blockCalls.clear();
    unblockCalls.clear();
    blockedPubkeys.clear();
  }
}

final _api = _MockApi();

void main() {
  late BlockActionsState Function() getState;

  setUpAll(() => RustLib.initMock(api: _api));
  setUp(() => _api.reset());

  Future<void> pump(
    WidgetTester tester, {
    required String accountPubkey,
    String? userPubkey,
    int refreshKey = 0,
  }) async {
    getState = await mountHook(
      tester,
      () => useBlockActions(
        accountPubkey: accountPubkey,
        userPubkey: userPubkey,
        refreshKey: refreshKey,
      ),
    );
  }

  group('useBlockActions', () {
    group('loading state', () {
      group('with null userPubkey', () {
        testWidgets('isLoading is false after settle', (tester) async {
          await pump(tester, accountPubkey: testPubkeyA);
          await tester.pumpAndSettle();

          expect(getState().isLoading, isFalse);
        });

        testWidgets('isBlocked is false', (tester) async {
          await pump(tester, accountPubkey: testPubkeyA);
          await tester.pumpAndSettle();

          expect(getState().isBlocked, isFalse);
        });

        testWidgets('resets isBlocked to false when userPubkey becomes null', (tester) async {
          _api.blockedPubkeys.add(testPubkeyB);
          await pump(tester, accountPubkey: testPubkeyA, userPubkey: testPubkeyB);
          await tester.pumpAndSettle();
          expect(getState().isBlocked, isTrue);

          getState = await mountHook(
            tester,
            () => useBlockActions(accountPubkey: testPubkeyA, userPubkey: null),
          );
          await tester.pumpAndSettle();

          expect(getState().isBlocked, isFalse);
        });

        testWidgets('does not call isUserBlocked API', (tester) async {
          await pump(tester, accountPubkey: testPubkeyA);
          await tester.pumpAndSettle();

          expect(_api.isBlockedCalls, isEmpty);
        });
      });

      testWidgets('isLoading is true while fetching', (tester) async {
        _api.isBlockedCompleter = Completer();
        await pump(tester, accountPubkey: testPubkeyA, userPubkey: testPubkeyB);

        expect(getState().isLoading, isTrue);
        expect(getState().isBlocked, isFalse);
      });

      testWidgets('isLoading becomes false after fetch completes', (tester) async {
        _api.isBlockedCompleter = Completer();
        await pump(tester, accountPubkey: testPubkeyA, userPubkey: testPubkeyB);

        expect(getState().isLoading, isTrue);

        _api.isBlockedCompleter!.complete(true);
        await tester.pumpAndSettle();

        expect(getState().isLoading, isFalse);
        expect(getState().isBlocked, isTrue);
      });
    });

    group('block status', () {
      testWidgets('returns false for non-blocked user', (tester) async {
        await pump(tester, accountPubkey: testPubkeyA, userPubkey: testPubkeyB);
        await tester.pumpAndSettle();

        expect(getState().isBlocked, isFalse);
        expect(getState().isLoading, isFalse);
      });

      testWidgets('returns true for blocked user', (tester) async {
        _api.blockedPubkeys.add(testPubkeyB);
        await pump(tester, accountPubkey: testPubkeyA, userPubkey: testPubkeyB);
        await tester.pumpAndSettle();

        expect(getState().isBlocked, isTrue);
        expect(getState().isLoading, isFalse);
      });

      testWidgets('defaults to false when fetch fails', (tester) async {
        _api.isBlockedError = Exception('Network error');
        await pump(tester, accountPubkey: testPubkeyA, userPubkey: testPubkeyB);
        await tester.pumpAndSettle();

        expect(getState().isBlocked, isFalse);
        expect(getState().isLoading, isFalse);
      });
    });

    group('API calls', () {
      testWidgets('calls isUserBlocked API with correct parameters', (tester) async {
        await pump(tester, accountPubkey: testPubkeyA, userPubkey: testPubkeyB);
        await tester.pumpAndSettle();

        expect(_api.isBlockedCalls.length, 1);
        expect(_api.isBlockedCalls[0].account, testPubkeyA);
        expect(_api.isBlockedCalls[0].target, testPubkeyB);
      });
    });

    group('toggleBlock action', () {
      group('with null userPubkey', () {
        testWidgets('does not call block or unblock API', (tester) async {
          await pump(tester, accountPubkey: testPubkeyA);
          await tester.pumpAndSettle();

          await getState().toggleBlock();
          await tester.pump();

          expect(_api.blockCalls.length + _api.unblockCalls.length, 0);
        });
      });

      group('while loading', () {
        testWidgets('does not call block or unblock API', (tester) async {
          _api.isBlockedCompleter = Completer();
          await pump(tester, accountPubkey: testPubkeyA, userPubkey: testPubkeyB);

          expect(getState().isLoading, isTrue);

          await getState().toggleBlock();
          await tester.pump();

          expect(_api.blockCalls.length + _api.unblockCalls.length, 0);
        });
      });

      testWidgets('calls block API with correct parameters when not blocked', (tester) async {
        await pump(tester, accountPubkey: testPubkeyA, userPubkey: testPubkeyB);
        await tester.pumpAndSettle();

        await getState().toggleBlock();
        await tester.pump();

        expect(_api.blockCalls.length, 1);
        expect(_api.blockCalls[0].account, testPubkeyA);
        expect(_api.blockCalls[0].target, testPubkeyB);
        expect(_api.unblockCalls.length, 0);
      });

      testWidgets('calls unblock API with correct parameters when blocked', (tester) async {
        _api.blockedPubkeys.add(testPubkeyB);
        await pump(tester, accountPubkey: testPubkeyA, userPubkey: testPubkeyB);
        await tester.pumpAndSettle();

        await getState().toggleBlock();
        await tester.pump();

        expect(_api.unblockCalls.length, 1);
        expect(_api.unblockCalls[0].account, testPubkeyA);
        expect(_api.unblockCalls[0].target, testPubkeyB);
        expect(_api.blockCalls.length, 0);
      });

      testWidgets('isActionLoading is true during block', (tester) async {
        _api.blockCompleter = Completer();
        await pump(tester, accountPubkey: testPubkeyA, userPubkey: testPubkeyB);
        await tester.pumpAndSettle();

        final future = getState().toggleBlock();
        await tester.pump();

        expect(getState().isActionLoading, isTrue);

        _api.blockCompleter!.complete();
        await future;
        await tester.pump();

        expect(getState().isActionLoading, isFalse);
      });

      testWidgets('isActionLoading is true during unblock', (tester) async {
        _api.blockedPubkeys.add(testPubkeyB);
        _api.unblockCompleter = Completer();
        await pump(tester, accountPubkey: testPubkeyA, userPubkey: testPubkeyB);
        await tester.pumpAndSettle();

        final future = getState().toggleBlock();
        await tester.pump();

        expect(getState().isActionLoading, isTrue);

        _api.unblockCompleter!.complete();
        await future;
        await tester.pump();

        expect(getState().isActionLoading, isFalse);
      });

      testWidgets('updates isBlocked to true after blocking', (tester) async {
        await pump(tester, accountPubkey: testPubkeyA, userPubkey: testPubkeyB);
        await tester.pumpAndSettle();

        expect(getState().isBlocked, isFalse);

        await getState().toggleBlock();
        await tester.pump();

        expect(getState().isBlocked, isTrue);
      });

      testWidgets('updates isBlocked to false after unblocking', (tester) async {
        _api.blockedPubkeys.add(testPubkeyB);
        await pump(tester, accountPubkey: testPubkeyA, userPubkey: testPubkeyB);
        await tester.pumpAndSettle();

        expect(getState().isBlocked, isTrue);

        await getState().toggleBlock();
        await tester.pump();

        expect(getState().isBlocked, isFalse);
      });

      testWidgets('sets error on block failure', (tester) async {
        _api.blockError = Exception('Network error');
        await pump(tester, accountPubkey: testPubkeyA, userPubkey: testPubkeyB);
        await tester.pumpAndSettle();

        expect(getState().error, isNull);

        await expectLater(getState().toggleBlock, throwsException);
        await tester.pump();

        expect(getState().error, 'Failed to block user');
      });

      testWidgets('sets error on unblock failure', (tester) async {
        _api.blockedPubkeys.add(testPubkeyB);
        _api.unblockError = Exception('Network error');
        await pump(tester, accountPubkey: testPubkeyA, userPubkey: testPubkeyB);
        await tester.pumpAndSettle();

        expect(getState().error, isNull);

        await expectLater(getState().toggleBlock, throwsException);
        await tester.pump();

        expect(getState().error, 'Failed to unblock user');
      });
    });

    group('cleanup', () {
      testWidgets('does not write stale state after refreshKey changes', (tester) async {
        final completer = Completer<bool>();
        _api.isBlockedCompleter = completer;

        await pump(tester, accountPubkey: testPubkeyA, userPubkey: testPubkeyB);

        _api.isBlockedCompleter = null;
        getState = await mountHook(
          tester,
          () => useBlockActions(
            accountPubkey: testPubkeyA,
            userPubkey: testPubkeyB,
            refreshKey: 1,
          ),
        );
        await tester.pumpAndSettle();

        expect(getState().isBlocked, isFalse);

        completer.complete(true);
        await tester.pumpAndSettle();

        expect(getState().isBlocked, isFalse);
      });
    });

    group('refreshKey', () {
      testWidgets('re-fetches block status when refreshKey changes', (tester) async {
        await pump(tester, accountPubkey: testPubkeyA, userPubkey: testPubkeyB);
        await tester.pumpAndSettle();
        expect(getState().isBlocked, isFalse);
        expect(_api.isBlockedCalls.length, 1);

        _api.blockedPubkeys.add(testPubkeyB);
        getState = await mountHook(
          tester,
          () => useBlockActions(
            accountPubkey: testPubkeyA,
            userPubkey: testPubkeyB,
            refreshKey: 1,
          ),
        );
        await tester.pumpAndSettle();

        expect(getState().isBlocked, isTrue);
        expect(_api.isBlockedCalls.length, 2);
      });
    });

    group('clearError', () {
      testWidgets('clears error state', (tester) async {
        _api.blockError = Exception('Network error');
        await pump(tester, accountPubkey: testPubkeyA, userPubkey: testPubkeyB);
        await tester.pumpAndSettle();

        await expectLater(getState().toggleBlock, throwsException);
        await tester.pump();

        expect(getState().error, isNotNull);

        getState().clearError();
        await tester.pump();

        expect(getState().error, isNull);
      });
    });
  });
}
