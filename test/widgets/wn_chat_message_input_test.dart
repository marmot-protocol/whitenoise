import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/widgets/wn_chat_message_input.dart';
import '../test_helpers.dart';

void main() {
  group('WnChatMessageInput', () {
    testWidgets('renders container with input field', (tester) async {
      await mountWidget(
        const WnChatMessageInput(
          inputField: TextField(key: Key('test_input')),
        ),
        tester,
      );

      expect(find.byKey(const Key('chat_message_input')), findsOneWidget);
      expect(find.byKey(const Key('test_input')), findsOneWidget);
    });

    testWidgets('renders attachment area when provided', (tester) async {
      await mountWidget(
        const WnChatMessageInput(
          attachmentArea: Text('Attachment', key: Key('test_attachment')),
          inputField: TextField(),
        ),
        tester,
      );

      expect(find.byKey(const Key('attachment_area')), findsOneWidget);
      expect(find.byKey(const Key('test_attachment')), findsOneWidget);
    });

    testWidgets('does not render attachment area when null', (tester) async {
      await mountWidget(
        const WnChatMessageInput(
          inputField: TextField(),
        ),
        tester,
      );

      expect(find.byKey(const Key('attachment_area')), findsNothing);
    });

    testWidgets('renders leading action when provided', (tester) async {
      await mountWidget(
        WnChatMessageInput(
          leadingAction: IconButton(
            key: const Key('test_leading'),
            icon: const Icon(Icons.add),
            onPressed: () {},
          ),
          inputField: const TextField(),
        ),
        tester,
      );

      expect(find.byKey(const Key('leading_action')), findsOneWidget);
      expect(find.byKey(const Key('test_leading')), findsOneWidget);
    });

    testWidgets('does not render leading action when null', (tester) async {
      await mountWidget(
        const WnChatMessageInput(
          inputField: TextField(),
        ),
        tester,
      );

      expect(find.byKey(const Key('leading_action')), findsNothing);
    });

    testWidgets('renders trailing action when provided', (tester) async {
      await mountWidget(
        WnChatMessageInput(
          trailingAction: IconButton(
            key: const Key('test_trailing'),
            icon: const Icon(Icons.send),
            onPressed: () {},
          ),
          inputField: const TextField(),
        ),
        tester,
      );

      expect(find.byKey(const Key('trailing_action')), findsOneWidget);
      expect(find.byKey(const Key('test_trailing')), findsOneWidget);
    });

    testWidgets('does not render trailing action when null', (tester) async {
      await mountWidget(
        const WnChatMessageInput(
          inputField: TextField(),
        ),
        tester,
      );

      expect(find.byKey(const Key('trailing_action')), findsNothing);
    });

    testWidgets('renders with all slots filled', (tester) async {
      await mountWidget(
        WnChatMessageInput(
          attachmentArea: const Text('Quote', key: Key('test_quote')),
          leadingAction: IconButton(
            key: const Key('test_add'),
            icon: const Icon(Icons.add),
            onPressed: () {},
          ),
          inputField: const TextField(key: Key('test_field')),
          trailingAction: IconButton(
            key: const Key('test_send'),
            icon: const Icon(Icons.send),
            onPressed: () {},
          ),
        ),
        tester,
      );

      expect(find.byKey(const Key('attachment_area')), findsOneWidget);
      expect(find.byKey(const Key('leading_action')), findsOneWidget);
      expect(find.byKey(const Key('test_field')), findsOneWidget);
      expect(find.byKey(const Key('trailing_action')), findsOneWidget);
    });

    testWidgets('uses secondary border when not focused', (tester) async {
      await mountWidget(
        const WnChatMessageInput(
          inputField: TextField(),
        ),
        tester,
      );

      final container = tester.widget<Container>(
        find.byKey(const Key('chat_message_input')),
      );
      final decoration = container.decoration as BoxDecoration;

      expect(decoration.border, isNotNull);
    });

    testWidgets('uses primary border when focused', (tester) async {
      await mountWidget(
        const WnChatMessageInput(
          inputField: TextField(),
          isFocused: true,
        ),
        tester,
      );

      final container = tester.widget<Container>(
        find.byKey(const Key('chat_message_input')),
      );
      final decoration = container.decoration as BoxDecoration;

      expect(decoration.border, isNotNull);
    });
  });
}
