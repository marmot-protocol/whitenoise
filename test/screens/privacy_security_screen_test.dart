import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/screens/chat_list_screen.dart';
import 'package:whitenoise/screens/home_screen.dart';
import 'package:whitenoise/screens/privacy_security_screen.dart';
import 'package:whitenoise/services/product_analytics_service.dart';
import 'package:whitenoise/src/rust/api/product_analytics.dart' as rust_analytics;
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_toggle.dart';

import '../mocks/mock_auth_notifier.dart';
import '../mocks/mock_secure_storage.dart';
import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

class _AnalyticsRecorder {
  bool enabled = false;
  final events = <rust_analytics.ProductAnalyticsEventName>[];

  ProductAnalyticsService service() {
    return ProductAnalyticsService(
      readSettings: () async => _settings(),
      setEnabled: ({required enabled, required consentVersion}) async {
        this.enabled = enabled;
        return _settings(consentVersion: consentVersion);
      },
      track: ({required event}) async {
        events.add(event.name);
        return rust_analytics.ProductAnalyticsTrackStatus.queued;
      },
      flush: () async => rust_analytics.ProductAnalyticsFlushStatus.flushed,
      consentVersion: () async => 'test-consent-version',
    );
  }

  rust_analytics.ProductAnalyticsSettings _settings({
    String consentVersion = 'test-consent-version',
  }) {
    final now = DateTime(2026);
    return rust_analytics.ProductAnalyticsSettings(
      enabled: enabled,
      createdAt: now,
      updatedAt: now,
      consentVersion: consentVersion,
    );
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
  });

  Future<void> pumpPrivacySecurityScreen(
    WidgetTester tester, {
    List<dynamic> overrides = const [],
  }) async {
    await mountTestApp(
      tester,
      overrides: [
        authProvider.overrideWith(MockAuthNotifier.new),
        secureStorageProvider.overrideWithValue(MockSecureStorage()),
        ...overrides,
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

    testWidgets('displays device-local analytics consent toggle', (tester) async {
      final analytics = _AnalyticsRecorder();
      await pumpPrivacySecurityScreen(
        tester,
        overrides: [productAnalyticsServiceProvider.overrideWithValue(analytics.service())],
      );

      final toggle = tester.widget<WnToggle>(
        find.byKey(const Key('privacy_security_analytics_consent_toggle')),
      );
      expect(toggle.value, isFalse);
      expect(find.text('Help improve White Noise'), findsOneWidget);
      expect(
        find.text(
          'Share anonymous usage data to help us find bugs and improve the app. '
          'Messages, contacts, and keys are never included.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('analytics toggle updates Rust consent state', (tester) async {
      final analytics = _AnalyticsRecorder();
      await pumpPrivacySecurityScreen(
        tester,
        overrides: [productAnalyticsServiceProvider.overrideWithValue(analytics.service())],
      );

      await tester.tap(find.byKey(const Key('privacy_security_analytics_consent_toggle')));
      await tester.pumpAndSettle();

      expect(analytics.enabled, isTrue);
      expect(analytics.events, isEmpty);
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
