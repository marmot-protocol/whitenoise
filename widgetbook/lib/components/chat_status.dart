import 'package:flutter/material.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_chat_status.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

class WnChatStatusStory extends StatelessWidget {
  const WnChatStatusStory({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

@widgetbook.UseCase(name: 'Chat Status', type: WnChatStatusStory)
Widget wnChatStatusShowcase(BuildContext context) {
  final selectedStatus = context.knobs.object.dropdown<ChatStatusType>(
    label: 'Status',
    options: ChatStatusType.values,
    initialOption: ChatStatusType.sending,
    labelBuilder: (value) => value.name,
  );

  final unreadCount = context.knobs.int.slider(
    label: 'Unread Count',
    initialValue: 1,
    min: 0,
    max: 150,
  );

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
          'Use the knobs panel to customize the chat status.',
          style: TextStyle(
            fontSize: 14,
            color: context.colors.backgroundContentSecondary,
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Status: ',
                style: TextStyle(
                  fontSize: 14,
                  color: context.colors.backgroundContentPrimary,
                ),
              ),
              const SizedBox(width: 8),
              WnChatStatus(
                status: selectedStatus,
                unreadCount: selectedStatus == ChatStatusType.unreadCount
                    ? unreadCount
                    : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Divider(color: context.colors.borderTertiary),
        const SizedBox(height: 24),
        _buildSection(
          context,
          'Delivery Status Icons',
          'Icons showing the delivery state of your last sent message.',
          [
            const _StatusExample(
              label: 'Sending',
              description: 'Message is being sent',
              status: ChatStatusType.sending,
            ),
            const _StatusExample(
              label: 'Sent',
              description: 'Message sent to relays',
              status: ChatStatusType.sent,
            ),
            const _StatusExample(
              label: 'Read',
              description: 'Message has been read',
              status: ChatStatusType.read,
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          context,
          'Special Status Icons',
          'Icons for special chat states like errors or new requests.',
          [
            const _StatusExample(
              label: 'Failed',
              description: 'Message failed to send',
              status: ChatStatusType.failed,
            ),
            const _StatusExample(
              label: 'Request',
              description: 'New chat request pending',
              status: ChatStatusType.request,
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          context,
          'Unread Count Variants',
          'Badge showing number of unread messages. Uses fixed sizes for different digit counts.',
          [
            const _StatusExample(
              label: 'Single Digit',
              description: '1-9 messages',
              status: ChatStatusType.unreadCount,
              unreadCount: 1,
            ),
            const _StatusExample(
              label: 'Double Digit',
              description: '10-99 messages',
              status: ChatStatusType.unreadCount,
              unreadCount: 21,
            ),
            const _StatusExample(
              label: 'Triple Digit',
              description: '99+ for 100+ messages',
              status: ChatStatusType.unreadCount,
              unreadCount: 100,
            ),
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

class _StatusExample extends StatelessWidget {
  const _StatusExample({
    required this.label,
    required this.description,
    required this.status,
    this.unreadCount,
  });

  final String label;
  final String description;
  final ChatStatusType status;
  final int? unreadCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: context.colors.backgroundContentPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: TextStyle(
              fontSize: 11,
              color: context.colors.backgroundContentSecondary,
            ),
          ),
          const SizedBox(height: 8),
          WnChatStatus(status: status, unreadCount: unreadCount),
        ],
      ),
    );
  }
}
