import 'package:flutter/material.dart'
    show BoxDecoration, Column, Container, FontWeight, Key, Text, TextOverflow, TextSpan, TextStyle;
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/widgets/wn_chat_system_message.dart';
import '../test_helpers.dart' show mountWidget;

void main() {
  group('WnChatSystemMessage tests', () {
    group('inline variant (default)', () {
      testWidgets('displays text', (WidgetTester tester) async {
        const widget = WnChatSystemMessage(text: 'Today');
        await mountWidget(widget, tester);
        expect(find.text('Today'), findsOneWidget);
      });

      testWidgets('renders inline by default when isSticky is not set', (
        WidgetTester tester,
      ) async {
        const widget = WnChatSystemMessage(text: 'Yesterday');
        await mountWidget(widget, tester);
        expect(find.byType(Container), findsNothing);
        expect(find.text('Yesterday'), findsOneWidget);
      });

      testWidgets('renders inline when isSticky is false', (
        WidgetTester tester,
      ) async {
        const widget = WnChatSystemMessage(
          text: 'Test Message',
        );
        await mountWidget(widget, tester);
        expect(find.byType(Container), findsNothing);
      });

      testWidgets('inline variant has no decoration', (
        WidgetTester tester,
      ) async {
        const widget = WnChatSystemMessage(
          key: Key('message'),
          text: 'Inline Message',
        );
        await mountWidget(widget, tester);
        expect(find.byType(Container), findsNothing);
      });
    });

    group('sticky variant', () {
      testWidgets('displays text', (WidgetTester tester) async {
        const widget = WnChatSystemMessage(text: 'Today', isSticky: true);
        await mountWidget(widget, tester);
        expect(find.text('Today'), findsOneWidget);
      });

      testWidgets('renders container when isSticky is true', (
        WidgetTester tester,
      ) async {
        const widget = WnChatSystemMessage(text: 'Sticky', isSticky: true);
        await mountWidget(widget, tester);
        expect(find.byType(Container), findsOneWidget);
      });

      testWidgets('sticky variant has border', (WidgetTester tester) async {
        const widget = WnChatSystemMessage(
          key: Key('sticky'),
          text: 'Sticky Message',
          isSticky: true,
        );
        await mountWidget(widget, tester);

        final container = tester.widget<Container>(find.byType(Container));
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.border, isNotNull);
      });

      testWidgets('sticky variant has shadow', (WidgetTester tester) async {
        const widget = WnChatSystemMessage(
          key: Key('sticky'),
          text: 'Sticky Message',
          isSticky: true,
        );
        await mountWidget(widget, tester);

        final container = tester.widget<Container>(find.byType(Container));
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.boxShadow, isNotNull);
        expect(decoration.boxShadow!.length, 2);
      });

      testWidgets('sticky variant has pill shape (large border radius)', (
        WidgetTester tester,
      ) async {
        const widget = WnChatSystemMessage(
          key: Key('sticky'),
          text: 'Sticky Message',
          isSticky: true,
        );
        await mountWidget(widget, tester);

        final container = tester.widget<Container>(find.byType(Container));
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.borderRadius, isNotNull);
      });
    });

    group('text content', () {
      testWidgets('renders date marker text', (WidgetTester tester) async {
        const widget = WnChatSystemMessage(text: 'Sat, 21 Jun');
        await mountWidget(widget, tester);
        expect(find.text('Sat, 21 Jun'), findsOneWidget);
      });

      testWidgets('renders date with year text', (WidgetTester tester) async {
        const widget = WnChatSystemMessage(text: '3 Jan, 2009');
        await mountWidget(widget, tester);
        expect(find.text('3 Jan, 2009'), findsOneWidget);
      });

      testWidgets('renders group event message', (WidgetTester tester) async {
        const widget = WnChatSystemMessage(text: 'You started the group chat');
        await mountWidget(widget, tester);
        expect(find.text('You started the group chat'), findsOneWidget);
      });

      testWidgets('renders membership update message', (
        WidgetTester tester,
      ) async {
        const widget = WnChatSystemMessage(text: 'Alice added Bob');
        await mountWidget(widget, tester);
        expect(find.text('Alice added Bob'), findsOneWidget);
      });

      testWidgets('renders name change message', (WidgetTester tester) async {
        const widget = WnChatSystemMessage(
          text: 'You changed group name to New Name',
        );
        await mountWidget(widget, tester);
        expect(find.text('You changed group name to New Name'), findsOneWidget);
      });

      testWidgets('renders long text', (WidgetTester tester) async {
        const widget = WnChatSystemMessage(
          text: 'This is a very long system message that should be handled gracefully',
        );
        await mountWidget(widget, tester);
        expect(
          find.text(
            'This is a very long system message that should be handled gracefully',
          ),
          findsOneWidget,
        );
      });
    });

    group('text styling', () {
      testWidgets('inline text uses Text widget', (WidgetTester tester) async {
        const widget = WnChatSystemMessage(text: 'Test');
        await mountWidget(widget, tester);
        final textWidget = tester.widget<Text>(find.text('Test'));
        expect(textWidget.style, isNotNull);
      });

      testWidgets('sticky text uses Text widget', (WidgetTester tester) async {
        const widget = WnChatSystemMessage(text: 'Test', isSticky: true);
        await mountWidget(widget, tester);
        final textWidget = tester.widget<Text>(find.text('Test'));
        expect(textWidget.style, isNotNull);
      });

      testWidgets('text has ellipsis overflow', (WidgetTester tester) async {
        const widget = WnChatSystemMessage(text: 'Test');
        await mountWidget(widget, tester);
        final textWidget = tester.widget<Text>(find.text('Test'));
        expect(textWidget.overflow, TextOverflow.ellipsis);
      });

      testWidgets('text has maxLines of 1', (WidgetTester tester) async {
        const widget = WnChatSystemMessage(text: 'Test');
        await mountWidget(widget, tester);
        final textWidget = tester.widget<Text>(find.text('Test'));
        expect(textWidget.maxLines, 1);
      });
    });

    group('centering', () {
      testWidgets('inline variant is centered', (WidgetTester tester) async {
        const widget = WnChatSystemMessage(text: 'Centered');
        await mountWidget(widget, tester);
        expect(find.text('Centered'), findsOneWidget);
      });

      testWidgets('sticky variant is centered', (WidgetTester tester) async {
        const widget = WnChatSystemMessage(text: 'Centered', isSticky: true);
        await mountWidget(widget, tester);
        expect(find.text('Centered'), findsOneWidget);
      });
    });

    group('multiple instances', () {
      testWidgets('can render multiple messages', (WidgetTester tester) async {
        final widget = const Column(
          children: [
            WnChatSystemMessage(text: 'Today'),
            WnChatSystemMessage(text: 'You started a chat'),
            WnChatSystemMessage(text: 'Yesterday', isSticky: true),
          ],
        );
        await mountWidget(widget, tester);
        expect(find.text('Today'), findsOneWidget);
        expect(find.text('You started a chat'), findsOneWidget);
        expect(find.text('Yesterday'), findsOneWidget);
      });
    });

    group('rich text (textSpan)', () {
      testWidgets('renders rich text in inline variant', (
        WidgetTester tester,
      ) async {
        final textSpan = const TextSpan(
          text: 'Chat started by ',
          children: [
            TextSpan(
              text: 'Alice',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        );
        final widget = WnChatSystemMessage(
          text: 'Chat started by Alice',
          textSpan: textSpan,
        );
        await mountWidget(widget, tester);
        expect(find.byType(Text), findsOneWidget);
      });

      testWidgets('renders rich text in sticky variant', (
        WidgetTester tester,
      ) async {
        final textSpan = const TextSpan(
          text: 'You started a chat',
        );
        final widget = WnChatSystemMessage(
          text: 'You started a chat',
          isSticky: true,
          textSpan: textSpan,
        );
        await mountWidget(widget, tester);
        expect(find.byType(Text), findsOneWidget);
        expect(find.byType(Container), findsOneWidget);
      });

      testWidgets('uses plain text when textSpan is null', (
        WidgetTester tester,
      ) async {
        const widget = WnChatSystemMessage(
          text: 'Plain text message',
        );
        await mountWidget(widget, tester);
        expect(find.text('Plain text message'), findsOneWidget);
      });
    });
  });
}
