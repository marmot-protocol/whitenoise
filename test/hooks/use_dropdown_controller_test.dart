import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/hooks/use_dropdown_controller.dart';
import 'package:whitenoise/widgets/wn_dropdown_selector.dart';

import '../test_helpers.dart';

void main() {
  group('useDropdownController', () {
    testWidgets('returns a WnDropdownController', (tester) async {
      final getController = await mountHook<WnDropdownController>(
        tester,
        useDropdownController,
      );

      expect(getController(), isA<WnDropdownController>());
    });

    testWidgets('returns the same controller across rebuilds', (tester) async {
      final getController = await mountHook<WnDropdownController>(
        tester,
        useDropdownController,
      );

      final first = getController();
      await tester.pump();
      final second = getController();

      expect(identical(first, second), isTrue);
    });

    testWidgets('controller is functional', (tester) async {
      final getController = await mountHook<WnDropdownController>(
        tester,
        useDropdownController,
      );

      final controller = getController();
      expect(controller.openItemKey, isNull);

      controller.open('test');
      expect(controller.isOpen('test'), isTrue);

      controller.close();
      expect(controller.openItemKey, isNull);
    });
  });
}
