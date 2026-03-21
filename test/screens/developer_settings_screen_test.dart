import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncData;
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/screens/app_logs_screen.dart';
import 'package:whitenoise/screens/developer_settings_screen.dart';
import 'package:whitenoise/screens/relay_control_state_screen.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';

import '../mocks/mock_secure_storage.dart';
import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

class _MockApi extends MockWnApi {
  @override
  Future<FlutterMetadata> crateApiUsersUserMetadata({
    required bool blockingDataSync,
    required String pubkey,
  }) async => const FlutterMetadata(name: 'Test', custom: {});
}

class _MockAuthNotifier extends AuthNotifier {
  @override
  Future<String?> build() async {
    state = const AsyncData(testPubkeyA);
    return testPubkeyA;
  }
}

void main() {
  late _MockApi mockApi;

  setUpAll(() {
    mockApi = _MockApi();
    RustLib.initMock(api: mockApi);
  });

  setUp(() {
    mockApi.reset();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await mountTestApp(
      tester,
      overrides: [
        authProvider.overrideWith(() => _MockAuthNotifier()),
        secureStorageProvider.overrideWithValue(MockSecureStorage()),
      ],
    );
    Routes.pushToDeveloperSettings(tester.element(find.byType(Scaffold)));
    await tester.pumpAndSettle();
  }

  group('DeveloperSettingsScreen', () {
    testWidgets('displays Developer Settings title', (tester) async {
      await pumpScreen(tester);
      expect(find.text('Developer Settings'), findsOneWidget);
    });

    testWidgets('tapping back icon returns to previous screen', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('slate_back_button')));
      await tester.pumpAndSettle();
      expect(find.byType(DeveloperSettingsScreen), findsNothing);
    });

    group('staging-only settings', () {
      testWidgets('tapping debug view toggle row toggles the switch', (tester) async {
        await pumpScreen(tester);

        final switchBefore = tester.widget<Switch>(
          find.byKey(const Key('debug_view_switch')),
        );
        expect(switchBefore.value, isFalse);

        await tester.tap(find.byKey(const Key('debug_view_toggle_row')));
        await tester.pumpAndSettle();

        final switchAfter = tester.widget<Switch>(
          find.byKey(const Key('debug_view_switch')),
        );
        expect(switchAfter.value, isTrue);
      });

      testWidgets('tapping debug view switch toggles the value', (tester) async {
        await pumpScreen(tester);

        await tester.tap(find.byKey(const Key('debug_view_switch')));
        await tester.pumpAndSettle();

        final switchAfter = tester.widget<Switch>(
          find.byKey(const Key('debug_view_switch')),
        );
        expect(switchAfter.value, isTrue);
      });

      testWidgets('tapping View Logs row navigates to app logs screen', (tester) async {
        await pumpScreen(tester);

        await tester.tap(find.byKey(const Key('view_logs_row')));
        await tester.pumpAndSettle();

        expect(find.byType(AppLogsScreen), findsOneWidget);
      });

      testWidgets('tapping key package row navigates to key package screen', (tester) async {
        await pumpScreen(tester);

        await tester.tap(find.byKey(const Key('key_package_management_row')));
        await tester.pumpAndSettle();

        expect(find.text('Key Package Management'), findsOneWidget);
      });

      testWidgets('tapping relay state row navigates to relay state screen', (tester) async {
        await pumpScreen(tester);

        await tester.tap(find.byKey(const Key('relay_state_row')));
        await tester.pumpAndSettle();

        expect(find.byType(RelayControlStateScreen), findsOneWidget);
      });

      testWidgets('tapping back in app logs screen returns to developer settings', (tester) async {
        await pumpScreen(tester);

        await tester.tap(find.byKey(const Key('view_logs_row')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('slate_back_button')));
        await tester.pumpAndSettle();

        expect(find.byType(DeveloperSettingsScreen), findsOneWidget);
      });
    });
  });
}
