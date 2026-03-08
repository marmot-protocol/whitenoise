import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/screens/fatal_error_screen.dart';

import '../test_helpers.dart';

void main() {
  Future<void> pumpFatalErrorScreen(
    WidgetTester tester, {
    Object? error,
    StackTrace? stackTrace,
    bool showDiagnostics = true,
  }) async {
    setUpTestView(tester);
    await tester.pumpWidget(
      FatalErrorScreen(
        error: error ?? StateError('Content hash mismatch'),
        stackTrace: stackTrace,
        showDiagnostics: showDiagnostics,
      ),
    );
  }

  group('FatalErrorScreen', () {
    group('renders without RustLib initialized', () {
      testWidgets('mounts successfully with no bridge dependency', (tester) async {
        await pumpFatalErrorScreen(tester);
        expect(find.byType(FatalErrorScreen), findsOneWidget);
      });
    });

    group('layout', () {
      testWidgets('shows warning icon', (tester) async {
        await pumpFatalErrorScreen(tester);
        expect(find.byKey(const Key('fatal_error_icon')), findsOneWidget);
      });

      testWidgets('shows a title', (tester) async {
        await pumpFatalErrorScreen(tester);
        expect(find.byKey(const Key('fatal_error_title')), findsOneWidget);
      });

      testWidgets('shows a message', (tester) async {
        await pumpFatalErrorScreen(tester);
        expect(find.byKey(const Key('fatal_error_message')), findsOneWidget);
      });
    });

    group('staging build (showDiagnostics: true)', () {
      testWidgets('title says Bindings out of date', (tester) async {
        await pumpFatalErrorScreen(tester, showDiagnostics: true);
        expect(find.text('Bindings out of date'), findsOneWidget);
      });

      testWidgets('message mentions just generate', (tester) async {
        await pumpFatalErrorScreen(tester, showDiagnostics: true);
        expect(find.textContaining('just generate'), findsOneWidget);
      });

      testWidgets('shows error detail box', (tester) async {
        await pumpFatalErrorScreen(tester, showDiagnostics: true);
        expect(find.byKey(const Key('fatal_error_detail_box')), findsOneWidget);
      });

      testWidgets('shows copy button', (tester) async {
        await pumpFatalErrorScreen(tester, showDiagnostics: true);
        expect(find.byKey(const Key('fatal_error_copy_button')), findsOneWidget);
      });

      testWidgets('detail box contains the error message', (tester) async {
        final error = StateError('test content hash mismatch');
        await pumpFatalErrorScreen(tester, error: error, showDiagnostics: true);
        expect(find.textContaining('test content hash mismatch'), findsOneWidget);
      });

      testWidgets('detail box contains the stack trace when provided', (tester) async {
        final stackTrace = StackTrace.fromString('at main (main.dart:53:3)');
        await pumpFatalErrorScreen(
          tester,
          error: StateError('hash mismatch'),
          stackTrace: stackTrace,
          showDiagnostics: true,
        );
        expect(find.textContaining('at main'), findsOneWidget);
      });

      testWidgets('copy button writes error text to clipboard', (tester) async {
        final clipboardData = <String?>[];
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (MethodCall call) async {
            if (call.method == 'Clipboard.setData') {
              final args = call.arguments as Map;
              clipboardData.add(args['text'] as String?);
            }
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );

        final error = StateError('hash mismatch error');
        await pumpFatalErrorScreen(tester, error: error, showDiagnostics: true);
        await tester.tap(find.byKey(const Key('fatal_error_copy_button')));
        await tester.pump();

        expect(clipboardData, isNotEmpty);
        expect(clipboardData.first, contains('hash mismatch error'));
      });
    });

    group('production build (showDiagnostics: false)', () {
      testWidgets('title says Something went wrong', (tester) async {
        await pumpFatalErrorScreen(tester, showDiagnostics: false);
        expect(find.text('Something went wrong'), findsOneWidget);
      });

      testWidgets('message mentions reinstall', (tester) async {
        await pumpFatalErrorScreen(tester, showDiagnostics: false);
        expect(find.textContaining('reinstall'), findsOneWidget);
      });

      testWidgets('does not show error detail box', (tester) async {
        await pumpFatalErrorScreen(tester, showDiagnostics: false);
        expect(find.byKey(const Key('fatal_error_detail_box')), findsNothing);
      });

      testWidgets('does not show copy button', (tester) async {
        await pumpFatalErrorScreen(tester, showDiagnostics: false);
        expect(find.byKey(const Key('fatal_error_copy_button')), findsNothing);
      });
    });

    group('accepts any error type', () {
      testWidgets('renders with a generic Exception', (tester) async {
        await pumpFatalErrorScreen(tester, error: Exception('DB init failed'));
        expect(find.byType(FatalErrorScreen), findsOneWidget);
      });

      testWidgets('renders with a String error', (tester) async {
        await pumpFatalErrorScreen(tester, error: 'unexpected crash');
        expect(find.byType(FatalErrorScreen), findsOneWidget);
      });
    });
  });
}
