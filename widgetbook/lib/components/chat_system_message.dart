import 'package:flutter/material.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_chat_system_message.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

class WnChatSystemMessageStory extends StatelessWidget {
  const WnChatSystemMessageStory({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

@widgetbook.UseCase(name: 'Chat System Message', type: WnChatSystemMessageStory)
Widget wnChatSystemMessageShowcase(BuildContext context) {
  return Scaffold(
    backgroundColor: context.colors.backgroundPrimary,
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
          'Use the knobs panel to customize this chat system message.',
          style: TextStyle(
            fontSize: 14,
            color: context.colors.backgroundContentSecondary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          constraints: const BoxConstraints(maxWidth: 375),
          child: WnChatSystemMessage(
            text: context.knobs.string(label: 'Text', initialValue: 'Today'),
            isSticky: context.knobs.boolean(
              label: 'Is Sticky',
              initialValue: false,
            ),
          ),
        ),
        const SizedBox(height: 32),
        Divider(color: context.colors.borderTertiary),
        const SizedBox(height: 24),
        _buildSection(
          context,
          'Variants',
          'WnChatSystemMessage has 2 variants: Inline (default) and Sticky (elevated chip).',
          [
            _MessageExample(
              label: 'Inline',
              child: const WnChatSystemMessage(text: 'Today'),
            ),
            _MessageExample(
              label: 'Sticky',
              child: const WnChatSystemMessage(text: 'Today', isSticky: true),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          context,
          'Date Markers',
          'Used to mark time breaks in chat history.',
          [
            _MessageExample(
              label: 'Today',
              child: const WnChatSystemMessage(text: 'Today'),
            ),
            _MessageExample(
              label: 'Yesterday',
              child: const WnChatSystemMessage(text: 'Yesterday'),
            ),
            _MessageExample(
              label: 'Date',
              child: const WnChatSystemMessage(text: 'Sat, 21 Jun'),
            ),
            _MessageExample(
              label: 'Date & Year',
              child: const WnChatSystemMessage(text: '3 Jan, 2009'),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          context,
          'Chat Events',
          'Used to show chat and group lifecycle events.',
          [
            _MessageExample(
              label: 'Chat Started',
              child: const WnChatSystemMessage(text: 'You started a chat'),
            ),
            _MessageExample(
              label: 'Group Started',
              child: const WnChatSystemMessage(
                text: 'You started the group chat',
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          context,
          'Membership Updates',
          'Used to show member additions and removals.',
          [
            _MessageExample(
              label: 'Added',
              child: const WnChatSystemMessage(text: 'You added Alice'),
            ),
            _MessageExample(
              label: 'Removed',
              child: const WnChatSystemMessage(text: 'Bob removed Charlie'),
            ),
            _MessageExample(
              label: 'Left',
              child: const WnChatSystemMessage(text: 'Alice left this group'),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          context,
          'Group Changes',
          'Used to show group property changes.',
          [
            _MessageExample(
              label: 'Name Changed',
              child: const WnChatSystemMessage(
                text: 'You changed group name to New Name',
              ),
            ),
            _MessageExample(
              label: 'Photo Changed',
              child: const WnChatSystemMessage(
                text: 'Alice changed group photo',
              ),
            ),
            _MessageExample(
              label: 'Description Changed',
              child: const WnChatSystemMessage(
                text: 'You changed group description',
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          context,
          'Sticky Date Headers',
          'Sticky variant used for pinned date markers at top of scroll view.',
          [
            _MessageExample(
              label: 'Sticky Today',
              child: const WnChatSystemMessage(text: 'Today', isSticky: true),
            ),
            _MessageExample(
              label: 'Sticky Date',
              child: const WnChatSystemMessage(
                text: 'Sat, 21 Jun',
                isSticky: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          context,
          'In Context',
          'How system messages appear between chat bubbles.',
          [_MessageExample(label: 'Chat Flow', child: _ChatFlowExample())],
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

class _MessageExample extends StatelessWidget {
  const _MessageExample({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
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
        Container(
          width: 300,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: context.colors.backgroundSecondary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _ChatFlowExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        color: context.colors.backgroundSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.colors.borderTertiary),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            child: const WnChatSystemMessage(text: 'Today', isSticky: true),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                const WnChatSystemMessage(text: 'You started a chat'),
                const SizedBox(height: 8),
                _MockBubble(text: 'Hey!', isOutgoing: true, context: context),
                const SizedBox(height: 4),
                _MockBubble(
                  text: 'Hi there!',
                  isOutgoing: false,
                  context: context,
                ),
                const SizedBox(height: 12),
                const WnChatSystemMessage(text: 'Yesterday'),
                const SizedBox(height: 8),
                _MockBubble(
                  text: 'How are you?',
                  isOutgoing: false,
                  context: context,
                ),
                const SizedBox(height: 4),
                _MockBubble(
                  text: 'Good, thanks!',
                  isOutgoing: true,
                  context: context,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MockBubble extends StatelessWidget {
  const _MockBubble({
    required this.text,
    required this.isOutgoing,
    required this.context,
  });

  final String text;
  final bool isOutgoing;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isOutgoing
              ? this.context.colors.fillPrimary
              : this.context.colors.backgroundPrimary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: isOutgoing
                ? this.context.colors.fillContentPrimary
                : this.context.colors.backgroundContentPrimary,
          ),
        ),
      ),
    );
  }
}
