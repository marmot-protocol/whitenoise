import 'package:flutter/material.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_icon.dart';
import 'package:whitenoise/widgets/wn_input_field_button.dart';
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
          'Message Input Container provides a styled frame for chat input with optional slots.',
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
              label: 'With leading action',
              child: _InputWithLeading(),
            ),
            const _InputExample(
              label: 'With trailing action',
              child: _InputWithTrailing(),
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

    final showLeadingAction = context.knobs.boolean(
      label: 'Show Leading Action',
      initialValue: true,
    );

    final showTrailingAction = context.knobs.boolean(
      label: 'Show Trailing Action',
      initialValue: true,
    );

    final isFocused = context.knobs.boolean(
      label: 'Is Focused',
      initialValue: false,
    );

    final colors = context.colors;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: WnChatMessageInput(
        isFocused: isFocused,
        attachmentArea: showAttachment
            ? WnMessageQuote(
                author: 'Alice',
                text: 'This is a quoted message that we are replying to.',
                onCancel: () {},
              )
            : null,
        leadingAction: showLeadingAction
            ? WnIcon(
                WnIcons.addLarge,
                color: colors.backgroundContentSecondary,
                size: 20,
              )
            : null,
        inputField: TextField(
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
        trailingAction: showTrailingAction
            ? WnInputFieldButton(
                icon: WnIcons.arrowUp,
                onPressed: () {},
                buttonSize: WnInputFieldButtonSize.size40,
              )
            : null,
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

    return WnChatMessageInput(
      isFocused: isFocused,
      inputField: TextField(
        controller: initialText != null
            ? TextEditingController(text: initialText)
            : null,
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

class _InputWithLeading extends StatelessWidget {
  const _InputWithLeading();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return WnChatMessageInput(
      leadingAction: WnIcon(
        WnIcons.addLarge,
        color: colors.backgroundContentSecondary,
        size: 20,
      ),
      inputField: TextField(
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

class _InputWithTrailing extends StatelessWidget {
  const _InputWithTrailing();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return WnChatMessageInput(
      inputField: TextField(
        controller: TextEditingController(text: 'Hello!'),
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
      trailingAction: WnInputFieldButton(
        icon: WnIcons.arrowUp,
        onPressed: () {},
        buttonSize: WnInputFieldButtonSize.size40,
      ),
    );
  }
}

class _InputWithQuote extends StatelessWidget {
  const _InputWithQuote();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return WnChatMessageInput(
      attachmentArea: WnMessageQuote(
        author: 'Bob',
        text: 'Check out this cool feature!',
        onCancel: () {},
      ),
      inputField: TextField(
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

    return WnChatMessageInput(
      isFocused: true,
      attachmentArea: WnMessageQuote(
        author: 'Alice',
        text: 'This is a reply to your message about the project deadline.',
        onCancel: () {},
      ),
      leadingAction: WnIcon(
        WnIcons.addLarge,
        color: colors.backgroundContentSecondary,
        size: 20,
      ),
      inputField: TextField(
        controller: TextEditingController(text: 'Thanks for the reminder!'),
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
      trailingAction: WnInputFieldButton(
        icon: WnIcons.arrowUp,
        onPressed: () {},
        buttonSize: WnInputFieldButtonSize.size40,
      ),
    );
  }
}
