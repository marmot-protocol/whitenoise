import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_message_quote.dart';
import '../test_helpers.dart';

void main() {
  group('WnMessageQuote', () {
    testWidgets('renders author', (tester) async {
      await mountWidget(
        const WnMessageQuote(author: 'Alice', text: 'Hello'),
        tester,
      );

      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets('renders content', (tester) async {
      await mountWidget(
        const WnMessageQuote(author: 'Alice', text: 'This is the reply content'),
        tester,
      );

      expect(find.text('This is the reply content'), findsOneWidget);
    });

    testWidgets('does not render content text when content is empty', (tester) async {
      await mountWidget(
        const WnMessageQuote(author: 'Alice', text: ''),
        tester,
      );

      final textWidgets = tester.widgetList<Text>(find.byType(Text));
      expect(textWidgets.length, 1);
      expect(textWidgets.first.data, 'Alice');
    });

    testWidgets('shows cancel button when onCancel is provided', (tester) async {
      await mountWidget(
        WnMessageQuote(author: 'Alice', text: 'Hello', onCancel: () {}),
        tester,
      );

      expect(find.byKey(const Key('cancel_quote_button')), findsOneWidget);
    });

    testWidgets('hides cancel button when onCancel is null', (tester) async {
      await mountWidget(
        const WnMessageQuote(author: 'Alice', text: 'Hello'),
        tester,
      );

      expect(find.byKey(const Key('cancel_quote_button')), findsNothing);
    });

    testWidgets('calls onCancel when cancel button is tapped', (tester) async {
      var cancelCalled = false;
      await mountWidget(
        WnMessageQuote(
          author: 'Alice',
          text: 'Hello',
          onCancel: () => cancelCalled = true,
        ),
        tester,
      );

      await tester.tap(find.byKey(const Key('cancel_quote_button')));
      await tester.pumpAndSettle();

      expect(cancelCalled, isTrue);
    });

    testWidgets('content text is max 2 lines with ellipsis', (tester) async {
      await mountWidget(
        const WnMessageQuote(author: 'Alice', text: 'Some content'),
        tester,
      );

      final textWidget = tester.widget<Text>(find.text('Some content'));
      expect((textWidget.maxLines, textWidget.overflow), (2, TextOverflow.ellipsis));
    });

    testWidgets('author name text is single line with ellipsis', (tester) async {
      await mountWidget(
        const WnMessageQuote(author: 'Author', text: 'Hello'),
        tester,
      );

      final textWidget = tester.widget<Text>(find.text('Author'));
      expect((textWidget.maxLines, textWidget.overflow), (1, TextOverflow.ellipsis));
    });

    group('quote bar', () {
      testWidgets('renders quote bar', (tester) async {
        await mountWidget(
          const WnMessageQuote(author: 'Alice', text: 'Hello'),
          tester,
        );

        expect(find.byKey(const Key('quote_bar')), findsOneWidget);
      });
    });

    group('media', () {
      testWidgets('shows thumbnail when image is provided', (tester) async {
        await mountWidget(
          WnMessageQuote(
            author: 'Alice',
            text: 'Hello',
            image: testImageProvider,
          ),
          tester,
        );

        expect(find.byKey(const Key('quote_thumbnail')), findsOneWidget);
      });

      testWidgets('hides thumbnail when image is null', (tester) async {
        await mountWidget(
          const WnMessageQuote(author: 'Alice', text: 'Hello'),
          tester,
        );

        expect(find.byKey(const Key('quote_thumbnail')), findsNothing);
      });
    });

    group('background color', () {
      testWidgets('uses backgroundPrimary when onCancel is null (Message type)', (tester) async {
        await mountWidget(
          const WnMessageQuote(author: 'Alice', text: 'Hello'),
          tester,
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(WnMessageQuote),
            matching: find.byType(Container).first,
          ),
        );
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, SemanticColors.light.backgroundPrimary);
      });

      testWidgets('uses backgroundTertiary when onCancel is provided (Input type)', (tester) async {
        await mountWidget(
          WnMessageQuote(author: 'Alice', text: 'Hello', onCancel: () {}),
          tester,
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(WnMessageQuote),
            matching: find.byType(Container).first,
          ),
        );
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, SemanticColors.light.backgroundTertiary);
      });
    });

    group('onTap', () {
      testWidgets('calls onTap when tapped', (tester) async {
        var tapCalled = false;
        await mountWidget(
          WnMessageQuote(
            author: 'Alice',
            text: 'Hello',
            onTap: () => tapCalled = true,
          ),
          tester,
        );

        await tester.tap(find.byKey(const Key('message_quote_tap_area')));
        await tester.pumpAndSettle();

        expect(tapCalled, isTrue);
      });

      testWidgets('no tap area key when onTap is null', (tester) async {
        await mountWidget(
          const WnMessageQuote(author: 'Alice', text: 'Hello'),
          tester,
        );

        expect(find.byKey(const Key('message_quote_tap_area')), findsNothing);
      });

      testWidgets('works with both onTap and onCancel', (tester) async {
        var tapCalled = false;
        var cancelCalled = false;
        await mountWidget(
          WnMessageQuote(
            author: 'Alice',
            text: 'Hello',
            onTap: () => tapCalled = true,
            onCancel: () => cancelCalled = true,
          ),
          tester,
        );

        await tester.tap(find.byKey(const Key('cancel_quote_button')));
        await tester.pumpAndSettle();
        expect(cancelCalled, isTrue);
        expect(tapCalled, isFalse);
      });
    });

    group('authorColor', () {
      testWidgets('uses custom authorColor when provided', (tester) async {
        const customColor = Colors.purple;
        await mountWidget(
          const WnMessageQuote(
            author: 'Alice',
            text: 'Hello',
            authorColor: customColor,
          ),
          tester,
        );

        final textWidget = tester.widget<Text>(find.text('Alice'));
        expect(textWidget.style?.color, customColor);
      });
    });
  });
}
