import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/hooks/use_follow_actions.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

class _MockApi extends MockWnApi {
  Completer<bool>? isFollowingCompleter;
  Completer<void>? followCompleter;
  Completer<void>? unfollowCompleter;
  Exception? isFollowingError;
  Exception? followError;
  Exception? unfollowError;
  final isFollowingCalls = <({String account, String user})>[];
  final followCalls = <({String account, String target})>[];
  final unfollowCalls = <({String account, String target})>[];
  final followingPubkeys = <String>{};

  @override
  Future<bool> crateApiAccountsIsFollowingUser({
    required String accountPubkey,
    required String userPubkey,
  }) async {
    isFollowingCalls.add((account: accountPubkey, user: userPubkey));
    if (isFollowingError != null) throw isFollowingError!;
    if (isFollowingCompleter != null) return isFollowingCompleter!.future;
    return followingPubkeys.contains(userPubkey);
  }

  @override
  Future<void> crateApiAccountsFollowUser({
    required String accountPubkey,
    required String userToFollowPubkey,
  }) async {
    followCalls.add((account: accountPubkey, target: userToFollowPubkey));
    if (followCompleter != null) await followCompleter!.future;
    if (followError != null) throw followError!;
  }

  @override
  Future<void> crateApiAccountsUnfollowUser({
    required String accountPubkey,
    required String userToUnfollowPubkey,
  }) async {
    unfollowCalls.add((account: accountPubkey, target: userToUnfollowPubkey));
    if (unfollowCompleter != null) await unfollowCompleter!.future;
    if (unfollowError != null) throw unfollowError!;
  }

  @override
  void reset() {
    super.reset();
    isFollowingCompleter = null;
    followCompleter = null;
    unfollowCompleter = null;
    isFollowingError = null;
    followError = null;
    unfollowError = null;
    isFollowingCalls.clear();
    followCalls.clear();
    unfollowCalls.clear();
    followingPubkeys.clear();
  }
}

final _api = _MockApi();

