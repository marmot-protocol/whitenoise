import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/screens/fatal_error_screen.dart';
import 'package:whitenoise/widgets/wn_callout.dart';

import '../test_helpers.dart';

void main() {
  Future<void> pumpFatalErrorScreen(
    WidgetTester tester, {
    String? errorMessage,
    StackTrace? stackTrace,
  }) async {
    setUpTestView(tester);
    await tester.pumpWidget(
      FatalErrorScreen(
        errorMessage: errorMessage ?? 'Content hash mismatch',
        stackTrace: stackTrace,
      ),
    );
    await tester.pumpAndSettle();
  }

  group('FatalErrorScreen', () {
    group('layout', () {
      testWidgets('displays whitenoise logo', (tester) async {
        await pumpFatalErrorScreen(tester);
        expect(find.byKey(const Key('whitenoise_logo')), findsOneWidget);
      });

      testWidgets('displays first slogan initially', (tester) async {
        await pumpFatalErrorScreen(tester);

        expect(find.text('Decentralized'), findsOneWidget);
        expect(find.text('Uncensorable'), findsNothing);
        expect(find.text('Secure Messaging'), findsNothing);
      });

      testWidgets('rotates to next slogan after interval', (tester) async {
        await pumpFatalErrorScreen(tester);

        expect(find.text('Decentralized'), findsOneWidget);

        await tester.pump(const Duration(seconds: 3));
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('Uncensorable'), findsOneWidget);
      });

      testWidgets('cycles back to first slogan after all shown', (tester) async {
        await pumpFatalErrorScreen(tester);

        expect(find.text('Decentralized'), findsOneWidget);

        await tester.pump(const Duration(seconds: 3));
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('Uncensorable'), findsOneWidget);

        await tester.pump(const Duration(seconds: 3));
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('Secure Messaging'), findsOneWidget);

        await tester.pump(const Duration(seconds: 3));
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('Decentralized'), findsOneWidget);
      });

      testWidgets('shows error callout with "Oh no!" title', (tester) async {
        await pumpFatalErrorScreen(tester);
        expect(find.text('Oh no!'), findsOneWidget);
        expect(find.byType(WnCallout), findsOneWidget);
      });

      testWidgets('shows error callout with description', (tester) async {
        await pumpFatalErrorScreen(tester);
        expect(
          find.textContaining('We hit a bump loading the app'),
          findsOneWidget,
        );
      });

      testWidgets('shows error callout icon', (tester) async {
        await pumpFatalErrorScreen(tester);
        expect(find.byKey(const Key('callout_icon')), findsOneWidget);
      });

      testWidgets('shows copy error button', (tester) async {
        await pumpFatalErrorScreen(tester);
        expect(find.byKey(const Key('fatal_error_copy_button')), findsOneWidget);
        expect(find.text('Copy error'), findsOneWidget);
      });
    });

    group('copy functionality', () {
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

        const errorMessage = 'test error';
        await pumpFatalErrorScreen(tester, errorMessage: errorMessage);
        await tester.tap(find.byKey(const Key('fatal_error_copy_button')));
        await tester.pumpAndSettle();

        expect(clipboardData, isNotEmpty);
        expect(clipboardData.first, contains('test error'));
      });

      testWidgets('copy button shows success notice', (tester) async {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (MethodCall call) async => null,
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );

        await pumpFatalErrorScreen(tester);
        await tester.tap(find.byKey(const Key('fatal_error_copy_button')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('fatal_error_notice')), findsOneWidget);
        expect(find.text('Error copied to clipboard'), findsOneWidget);
      });

      testWidgets('success notice auto dismisses after default duration', (tester) async {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (MethodCall call) async => null,
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );

        await pumpFatalErrorScreen(tester);
        await tester.tap(find.byKey(const Key('fatal_error_copy_button')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('fatal_error_notice')), findsOneWidget);

        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('fatal_error_notice')), findsNothing);
      });

      testWidgets('copy button includes stack trace when provided', (tester) async {
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

        final stackTrace = StackTrace.fromString('at main (main.dart:53:3)');
        await pumpFatalErrorScreen(
          tester,
          errorMessage: 'test error',
          stackTrace: stackTrace,
        );
        await tester.tap(find.byKey(const Key('fatal_error_copy_button')));
        await tester.pumpAndSettle();

        expect(clipboardData.first, contains('at main'));
      });
    });
  });
}
