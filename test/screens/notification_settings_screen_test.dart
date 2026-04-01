import 'dart:async' show Completer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncData;
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/screens/notification_settings_screen.dart';
import 'package:whitenoise/src/rust/api/accounts.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/widgets/wn_checkbox.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart';

import '../mocks/mock_secure_storage.dart';
import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

class _BlockableMockApi extends MockWnApi {
  Completer<AccountSettings>? updateCompleter;

  @override
  Future<AccountSettings> crateApiAccountsUpdateNotificationsEnabled({
    required String pubkey,
    required bool enabled,
  }) async {
    if (updateCompleter != null) {
      return updateCompleter!.future;
    }
    return super.crateApiAccountsUpdateNotificationsEnabled(pubkey: pubkey, enabled: enabled);
  }
}

class _MockAuthNotifier extends AuthNotifier {
  final String? pubkey;

  _MockAuthNotifier({this.pubkey = testPubkeyA});

  @override
  Future<String?> build() async {
    if (pubkey != null) {
      state = AsyncData(pubkey);
    }
    return pubkey;
  }
}

void main() {
  late _BlockableMockApi mockApi;

  setUpAll(() {
    mockApi = _BlockableMockApi();
    RustLib.initMock(api: mockApi);
  });

  setUp(() {
    mockApi.reset();
    mockApi.updateCompleter = null;
  });

  late _MockAuthNotifier mockAuth;

  Future<void> pumpScreen(
    WidgetTester tester, {
    String? pubkey = testPubkeyA,
  }) async {
    mockAuth = _MockAuthNotifier(pubkey: pubkey);
    await mountTestApp(
      tester,
      overrides: [
        authProvider.overrideWith(() => mockAuth),
        secureStorageProvider.overrideWithValue(MockSecureStorage()),
      ],
    );
    Routes.pushToNotificationSettings(tester.element(find.byType(Scaffold)));
    await tester.pumpAndSettle();
  }

  group('NotificationSettingsScreen', () {
    testWidgets('renders screen title', (tester) async {
      await pumpScreen(tester);
      expect(find.text('Notifications'), findsWidgets);
    });

    testWidgets('back button pops screen', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byKey(const Key('slate_back_button')));
      await tester.pumpAndSettle();

      expect(find.byType(NotificationSettingsScreen), findsNothing);
    });

    testWidgets('shows checkbox checked when notificationsEnabled: true', (tester) async {
      mockApi.mockNotificationsEnabled = true;
      await pumpScreen(tester);

      final checkbox = tester.widget<WnCheckbox>(find.byType(WnCheckbox));
      expect(checkbox.value, isTrue);
    });

    testWidgets('shows checkbox unchecked when notificationsEnabled: false', (tester) async {
      mockApi.mockNotificationsEnabled = false;
      await pumpScreen(tester);

      final checkbox = tester.widget<WnCheckbox>(find.byType(WnCheckbox));
      expect(checkbox.value, isFalse);
    });

    testWidgets('tapping checkbox calls updateNotificationsEnabled with flipped value', (
      tester,
    ) async {
      mockApi.mockNotificationsEnabled = true;
      await pumpScreen(tester);

      await tester.tap(find.byKey(const Key('notifications_checkbox')));
      await tester.pumpAndSettle();

      expect(mockApi.mockNotificationsEnabled, false);
    });

    testWidgets('checkbox is not interactive while isUpdating', (tester) async {
      mockApi.mockNotificationsEnabled = true;
      final updateCompleter = Completer<AccountSettings>();
      mockApi.updateCompleter = updateCompleter;
      await pumpScreen(tester);

      final checkboxBefore = tester.widget<WnCheckbox>(find.byType(WnCheckbox));
      expect(checkboxBefore.enabled, isTrue);

      await tester.tap(find.byKey(const Key('notifications_checkbox')));
      await tester.pump();

      final checkboxDuring = tester.widget<WnCheckbox>(find.byType(WnCheckbox));
      expect(checkboxDuring.enabled, isFalse);

      updateCompleter.complete(const AccountSettings(notificationsEnabled: false));
      await tester.pumpAndSettle();

      final checkboxAfter = tester.widget<WnCheckbox>(find.byType(WnCheckbox));
      expect(checkboxAfter.enabled, isTrue);
    });

    testWidgets('shows SizedBox.shrink body when pubkey becomes null after initial render', (
      tester,
    ) async {
      await pumpScreen(tester);
      expect(find.byType(NotificationSettingsScreen), findsOneWidget);

      mockAuth.state = const AsyncData(null);
      await tester.pump();

      expect(find.text('Notifications'), findsNothing);
    });

    testWidgets('shows localized error notice when settings fail to load', (tester) async {
      mockApi.shouldFailAccountSettings = true;
      await pumpScreen(tester);

      expect(find.byType(WnSystemNotice), findsOneWidget);
      expect(
        find.text('Could not load notification settings. Please try again.'),
        findsOneWidget,
      );
    });

    testWidgets('shows localized error notice when update fails', (tester) async {
      mockApi.shouldFailUpdateNotificationsEnabled = true;
      await pumpScreen(tester);

      await tester.tap(find.byKey(const Key('notifications_checkbox')));
      await tester.pumpAndSettle();

      expect(find.byType(WnSystemNotice), findsOneWidget);
      expect(
        find.text('Could not update notification settings. Please try again.'),
        findsOneWidget,
      );
    });
  });
}
