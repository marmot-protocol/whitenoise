import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/widgets/keyboard_dismiss_on_tap.dart';
import 'package:whitenoise/widgets/wn_input_text_area.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('KeyboardDismissOnTap unfocuses WnInputTextArea on background tap', (tester) async {
    const fieldKey = Key('text_area');
    final focusNode = FocusNode();

    await mountWidget(
      KeyboardDismissOnTap(
        child: Column(
          children: [
            WnInputTextArea(
              key: fieldKey,
              label: 'Label',
              placeholder: 'Placeholder',
              focusNode: focusNode,
            ),
            const Expanded(
              child: SizedBox(),
            ),
          ],
        ),
      ),
      tester,
    );

    final fieldFinder = find.byKey(fieldKey);
    expect(fieldFinder, findsOneWidget);

    await tester.tap(fieldFinder);
    await tester.pumpAndSettle();

    expect(focusNode.hasFocus, isTrue);

    await tester.tap(find.byType(KeyboardDismissOnTap));
    await tester.pumpAndSettle();

    expect(focusNode.hasFocus, isFalse);
  });
}
