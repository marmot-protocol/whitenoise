import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/widgets/wn_chat_message_input.dart';
import '../test_helpers.dart';

WnChatMessageInput _buildInput({
  Widget? attachmentArea,
  TextEditingController? controller,
  String? initialText,
  VoidCallback? onAddTap,
  VoidCallback? onSend,
  bool sendEnabled = false,
  bool isFocused = false,
}) {
  final ctrl = controller ?? TextEditingController(text: initialText ?? '');
  return WnChatMessageInput(
    attachmentArea: attachmentArea,
    controller: ctrl,
    inputStyle: const TextStyle(fontSize: 14),
    onAddTap: onAddTap ?? () {},
    onSend: onSend,
    sendEnabled: sendEnabled,
    isFocused: isFocused,
    inputField: TextField(controller: ctrl),
  );
}

void main() {
  group('WnChatMessageInput', () {
    testWidgets('renders container with input field', (tester) async {
      final ctrl = TextEditingController();
      await mountWidget(
        WnChatMessageInput(
          controller: ctrl,
          inputStyle: const TextStyle(fontSize: 14),
          onAddTap: () {},
          inputField: TextField(key: const Key('test_input'), controller: ctrl),
        ),
        tester,
      );

      expect(find.byKey(const Key('chat_message_input')), findsOneWidget);
      expect(find.byKey(const Key('test_input')), findsOneWidget);
    });

    testWidgets('renders attachment area when provided', (tester) async {
      await mountWidget(
        _buildInput(
          attachmentArea: const Text('Attachment', key: Key('test_attachment')),
        ),
        tester,
      );

      expect(find.byKey(const Key('attachment_area')), findsOneWidget);
      expect(find.byKey(const Key('test_attachment')), findsOneWidget);
    });

    testWidgets('does not render attachment area when null', (tester) async {
      await mountWidget(_buildInput(), tester);

      expect(find.byKey(const Key('attachment_area')), findsNothing);
    });

    testWidgets('always renders add button', (tester) async {
      await mountWidget(_buildInput(), tester);

      expect(find.byKey(const Key('add_button')), findsOneWidget);
    });

    testWidgets('add button fires onAddTap', (tester) async {
      var tapped = false;
      await mountWidget(_buildInput(onAddTap: () => tapped = true), tester);

      await tester.tap(find.byKey(const Key('add_button')));
      expect(tapped, isTrue);
    });

    testWidgets('does not render send button when onSend is null', (tester) async {
      await mountWidget(_buildInput(), tester);

      expect(find.byKey(const Key('send_button')), findsNothing);
    });

    testWidgets('renders send button when onSend is provided', (tester) async {
      await mountWidget(_buildInput(onSend: () {}, sendEnabled: true), tester);

      expect(find.byKey(const Key('send_button')), findsOneWidget);
    });

    testWidgets('send button fires onSend when enabled', (tester) async {
      var sent = false;
      await mountWidget(
        _buildInput(onSend: () => sent = true, sendEnabled: true),
        tester,
      );

      await tester.tap(find.byKey(const Key('send_button')));
      expect(sent, isTrue);
    });

    testWidgets('send button does not fire onSend when disabled', (tester) async {
      var sent = false;
      await mountWidget(
        _buildInput(onSend: () => sent = true),
        tester,
      );

      await tester.tap(find.byKey(const Key('send_button')));
      expect(sent, isFalse);
    });

    testWidgets('renders with all slots filled', (tester) async {
      final ctrl = TextEditingController();
      await mountWidget(
        WnChatMessageInput(
          attachmentArea: const Text('Quote', key: Key('test_quote')),
          controller: ctrl,
          inputStyle: const TextStyle(fontSize: 14),
          onAddTap: () {},
          inputField: TextField(key: const Key('test_field'), controller: ctrl),
          onSend: () {},
          sendEnabled: true,
        ),
        tester,
      );

      expect(find.byKey(const Key('attachment_area')), findsOneWidget);
      expect(find.byKey(const Key('add_button')), findsOneWidget);
      expect(find.byKey(const Key('test_field')), findsOneWidget);
      expect(find.byKey(const Key('send_button')), findsOneWidget);
    });

    testWidgets('uses secondary border when not focused', (tester) async {
      await mountWidget(_buildInput(), tester);

      final container = tester.widget<Container>(
        find.byKey(const Key('chat_message_input')),
      );
      final decoration = container.decoration as BoxDecoration;

      expect(decoration.border, isNotNull);
    });

    testWidgets('uses primary border when focused', (tester) async {
      await mountWidget(_buildInput(isFocused: true), tester);

      final container = tester.widget<Container>(
        find.byKey(const Key('chat_message_input')),
      );
      final decoration = container.decoration as BoxDecoration;

      expect(decoration.border, isNotNull);
    });

    testWidgets('always uses stretch alignment with IntrinsicHeight', (tester) async {
      await mountWidget(
        _buildInput(initialText: 'hello', onSend: () {}, sendEnabled: true),
        tester,
      );

      expect(
        find.descendant(
          of: find.byKey(const Key('chat_message_input')),
          matching: find.byType(IntrinsicHeight),
        ),
        findsOneWidget,
      );

      final row = tester.widget<Row>(
        find.descendant(
          of: find.byKey(const Key('chat_message_input')),
          matching: find.byType(Row),
        ),
      );

      expect(row.crossAxisAlignment, CrossAxisAlignment.stretch);
    });

    testWidgets('single-line: buttons use center alignment', (tester) async {
      await mountWidget(
        _buildInput(initialText: 'hello', onSend: () {}, sendEnabled: true),
        tester,
      );

      final aligns = tester.widgetList<Align>(
        find.descendant(
          of: find.byKey(const Key('chat_message_input')),
          matching: find.byType(Align),
        ),
      );

      for (final align in aligns) {
        expect(align.alignment, Alignment.center);
      }
    });

    testWidgets('multiline: add button top, send button bottom', (tester) async {
      setUpTestView(tester);
      final longText = 'word ' * 40;
      await mountWidget(
        _buildInput(initialText: longText, onSend: () {}, sendEnabled: true),
        tester,
      );

      final addAlign = tester.widget<Align>(
        find.ancestor(
          of: find.byKey(const Key('add_button')),
          matching: find.byType(Align),
        ),
      );
      expect(addAlign.alignment, Alignment.topCenter);

      final sendAlign = tester.widget<Align>(
        find.ancestor(
          of: find.byKey(const Key('send_button')),
          matching: find.byType(Align),
        ),
      );
      expect(sendAlign.alignment, Alignment.bottomCenter);
    });
  });
}