void main() {
  late FollowActionsState Function() getState;

  setUpAll(() => RustLib.initMock(api: _api));
  setUp(() => _api.reset());

  Future<void> pump(
    WidgetTester tester, {
    required String accountPubkey,
    String? userPubkey,
  }) async {
    getState = await mountHook(
      tester,
      () => useFollowActions(
        accountPubkey: accountPubkey,
        userPubkey: userPubkey,
      ),
    );
  }

  group('useFollowActions', () {
    group('loading state', () {
      group('with null userPubkey', () {
        testWidgets('isLoading stays true after settle', (tester) async {
          await pump(tester, accountPubkey: testPubkeyA);
          await tester.pumpAndSettle();

          expect(getState().isLoading, isTrue);
        });

        testWidgets('isFollowing is false', (tester) async {
          await pump(tester, accountPubkey: testPubkeyA);
          await tester.pumpAndSettle();

          expect(getState().isFollowing, isFalse);
        });

        testWidgets('does not call isFollowing API', (tester) async {
          await pump(tester, accountPubkey: testPubkeyA);
          await tester.pumpAndSettle();

          expect(_api.isFollowingCalls, isEmpty);
        });
      });

      testWidgets('isLoading is true while fetching', (tester) async {
        _api.isFollowingCompleter = Completer();
        await pump(tester, accountPubkey: testPubkeyA, userPubkey: testPubkeyB);

        expect(getState().isLoading, isTrue);
        expect(getState().isFollowing, isFalse);
      });

      testWidgets('isLoading becomes false after fetch completes', (tester) async {
        _api.isFollowingCompleter = Completer();
        await pump(tester, accountPubkey: testPubkeyA, userPubkey: testPubkeyB);

        expect(getState().isLoading, isTrue);

        _api.isFollowingCompleter!.complete(true);
        await tester.pumpAndSettle();

        expect(getState().isLoading, isFalse);
        expect(getState().isFollowing, isTrue);
      });
    });

    group('follow status', () {
      testWidgets('returns false for non-followed user', (tester) async {
        await pump(tester, accountPubkey: testPubkeyA, userPubkey: testPubkeyB);
        await tester.pumpAndSettle();

        expect(getState().isFollowing, isFalse);
        expect(getState().isLoading, isFalse);
      });

      testWidgets('returns true for followed user', (tester) async {
        _api.followingPubkeys.add(testPubkeyB);
        await pump(tester, accountPubkey: testPubkeyA, userPubkey: testPubkeyB);
        await tester.pumpAndSettle();

        expect(getState().isFollowing, isTrue);
        expect(getState().isLoading, isFalse);
      });

      testWidgets('defaults to false when fetch fails', (tester) async {
        _api.isFollowingError = Exception('Network error');
        await pump(tester, accountPubkey: testPubkeyA, userPubkey: testPubkeyB);
        await tester.pumpAndSettle();

        expect(getState().isFollowing, isFalse);
        expect(getState().isLoading, isFalse);
      });
    });

    group('API calls', () {
      testWidgets('calls API with correct parameters', (tester) async {
        await pump(tester, accountPubkey: testPubkeyA, userPubkey: testPubkeyB);
        await tester.pumpAndSettle();

        expect(_api.isFollowingCalls.length, 1);
        expect(_api.isFollowingCalls[0].account, testPubkeyA);
        expect(_api.isFollowingCalls[0].user, testPubkeyB);
      });
    });

    group('follow action', () {
      group('with null userPubkey', () {
        testWidgets('does not call follow API', (tester) async {
          await pump(tester, accountPubkey: testPubkeyA);
          await tester.pumpAndSettle();

          await getState().follow();
          await tester.pump();

          expect(_api.followCalls, isEmpty);
        });
      });

      testWidgets('calls follow API with correct parameters', (tester) async {
        await pump(tester, accountPubkey: testPubkeyA, userPubkey: testPubkeyB);
        await tester.pumpAndSettle();

        await getState().follow();
        await tester.pump();

        expect(_api.followCalls.length, 1);
        expect(_api.followCalls[0].account, testPubkeyA);
        expect(_api.followCalls[0].target, testPubkeyB);
      });

      testWidgets('isActionLoading is true during follow', (tester) async {
        _api.followCompleter = Completer();
        await pump(tester, accountPubkey: testPubkeyA, userPubkey: testPubkeyB);
        await tester.pumpAndSettle();

        final future = getState().follow();
        await tester.pump();

        expect(getState().isActionLoading, isTrue);

        _api.followCompleter!.complete();
        await future;
        await tester.pump();

        expect(getState().isActionLoading, isFalse);
      });

      testWidgets('updates isFollowing to true after follow', (tester) async {
        await pump(tester, accountPubkey: testPubkeyA, userPubkey: testPubkeyB);
        await tester.pumpAndSettle();

        expect(getState().isFollowing, isFalse);

        await getState().follow();
        await tester.pump();

        expect(getState().isFollowing, isTrue);
        expect(_api.isFollowingCalls.length, 1);
      });

      testWidgets('sets error on follow failure', (tester) async {
        _api.followError = Exception('Network error');
        await pump(tester, accountPubkey: testPubkeyA, userPubkey: testPubkeyB);
        await tester.pumpAndSettle();

        expect(getState().error, isNull);

        try {
          await getState().follow();
        } catch (_) {}
        await tester.pump();

        expect(getState().error, 'Failed to follow user');
      });
    });

    group('unfollow action', () {
      group('with null userPubkey', () {
        testWidgets('does not call unfollow API', (tester) async {
          await pump(tester, accountPubkey: testPubkeyA);
          await tester.pumpAndSettle();

          await getState().unfollow();
          await tester.pump();

          expect(_api.unfollowCalls, isEmpty);
        });
      });

      testWidgets('calls unfollow API with correct parameters', (tester) async {
        _api.followingPubkeys.add(testPubkeyB);
        await pump(tester, accountPubkey: testPubkeyA, userPubkey: testPubkeyB);
        await tester.pumpAndSettle();

        await getState().unfollow();
        await tester.pump();

        expect(_api.unfollowCalls.length, 1);
        expect(_api.unfollowCalls[0].account, testPubkeyA);
        expect(_api.unfollowCalls[0].target, testPubkeyB);
      });

      testWidgets('isActionLoading is true during unfollow', (tester) async {
        _api.followingPubkeys.add(testPubkeyB);
        _api.unfollowCompleter = Completer();
        await pump(tester, accountPubkey: testPubkeyA, userPubkey: testPubkeyB);
        await tester.pumpAndSettle();

        final future = getState().unfollow();
        await tester.pump();

        expect(getState().isActionLoading, isTrue);

        _api.unfollowCompleter!.complete();
        await future;
        await tester.pump();

        expect(getState().isActionLoading, isFalse);
      });

      testWidgets('updates isFollowing to false after unfollow', (tester) async {
        _api.followingPubkeys.add(testPubkeyB);
        await pump(tester, accountPubkey: testPubkeyA, userPubkey: testPubkeyB);
        await tester.pumpAndSettle();

        expect(getState().isFollowing, isTrue);

        await getState().unfollow();
        await tester.pump();

        expect(getState().isFollowing, isFalse);
        expect(_api.isFollowingCalls.length, 1);
      });

      testWidgets('sets error on unfollow failure', (tester) async {
        _api.followingPubkeys.add(testPubkeyB);
        _api.unfollowError = Exception('Network error');
        await pump(tester, accountPubkey: testPubkeyA, userPubkey: testPubkeyB);
        await tester.pumpAndSettle();

        expect(getState().error, isNull);

        try {
          await getState().unfollow();
        } catch (_) {}
        await tester.pump();

        expect(getState().error, 'Failed to unfollow user');
      });
    });

    group('toggleFollow action', () {
      group('with null userPubkey', () {
        testWidgets('does not call follow or unfollow API', (tester) async {
          await pump(tester, accountPubkey: testPubkeyA);
          await tester.pumpAndSettle();

          await getState().toggleFollow();
          await tester.pump();

          expect(_api.followCalls.length + _api.unfollowCalls.length, 0);
        });
      });

      testWidgets('calls follow when not following', (tester) async {
        await pump(tester, accountPubkey: testPubkeyA, userPubkey: testPubkeyB);
        await tester.pumpAndSettle();

        expect(getState().isFollowing, isFalse);

        await getState().toggleFollow();
        await tester.pump();

        expect(_api.followCalls.length, 1);
        expect(_api.unfollowCalls.length, 0);
        expect(getState().isFollowing, isTrue);
      });

      testWidgets('calls unfollow when following', (tester) async {
        _api.followingPubkeys.add(testPubkeyB);
        await pump(tester, accountPubkey: testPubkeyA, userPubkey: testPubkeyB);
        await tester.pumpAndSettle();

        expect(getState().isFollowing, isTrue);

        await getState().toggleFollow();
        await tester.pump();

        expect(_api.followCalls.length, 0);
        expect(_api.unfollowCalls.length, 1);
        expect(getState().isFollowing, isFalse);
      });
    });

    group('clearError', () {
      testWidgets('clears error state', (tester) async {
        _api.followError = Exception('Network error');
        await pump(tester, accountPubkey: testPubkeyA, userPubkey: testPubkeyB);
        await tester.pumpAndSettle();

        try {
          await getState().follow();
        } catch (_) {}
        await tester.pump();

        expect(getState().error, isNotNull);

        getState().clearError();
        await tester.pump();

        expect(getState().error, isNull);
      });
    });
  });
}
