import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/screens/chat_list_screen.dart';
import 'package:whitenoise/screens/home_screen.dart';
import 'package:whitenoise/screens/privacy_security_screen.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/widgets/wn_button.dart';

import '../mocks/mock_auth_notifier.dart';
import '../mocks/mock_secure_storage.dart';
import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

void main() {
  late MockWnApi mockApi;

  setUpAll(() {
    mockApi = MockWnApi();
    RustLib.initMock(api: mockApi);
  });

  setUp(() {
    mockApi.reset();
  });

  Future<void> pumpPrivacySecurityScreen(WidgetTester tester) async {
    await mountTestApp(
      tester,
      overrides: [
        authProvider.overrideWith(MockAuthNotifier.new),
        secureStorageProvider.overrideWithValue(MockSecureStorage()),
      ],
    );
    Routes.pushToPrivacySecurity(tester.element(find.byType(Scaffold)));
    await tester.pumpAndSettle();
  }

  group('PrivacySecurityScreen', () {
    testWidgets('displays Privacy & security title', (tester) async {
      await pumpPrivacySecurityScreen(tester);
      expect(find.text('Privacy & security'), findsOneWidget);
    });

    testWidgets('tapping back icon returns to previous screen', (tester) async {
      await pumpPrivacySecurityScreen(tester);
      await tester.tap(find.byKey(const Key('slate_back_button')));
      await tester.pumpAndSettle();
      expect(find.byType(ChatListScreen), findsOneWidget);
    });

    testWidgets('displays delete all app data section', (tester) async {
      await pumpPrivacySecurityScreen(tester);
      expect(find.text('Delete All App Data'), findsOneWidget);
      expect(find.byKey(const Key('delete_all_data_button')), findsOneWidget);
      expect(find.text('Delete app data'), findsOneWidget);
      expect(
        find.text(
          'Erase every profile, key, chat, and local file from this device.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('tapping delete app data shows confirmation sheet', (tester) async {
      await pumpPrivacySecurityScreen(tester);

      await tester.tap(find.byKey(const Key('delete_all_data_button')));
      await tester.pumpAndSettle();

      expect(find.text('Delete all app data?'), findsOneWidget);
      expect(
        find.text(
          'This will erase every profile, key, chat, and local file from this device. This cannot be undone.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('confirm_button')), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('canceling delete all data does not call API', (tester) async {
      await pumpPrivacySecurityScreen(tester);

      await tester.tap(find.byKey(const Key('delete_all_data_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('cancel_button')));
      await tester.pumpAndSettle();

      expect(mockApi.deleteAllDataCalled, false);
    });

    testWidgets('confirming delete all data calls API and navigates to home', (tester) async {
      await pumpPrivacySecurityScreen(tester);

      await tester.tap(find.byKey(const Key('delete_all_data_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('confirm_button')));
      await tester.pumpAndSettle();

      expect(mockApi.deleteAllDataCalled, true);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('confirm button shows loading during delete operation', (tester) async {
      mockApi.deleteAllDataDelay = const Duration(seconds: 2);

      await pumpPrivacySecurityScreen(tester);

      await tester.tap(find.byKey(const Key('delete_all_data_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('confirm_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final confirmButton = tester.widget<WnButton>(find.byKey(const Key('confirm_button')));
      expect(confirmButton.loading, true);

      await tester.pumpAndSettle();
    });

    testWidgets('delete all data shows error when API fails', (tester) async {
      mockApi.deleteAllDataShouldFail = true;

      await pumpPrivacySecurityScreen(tester);

      await tester.tap(find.byKey(const Key('delete_all_data_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('confirm_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));

      expect(mockApi.deleteAllDataCalled, true);
      expect(find.text('Failed to delete all data. Please try again.'), findsOneWidget);
      expect(find.byType(PrivacySecurityScreen), findsOneWidget);
    });
  });
}
