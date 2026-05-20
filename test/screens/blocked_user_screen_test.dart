import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncData;
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/screens/blocked_user_screen.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/widgets/wn_avatar.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_overlay.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart';

import '../mocks/mock_clipboard.dart' show clearClipboardMock, mockClipboard, mockClipboardFailing;
import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

const _testPubkey = testPubkeyA;
const _blockedPubkey = testPubkeyB;

class _MockApi extends MockWnApi {
  Completer<void>? unblockCompleter;
  Exception? unblockError;
  final unblockCalls = <({String account, String target})>[];

  @override
  Future<void> crateApiMuteListUnblockUser({
    required String accountPubkey,
    required String targetPubkey,
  }) async {
    unblockCalls.add((account: accountPubkey, target: targetPubkey));
    if (unblockCompleter != null) await unblockCompleter!.future;
    if (unblockError != null) throw unblockError!;
    await super.crateApiMuteListUnblockUser(
      accountPubkey: accountPubkey,
      targetPubkey: targetPubkey,
    );
  }

  @override
  void reset() {
    super.reset();
    unblockCompleter = null;
    unblockError = null;
    unblockCalls.clear();
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
  setUp(() {
    _api.reset();
    _api.blockedPubkeys.add(_blockedPubkey);
  });

  Future<void> pumpBlockedUserScreen(WidgetTester tester) async {
    await mountTestApp(
      tester,
      overrides: [authProvider.overrideWith(() => _MockAuthNotifier())],
    );
    await tester.pumpAndSettle();
    Routes.pushToBlockedUser(
      tester.element(find.byType(Scaffold)),
      _blockedPubkey,
    );
    await tester.pumpAndSettle();
  }

  group('BlockedUserScreen', () {
    testWidgets('displays Profile header title', (tester) async {
      await pumpBlockedUserScreen(tester);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('uses light overlay variant so the list shows blurred behind', (tester) async {
      await pumpBlockedUserScreen(tester);

      final overlay = tester.widget<WnOverlay>(find.byType(WnOverlay));
      expect(overlay.variant, WnOverlayVariant.light);
    });

    testWidgets('displays user display name when metadata has one', (tester) async {
      _api.seedUserInitialSnapshot(
        _blockedPubkey,
        metadata: const FlutterMetadata(displayName: 'Bob', custom: {}),
      );
      await pumpBlockedUserScreen(tester);

      expect(find.text('Bob'), findsOneWidget);
    });

    testWidgets('renders avatar matching the blocked user pubkey', (tester) async {
      _api.seedUserInitialSnapshot(
        _blockedPubkey,
        metadata: const FlutterMetadata(displayName: 'Bob', custom: {}),
      );
      await pumpBlockedUserScreen(tester);

      expect(
        find.descendant(
          of: find.byType(BlockedUserScreen),
          matching: find.byType(WnAvatar),
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows the blocked notice with header and description', (tester) async {
      await pumpBlockedUserScreen(tester);

      expect(find.byKey(const Key('blocked_user_detail_notice')), findsOneWidget);
      expect(find.text('You blocked this user'), findsOneWidget);
      expect(
        find.textContaining("You've blocked this user"),
        findsOneWidget,
      );
    });

    testWidgets('notice is expanded by default', (tester) async {
      await pumpBlockedUserScreen(tester);

      final notice = tester.widget<WnSystemNotice>(
        find.byKey(const Key('blocked_user_detail_notice')),
      );
      expect(notice.variant, WnSystemNoticeVariant.expanded);
      expect(find.byKey(const Key('blocked_user_unblock_button')), findsOneWidget);
    });

    testWidgets('notice uses the elevatedCard type so the card stands off the slate', (
      tester,
    ) async {
      await pumpBlockedUserScreen(tester);

      final notice = tester.widget<WnSystemNotice>(
        find.byKey(const Key('blocked_user_detail_notice')),
      );
      expect(notice.type, WnSystemNoticeType.elevatedCard);
    });

    testWidgets('notice collapses when chevron is tapped', (tester) async {
      await pumpBlockedUserScreen(tester);

      await tester.tap(find.byKey(const Key('systemNotice_actionIcon')));
      await tester.pumpAndSettle();

      final notice = tester.widget<WnSystemNotice>(
        find.byKey(const Key('blocked_user_detail_notice')),
      );
      expect(notice.variant, WnSystemNoticeVariant.collapsed);
    });

    testWidgets('tapping unblock calls the unblock API', (tester) async {
      await pumpBlockedUserScreen(tester);

      await tester.tap(find.byKey(const Key('blocked_user_unblock_button')));
      await tester.pumpAndSettle();

      expect(_api.unblockCalls.length, 1);
      expect(_api.unblockCalls[0].account, _testPubkey);
      expect(_api.unblockCalls[0].target, _blockedPubkey);
    });

    testWidgets('successful unblock morphs the same screen into the action panel', (tester) async {
      await pumpBlockedUserScreen(tester);

      await tester.tap(find.byKey(const Key('blocked_user_unblock_button')));
      await tester.pumpAndSettle();

      expect(find.byType(BlockedUserScreen), findsOneWidget);
      expect(find.byKey(const Key('blocked_user_unblocked_panel')), findsOneWidget);
      expect(find.byKey(const Key('blocked_user_detail_notice')), findsNothing);
      expect(find.byKey(const Key('blocked_user_send_message_button')), findsOneWidget);
      expect(find.byKey(const Key('blocked_user_block_button')), findsOneWidget);
    });

    testWidgets('shows loading state while unblock is in progress', (tester) async {
      _api.unblockCompleter = Completer<void>();
      await pumpBlockedUserScreen(tester);

      await tester.tap(find.byKey(const Key('blocked_user_unblock_button')));
      await tester.pump();

      final button = tester.widget<WnButton>(
        find.byKey(const Key('blocked_user_unblock_button')),
      );
      expect(button.loading, isTrue);

      _api.unblockCompleter!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('shows error notice when unblock fails', (tester) async {
      _api.unblockError = Exception('boom');
      await pumpBlockedUserScreen(tester);

      await tester.tap(find.byKey(const Key('blocked_user_unblock_button')));
      await tester.pumpAndSettle();

      expect(
        find.text('Failed to unblock user. Please try again.'),
        findsOneWidget,
      );
      expect(find.byType(BlockedUserScreen), findsOneWidget);
    });

    testWidgets('shows success notice when npub is copied', (tester) async {
      mockClipboard();
      addTearDown(clearClipboardMock);
      await pumpBlockedUserScreen(tester);

      await tester.tap(find.byKey(const Key('copy_button')));
      await tester.pumpAndSettle();

      expect(find.text('Public key copied to clipboard'), findsOneWidget);
    });

    testWidgets('shows error notice when npub copy fails', (tester) async {
      mockClipboardFailing();
      addTearDown(clearClipboardMock);
      await pumpBlockedUserScreen(tester);

      await tester.tap(find.byKey(const Key('copy_button')));
      await tester.pumpAndSettle();

      expect(find.text('Failed to copy public key. Please try again.'), findsOneWidget);
    });

    testWidgets('tapping back returns to the previous screen', (tester) async {
      await pumpBlockedUserScreen(tester);

      await tester.tap(find.byKey(const Key('slate_back_button')));
      await tester.pumpAndSettle();

      expect(find.byType(BlockedUserScreen), findsNothing);
    });
  });
}
