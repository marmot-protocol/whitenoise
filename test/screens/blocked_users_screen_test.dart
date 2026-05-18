import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncData;
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/screens/blocked_user_screen.dart';
import 'package:whitenoise/screens/blocked_users_screen.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/src/rust/api/mute_list.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';

import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

const _testPubkey = testPubkeyA;
const _blockedPubkeyB = testPubkeyB;
const _blockedPubkeyC = testPubkeyC;

class _MockApi extends MockWnApi {
  Completer<List<MuteListEntry>>? getBlockedUsersCompleter;
  Exception? getBlockedUsersError;
  int getBlockedUsersCallCount = 0;

  @override
  Future<List<MuteListEntry>> crateApiMuteListGetBlockedUsers({
    required String accountPubkey,
  }) async {
    getBlockedUsersCallCount++;
    if (getBlockedUsersCompleter != null) return getBlockedUsersCompleter!.future;
    if (getBlockedUsersError != null) throw getBlockedUsersError!;
    return super.crateApiMuteListGetBlockedUsers(accountPubkey: accountPubkey);
  }

  @override
  void reset() {
    super.reset();
    getBlockedUsersCompleter = null;
    getBlockedUsersError = null;
    getBlockedUsersCallCount = 0;
  }
}

class _MockAuthNotifier extends AuthNotifier {
  @override
  Future<String?> build() async {
    state = const AsyncData(_testPubkey);
    return _testPubkey;
  }
}

final _api = _MockApi();

void main() {
  setUpAll(() => RustLib.initMock(api: _api));
  setUp(() => _api.reset());

  Future<void> pumpBlockedUsersScreen(WidgetTester tester) async {
    await mountTestApp(
      tester,
      overrides: [authProvider.overrideWith(() => _MockAuthNotifier())],
    );
    await tester.pumpAndSettle();
    Routes.pushToBlockedUsers(tester.element(find.byType(Scaffold)));
    await tester.pumpAndSettle();
  }

  group('BlockedUsersScreen', () {
    testWidgets('displays Blocked users header title', (tester) async {
      await pumpBlockedUsersScreen(tester);
      expect(find.text('Blocked users'), findsOneWidget);
    });

    testWidgets('shows empty state when no users are blocked', (tester) async {
      await pumpBlockedUsersScreen(tester);

      expect(find.byKey(const Key('blocked_users_empty')), findsOneWidget);
      expect(find.text("You haven't blocked anyone yet."), findsOneWidget);
      expect(find.byKey(const Key('blocked_users_list')), findsNothing);
    });

    testWidgets('shows loading indicator while fetching blocked users', (tester) async {
      await mountTestApp(
        tester,
        overrides: [authProvider.overrideWith(() => _MockAuthNotifier())],
      );
      await tester.pumpAndSettle();

      _api.getBlockedUsersCompleter = Completer<List<MuteListEntry>>();
      Routes.pushToBlockedUsers(tester.element(find.byType(Scaffold)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byKey(const Key('blocked_users_loading')), findsOneWidget);

      _api.getBlockedUsersCompleter!.complete([]);
      _api.getBlockedUsersCompleter = null;
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('blocked_users_loading')), findsNothing);
    });

    testWidgets('renders one row per blocked user', (tester) async {
      _api.blockedPubkeys.addAll([_blockedPubkeyB, _blockedPubkeyC]);
      _api.seedUserInitialSnapshot(
        _blockedPubkeyB,
        metadata: const FlutterMetadata(displayName: 'Bob', custom: {}),
      );
      _api.seedUserInitialSnapshot(
        _blockedPubkeyC,
        metadata: const FlutterMetadata(displayName: 'Carol', custom: {}),
      );

      await pumpBlockedUsersScreen(tester);

      expect(find.byKey(const Key('blocked_users_list')), findsOneWidget);
      expect(find.byKey(const Key('blocked_user_tile_$_blockedPubkeyB')), findsOneWidget);
      expect(find.byKey(const Key('blocked_user_tile_$_blockedPubkeyC')), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Carol'), findsOneWidget);
    });

    testWidgets('falls back to truncated pubkey when metadata has no name', (tester) async {
      _api.blockedPubkeys.add(_blockedPubkeyB);

      await pumpBlockedUsersScreen(tester);

      expect(find.textContaining(_blockedPubkeyB.substring(0, 8)), findsWidgets);
    });

    testWidgets('shows error state instead of empty state when fetch fails', (tester) async {
      _api.getBlockedUsersError = Exception('boom');

      await pumpBlockedUsersScreen(tester);

      expect(find.byKey(const Key('blocked_users_error')), findsOneWidget);
      expect(find.text('Failed to load blocked users. Please try again.'), findsOneWidget);
      expect(find.byKey(const Key('blocked_users_empty')), findsNothing);
    });

    testWidgets('tapping a row navigates to BlockedUserScreen', (tester) async {
      _api.blockedPubkeys.add(_blockedPubkeyB);
      _api.seedUserInitialSnapshot(
        _blockedPubkeyB,
        metadata: const FlutterMetadata(displayName: 'Bob', custom: {}),
      );

      await pumpBlockedUsersScreen(tester);

      await tester.tap(find.byKey(const Key('blocked_user_tile_$_blockedPubkeyB')));
      await tester.pumpAndSettle();

      expect(find.byType(BlockedUserScreen), findsOneWidget);
    });

    testWidgets('returning from detail screen refreshes the blocked list', (tester) async {
      _api.blockedPubkeys.add(_blockedPubkeyB);

      await pumpBlockedUsersScreen(tester);
      final callsBeforeDetail = _api.getBlockedUsersCallCount;

      Routes.pushToBlockedUser(
        tester.element(find.byType(BlockedUsersScreen)),
        _blockedPubkeyB,
      );
      await tester.pumpAndSettle();
      Routes.goBack(tester.element(find.byType(BlockedUserScreen)));
      await tester.pumpAndSettle();

      expect(_api.getBlockedUsersCallCount, greaterThan(callsBeforeDetail));
    });

    testWidgets('tapping back navigates to previous screen', (tester) async {
      await pumpBlockedUsersScreen(tester);

      await tester.tap(find.byKey(const Key('slate_back_button')));
      await tester.pumpAndSettle();

      expect(find.byType(BlockedUsersScreen), findsNothing);
    });
  });
}
