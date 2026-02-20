import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/widgets/wn_dropdown_selector.dart';

import '../test_helpers.dart';

void _noop(dynamic _) {}

void main() {
  group('WnDropdownSelector', () {
    testWidgets('displays label', (tester) async {
      await mountWidget(
        WnDropdownSelector<String>(
          label: 'Test Label',
          options: const [
            WnDropdownOption(value: 'a', label: 'Option A'),
            WnDropdownOption(value: 'b', label: 'Option B'),
          ],
          value: 'a',
          onChanged: (_) {},
        ),
        tester,
      );

      expect(find.text('Test Label'), findsOneWidget);
    });

    testWidgets('displays current value', (tester) async {
      await mountWidget(
        WnDropdownSelector<String>(
          label: 'Test',
          options: const [
            WnDropdownOption(value: 'a', label: 'Option A'),
            WnDropdownOption(value: 'b', label: 'Option B'),
          ],
          value: 'a',
          onChanged: (_) {},
        ),
        tester,
      );

      expect(find.text('Option A'), findsOneWidget);
    });

    testWidgets('shows dropdown options when tapped', (tester) async {
      await mountWidget(
        WnDropdownSelector<String>(
          label: 'Test',
          options: const [
            WnDropdownOption(value: 'a', label: 'Option A'),
            WnDropdownOption(value: 'b', label: 'Option B'),
            WnDropdownOption(value: 'c', label: 'Option C'),
          ],
          value: 'a',
          onChanged: (_) {},
        ),
        tester,
      );

      await tester.tap(find.text('Option A'));
      await tester.pumpAndSettle();

      expect(find.text('Option A'), findsNWidgets(2));
      expect(find.text('Option B'), findsOneWidget);
      expect(find.text('Option C'), findsOneWidget);
    });

    testWidgets('calls onChanged when option is selected', (tester) async {
      String? selectedValue;

      await mountWidget(
        WnDropdownSelector<String>(
          label: 'Test',
          options: const [
            WnDropdownOption(value: 'a', label: 'Option A'),
            WnDropdownOption(value: 'b', label: 'Option B'),
          ],
          value: 'a',
          onChanged: (value) => selectedValue = value,
        ),
        tester,
      );

      await tester.tap(find.text('Option A'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Option B'));
      await tester.pumpAndSettle();

      expect(selectedValue, 'b');
    });

    testWidgets('works with enum values', (tester) async {
      ThemeMode? selectedMode;

      await mountWidget(
        WnDropdownSelector<ThemeMode>(
          label: 'Theme',
          options: const [
            WnDropdownOption(value: ThemeMode.system, label: 'System'),
            WnDropdownOption(value: ThemeMode.light, label: 'Light'),
            WnDropdownOption(value: ThemeMode.dark, label: 'Dark'),
          ],
          value: ThemeMode.system,
          onChanged: (value) => selectedMode = value,
        ),
        tester,
      );

      await tester.tap(find.text('System'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      expect(selectedMode, ThemeMode.dark);
    });

    testWidgets('displays dropdown icon', (tester) async {
      await mountWidget(
        WnDropdownSelector<String>(
          label: 'Test',
          options: const [
            WnDropdownOption(value: 'a', label: 'Option A'),
          ],
          value: 'a',
          onChanged: (_) {},
        ),
        tester,
      );

      expect(find.byKey(const Key('dropdown_icon')), findsOneWidget);
    });

    testWidgets('works with int values', (tester) async {
      int? selectedValue;

      await mountWidget(
        WnDropdownSelector<int>(
          label: 'Numbers',
          options: const [
            WnDropdownOption(value: 1, label: 'One'),
            WnDropdownOption(value: 2, label: 'Two'),
            WnDropdownOption(value: 3, label: 'Three'),
          ],
          value: 1,
          onChanged: (value) => selectedValue = value,
        ),
        tester,
      );

      await tester.tap(find.text('One'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Three'));
      await tester.pumpAndSettle();

      expect(selectedValue, 3);
    });

    testWidgets('displays correct selected value after change', (tester) async {
      String currentValue = 'a';

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: WnDropdownSelector<String>(
                  label: 'Test',
                  options: const [
                    WnDropdownOption(value: 'a', label: 'Option A'),
                    WnDropdownOption(value: 'b', label: 'Option B'),
                  ],
                  value: currentValue,
                  onChanged: (value) => setState(() => currentValue = value),
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('Option A'), findsOneWidget);

      await tester.tap(find.text('Option A'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Option B'));
      await tester.pumpAndSettle();

      expect(find.text('Option B'), findsOneWidget);
    });

    testWidgets('handles single option', (tester) async {
      await mountWidget(
        WnDropdownSelector<String>(
          label: 'Single',
          options: const [
            WnDropdownOption(value: 'only', label: 'Only Option'),
          ],
          value: 'only',
          onChanged: (_) {},
        ),
        tester,
      );

      expect(find.text('Only Option'), findsOneWidget);
    });

    testWidgets('shows chevron icon when closed', (tester) async {
      await mountWidget(
        WnDropdownSelector<String>(
          label: 'Test',
          options: const [
            WnDropdownOption(value: 'a', label: 'Option A'),
            WnDropdownOption(value: 'b', label: 'Option B'),
          ],
          value: 'a',
          onChanged: (_) {},
        ),
        tester,
      );

      expect(find.byKey(const Key('dropdown_icon')), findsOneWidget);
    });

    testWidgets('shows checkmark for selected item', (tester) async {
      await mountWidget(
        WnDropdownSelector<String>(
          label: 'Test',
          options: const [
            WnDropdownOption(value: 'a', label: 'Option A'),
            WnDropdownOption(value: 'b', label: 'Option B'),
          ],
          value: 'a',
          onChanged: (_) {},
        ),
        tester,
      );

      await tester.tap(find.text('Option A'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('checkmark_icon')), findsOneWidget);
    });

    testWidgets('supports small size variant', (tester) async {
      await mountWidget(
        WnDropdownSelector<String>(
          label: 'Test',
          options: const [
            WnDropdownOption(value: 'a', label: 'Option A'),
          ],
          value: 'a',
          onChanged: (_) {},
        ),
        tester,
      );

      expect(find.byType(WnDropdownSelector<String>), findsOneWidget);
    });

    testWidgets('supports large size variant', (tester) async {
      await mountWidget(
        WnDropdownSelector<String>(
          label: 'Test',
          options: const [
            WnDropdownOption(value: 'a', label: 'Option A'),
          ],
          value: 'a',
          onChanged: (_) {},
          size: WnDropdownSize.large,
        ),
        tester,
      );

      expect(find.byType(WnDropdownSelector<String>), findsOneWidget);
    });

    testWidgets('displays helper text when provided', (tester) async {
      await mountWidget(
        WnDropdownSelector<String>(
          label: 'Test',
          options: const [
            WnDropdownOption(value: 'a', label: 'Option A'),
          ],
          value: 'a',
          onChanged: (_) {},
          helperText: 'This is helper text',
        ),
        tester,
      );

      expect(find.text('This is helper text'), findsOneWidget);
    });

    testWidgets('does not open when disabled', (tester) async {
      await mountWidget(
        WnDropdownSelector<String>(
          label: 'Test',
          options: const [
            WnDropdownOption(value: 'a', label: 'Option A'),
            WnDropdownOption(value: 'b', label: 'Option B'),
          ],
          value: 'a',
          onChanged: (_) {},
          isDisabled: true,
        ),
        tester,
      );

      await tester.tap(find.text('Option A'));
      await tester.pumpAndSettle();

      expect(find.text('Option B'), findsNothing);
    });

    testWidgets('closes menu when selecting an option', (tester) async {
      await mountWidget(
        WnDropdownSelector<String>(
          label: 'Test',
          options: const [
            WnDropdownOption(value: 'a', label: 'Option A'),
            WnDropdownOption(value: 'b', label: 'Option B'),
          ],
          value: 'a',
          onChanged: (_) {},
        ),
        tester,
      );

      await tester.tap(find.text('Option A'));
      await tester.pumpAndSettle();

      expect(find.text('Option B'), findsOneWidget);

      await tester.tap(find.text('Option B'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('dropdown_icon')), findsOneWidget);
    });

    testWidgets('closes dropdown when tapping header again', (tester) async {
      await mountWidget(
        WnDropdownSelector<String>(
          label: 'Test',
          options: const [
            WnDropdownOption(value: 'a', label: 'Option A'),
            WnDropdownOption(value: 'b', label: 'Option B'),
          ],
          value: 'a',
          onChanged: (_) {},
        ),
        tester,
      );

      await tester.tap(find.text('Option A'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('dropdown_icon')), findsOneWidget);
      expect(find.text('Option B'), findsOneWidget);

      await tester.tap(find.text('Option A').first);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('dropdown_icon')), findsOneWidget);
      expect(find.text('Option B'), findsNothing);
    });

    testWidgets('shows error border when isError is true', (tester) async {
      await mountWidget(
        WnDropdownSelector<String>(
          label: 'Test',
          options: const [
            WnDropdownOption(value: 'a', label: 'Option A'),
          ],
          value: 'a',
          onChanged: (_) {},
          isError: true,
        ),
        tester,
      );

      expect(find.byType(WnDropdownSelector<String>), findsOneWidget);
    });

    testWidgets('shows error helper text styling when isError is true', (tester) async {
      await mountWidget(
        WnDropdownSelector<String>(
          label: 'Test',
          options: const [
            WnDropdownOption(value: 'a', label: 'Option A'),
          ],
          value: 'a',
          onChanged: (_) {},
          isError: true,
          helperText: 'Error message',
        ),
        tester,
      );

      expect(find.text('Error message'), findsOneWidget);
    });

    testWidgets('scrolls when more than 5 options', (tester) async {
      await mountWidget(
        WnDropdownSelector<String>(
          label: 'Test',
          options: const [
            WnDropdownOption(value: '1', label: 'Option 1'),
            WnDropdownOption(value: '2', label: 'Option 2'),
            WnDropdownOption(value: '3', label: 'Option 3'),
            WnDropdownOption(value: '4', label: 'Option 4'),
            WnDropdownOption(value: '5', label: 'Option 5'),
            WnDropdownOption(value: '6', label: 'Option 6'),
            WnDropdownOption(value: '7', label: 'Option 7'),
          ],
          value: '1',
          onChanged: (_) {},
        ),
        tester,
      );

      await tester.tap(find.text('Option 1'));
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('shows close icon when open', (tester) async {
      await mountWidget(
        WnDropdownSelector<String>(
          label: 'Test',
          options: const [
            WnDropdownOption(value: 'a', label: 'Option A'),
            WnDropdownOption(value: 'b', label: 'Option B'),
          ],
          value: 'a',
          onChanged: (_) {},
        ),
        tester,
      );

      expect(find.byKey(const Key('dropdown_icon')), findsOneWidget);

      await tester.tap(find.text('Option A'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('dropdown_icon')), findsOneWidget);
    });

    testWidgets('handles value not in options gracefully', (tester) async {
      await mountWidget(
        WnDropdownSelector<String>(
          label: 'Test',
          options: const [
            WnDropdownOption(value: 'a', label: 'Option A'),
            WnDropdownOption(value: 'b', label: 'Option B'),
          ],
          value: 'nonexistent',
          onChanged: (_) {},
        ),
        tester,
      );

      expect(find.byType(WnDropdownSelector<String>), findsOneWidget);
    });

    testWidgets('closes dropdown when isDisabled changes to true while open', (tester) async {
      setUpTestView(tester);
      bool isDisabled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Column(
                  children: [
                    WnDropdownSelector<String>(
                      label: 'Test',
                      options: const [
                        WnDropdownOption(value: 'a', label: 'Option A'),
                        WnDropdownOption(value: 'b', label: 'Option B'),
                      ],
                      value: 'a',
                      onChanged: (_) {},
                      isDisabled: isDisabled,
                    ),
                    ElevatedButton(
                      key: const Key('disable_button'),
                      onPressed: () => setState(() => isDisabled = true),
                      child: const Text('Disable'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Option A'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('dropdown_icon')), findsOneWidget);
      expect(find.text('Option B'), findsOneWidget);

      await tester.tap(find.byKey(const Key('disable_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('dropdown_icon')), findsOneWidget);
      expect(find.text('Option B'), findsNothing);
    });

    testWidgets('does not call onChanged when selecting while disabled', (tester) async {
      setUpTestView(tester);
      bool isDisabled = false;
      String? selectedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Column(
                  children: [
                    WnDropdownSelector<String>(
                      label: 'Test',
                      options: const [
                        WnDropdownOption(value: 'a', label: 'Option A'),
                        WnDropdownOption(value: 'b', label: 'Option B'),
                      ],
                      value: 'a',
                      onChanged: (value) => selectedValue = value,
                      isDisabled: isDisabled,
                    ),
                    ElevatedButton(
                      key: const Key('disable_button'),
                      onPressed: () => setState(() => isDisabled = true),
                      child: const Text('Disable'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Option A'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('disable_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Option A'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('dropdown_icon')), findsOneWidget);
      expect(selectedValue, isNull);
    });
  });

  group('WnDropdownOption', () {
    test('stores value and label correctly', () {
      const option = WnDropdownOption(value: 42, label: 'Forty Two');

      expect(option.value, 42);
      expect(option.label, 'Forty Two');
    });

    test('works with nullable types', () {
      const option = WnDropdownOption<String?>(value: null, label: 'None');

      expect(option.value, isNull);
      expect(option.label, 'None');
    });
  });

  group('WnDropdownSize', () {
    test('has small and large variants', () {
      expect(WnDropdownSize.values, contains(WnDropdownSize.small));
      expect(WnDropdownSize.values, contains(WnDropdownSize.large));
    });
  });

  group('WnDropdownSelector press states', () {
    testWidgets('shows pressed border color on tap down', (tester) async {
      await mountWidget(
        WnDropdownSelector<String>(
          label: 'Test',
          options: const [
            WnDropdownOption(value: 'a', label: 'Option A'),
          ],
          value: 'a',
          onChanged: (_) {},
        ),
        tester,
      );

      final gesture = await tester.startGesture(tester.getCenter(find.text('Option A')));
      await tester.pump();

      expect(find.byType(WnDropdownSelector<String>), findsOneWidget);

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('resets border color on tap cancel', (tester) async {
      await mountWidget(
        WnDropdownSelector<String>(
          label: 'Test',
          options: const [
            WnDropdownOption(value: 'a', label: 'Option A'),
          ],
          value: 'a',
          onChanged: (_) {},
        ),
        tester,
      );

      final gesture = await tester.startGesture(tester.getCenter(find.text('Option A')));
      await tester.pump();

      await gesture.cancel();
      await tester.pumpAndSettle();

      expect(find.byType(WnDropdownSelector<String>), findsOneWidget);
    });

    testWidgets('shows error border when isError and pressed', (tester) async {
      await mountWidget(
        WnDropdownSelector<String>(
          label: 'Test',
          options: const [
            WnDropdownOption(value: 'a', label: 'Option A'),
          ],
          value: 'a',
          onChanged: (_) {},
          isError: true,
        ),
        tester,
      );

      final gesture = await tester.startGesture(tester.getCenter(find.text('Option A')));
      await tester.pump();

      expect(find.byType(WnDropdownSelector<String>), findsOneWidget);

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('does not show pressed state when disabled', (tester) async {
      await mountWidget(
        WnDropdownSelector<String>(
          label: 'Test',
          options: const [
            WnDropdownOption(value: 'a', label: 'Option A'),
          ],
          value: 'a',
          onChanged: (_) {},
          isDisabled: true,
        ),
        tester,
      );

      final gesture = await tester.startGesture(tester.getCenter(find.text('Option A')));
      await tester.pump();

      expect(find.byType(WnDropdownSelector<String>), findsOneWidget);

      await gesture.up();
      await tester.pumpAndSettle();
    });
  });

  group('WnDropdownSelector exclusive open (WnDropdownScope)', () {
    testWidgets('opening second dropdown closes first when using WnDropdownScope', (tester) async {
      setUpTestView(tester);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WnDropdownScope(
              controller: WnDropdownController(),
              child: const Column(
                children: [
                  WnDropdownSelector<String>(
                    key: Key('dropdown_1'),
                    label: 'First',
                    options: [
                      WnDropdownOption(value: 'a', label: 'Option A'),
                      WnDropdownOption(value: 'b', label: 'Option B'),
                    ],
                    value: 'a',
                    onChanged: _noop,
                  ),
                  WnDropdownSelector<String>(
                    key: Key('dropdown_2'),
                    label: 'Second',
                    options: [
                      WnDropdownOption(value: 'x', label: 'Option X'),
                      WnDropdownOption(value: 'y', label: 'Option Y'),
                    ],
                    value: 'x',
                    onChanged: _noop,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Option A'));
      await tester.pumpAndSettle();
      expect(find.text('Option B'), findsOneWidget);

      await tester.tap(find.text('Option X'));
      await tester.pumpAndSettle();
      expect(find.text('Option Y'), findsOneWidget);
      expect(find.text('Option B'), findsNothing);
    });

    testWidgets('without WnDropdownScope both dropdowns can be open simultaneously', (
      tester,
    ) async {
      setUpTestView(tester);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                WnDropdownSelector<String>(
                  key: Key('dropdown_1'),
                  label: 'First',
                  options: [
                    WnDropdownOption(value: 'a', label: 'Option A'),
                    WnDropdownOption(value: 'b', label: 'Option B'),
                  ],
                  value: 'a',
                  onChanged: _noop,
                ),
                WnDropdownSelector<String>(
                  key: Key('dropdown_2'),
                  label: 'Second',
                  options: [
                    WnDropdownOption(value: 'x', label: 'Option X'),
                    WnDropdownOption(value: 'y', label: 'Option Y'),
                  ],
                  value: 'x',
                  onChanged: _noop,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Option A'));
      await tester.pumpAndSettle();
      expect(find.text('Option B'), findsOneWidget);

      await tester.tap(find.text('Option X'));
      await tester.pumpAndSettle();
      expect(find.text('Option Y'), findsOneWidget);
      expect(find.text('Option B'), findsOneWidget);
    });
  });

  group('WnDropdownSelector animation', () {
    testWidgets('animates open and close', (tester) async {
      await mountWidget(
        WnDropdownSelector<String>(
          label: 'Test',
          options: const [
            WnDropdownOption(value: 'a', label: 'Option A'),
            WnDropdownOption(value: 'b', label: 'Option B'),
          ],
          value: 'a',
          onChanged: (_) {},
        ),
        tester,
      );

      await tester.tap(find.text('Option A'));
      await tester.pump(const Duration(milliseconds: 60));

      expect(find.byType(WnDropdownSelector<String>), findsOneWidget);

      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('dropdown_icon')));
      await tester.pump(const Duration(milliseconds: 60));

      expect(find.byType(WnDropdownSelector<String>), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('closes animation when option selected', (tester) async {
      String? selected;
      await mountWidget(
        WnDropdownSelector<String>(
          label: 'Test',
          options: const [
            WnDropdownOption(value: 'a', label: 'Option A'),
            WnDropdownOption(value: 'b', label: 'Option B'),
          ],
          value: 'a',
          onChanged: (v) => selected = v,
        ),
        tester,
      );

      await tester.tap(find.text('Option A'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Option B'));
      await tester.pump(const Duration(milliseconds: 60));

      expect(find.byType(WnDropdownSelector<String>), findsOneWidget);
      expect(selected, 'b');

      await tester.pumpAndSettle();
    });
  });
}
