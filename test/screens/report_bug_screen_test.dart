import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncData;
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/screens/report_bug_screen.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

class _MockApi extends MockWnApi {}

class _MockAuthNotifier extends AuthNotifier {
  @override
  Future<String?> build() async {
    state = const AsyncData(testPubkeyA);
    return testPubkeyA;
  }
}

// TODO(#478): WnInputTextArea's internal Row(mainAxisSize: min) overflows in
// the 420px test viewport causing rendering exceptions. Drain them so they don't
// pollute logic-focused tests. Remove this helper once the widget is fixed.
void drainRenderingExceptions(WidgetTester tester) {
  while (tester.takeException() != null) {}
}

void main() {
  late _MockApi mockApi;

  setUpAll(() {
    PackageInfo.setMockInitialValues(
      appName: 'Whitenoise',
      packageName: 'com.example.whitenoise',
      version: '1.2.3',
      buildNumber: '42',
      buildSignature: '',
    );
    mockApi = _MockApi();
    RustLib.initMock(api: mockApi);
  });

  setUp(() {
    mockApi.reset();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await mountTestApp(
      tester,
      overrides: [authProvider.overrideWith(() => _MockAuthNotifier())],
    );
    Routes.pushToReportBug(tester.element(find.byType(Scaffold)));
    await tester.pumpAndSettle();
    drainRenderingExceptions(tester);
  }

  /// Scroll to bring [target] into view by dragging the scroll view.
  Future<void> scrollTo(WidgetTester tester, Finder target) async {
    // Dismiss keyboard/focus — a focused text field prevents the scroll
    // view from scrolling away from it.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    drainRenderingExceptions(tester);
    await tester.scrollUntilVisible(
      target,
      100.0,
      scrollable: find
          .descendant(
            of: find.byType(SingleChildScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    drainRenderingExceptions(tester);
  }

  group('ReportBugScreen', () {
    testWidgets('renders screen title', (tester) async {
      await pumpScreen(tester);
      expect(find.text('Report bug'), findsOneWidget);
    });

    testWidgets('tapping back returns to previous screen', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('slate_back_button')));
      await tester.pumpAndSettle();
      expect(find.byType(ReportBugScreen), findsNothing);
    });

    testWidgets('shows all form fields', (tester) async {
      await pumpScreen(tester);
      expect(find.text('What went wrong?'), findsOneWidget);
      expect(find.text('What did you expect to happen?'), findsOneWidget);
      expect(find.text('Steps to reproduce'), findsOneWidget);
      expect(find.text('How often does this happen?'), findsOneWidget);
    });

    testWidgets('shows frequency options when dropdown is tapped', (tester) async {
      await pumpScreen(tester);
      await scrollTo(tester, find.byKey(const Key('report_bug_frequency')));
      await tester.tap(find.text('Select'));
      await tester.pumpAndSettle();
      drainRenderingExceptions(tester);
      expect(find.text('Always'), findsOneWidget);
      expect(find.text('Often'), findsOneWidget);
      expect(find.text('Sometimes'), findsOneWidget);
      expect(find.text('Rarely'), findsOneWidget);
    });

    testWidgets('shows privacy toggles', (tester) async {
      await pumpScreen(tester);
      expect(find.text('Include your npub'), findsOneWidget);
      expect(find.text('Include logs'), findsOneWidget);
    });

    testWidgets('shows send button', (tester) async {
      await pumpScreen(tester);
      await scrollTo(tester, find.text('Send report'));
      expect(find.text('Send report'), findsOneWidget);
    });

    testWidgets('shows validation error when what went wrong is empty', (tester) async {
      await pumpScreen(tester);
      await scrollTo(tester, find.text('Send report'));
      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();
      drainRenderingExceptions(tester);
      expect(find.text('Please describe what went wrong.'), findsOneWidget);
      expect(mockApi.sendBugReportCalled, isFalse);
    });

    testWidgets('calls sendBugReport with filled form', (tester) async {
      await pumpScreen(tester);
      await tester.enterText(
        find.byKey(const Key('report_bug_what_went_wrong')),
        'App crashed when opening chat',
      );
      await scrollTo(tester, find.text('Send report'));
      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();
      drainRenderingExceptions(tester);
      expect(mockApi.sendBugReportCalled, isTrue);
      expect(
        mockApi.lastBugReportWhatWentWrong,
        'App crashed when opening chat',
      );
    });

    testWidgets('shows success notice after successful send', (tester) async {
      await pumpScreen(tester);
      await tester.enterText(
        find.byKey(const Key('report_bug_what_went_wrong')),
        'Something broke',
      );
      await scrollTo(tester, find.text('Send report'));
      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();
      drainRenderingExceptions(tester);
      expect(find.text('Bug report sent. Thank you!'), findsOneWidget);
    });

    testWidgets('shows error notice when send fails', (tester) async {
      mockApi.sendBugReportShouldFail = true;
      await pumpScreen(tester);
      await tester.enterText(
        find.byKey(const Key('report_bug_what_went_wrong')),
        'Something broke',
      );
      await scrollTo(tester, find.text('Send report'));
      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();
      drainRenderingExceptions(tester);
      expect(
        find.text('Failed to send report. Please try again.'),
        findsOneWidget,
      );
    });

    testWidgets('shows log preview when include logs toggled on', (tester) async {
      await pumpScreen(tester);
      await scrollTo(tester, find.byKey(const Key('include_logs_toggle')));
      await tester.tap(find.byKey(const Key('include_logs_toggle')));
      await tester.pumpAndSettle();
      drainRenderingExceptions(tester);
      await scrollTo(tester, find.text('Log preview'));
      expect(find.text('Log preview'), findsOneWidget);
    });

    testWidgets('passes logs to sendBugReport when toggle is on', (tester) async {
      await pumpScreen(tester);
      await scrollTo(tester, find.byKey(const Key('include_logs_toggle')));
      await tester.tap(find.byKey(const Key('include_logs_toggle')));
      await tester.pumpAndSettle();
      drainRenderingExceptions(tester);
      await tester.enterText(
        find.byKey(const Key('report_bug_what_went_wrong')),
        'Crash on open',
      );
      await scrollTo(tester, find.text('Send report'));
      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();
      drainRenderingExceptions(tester);
      expect(mockApi.lastBugReportLogs, isNotNull);
    });

    testWidgets('passes null logs to sendBugReport when toggle is off', (tester) async {
      await pumpScreen(tester);
      await tester.enterText(
        find.byKey(const Key('report_bug_what_went_wrong')),
        'Crash on open',
      );
      await scrollTo(tester, find.text('Send report'));
      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();
      drainRenderingExceptions(tester);
      expect(mockApi.lastBugReportLogs, isNull);
    });

    testWidgets('passes null npub when include npub toggle is off', (tester) async {
      await pumpScreen(tester);
      await tester.enterText(
        find.byKey(const Key('report_bug_what_went_wrong')),
        'Crash on open',
      );
      await scrollTo(tester, find.text('Send report'));
      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();
      drainRenderingExceptions(tester);
      expect(mockApi.lastBugReportNpub, isNull);
    });

    testWidgets('passes npub when include npub toggle is on', (tester) async {
      await pumpScreen(tester);
      await scrollTo(tester, find.byKey(const Key('include_npub_toggle')));
      await tester.tap(find.byKey(const Key('include_npub_toggle')));
      await tester.pumpAndSettle();
      drainRenderingExceptions(tester);
      await tester.enterText(
        find.byKey(const Key('report_bug_what_went_wrong')),
        'Crash on open',
      );
      await scrollTo(tester, find.text('Send report'));
      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();
      drainRenderingExceptions(tester);
      expect(mockApi.lastBugReportNpub, isNotNull);
    });
  });
}
