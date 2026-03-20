import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncData;
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/screens/add_profile_screen.dart';
import 'package:whitenoise/screens/switch_profile_screen.dart';
import 'package:whitenoise/src/rust/api/accounts.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/widgets/wn_profile_switcher_item.dart';

import '../mocks/mock_secure_storage.dart';
import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

class _MockApi extends MockWnApi {
  bool returnNoName = false;

  @override
  Future<FlutterMetadata> crateApiUsersUserMetadata({
    required bool blockingDataSync,
    required String pubkey,
  }) async {
    if (returnNoName) {
      return const FlutterMetadata(custom: {});
    }
    return const FlutterMetadata(
      name: 'Test User',
      displayName: 'Test Display Name',
      custom: {},
    );
  }
}

class _MockAuthNotifier extends AuthNotifier {
  @override
  Future<String?> build() async {
    state = const AsyncData(testPubkeyA);
    return testPubkeyA;
  }
}

class _FailingSwitchAuthNotifier extends AuthNotifier {
  @override
  Future<String?> build() async {
    state = const AsyncData(testPubkeyA);
    return testPubkeyA;
  }

  @override
  Future<void> switchProfile(String pubkey) async {
    throw Exception('Switch failed');
  }
}

Account _makeAccount(String pubkey) => Account(
  pubkey: pubkey,
  accountType: AccountType.local,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

void main() {
  late _MockApi mockApi;

  setUpAll(() {
    mockApi = _MockApi();
    RustLib.initMock(api: mockApi);
  });

  setUp(() {
    mockApi.reset();
    mockApi.accounts = [_makeAccount(testPubkeyA)];
  });

  Future<void> pumpSwitchProfileScreen(WidgetTester tester) async {
    await mountTestApp(
      tester,
      overrides: [
        authProvider.overrideWith(() => _MockAuthNotifier()),
        secureStorageProvider.overrideWithValue(MockSecureStorage()),
      ],
    );
    Routes.pushToSwitchProfile(tester.element(find.byType(Scaffold)));
    await tester.pumpAndSettle();
  }

  group('SwitchProfileScreen', () {
    testWidgets('displays Profiles title', (tester) async {
      await pumpSwitchProfileScreen(tester);
      expect(find.text('Profiles'), findsOneWidget);
    });

    testWidgets('displays account display name', (tester) async {
      await pumpSwitchProfileScreen(tester);
      expect(find.text('Test Display Name'), findsOneWidget);
    });

    testWidgets('displays "No name" when account has no display name', (tester) async {
      mockApi.returnNoName = true;

      await pumpSwitchProfileScreen(tester);

      expect(find.text('No name'), findsOneWidget);
    });

    testWidgets('displays "No accounts available" when account list is empty', (tester) async {
      mockApi.accounts = [];

      await pumpSwitchProfileScreen(tester);

      expect(find.text('No accounts available'), findsOneWidget);
    });

    testWidgets('displays Connect Another Profile button', (tester) async {
      await pumpSwitchProfileScreen(tester);
      expect(find.text('Connect Another Profile'), findsOneWidget);
    });

    testWidgets('tapping Connect Another Profile navigates to AddProfileScreen', (tester) async {
      await pumpSwitchProfileScreen(tester);
      await tester.tap(find.text('Connect Another Profile'));
      await tester.pumpAndSettle();
      expect(find.byType(AddProfileScreen), findsOneWidget);
    });

    testWidgets('tapping back button returns to previous screen', (tester) async {
      await pumpSwitchProfileScreen(tester);
      await tester.tap(find.byKey(const Key('slate_back_button')));
      await tester.pumpAndSettle();
      expect(find.byType(SwitchProfileScreen), findsNothing);
    });

    testWidgets('shows error when switching profile fails', (tester) async {
      mockApi.accounts = [
        _makeAccount(testPubkeyA),
        _makeAccount(testPubkeyB),
      ];

      await mountTestApp(
        tester,
        overrides: [
          authProvider.overrideWith(() => _FailingSwitchAuthNotifier()),
          secureStorageProvider.overrideWithValue(MockSecureStorage()),
        ],
      );
      Routes.pushToSwitchProfile(tester.element(find.byType(Scaffold)));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(WnProfileSwitcherItem).at(1));
      await tester.pumpAndSettle();

      expect(find.text('Failed to switch profile. Please try again.'), findsOneWidget);
    });

    testWidgets('displays multiple accounts', (tester) async {
      mockApi.accounts = [
        _makeAccount(testPubkeyA),
        _makeAccount(testPubkeyB),
      ];

      await mountTestApp(
        tester,
        overrides: [
          authProvider.overrideWith(() => _MockAuthNotifier()),
          secureStorageProvider.overrideWithValue(MockSecureStorage()),
        ],
      );
      Routes.pushToSwitchProfile(tester.element(find.byType(Scaffold)));
      await tester.pumpAndSettle();

      expect(find.byType(WnProfileSwitcherItem), findsNWidgets(2));
    });
  });
}
