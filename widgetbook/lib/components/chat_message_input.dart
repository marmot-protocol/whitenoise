import 'package:flutter/material.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_chat_message_input.dart';
import 'package:whitenoise/widgets/wn_message_quote.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

class WnChatMessageInputStory extends StatelessWidget {
  const WnChatMessageInputStory({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

@widgetbook.UseCase(name: 'Chat Message Input', type: WnChatMessageInputStory)
Widget wnChatMessageInputShowcase(BuildContext context) {
  return Scaffold(
    backgroundColor: context.colors.backgroundSecondary,
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Playground',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: context.colors.backgroundContentPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Use the knobs panel to customize this message input container.',
          style: TextStyle(
            fontSize: 14,
            color: context.colors.backgroundContentSecondary,
          ),
        ),
        const SizedBox(height: 16),
        const _InteractiveMessageInputContainer(),
        const SizedBox(height: 32),
        Divider(color: context.colors.borderTertiary),
        const SizedBox(height: 24),
        _buildSection(
          context,
          'All Variants',
          'Chat message input with built-in add and send buttons.',
          [
            const _InputExample(
              label: 'Empty (unfocused)',
              child: _BasicInput(isFocused: false),
            ),
            const _InputExample(
              label: 'Empty (focused)',
              child: _BasicInput(isFocused: true),
            ),
            const _InputExample(
              label: 'With text',
              child: _BasicInput(
                initialText: 'Hello, how are you?',
                isFocused: true,
              ),
            ),
            const _InputExample(
              label: 'With send enabled',
              child: _InputWithSendEnabled(),
            ),
            const _InputExample(
              label: 'With send disabled',
              child: _InputWithSendDisabled(),
            ),
            const _InputExample(
              label: 'With attachment (quote)',
              child: _InputWithQuote(),
            ),
            const _InputExample(label: 'Full example', child: _FullInput()),
          ],
        ),
      ],
    ),
  );
}

Widget _buildSection(
  BuildContext context,
  String title,
  String description,
  List<Widget> children,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: context.colors.backgroundContentPrimary,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        description,
        style: TextStyle(
          fontSize: 13,
          color: context.colors.backgroundContentSecondary,
        ),
      ),
      const SizedBox(height: 16),
      Wrap(spacing: 24, runSpacing: 24, children: children),
    ],
  );
}

class _InputExample extends StatelessWidget {
  const _InputExample({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: context.colors.backgroundContentSecondary,
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: child,
        ),
      ],
    );
  }
}

class _InteractiveMessageInputContainer extends StatelessWidget {
  const _InteractiveMessageInputContainer();

  @override
  Widget build(BuildContext context) {
    final showAttachment = context.knobs.boolean(
      label: 'Show Attachment',
      initialValue: false,
    );

    final showSend = context.knobs.boolean(
      label: 'Show Send Button',
      initialValue: true,
    );

    final sendEnabled = context.knobs.boolean(
      label: 'Send Enabled',
      initialValue: true,
    );

    final isFocused = context.knobs.boolean(
      label: 'Is Focused',
      initialValue: false,
    );

    final colors = context.colors;
    final controller = TextEditingController();

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: WnChatMessageInput(
        controller: controller,
        inputStyle: TextStyle(color: colors.backgroundContentPrimary),
        isFocused: isFocused,
        attachmentArea: showAttachment
            ? WnMessageQuote(
                author: 'Alice',
                text: 'This is a quoted message that we are replying to.',
                onCancel: () {},
              )
            : null,
        onAddTap: () {},
        inputField: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Message',
            hintStyle: TextStyle(color: colors.backgroundContentTertiary),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 16,
            ),
          ),
        ),
        onSend: showSend ? () {} : null,
        sendEnabled: sendEnabled,
      ),
    );
  }
}

class _BasicInput extends StatelessWidget {
  const _BasicInput({this.initialText, this.isFocused = false});

  final String? initialText;
  final bool isFocused;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final controller = initialText != null
        ? TextEditingController(text: initialText)
        : TextEditingController();

    return WnChatMessageInput(
      controller: controller,
      inputStyle: TextStyle(color: colors.backgroundContentPrimary),
      isFocused: isFocused,
      onAddTap: () {},
      inputField: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Message',
          hintStyle: TextStyle(color: colors.backgroundContentTertiary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

class _InputWithSendEnabled extends StatelessWidget {
  const _InputWithSendEnabled();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final controller = TextEditingController(text: 'Hello!');

    return WnChatMessageInput(
      controller: controller,
      inputStyle: TextStyle(color: colors.backgroundContentPrimary),
      onAddTap: () {},
      inputField: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Message',
          hintStyle: TextStyle(color: colors.backgroundContentTertiary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 16,
          ),
        ),
      ),
      onSend: () {},
      sendEnabled: true,
    );
  }
}

class _InputWithSendDisabled extends StatelessWidget {
  const _InputWithSendDisabled();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final controller = TextEditingController();

    return WnChatMessageInput(
      controller: controller,
      inputStyle: TextStyle(color: colors.backgroundContentPrimary),
      onAddTap: () {},
      inputField: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Message',
          hintStyle: TextStyle(color: colors.backgroundContentTertiary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 16,
          ),
        ),
      ),
      onSend: () {},
      sendEnabled: false,
    );
  }
}

class _InputWithQuote extends StatelessWidget {
  const _InputWithQuote();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final controller = TextEditingController();

    return WnChatMessageInput(
      controller: controller,
      inputStyle: TextStyle(color: colors.backgroundContentPrimary),
      onAddTap: () {},
      attachmentArea: WnMessageQuote(
        author: 'Bob',
        text: 'Check out this cool feature!',
        onCancel: () {},
      ),
      inputField: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Message',
          hintStyle: TextStyle(color: colors.backgroundContentTertiary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

class _FullInput extends StatelessWidget {
  const _FullInput();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final controller = TextEditingController(text: 'Thanks for the reminder!');

    return WnChatMessageInput(
      controller: controller,
      inputStyle: TextStyle(color: colors.backgroundContentPrimary),
      isFocused: true,
      attachmentArea: WnMessageQuote(
        author: 'Alice',
        text: 'This is a reply to your message about the project deadline.',
        onCancel: () {},
      ),
      onAddTap: () {},
      inputField: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Message',
          hintStyle: TextStyle(color: colors.backgroundContentTertiary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 16,
          ),
        ),
      ),
      onSend: () {},
      sendEnabled: true,
    );
  }
}
