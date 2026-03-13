import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncData;
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:whitenoise/providers/app_version_provider.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/screens/appearance_screen.dart';
import 'package:whitenoise/screens/chat_list_screen.dart';
import 'package:whitenoise/screens/developer_settings_screen.dart';
import 'package:whitenoise/screens/donate_screen.dart';
import 'package:whitenoise/screens/edit_profile_screen.dart';
import 'package:whitenoise/screens/network_screen.dart';
import 'package:whitenoise/screens/privacy_security_screen.dart';
import 'package:whitenoise/screens/profile_keys_screen.dart';
import 'package:whitenoise/screens/share_profile_screen.dart';
import 'package:whitenoise/screens/sign_out_screen.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/widgets/wn_avatar.dart';

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

  @override
  Future<String> crateApiAccountsExportAccountNsec({required String pubkey}) async {
    return 'nsec1test${pubkey.substring(0, 10)}';
  }
}

class _MockAuthNotifier extends AuthNotifier {
  _MockAuthNotifier([this._pubkey = testPubkeyA]);

  final String _pubkey;
  bool logoutCalled = false;

  @override
  Future<String?> build() async {
    state = AsyncData(_pubkey);
    return _pubkey;
  }
}

void main() {
  late _MockApi mockApi;
  const appVersion = '1.2.3+45';

  setUpAll(() {
    mockApi = _MockApi();
    RustLib.initMock(api: mockApi);
    PackageInfo.setMockInitialValues(
      appName: 'Whitenoise',
      packageName: 'com.example.whitenoise',
      version: '1.2.3',
      buildNumber: '45',
      buildSignature: '',
    );
  });

  setUp(() {
    mockApi.reset();
  });

  late _MockAuthNotifier mockAuth;

  Future<void> pumpSettingsScreen(WidgetTester tester) async {
    mockAuth = _MockAuthNotifier();

    await mountTestApp(
      tester,
      overrides: [
        authProvider.overrideWith(() => mockAuth),
        secureStorageProvider.overrideWithValue(MockSecureStorage()),
        appVersionProvider.overrideWith((ref) async => appVersion),
      ],
    );
    Routes.pushToSettings(tester.element(find.byType(Scaffold)));
    await tester.pumpAndSettle();
  }

  group('SettingsScreen', () {
    testWidgets('displays Settings title', (tester) async {
      await pumpSettingsScreen(tester);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('displays user display name', (tester) async {
      await pumpSettingsScreen(tester);
      expect(find.text('Test Display Name'), findsOneWidget);
    });

    testWidgets('displays formatted pubkey under display name', (tester) async {
      await pumpSettingsScreen(tester);
      expect(find.text(testNpubAFormatted), findsOneWidget);
    });

    testWidgets('tapping back button returns to previous screen', (tester) async {
      await pumpSettingsScreen(tester);
      await tester.tap(find.byKey(const Key('slate_back_button')));
      await tester.pumpAndSettle();
      expect(find.byType(ChatListScreen), findsOneWidget);
    });

    testWidgets('tapping Edit profile navigates to EditProfileScreen', (tester) async {
      await pumpSettingsScreen(tester);
      await tester.tap(find.text('Edit profile'));
      await tester.pumpAndSettle();
      expect(find.byType(EditProfileScreen), findsOneWidget);
    });

    testWidgets('tapping Profile keys navigates to ProfileKeysScreen', (tester) async {
      await pumpSettingsScreen(tester);
      await tester.tap(find.text('Profile keys'));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileKeysScreen), findsOneWidget);
    });

    testWidgets('tapping Share & connect button navigates to ShareProfileScreen', (tester) async {
      await pumpSettingsScreen(tester);
      await tester.tap(find.byKey(const Key('share_and_connect_button')));
      await tester.pumpAndSettle();
      expect(find.byType(ShareProfileScreen), findsOneWidget);
    });

    testWidgets('tapping Network relays navigates to NetworkScreen', (tester) async {
      await pumpSettingsScreen(tester);
      await tester.tap(find.text('Network relays'));
      await tester.pumpAndSettle();
      expect(find.byType(NetworkScreen), findsOneWidget);
    });

    testWidgets('tapping Privacy & security navigates to PrivacySecurityScreen', (tester) async {
      await pumpSettingsScreen(tester);
      await tester.tap(find.text('Privacy & security'));
      await tester.pumpAndSettle();
      expect(find.byType(PrivacySecurityScreen), findsOneWidget);
    });

    testWidgets('tapping Appearance navigates to AppearanceScreen', (tester) async {
      await pumpSettingsScreen(tester);
      await tester.tap(find.text('Appearance'));
      await tester.pumpAndSettle();
      expect(find.byType(AppearanceScreen), findsOneWidget);
    });

    testWidgets('tapping Donate navigates to Donate screen', (tester) async {
      await pumpSettingsScreen(tester);
      await tester.tap(find.text('Donate'));
      await tester.pumpAndSettle();
      expect(find.byType(DonateScreen), findsOneWidget);
    });

    testWidgets('tapping Sign out navigates to SignOutScreen', (tester) async {
      await pumpSettingsScreen(tester);
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      expect(find.byType(SignOutScreen), findsOneWidget);
    });

    testWidgets('tapping Developer settings navigates to Developer settings screen', (
      tester,
    ) async {
      await pumpSettingsScreen(tester);
      await tester.tap(find.text('Developer settings'));
      await tester.pumpAndSettle();
      expect(find.byType(DeveloperSettingsScreen), findsOneWidget);
    });

    testWidgets('tapping Switch profile navigates to SwitchProfileScreen', (tester) async {
      await pumpSettingsScreen(tester);
      await tester.tap(find.text('Switch profile'));
      await tester.pumpAndSettle();
      expect(find.text('Profiles'), findsOneWidget);
    });

    testWidgets('renders empty widget when pubkey becomes null', (tester) async {
      await pumpSettingsScreen(tester);

      expect(find.text('Settings'), findsOneWidget);

      mockAuth.state = const AsyncData(null);
      await tester.pump();

      expect(find.text('Edit profile'), findsNothing);
    });

    testWidgets('passes color derived from pubkey to avatar', (tester) async {
      await pumpSettingsScreen(tester);

      final avatar = tester.widget<WnAvatar>(find.byType(WnAvatar));
      expect(avatar.color, AvatarColor.violet);
    });

    testWidgets('different pubkey passes different avatar color', (tester) async {
      await mountTestApp(
        tester,
        overrides: [
          authProvider.overrideWith(() => _MockAuthNotifier(testPubkeyD)),
          secureStorageProvider.overrideWithValue(MockSecureStorage()),
        ],
      );
      Routes.pushToSettings(tester.element(find.byType(Scaffold)));
      await tester.pumpAndSettle();

      final avatar = tester.widget<WnAvatar>(find.byType(WnAvatar));
      expect(avatar.color, AvatarColor.cyan);
    });

    testWidgets('displays "No name" when user has no display name', (tester) async {
      mockApi.returnNoName = true;

      await pumpSettingsScreen(tester);

      expect(find.text('No name'), findsOneWidget);

      mockApi.returnNoName = false;
    });

    testWidgets('displays app version at the bottom', (tester) async {
      await pumpSettingsScreen(tester);

      expect(find.text('v1.2.3+45'), findsOneWidget);
    });
  });
}
