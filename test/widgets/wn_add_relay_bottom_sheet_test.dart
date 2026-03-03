import 'package:flutter/material.dart'
    show FilledButton, Key, Locale, MaterialApp, Scaffold, Builder, ElevatedButton, Text, TextField;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/l10n/generated/app_localizations.dart';
import 'package:whitenoise/widgets/wn_add_relay_bottom_sheet.dart';
import '../test_helpers.dart';

void main() {
  group('WnAddRelayBottomSheet', () {
    testWidgets('displays title', (tester) async {
      final widget = WnAddRelayBottomSheet(
        onRelayAdded: (_) async {},
      );
      await mountWidget(widget, tester);
      expect(find.text('Add Relay'), findsAtLeastNWidgets(1));
    });

    testWidgets('displays input field label', (tester) async {
      final widget = WnAddRelayBottomSheet(
        onRelayAdded: (_) async {},
      );
      await mountWidget(widget, tester);
      expect(find.text('Enter relay address'), findsOneWidget);
    });

    testWidgets('pre-populates input with wss://', (tester) async {
      final widget = WnAddRelayBottomSheet(
        onRelayAdded: (_) async {},
      );
      await mountWidget(widget, tester);
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, 'wss://');
    });

    testWidgets('displays paste button', (tester) async {
      final widget = WnAddRelayBottomSheet(
        onRelayAdded: (_) async {},
      );
      await mountWidget(widget, tester);
      expect(find.byKey(const Key('paste_button')), findsOneWidget);
    });

    testWidgets('displays disabled add button initially', (tester) async {
      final widget = WnAddRelayBottomSheet(
        onRelayAdded: (_) async {},
      );
      await mountWidget(widget, tester);
      final button = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Add Relay').last,
          matching: find.byType(FilledButton),
        ),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('enables add button after valid URL is entered', (tester) async {
      final widget = WnAddRelayBottomSheet(
        onRelayAdded: (_) async {},
      );
      await mountWidget(widget, tester);

      await tester.enterText(find.byType(TextField), 'wss://relay.example.com');
      await tester.pump(const Duration(milliseconds: 600));

      final buttons = find.byType(FilledButton);
      final button = tester.widget<FilledButton>(buttons.last);
      expect(button.onPressed, isNotNull);
    });

    testWidgets('shows error for invalid URL', (tester) async {
      final widget = WnAddRelayBottomSheet(
        onRelayAdded: (_) async {},
      );
      await mountWidget(widget, tester);

      await tester.enterText(find.byType(TextField), 'invalid-url');
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.textContaining('URL must start with wss:// or ws://'), findsOneWidget);
    });

    testWidgets('validates URL must start with wss:// or ws://', (tester) async {
      final widget = WnAddRelayBottomSheet(
        onRelayAdded: (_) async {},
      );
      await mountWidget(widget, tester);

      await tester.enterText(find.byType(TextField), 'https://relay.example.com');
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.textContaining('wss://'), findsWidgets);
    });

    testWidgets('shows error for double wss:// URL', (tester) async {
      final widget = WnAddRelayBottomSheet(
        onRelayAdded: (_) async {},
      );
      await mountWidget(widget, tester);

      await tester.enterText(find.byType(TextField), 'wss://wss://relay.example.com');
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Invalid relay URL'), findsOneWidget);
    });

    testWidgets('shows error for URL with invalid host', (tester) async {
      final widget = WnAddRelayBottomSheet(
        onRelayAdded: (_) async {},
      );
      await mountWidget(widget, tester);

      await tester.enterText(find.byType(TextField), 'wss://localhost');
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Invalid relay URL'), findsOneWidget);
    });

    testWidgets('calls onRelayAdded when add button is tapped', (tester) async {
      setUpTestView(tester);
      String? addedUrl;
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: testDesignSize,
          builder: (_, _) => MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => WnAddRelayBottomSheet.show(
                    context: context,
                    onRelayAdded: (url) async => addedUrl = url,
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'wss://relay.example.com');
      await tester.pump(const Duration(milliseconds: 600));

      await tester.tap(find.byKey(const Key('add_relay_submit_button')));
      await tester.pumpAndSettle();

      expect(addedUrl, 'wss://relay.example.com');
    });

    testWidgets('closes bottom sheet after adding relay', (tester) async {
      setUpTestView(tester);
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: testDesignSize,
          builder: (_, _) => MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => WnAddRelayBottomSheet.show(
                    context: context,
                    onRelayAdded: (_) async {},
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Enter relay address'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'wss://relay.example.com');
      await tester.pump(const Duration(milliseconds: 600));

      await tester.tap(find.byKey(const Key('add_relay_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Enter relay address'), findsNothing);
    });

    group('static show method', () {
      testWidgets('opens modal bottom sheet', (tester) async {
        setUpTestView(tester);
        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: testDesignSize,
            builder: (_, _) => MaterialApp(
              locale: const Locale('en'),
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () => WnAddRelayBottomSheet.show(
                      context: context,
                      onRelayAdded: (_) async {},
                    ),
                    child: const Text('Open Sheet'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Sheet'));
        await tester.pumpAndSettle();

        expect(find.text('Add Relay'), findsAtLeastNWidgets(1));
        expect(find.text('Enter relay address'), findsOneWidget);
      });
    });

    group('empty URL validation', () {
      testWidgets('keeps button disabled for empty wss:// prefix only', (tester) async {
        final widget = WnAddRelayBottomSheet(
          onRelayAdded: (_) async {},
        );
        await mountWidget(widget, tester);

        await tester.enterText(find.byType(TextField), 'wss://');
        await tester.pump(const Duration(milliseconds: 600));

        final buttons = find.byType(FilledButton);
        final button = tester.widget<FilledButton>(buttons.last);
        expect(button.onPressed, isNull);
      });

      testWidgets('keeps button disabled for ws:// prefix only', (tester) async {
        final widget = WnAddRelayBottomSheet(
          onRelayAdded: (_) async {},
        );
        await mountWidget(widget, tester);

        await tester.enterText(find.byType(TextField), 'ws://');
        await tester.pump(const Duration(milliseconds: 600));

        final buttons = find.byType(FilledButton);
        final button = tester.widget<FilledButton>(buttons.last);
        expect(button.onPressed, isNull);
      });

      testWidgets('keeps button disabled for empty string', (tester) async {
        final widget = WnAddRelayBottomSheet(
          onRelayAdded: (_) async {},
        );
        await mountWidget(widget, tester);

        await tester.enterText(find.byType(TextField), '');
        await tester.pump(const Duration(milliseconds: 600));

        final buttons = find.byType(FilledButton);
        final button = tester.widget<FilledButton>(buttons.last);
        expect(button.onPressed, isNull);
      });
    });

    group('clear button', () {
      testWidgets('shows clear button when text is entered', (tester) async {
        final widget = WnAddRelayBottomSheet(
          onRelayAdded: (_) async {},
        );
        await mountWidget(widget, tester);

        await tester.enterText(find.byType(TextField), 'wss://relay.example.com');
        await tester.pump();

        expect(find.byKey(const Key('clear_button')), findsOneWidget);
        expect(find.byKey(const Key('paste_button')), findsNothing);
      });

      testWidgets('clears input when clear button is tapped', (tester) async {
        final widget = WnAddRelayBottomSheet(
          onRelayAdded: (_) async {},
        );
        await mountWidget(widget, tester);

        await tester.enterText(find.byType(TextField), 'wss://relay.example.com');
        await tester.pump();

        await tester.tap(find.byKey(const Key('clear_button')));
        await tester.pump();

        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.controller?.text, 'wss://');
      });

      testWidgets('shows paste button after clearing', (tester) async {
        final widget = WnAddRelayBottomSheet(
          onRelayAdded: (_) async {},
        );
        await mountWidget(widget, tester);

        await tester.enterText(find.byType(TextField), 'wss://relay.example.com');
        await tester.pump();

        expect(find.byKey(const Key('clear_button')), findsOneWidget);

        await tester.tap(find.byKey(const Key('clear_button')));
        await tester.pump();

        expect(find.byKey(const Key('paste_button')), findsOneWidget);
        expect(find.byKey(const Key('clear_button')), findsNothing);
      });

      testWidgets('disables submit button after clearing', (tester) async {
        final widget = WnAddRelayBottomSheet(
          onRelayAdded: (_) async {},
        );
        await mountWidget(widget, tester);

        await tester.enterText(find.byType(TextField), 'wss://relay.example.com');
        await tester.pump(const Duration(milliseconds: 600));

        final buttons = find.byType(FilledButton);
        final buttonBefore = tester.widget<FilledButton>(buttons.last);
        expect(buttonBefore.onPressed, isNotNull);

        await tester.tap(find.byKey(const Key('clear_button')));
        await tester.pump();

        final buttonAfter = tester.widget<FilledButton>(buttons.last);
        expect(buttonAfter.onPressed, isNull);
      });
    });
  });
}
