import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/widgets/wn_toggle.dart';

import '../test_helpers.dart';

void main() {
  group('WnToggle', () {
    testWidgets('renders Figma-sized switch', (tester) async {
      await mountWidget(WnToggle(value: false, onChanged: (_) {}), tester);

      final size = tester.getSize(find.byType(WnToggle));

      expect(size.width, 56);
      expect(size.height, 28);
    });

    testWidgets('calls onChanged with toggled value', (tester) async {
      bool? changedValue;
      await mountWidget(
        WnToggle(
          value: false,
          onChanged: (value) => changedValue = value,
        ),
        tester,
      );

      await tester.tap(find.byType(WnToggle));

      expect(changedValue, isTrue);
    });

    testWidgets('does not call onChanged when disabled', (tester) async {
      bool changed = false;
      await mountWidget(
        WnToggle(
          value: false,
          enabled: false,
          onChanged: (_) => changed = true,
        ),
        tester,
      );

      await tester.tap(find.byType(WnToggle));

      expect(changed, isFalse);
    });
  });
}
