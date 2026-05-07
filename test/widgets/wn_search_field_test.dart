import 'package:flutter/material.dart'
    show
        BuildContext,
        Builder,
        CircularProgressIndicator,
        EditableText,
        Key,
        TextField,
        TextEditingController,
        kMinInteractiveDimension;
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/theme/semantic_colors.dart' show SemanticColors;
import 'package:whitenoise/widgets/wn_search_field.dart' show WnSearchField;
import '../test_helpers.dart' show mountWidget;

void main() {
  group('WnSearchField', () {
    testWidgets('displays placeholder', (tester) async {
      await mountWidget(const WnSearchField(placeholder: 'Search users'), tester);
      expect(find.text('Search users'), findsOneWidget);
    });

    testWidgets('has backgroundPrimary fill color', (tester) async {
      await mountWidget(const WnSearchField(placeholder: 'Search'), tester);
      final textField = tester.widget<TextField>(find.byType(TextField));
      final decoration = textField.decoration!;
      expect(decoration.fillColor, SemanticColors.light.backgroundPrimary);
    });

    testWidgets('displays search icon', (tester) async {
      await mountWidget(const WnSearchField(placeholder: 'Search'), tester);
      expect(find.byKey(const Key('search_icon')), findsOneWidget);
    });

    testWidgets('displays entered text', (tester) async {
      await mountWidget(const WnSearchField(placeholder: 'Search'), tester);
      await tester.enterText(find.byType(TextField), 'hello');
      await tester.pump();
      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('is not focused by default', (tester) async {
      await mountWidget(const WnSearchField(placeholder: 'Search'), tester);
      final field = tester.widget<EditableText>(find.byType(EditableText));
      expect(field.focusNode.hasFocus, isFalse);
    });

    testWidgets('calls onChanged when text changes', (tester) async {
      String? changedValue;
      await mountWidget(
        WnSearchField(placeholder: 'Search', onChanged: (v) => changedValue = v),
        tester,
      );
      await tester.enterText(find.byType(TextField), 'test');
      expect(changedValue, 'test');
    });

    testWidgets('uses provided controller', (tester) async {
      final controller = TextEditingController(text: 'initial');
      addTearDown(controller.dispose);
      await mountWidget(
        WnSearchField(placeholder: 'Search', controller: controller),
        tester,
      );
      expect(find.text('initial'), findsOneWidget);
    });

    group('with autofocus', () {
      testWidgets('is focused', (tester) async {
        await mountWidget(
          const WnSearchField(placeholder: 'Search', autofocus: true),
          tester,
        );
        final field = tester.widget<EditableText>(find.byType(EditableText));
        expect(field.focusNode.hasFocus, isTrue);
      });
    });

    group('with onScan', () {
      testWidgets('displays scan button when onScan is provided', (tester) async {
        await mountWidget(
          WnSearchField(placeholder: 'Search', onScan: () {}),
          tester,
        );
        expect(find.byKey(const Key('scan_button')), findsOneWidget);
      });

      testWidgets('does not display scan button when onScan is null', (tester) async {
        await mountWidget(const WnSearchField(placeholder: 'Search'), tester);
        expect(find.byKey(const Key('scan_button')), findsNothing);
      });

      testWidgets('calls onScan when scan button is tapped', (tester) async {
        var scanCalled = false;
        await mountWidget(
          WnSearchField(placeholder: 'Search', onScan: () => scanCalled = true),
          tester,
        );
        await tester.tap(find.byKey(const Key('scan_button')));
        expect(scanCalled, isTrue);
      });
    });

    group('with isLoading', () {
      testWidgets('shows loading indicator when isLoading is true', (tester) async {
        await mountWidget(
          const WnSearchField(placeholder: 'Search', isLoading: true),
          tester,
        );
        expect(find.byKey(const Key('search_loading_indicator')), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('hides scan button when isLoading is true', (tester) async {
        await mountWidget(
          WnSearchField(placeholder: 'Search', onScan: () {}, isLoading: true),
          tester,
        );
        expect(find.byKey(const Key('scan_button')), findsNothing);
        expect(find.byKey(const Key('search_loading_indicator')), findsOneWidget);
      });

      testWidgets('shows scan button when isLoading is false', (tester) async {
        await mountWidget(
          WnSearchField(placeholder: 'Search', onScan: () {}),
          tester,
        );
        expect(find.byKey(const Key('scan_button')), findsOneWidget);
        expect(find.byKey(const Key('search_loading_indicator')), findsNothing);
      });
    });

    group('heightOf', () {
      testWidgets('is at least the minimum interactive dimension', (tester) async {
        late double reportedHeight;
        await mountWidget(
          Builder(
            builder: (BuildContext context) {
              reportedHeight = WnSearchField.heightOf(context);
              return const WnSearchField(placeholder: 'Search');
            },
          ),
          tester,
        );
        expect(reportedHeight, greaterThanOrEqualTo(kMinInteractiveDimension));
      });

      testWidgets('matches the rendered TextField height', (tester) async {
        late double reportedHeight;
        await mountWidget(
          Builder(
            builder: (BuildContext context) {
              reportedHeight = WnSearchField.heightOf(context);
              return const WnSearchField(placeholder: 'Search');
            },
          ),
          tester,
        );
        final renderedHeight = tester.getSize(find.byType(TextField)).height;
        expect(reportedHeight, renderedHeight);
      });
    });
  });
}
