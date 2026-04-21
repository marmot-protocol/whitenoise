import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/widgets/wn_pill.dart';
import '../test_helpers.dart' show mountWidget;

void main() {
  group('WnPill', () {
    testWidgets('renders label text', (tester) async {
      await mountWidget(const WnPill(label: 'Legacy'), tester);

      expect(find.text('Legacy'), findsOneWidget);
    });

    testWidgets('renders with custom label', (tester) async {
      await mountWidget(const WnPill(label: 'Debug info'), tester);

      expect(find.text('Debug info'), findsOneWidget);
    });

    testWidgets('renders as stadium-shaped container', (tester) async {
      await mountWidget(const WnPill(label: 'Test'), tester);

      final container = tester.widget<Container>(
        find.ancestor(of: find.text('Test'), matching: find.byType(Container)),
      );
      final decoration = container.decoration as ShapeDecoration;
      expect(decoration.shape, isA<StadiumBorder>());
    });
  });
}
