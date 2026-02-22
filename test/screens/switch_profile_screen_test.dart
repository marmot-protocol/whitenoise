import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncData;
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/src/rust/api/accounts.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/utils/avatar_color.dart' show AvatarColor;
import 'package:whitenoise/widgets/wn_avatar.dart' show WnAvatar;
import 'package:whitenoise/widgets/wn_middle_ellipsis_text.dart';

import '../mocks/mock_secure_storage.dart';
import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

class _MockAuthNotifier extends AuthNotifier {
  String? _pubkey;
  Completer<void>? switchProfileCompleter;
  bool shouldThrowOnSwitch = false;

  _MockAuthNotifier(this._pubkey);

  @override
  Future<String?> build() async {
    if (_pubkey != null) {
      state = AsyncData(_pubkey);
    }
    return _pubkey;
  }

  @override
  Future<void> switchProfile(String pubkey) async {
    if (switchProfileCompleter != null) {
      await switchProfileCompleter!.future;
    }
    if (shouldThrowOnSwitch) {
      throw Exception('Switch failed');
    }
    _pubkey = pubkey;
    state = AsyncData(pubkey);
  }
}

void main() {
  late MockWnApi mockApi;

  setUpAll(() {
    mockApi = MockWnApi();
    RustLib.initMock(api: mockApi);
  });

  setUp(() {
    mockApi.reset();
    mockApi.getAccountsCompleter = null;
    mockApi.accounts = [
      Account(
        accountType: AccountType.local,
        pubkey: testPubkeyA,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Account(
        accountType: AccountType.local,
        pubkey: testPubkeyB,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  });

  Future<_MockAuthNotifier> pumpSwitchProfileScreen(
    WidgetTester tester,
    String currentPubkey, {
    _MockAuthNotifier? authNotifier,
  }) async {
    final notifier = authNotifier ?? _MockAuthNotifier(currentPubkey);
    await mountTestApp(
      tester,
      overrides: [
        authProvider.overrideWith(() => notifier),
        secureStorageProvider.overrideWithValue(MockSecureStorage()),
      ],
    );
    Routes.pushToSettings(tester.element(find.byType(Scaffold)));
    await tester.pumpAndSettle();
    Routes.pushToSwitchProfile(tester.element(find.byType(Scaffold)));
    await tester.pumpAndSettle();
    return notifier;
  }

  group('SwitchProfileScreen', () {
    testWidgets('displays Profiles title', (tester) async {
      await pumpSwitchProfileScreen(tester, testPubkeyA);
      expect(find.text('Profiles'), findsOneWidget);
    });

    testWidgets('tapping header back button goes back', (tester) async {
      await pumpSwitchProfileScreen(tester, testPubkeyA);
      await tester.tap(find.byKey(const Key('slate_close_button')));
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('tapping close while loading goes back', (tester) async {
      final completer = Completer<List<Account>>();
      mockApi.getAccountsCompleter = completer;
      final notifier = _MockAuthNotifier(testPubkeyA);
      await mountTestApp(
        tester,
        overrides: [
          authProvider.overrideWith(() => notifier),
          secureStorageProvider.overrideWithValue(MockSecureStorage()),
        ],
      );
      Routes.pushToSettings(tester.element(find.byType(Scaffold)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      Routes.pushToSwitchProfile(tester.element(find.byType(Scaffold)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byKey(const Key('slate_close_button')));
      completer.complete([]);
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('displays list of accounts', (tester) async {
      await pumpSwitchProfileScreen(tester, testPubkeyA);
      expect(find.text('Display $testPubkeyA'), findsOneWidget);
      expect(find.text('Display $testPubkeyB'), findsOneWidget);
    });

    testWidgets('displays checkmark for current account', (tester) async {
      await pumpSwitchProfileScreen(tester, testPubkeyA);
      expect(find.byKey(const Key('profile_switcher_item_checkmark')), findsOneWidget);
    });

    testWidgets('displays Connect Another Profile button', (tester) async {
      await pumpSwitchProfileScreen(tester, testPubkeyA);
      expect(find.text('Connect Another Profile'), findsOneWidget);
    });

    testWidgets('tapping current account goes back', (tester) async {
      await pumpSwitchProfileScreen(tester, testPubkeyA);
      await tester.tap(find.text('Display $testPubkeyA'));
      await tester.pumpAndSettle();
      expect(find.text('Profiles'), findsNothing);
    });

    testWidgets('tapping different account switches profile', (tester) async {
      await pumpSwitchProfileScreen(tester, testPubkeyA);
      await tester.tap(find.text('Display $testPubkeyB'));
      await tester.pumpAndSettle();
      expect(find.text('Profiles'), findsNothing);
    });

    testWidgets('tapping Connect Another Profile navigates to AddProfileScreen', (tester) async {
      await pumpSwitchProfileScreen(tester, testPubkeyA);
      await tester.tap(find.text('Connect Another Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Add a new profile'), findsOneWidget);
    });

    testWidgets('shows no accounts message when empty', (tester) async {
      mockApi.accounts = [];
      await pumpSwitchProfileScreen(tester, testPubkeyA);
      expect(find.text('No accounts available'), findsOneWidget);
    });

    testWidgets('displays loading state then resolves', (tester) async {
      final completer = Completer<List<Account>>();
      mockApi.getAccountsCompleter = completer;
      final notifier = _MockAuthNotifier(testPubkeyA);
      await mountTestApp(
        tester,
        overrides: [
          authProvider.overrideWith(() => notifier),
          secureStorageProvider.overrideWithValue(MockSecureStorage()),
        ],
      );
      Routes.pushToSettings(tester.element(find.byType(Scaffold)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      Routes.pushToSwitchProfile(tester.element(find.byType(Scaffold)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Profiles'), findsOneWidget);
      completer.complete([]);
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('disables taps while switching profile', (tester) async {
      final mockAuthNotifier = _MockAuthNotifier(testPubkeyA);
      mockAuthNotifier.switchProfileCompleter = Completer<void>();

      await pumpSwitchProfileScreen(
        tester,
        testPubkeyA,
        authNotifier: mockAuthNotifier,
      );

      await tester.tap(find.text('Display $testPubkeyB'));
      await tester.pump();

      expect(find.text('Display $testPubkeyA'), findsOneWidget);

      mockAuthNotifier.switchProfileCompleter!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('displays error message when switch fails', (tester) async {
      final mockAuthNotifier = _MockAuthNotifier(testPubkeyA);
      mockAuthNotifier.shouldThrowOnSwitch = true;

      await pumpSwitchProfileScreen(
        tester,
        testPubkeyA,
        authNotifier: mockAuthNotifier,
      );

      await tester.tap(find.text('Display $testPubkeyB'));
      await tester.pumpAndSettle();

      expect(find.text('Failed to switch profile. Please try again.'), findsOneWidget);
    });

    testWidgets('passes color derived from pubkey to each avatar', (tester) async {
      await pumpSwitchProfileScreen(tester, testPubkeyA);

      final avatars = tester.widgetList<WnAvatar>(find.byType(WnAvatar)).toList();
      expect(avatars.length, 2);
      expect(avatars[0].color, AvatarColor.violet);
      expect(avatars[1].color, AvatarColor.amber);
    });

    testWidgets('displays formatted npub for first account', (tester) async {
      await pumpSwitchProfileScreen(tester, testPubkeyA);
      final middleEllipsisWidgets = tester.widgetList<WnMiddleEllipsisText>(
        find.byType(WnMiddleEllipsisText),
      );
      expect(middleEllipsisWidgets.any((w) => w.text.startsWith('npub 1a1b')), isTrue);
    });

    testWidgets('displays formatted npub for second account', (tester) async {
      await pumpSwitchProfileScreen(tester, testPubkeyA);
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();
      final middleEllipsisWidgets = tester.widgetList<WnMiddleEllipsisText>(
        find.byType(WnMiddleEllipsisText),
      );
      expect(middleEllipsisWidgets.any((w) => w.text.startsWith('npub 1b2c')), isTrue);
    });
  });
}
