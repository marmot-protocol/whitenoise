import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncData;
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/src/rust/api/users.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';
import 'package:whitenoise/widgets/wn_user_bubble.dart';

import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

User _userFactory(String pubkey, {String? displayName}) => User(
  pubkey: pubkey,
  metadata: FlutterMetadata(displayName: displayName, custom: const {}),
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

class _MockApi extends MockWnApi {
  List<User> followsList = [
    _userFactory(testPubkeyB, displayName: 'Bob'),
    _userFactory(testPubkeyC, displayName: 'Charlie'),
  ];

  @override
  Future<List<User>> crateApiAccountsAccountFollows({required String pubkey}) async {
    return followsList;
  }
}

class _MockAuthNotifier extends AuthNotifier {
  @override
  Future<String?> build() async {
    state = const AsyncData(testPubkeyA);
    return testPubkeyA;
  }
}

final _api = _MockApi();

void main() {
  setUpAll(() => RustLib.initMock(api: _api));

  setUp(() {
    _api.reset();
    _api.followsList = [
      _userFactory(testPubkeyB, displayName: 'Bob'),
      _userFactory(testPubkeyC, displayName: 'Charlie'),
    ];
  });

  Future<void> pumpUserSelectionScreen(
    WidgetTester tester, {
    List<User> initialUsers = const [],
  }) async {
    await mountTestApp(
      tester,
      overrides: [authProvider.overrideWith(() => _MockAuthNotifier())],
    );
    await tester.pumpAndSettle();
    Routes.pushToUserSelection(
      tester.element(find.byType(Scaffold)),
      initialUsers: initialUsers,
    );
    await tester.pumpAndSettle();
  }

  group('UserSelectionScreen', () {
    testWidgets('displays slate container', (tester) async {
      await pumpUserSelectionScreen(tester);
      expect(find.byType(WnSlate), findsOneWidget);
    });

    testWidgets('displays screen header with title', (tester) async {
      await pumpUserSelectionScreen(tester);
      expect(find.byType(WnSlateNavigationHeader), findsOneWidget);
      expect(find.text('New group chat'), findsOneWidget);
    });

    testWidgets('displays continue button in footer', (tester) async {
      await pumpUserSelectionScreen(tester);
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('continue button is disabled when no users selected', (tester) async {
      await pumpUserSelectionScreen(tester);
      final actualButton = tester.widget<WnButton>(find.widgetWithText(WnButton, 'Continue'));
      expect(actualButton.onPressed, isNull);
    });

    testWidgets('displays user list from follows', (tester) async {
      await pumpUserSelectionScreen(tester);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Charlie'), findsOneWidget);
    });

    testWidgets('displays search field', (tester) async {
      await pumpUserSelectionScreen(tester);
      expect(find.text('Name or npub1...'), findsOneWidget);
    });

    testWidgets('selecting user shows user bubble', (tester) async {
      await pumpUserSelectionScreen(tester);

      await tester.tap(find.text('Bob'));
      await tester.pumpAndSettle();

      expect(find.byType(WnUserBubble), findsOneWidget);
      expect(find.byKey(const Key('selected_users_bubbles')), findsOneWidget);
    });

    testWidgets('selecting multiple users shows multiple bubbles', (tester) async {
      await pumpUserSelectionScreen(tester);

      await tester.tap(find.text('Bob'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Charlie'));
      await tester.pumpAndSettle();

      expect(find.byType(WnUserBubble), findsNWidgets(2));
    });

    testWidgets('tapping user bubble deselects user', (tester) async {
      await pumpUserSelectionScreen(tester);

      await tester.tap(find.text('Bob'));
      await tester.pumpAndSettle();

      expect(find.byType(WnUserBubble), findsOneWidget);

      await tester.tap(find.byKey(const Key('bubble_$testPubkeyB')));
      await tester.pumpAndSettle();

      expect(find.byType(WnUserBubble), findsNothing);
    });

    testWidgets('continue button is enabled when users selected', (tester) async {
      await pumpUserSelectionScreen(tester);

      await tester.tap(find.text('Bob'));
      await tester.pumpAndSettle();

      final button = tester.widget<WnButton>(find.widgetWithText(WnButton, 'Continue'));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('displays no results message when search has no matches', (tester) async {
      await pumpUserSelectionScreen(tester);

      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      await tester.enterText(textField, 'NonExistentUser');
      await tester.pumpAndSettle();

      expect(find.text('No results'), findsOneWidget);
    });

    testWidgets('displays user without displayName using formatted pubkey', (tester) async {
      _api.followsList = [
        User(
          pubkey: testPubkeyB,
          metadata: const FlutterMetadata(custom: {}),
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ),
      ];

      await pumpUserSelectionScreen(tester);

      expect(find.textContaining('npub1'), findsWidgets);
    });

    testWidgets('tapping continue button navigates to group details', (tester) async {
      _api.followsList = [
        _userFactory(testPubkeyB, displayName: 'Bob'),
        _userFactory(testPubkeyC, displayName: 'Charlie'),
      ];

      await pumpUserSelectionScreen(tester);

      await tester.tap(find.text('Bob'));
      await tester.pumpAndSettle();

      final continueButton = find.widgetWithText(WnButton, 'Continue');
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      expect(find.text('Set up group'), findsOneWidget);
    });

    testWidgets('tapping back button navigates back', (tester) async {
      await pumpUserSelectionScreen(tester);

      expect(find.byType(WnSlateNavigationHeader), findsOneWidget);

      final backButton = find.byKey(const Key('slate_back_button'));
      expect(backButton, findsOneWidget);

      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.byType(WnSlateNavigationHeader), findsNothing);
    });

    testWidgets('tapping scan button navigates to scan screen', (tester) async {
      await pumpUserSelectionScreen(tester);

      final scanButton = find.byKey(const Key('scan_button'));
      expect(scanButton, findsOneWidget);

      await tester.tap(scanButton.first);
      await tester.pumpAndSettle();
    });

    group('with initialUsers', () {
      testWidgets('pre-selects initial users as bubbles', (tester) async {
        final initialUsers = [_userFactory(testPubkeyB, displayName: 'Bob')];
        await pumpUserSelectionScreen(tester, initialUsers: initialUsers);

        expect(find.byType(WnUserBubble), findsOneWidget);
        expect(find.byKey(const Key('selected_users_bubbles')), findsOneWidget);
      });

      testWidgets('continue button is enabled when initial users provided', (tester) async {
        final initialUsers = [_userFactory(testPubkeyB, displayName: 'Bob')];
        await pumpUserSelectionScreen(tester, initialUsers: initialUsers);

        final button = tester.widget<WnButton>(find.widgetWithText(WnButton, 'Continue'));
        expect(button.onPressed, isNotNull);
      });

      testWidgets('initial user bubble can be deselected', (tester) async {
        final initialUsers = [_userFactory(testPubkeyB, displayName: 'Bob')];
        await pumpUserSelectionScreen(tester, initialUsers: initialUsers);

        expect(find.byType(WnUserBubble), findsOneWidget);

        await tester.tap(find.byKey(const Key('bubble_$testPubkeyB')));
        await tester.pumpAndSettle();

        expect(find.byType(WnUserBubble), findsNothing);
      });

      testWidgets('without initialUsers shows no pre-selected bubbles', (tester) async {
        await pumpUserSelectionScreen(tester);

        expect(find.byType(WnUserBubble), findsNothing);
      });
    });
  });
}
