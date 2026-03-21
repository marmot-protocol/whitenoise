import 'package:flutter/material.dart' show EditableText, Key, TextField;
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/widgets/wn_input.dart' show WnInputSize;
import 'package:whitenoise/widgets/wn_input_password.dart';
import '../test_helpers.dart' show mountWidget;

void main() {
  group('WnInputPassword', () {
    testWidgets('displays label when provided', (tester) async {
      await mountWidget(
        const WnInputPassword(label: 'Password', placeholder: 'Enter password'),
        tester,
      );
      expect(find.text('Password'), findsOneWidget);
    });

    group('labelHelpIcon', () {
      testWidgets('shows help icon when labelHelpIcon callback provided', (tester) async {
        await mountWidget(
          WnInputPassword(
            label: 'Password',
            placeholder: 'hint',
            labelHelpIcon: () {},
          ),
          tester,
        );
        expect(find.byKey(const Key('label_help_icon')), findsOneWidget);
      });

      testWidgets('calls labelHelpIcon when tapped', (tester) async {
        bool helpTapped = false;
        await mountWidget(
          WnInputPassword(
            label: 'Password',
            placeholder: 'hint',
            labelHelpIcon: () {
              helpTapped = true;
            },
          ),
          tester,
        );
        await tester.tap(find.byKey(const Key('label_help_icon')));
        await tester.pump();
        expect(helpTapped, isTrue);
      });
    });

    testWidgets('displays placeholder', (tester) async {
      await mountWidget(
        const WnInputPassword(label: 'Password', placeholder: 'Enter password'),
        tester,
      );
      expect(find.text('Enter password'), findsOneWidget);
    });

    testWidgets('obscures text by default', (tester) async {
      await mountWidget(
        const WnInputPassword(label: 'Password', placeholder: 'hint'),
        tester,
      );
      await tester.enterText(find.byKey(const Key('password_field')), 'secret');
      await tester.pump();
      final field = tester.widget<EditableText>(find.byType(EditableText));
      expect(field.obscureText, isTrue);
    });

    testWidgets('is not focused by default', (tester) async {
      await mountWidget(
        const WnInputPassword(label: 'Password', placeholder: 'hint'),
        tester,
      );
      final field = tester.widget<EditableText>(find.byType(EditableText));
      expect(field.focusNode.hasFocus, isFalse);
    });

    group('with autofocus', () {
      testWidgets('is focused', (tester) async {
        await mountWidget(
          const WnInputPassword(
            label: 'Password',
            placeholder: 'hint',
            autofocus: true,
          ),
          tester,
        );
        final field = tester.widget<EditableText>(find.byType(EditableText));
        expect(field.focusNode.hasFocus, isTrue);
      });
    });

    group('sizes', () {
      testWidgets('defaults to size56', (tester) async {
        await mountWidget(
          const WnInputPassword(placeholder: 'hint'),
          tester,
        );
        expect(find.byKey(const Key('password_field')), findsOneWidget);
        final containerSize = tester.getSize(
          find.byKey(const Key('password_field_container')),
        );
        expect(containerSize.height, equals(56.0));
      });

      testWidgets('can use size44', (tester) async {
        await mountWidget(
          const WnInputPassword(placeholder: 'hint', size: WnInputSize.size44),
          tester,
        );
        expect(find.byKey(const Key('password_field')), findsOneWidget);
        final containerSize = tester.getSize(
          find.byKey(const Key('password_field_container')),
        );
        expect(containerSize.height, equals(44.0));
      });
    });

    group('visibility toggle', () {
      testWidgets('hidden when field is empty', (tester) async {
        await mountWidget(
          const WnInputPassword(label: 'Password', placeholder: 'hint'),
          tester,
        );
        expect(find.byKey(const Key('visibility_toggle')), findsNothing);
      });

      testWidgets('shows visibility toggle when field has text', (tester) async {
        await mountWidget(
          const WnInputPassword(label: 'Password', placeholder: 'hint'),
          tester,
        );
        await tester.enterText(find.byKey(const Key('password_field')), 'secret');
        await tester.pump();
        expect(find.byKey(const Key('visibility_toggle')), findsOneWidget);
      });

      testWidgets('toggles visibility when tapped', (tester) async {
        await mountWidget(
          const WnInputPassword(label: 'Password', placeholder: 'hint'),
          tester,
        );
        await tester.enterText(find.byKey(const Key('password_field')), 'secret');
        await tester.pump();

        final fieldBefore = tester.widget<EditableText>(find.byType(EditableText));
        expect(fieldBefore.obscureText, isTrue);

        await tester.tap(find.byKey(const Key('visibility_toggle')));
        await tester.pump();

        final fieldAfter = tester.widget<EditableText>(find.byType(EditableText));
        expect(fieldAfter.obscureText, isFalse);

        await tester.tap(find.byKey(const Key('visibility_toggle')));
        await tester.pump();

        final fieldToggleBack = tester.widget<EditableText>(find.byType(EditableText));
        expect(fieldToggleBack.obscureText, isTrue);
      });
    });

    group('with error', () {
      testWidgets('shows error message', (tester) async {
        await mountWidget(
          const WnInputPassword(
            label: 'Password',
            placeholder: 'hint',
            errorText: 'Invalid password',
          ),
          tester,
        );
        expect(find.text('Invalid password'), findsOneWidget);
      });
    });

    group('with helper text', () {
      testWidgets('shows helper text when provided', (tester) async {
        await mountWidget(
          const WnInputPassword(
            label: 'Password',
            placeholder: 'hint',
            helperText: 'Use a strong password',
          ),
          tester,
        );
        expect(find.text('Use a strong password'), findsOneWidget);
      });
    });

    group('scan button', () {
      testWidgets('shows scan button when onScan provided', (tester) async {
        await mountWidget(
          WnInputPassword(
            label: 'Password',
            placeholder: 'hint',
            onScan: () {},
          ),
          tester,
        );
        expect(find.byKey(const Key('scan_button')), findsOneWidget);
      });

      testWidgets(
        'shows scan button alongside visibility toggle when onScan provided and field has text',
        (
          tester,
        ) async {
          await mountWidget(
            WnInputPassword(
              label: 'Password',
              placeholder: 'hint',
              onScan: () {},
            ),
            tester,
          );
          await tester.enterText(find.byKey(const Key('password_field')), 'secret');
          await tester.pump();
          expect(find.byKey(const Key('scan_button')), findsOneWidget);
          expect(find.byKey(const Key('visibility_toggle')), findsOneWidget);
        },
      );

      testWidgets('scan button remains visible when filled', (tester) async {
        await mountWidget(
          WnInputPassword(
            label: 'Password',
            placeholder: 'hint',
            onScan: () {},
          ),
          tester,
        );
        await tester.enterText(find.byKey(const Key('password_field')), 'text');
        await tester.pump();
        expect(find.byKey(const Key('scan_button')), findsOneWidget);
        expect(find.byKey(const Key('visibility_toggle')), findsOneWidget);
      });

      testWidgets('calls onScan when tapped', (tester) async {
        bool scanCalled = false;
        await mountWidget(
          WnInputPassword(
            label: 'Password',
            placeholder: 'hint',
            onScan: () {
              scanCalled = true;
            },
          ),
          tester,
        );
        await tester.tap(find.byKey(const Key('scan_button')));
        await tester.pump();
        expect(scanCalled, isTrue);
      });
    });

    group('paste button', () {
      testWidgets('shows paste button when empty and onPaste provided', (tester) async {
        await mountWidget(
          WnInputPassword(
            label: 'Password',
            placeholder: 'hint',
            onPaste: () {},
          ),
          tester,
        );
        expect(find.byKey(const Key('paste_button')), findsOneWidget);
      });

      testWidgets('shows clear button when filled', (tester) async {
        await mountWidget(
          WnInputPassword(
            label: 'Password',
            placeholder: 'hint',
            onPaste: () {},
          ),
          tester,
        );
        await tester.enterText(find.byKey(const Key('password_field')), 'text');
        await tester.pump();
        expect(find.byKey(const Key('clear_button')), findsOneWidget);
      });

      testWidgets('calls onPaste when tapped', (tester) async {
        bool pasteCalled = false;
        await mountWidget(
          WnInputPassword(
            label: 'Password',
            placeholder: 'hint',
            onPaste: () {
              pasteCalled = true;
            },
          ),
          tester,
        );
        await tester.tap(find.byKey(const Key('paste_button')));
        await tester.pump();
        expect(pasteCalled, isTrue);
      });

      testWidgets('clears field when clear button tapped', (tester) async {
        await mountWidget(
          WnInputPassword(
            label: 'Password',
            placeholder: 'hint',
            onPaste: () {},
          ),
          tester,
        );
        await tester.enterText(find.byKey(const Key('password_field')), 'text');
        await tester.pump();

        await tester.tap(find.byKey(const Key('clear_button')));
        await tester.pump();

        final field = tester.widget<TextField>(find.byKey(const Key('password_field')));
        expect(field.controller?.text, isEmpty);
      });
    });

    group('with disabled state', () {
      testWidgets('field is disabled when enabled is false', (tester) async {
        await mountWidget(
          const WnInputPassword(
            label: 'Password',
            placeholder: 'hint',
            enabled: false,
          ),
          tester,
        );
        final field = tester.widget<TextField>(find.byKey(const Key('password_field')));
        expect(field.enabled, isFalse);
      });
    });
  });
}
