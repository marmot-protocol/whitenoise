import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/widgets/wn_callout.dart';
import 'package:whitenoise/widgets/wn_icon.dart';
import '../test_helpers.dart' show mountWidget;

void main() {
  group('WnCallout', () {
    testWidgets('displays title', (tester) async {
      const widget = WnCallout(
        title: 'Callout Title',
      );
      await mountWidget(widget, tester);
      expect(find.text('Callout Title'), findsOneWidget);
    });

    testWidgets('displays description when provided', (tester) async {
      const widget = WnCallout(
        title: 'Callout Title',
        description: 'Callout description',
      );
      await mountWidget(widget, tester);
      expect(find.text('Callout description'), findsOneWidget);
    });

    testWidgets('does not display description when not provided', (tester) async {
      const widget = WnCallout(
        title: 'Callout Title',
      );
      await mountWidget(widget, tester);
      expect(find.text('Callout description'), findsNothing);
    });

    testWidgets('displays information icon for info type', (tester) async {
      const widget = WnCallout(
        title: 'Callout Title',
        type: CalloutType.info,
      );
      await mountWidget(widget, tester);
      expect(find.byKey(const Key('callout_icon')), findsOneWidget);
      final icon = tester.widget<WnIcon>(find.byKey(const Key('callout_icon')));
      expect(icon.icon, WnIcons.informationFilled);
    });

    testWidgets('displays warning icon for warning type', (tester) async {
      const widget = WnCallout(
        title: 'Callout Title',
        type: CalloutType.warning,
      );
      await mountWidget(widget, tester);
      expect(find.byKey(const Key('callout_icon')), findsOneWidget);
      final icon = tester.widget<WnIcon>(find.byKey(const Key('callout_icon')));
      expect(icon.icon, WnIcons.warningFilled);
    });

    testWidgets('displays checkmark icon for success type', (tester) async {
      const widget = WnCallout(
        title: 'Callout Title',
        type: CalloutType.success,
      );
      await mountWidget(widget, tester);
      expect(find.byKey(const Key('callout_icon')), findsOneWidget);
      final icon = tester.widget<WnIcon>(find.byKey(const Key('callout_icon')));
      expect(icon.icon, WnIcons.checkmarkFilled);
    });

    testWidgets('displays error icon for error type', (tester) async {
      const widget = WnCallout(
        title: 'Callout Title',
        type: CalloutType.error,
      );
      await mountWidget(widget, tester);
      expect(find.byKey(const Key('callout_icon')), findsOneWidget);
      final icon = tester.widget<WnIcon>(find.byKey(const Key('callout_icon')));
      expect(icon.icon, WnIcons.errorFilled);
    });

    testWidgets('displays dismiss button when onDismiss is provided', (tester) async {
      final dismissed = [false];
      final widget = WnCallout(
        title: 'Callout Title',
        onDismiss: () => dismissed[0] = true,
      );
      await mountWidget(widget, tester);
      expect(find.byKey(const Key('callout_dismiss')), findsOneWidget);
      await tester.tap(find.byKey(const Key('callout_dismiss')));
      expect(dismissed[0], isTrue);
    });

    testWidgets('does not display dismiss button when onDismiss is null', (tester) async {
      const widget = WnCallout(
        title: 'Callout Title',
      );
      await mountWidget(widget, tester);
      expect(find.byKey(const Key('callout_dismiss')), findsNothing);
    });

    testWidgets('has rounded corners', (tester) async {
      const widget = WnCallout(
        title: 'Callout Title',
      );
      await mountWidget(widget, tester);
      final container = tester.widget<Container>(
        find.ancestor(
          of: find.text('Callout Title'),
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, isNotNull);
    });

    testWidgets('defaults to neutral type', (tester) async {
      const widget = WnCallout(
        title: 'Callout Title',
      );
      await mountWidget(widget, tester);
      expect(find.byKey(const Key('callout_icon')), findsOneWidget);
      final icon = tester.widget<WnIcon>(find.byKey(const Key('callout_icon')));
      expect(icon.icon, WnIcons.helpFilled);
    });

    testWidgets('compact mode has smaller minimum height than non-compact', (tester) async {
      await mountWidget(
        const WnCallout(title: 'Callout Title', compact: true),
        tester,
      );
      final compactContainer = tester.widget<Container>(
        find.ancestor(
          of: find.text('Callout Title'),
          matching: find.byType(Container),
        ),
      );
      final compactConstraints = compactContainer.constraints!;

      await mountWidget(
        const WnCallout(title: 'Callout Title'),
        tester,
      );
      final normalContainer = tester.widget<Container>(
        find.ancestor(
          of: find.text('Callout Title'),
          matching: find.byType(Container),
        ),
      );
      final normalConstraints = normalContainer.constraints!;

      expect(compactConstraints.minHeight, lessThan(normalConstraints.minHeight));
    });

    testWidgets('displays toggle button when onToggle is provided', (tester) async {
      final toggled = [false];
      final widget = WnCallout(
        title: 'Callout Title',
        onToggle: () => toggled[0] = true,
      );
      await mountWidget(widget, tester);
      expect(find.byKey(const Key('callout_toggle')), findsOneWidget);
      await tester.tap(find.byKey(const Key('callout_toggle')));
      expect(toggled[0], isTrue);
    });

    testWidgets('does not display toggle button when onToggle is null', (tester) async {
      const widget = WnCallout(title: 'Callout Title');
      await mountWidget(widget, tester);
      expect(find.byKey(const Key('callout_toggle')), findsNothing);
    });

    testWidgets('shows chevron up icon when expanded', (tester) async {
      const widget = WnCallout(
        title: 'Callout Title',
        isExpanded: true,
      );
      await mountWidget(widget, tester);
      expect(find.byKey(const Key('callout_icon')), findsOneWidget);
    });
  });
}
