import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/widgets/wn_checkbox.dart';
import 'package:whitenoise/widgets/wn_icon.dart';
import '../test_helpers.dart' show mountWidget;

void main() {
  group('WnCheckbox', () {
    testWidgets('renders label and description', (tester) async {
      await mountWidget(
        WnCheckbox(
          label: 'Test Label',
          description: 'Test Description',
          value: false,
          onChanged: (_) {},
        ),
        tester,
      );

      expect(find.text('Test Label'), findsOneWidget);
      expect(find.text('Test Description'), findsOneWidget);
    });

    testWidgets('renders without description', (tester) async {
      await mountWidget(
        WnCheckbox(
          label: 'Test Label',
          value: false,
          onChanged: (_) {},
        ),
        tester,
      );

      expect(find.text('Test Label'), findsOneWidget);
    });

    testWidgets('calls onChanged when tapped', (tester) async {
      var changed = false;

      await mountWidget(
        WnCheckbox(
          label: 'Test Label',
          value: false,
          onChanged: (v) => changed = v,
        ),
        tester,
      );

      await tester.tap(find.byType(WnCheckbox));
      await tester.pump();

      expect(changed, isTrue);
    });

    testWidgets('toggles value on tap', (tester) async {
      var value = false;

      await mountWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return WnCheckbox(
              label: 'Test Label',
              value: value,
              onChanged: (v) => setState(() => value = v),
            );
          },
        ),
        tester,
      );

      await tester.tap(find.byType(WnCheckbox));
      await tester.pump();

      expect(value, isTrue);

      await tester.tap(find.byType(WnCheckbox));
      await tester.pump();

      expect(value, isFalse);
    });

    testWidgets('uses provided checkboxKey', (tester) async {
      const testKey = Key('test_checkbox');

      await mountWidget(
        WnCheckbox(
          label: 'Test Label',
          value: false,
          onChanged: (_) {},
          checkboxKey: testKey,
        ),
        tester,
      );

      expect(find.byKey(testKey), findsOneWidget);
    });

    testWidgets('checkbox shows correct icon for value', (tester) async {
      await mountWidget(
        WnCheckbox(
          label: 'Test Label',
          value: true,
          onChanged: (_) {},
        ),
        tester,
      );

      final icon = tester.widget<WnIcon>(find.byType(WnIcon));
      expect(icon.icon, WnIcons.checkboxChecked);
    });

    testWidgets('unfocuses current field when tapped', (tester) async {
      final focusNode = FocusNode();

      await mountWidget(
        Column(
          children: [
            TextField(
              key: const Key('focus_target'),
              focusNode: focusNode,
            ),
            WnCheckbox(
              label: 'Test Label',
              value: false,
              onChanged: (_) {},
            ),
          ],
        ),
        tester,
      );

      await tester.tap(find.byKey(const Key('focus_target')));
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);

      await tester.tap(find.byType(WnCheckbox));
      await tester.pump();

      expect(focusNode.hasFocus, isFalse);
    });
  });
}
