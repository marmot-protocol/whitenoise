import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncData;
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:whitenoise/providers/app_version_provider.dart';
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

void main() {
  late _MockApi mockApi;
  const appVersion = '1.2.3+42';

  setUpAll(() {
    mockApi = _MockApi();
    RustLib.initMock(api: mockApi);
    PackageInfo.setMockInitialValues(
      appName: 'Whitenoise',
      packageName: 'com.example.whitenoise',
      version: '1.2.3',
      buildNumber: '42',
      buildSignature: '',
    );
  });

  setUp(() {
    mockApi.reset();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await mountTestApp(
      tester,
      overrides: [
        authProvider.overrideWith(() => _MockAuthNotifier()),
        appVersionProvider.overrideWith((ref) async => appVersion),
      ],
    );
    Routes.pushToReportBug(tester.element(find.byType(Scaffold)));
    await tester.pumpAndSettle();
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
      expect(find.text('Steps to reproduce'), findsOneWidget);
      expect(find.text('How often does this happen?'), findsOneWidget);
    });

    testWidgets('shows frequency options when dropdown is tapped', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.text('Select'));
      await tester.pumpAndSettle();
      expect(find.text('Once'), findsOneWidget);
      expect(find.text('Sometimes'), findsOneWidget);
      expect(find.text('Always'), findsOneWidget);
    });

    testWidgets('shows npub checkbox', (tester) async {
      await pumpScreen(tester);
      expect(find.text('Include your npub'), findsOneWidget);
    });

    testWidgets('tapping npub checkbox row toggles npub inclusion', (tester) async {
      await pumpScreen(tester);

      await tester.enterText(
        find.byKey(const Key('report_bug_description')),
        'Crash on open',
      );

      await tester.tap(find.byKey(const Key('include_npub_checkbox')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();

      expect(mockApi.lastBugReportNpub, isNotNull);
    });

    testWidgets('does not show logs options', (tester) async {
      await pumpScreen(tester);
      expect(find.text('Include logs'), findsNothing);
    });

    testWidgets('shows send button', (tester) async {
      await pumpScreen(tester);
      expect(find.text('Send report'), findsOneWidget);
    });

    testWidgets('shows validation error when description is empty', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();
      expect(find.text('Please describe what went wrong.'), findsOneWidget);
      expect(mockApi.sendBugReportCalled, isFalse);
    });

    testWidgets('calls sendBugReport with filled form', (tester) async {
      await pumpScreen(tester);
      await tester.enterText(
        find.byKey(const Key('report_bug_description')),
        'App crashed when opening chat',
      );
      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();
      expect(mockApi.sendBugReportCalled, isTrue);
      expect(
        mockApi.lastBugReportWhatWentWrong,
        'App crashed when opening chat',
      );
      expect(mockApi.lastBugReportAppVersion, appVersion);
    });

    testWidgets('shows success notice after successful send', (tester) async {
      await pumpScreen(tester);
      await tester.enterText(
        find.byKey(const Key('report_bug_description')),
        'Something broke',
      );
      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();
      expect(find.text('Bug report sent. Thank you!'), findsOneWidget);
    });

    testWidgets('shows error notice when send fails', (tester) async {
      mockApi.sendBugReportShouldFail = true;
      await pumpScreen(tester);
      await tester.enterText(
        find.byKey(const Key('report_bug_description')),
        'Something broke',
      );
      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();
      expect(
        find.text('Failed to send report. Please try again.'),
        findsOneWidget,
      );
    });

    testWidgets('passes null npub when include npub checkbox is unchecked', (tester) async {
      await pumpScreen(tester);
      await tester.enterText(
        find.byKey(const Key('report_bug_description')),
        'Crash on open',
      );
      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();
      expect(mockApi.lastBugReportNpub, isNull);
    });

    testWidgets('passes npub when include npub checkbox is checked', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('include_npub_checkbox')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('report_bug_description')),
        'Crash on open',
      );
      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();
      expect(mockApi.lastBugReportNpub, isNotNull);
    });

    testWidgets('passes null logs to sendBugReport', (tester) async {
      await pumpScreen(tester);
      await tester.enterText(
        find.byKey(const Key('report_bug_description')),
        'Crash on open',
      );
      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();
      expect(mockApi.lastBugReportLogs, isNull);
    });

    testWidgets(
      'tapping frequency dropdown dismisses keyboard when description is focused',
      (tester) async {
        await pumpScreen(tester);

        const descriptionKey = Key('report_bug_description');

        await tester.enterText(
          find.byKey(descriptionKey),
          'Crash on open',
        );
        await tester.pumpAndSettle();

        final editableFinder = find.descendant(
          of: find.byKey(descriptionKey),
          matching: find.byType(EditableText),
        );
        final editableBefore = tester.widget<EditableText>(editableFinder);
        expect(editableBefore.focusNode.hasFocus, isTrue);

        await tester.tap(find.text('Select'));
        await tester.pumpAndSettle();

        final editableAfter = tester.widget<EditableText>(editableFinder);
        expect(editableAfter.focusNode.hasFocus, isFalse);
      },
    );

    testWidgets(
      'tapping npub checkbox dismisses keyboard when description is focused',
      (tester) async {
        await pumpScreen(tester);

        const descriptionKey = Key('report_bug_description');

        await tester.enterText(
          find.byKey(descriptionKey),
          'Crash on open',
        );
        await tester.pumpAndSettle();

        final editableFinder = find.descendant(
          of: find.byKey(descriptionKey),
          matching: find.byType(EditableText),
        );
        final editableBefore = tester.widget<EditableText>(editableFinder);
        expect(editableBefore.focusNode.hasFocus, isTrue);

        await tester.tap(find.byKey(const Key('include_npub_checkbox')));
        await tester.pumpAndSettle();

        final editableAfter = tester.widget<EditableText>(editableFinder);
        expect(editableAfter.focusNode.hasFocus, isFalse);
      },
    );

    testWidgets('shows error notice when app version is not yet loaded', (tester) async {
      final completer = Completer<String>();
      await mountTestApp(
        tester,
        overrides: [
          authProvider.overrideWith(() => _MockAuthNotifier()),
          appVersionProvider.overrideWith((ref) => completer.future),
        ],
      );
      Routes.pushToReportBug(tester.element(find.byType(Scaffold)));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('report_bug_description')),
        'Something broke',
      );
      await tester.tap(find.text('Send report'));
      await tester.pump();

      expect(find.text('Failed to send report. Please try again.'), findsOneWidget);
      expect(mockApi.sendBugReportCalled, isFalse);

      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('clears description validation error when user starts typing', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();
      expect(find.text('Please describe what went wrong.'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('report_bug_description')),
        'a',
      );
      await tester.pump();

      expect(find.text('Please describe what went wrong.'), findsNothing);
    });

    testWidgets('passes frequency value when selected', (tester) async {
      await pumpScreen(tester);
      await tester.enterText(
        find.byKey(const Key('report_bug_description')),
        'Crash on open',
      );
      await tester.tap(find.text('Select'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Always').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();

      expect(mockApi.lastBugReportFrequency, 'always');
    });

    testWidgets('passes null steps to reproduce when empty', (tester) async {
      await pumpScreen(tester);
      await tester.enterText(
        find.byKey(const Key('report_bug_description')),
        'Crash on open',
      );
      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();

      expect(mockApi.lastBugReportStepsToReproduce, isNull);
    });

    testWidgets('passes steps to reproduce when provided', (tester) async {
      await pumpScreen(tester);
      await tester.enterText(
        find.byKey(const Key('report_bug_description')),
        'Crash on open',
      );
      await tester.enterText(
        find.byKey(const Key('report_bug_steps_to_reproduce')),
        '1. Open app\n2. Tap chat\n3. Crash',
      );
      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();

      expect(mockApi.lastBugReportStepsToReproduce, '1. Open app\n2. Tap chat\n3. Crash');
    });
  });
}
