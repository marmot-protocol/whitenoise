import 'package:flutter/material.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_chat_list_item.dart';
import 'package:whitenoise/widgets/wn_chat_status.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../foundations/design_width_container.dart';

class WnChatListItemStory extends StatelessWidget {
  const WnChatListItemStory({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

@widgetbook.UseCase(name: 'Chat List Item', type: WnChatListItemStory)
Widget wnChatListItemShowcase(BuildContext context) {
  final colors = context.colors;

  final title = context.knobs.string(label: 'Title', initialValue: 'John Doe');
  final subtitle = context.knobs.string(
    label: 'Subtitle',
    initialValue: 'Hey, how are you?',
  );
  final timestamp = context.knobs.string(
    label: 'Timestamp',
    initialValue: '2m',
  );
  final hasImage = context.knobs.boolean(
    label: 'Has Avatar Image',
    initialValue: false,
  );
  final avatarName = context.knobs.stringOrNull(
    label: 'Avatar Name',
    initialValue: 'John Doe',
  );
  final status = context.knobs.objectOrNull.dropdown<ChatStatusType>(
    label: 'Status',
    options: ChatStatusType.values,
    initialOption: ChatStatusType.sending,
    labelBuilder: (value) => value.name,
  );
  final unreadCount = context.knobs.int.slider(
    label: 'Unread Count',
    initialValue: 3,
    min: 0,
    max: 150,
  );
  final notificationOff = context.knobs.boolean(
    label: 'Notification Off',
    initialValue: false,
  );
  final isSelected = context.knobs.boolean(
    label: 'Is Selected',
    initialValue: false,
  );
  final isFromYou = context.knobs.boolean(
    label: 'Is From You',
    initialValue: false,
  );

  return Scaffold(
    backgroundColor: colors.backgroundPrimary,
    body: Center(
      child: DesignWidthContainer(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Playground',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colors.backgroundContentPrimary,
              ),
            ),
            const SizedBox(height: 16),
            WnChatListItem(
              title: title,
              subtitle: subtitle,
              timestamp: timestamp,
              avatarUrl: hasImage
                  ? 'https://www.whitenoise.chat/images/mask-man.webp'
                  : null,
              avatarName: avatarName,
              status: status,
              unreadCount: status == ChatStatusType.unreadCount
                  ? unreadCount
                  : null,
              notificationOff: notificationOff,
              isSelected: isSelected,
              prefixSubtitle: isFromYou ? 'You: ' : null,
              onTap: () {},
            ),
            const SizedBox(height: 32),
            Divider(color: colors.borderTertiary),
            const SizedBox(height: 24),
            Text(
              'All Status Types',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.backgroundContentPrimary,
              ),
            ),
            const SizedBox(height: 16),
            WnChatListItem(
              title: 'Sending (from you)',
              subtitle: 'Message sending',
              timestamp: '1m',
              status: ChatStatusType.sending,
              prefixSubtitle: 'You: ',
              onTap: () {},
            ),
            WnChatListItem(
              title: 'Sent (from you)',
              subtitle: 'Message sent',
              timestamp: '2m',
              status: ChatStatusType.sent,
              prefixSubtitle: 'You: ',
              onTap: () {},
            ),
            WnChatListItem(
              title: 'Read (from you)',
              subtitle: 'Message read',
              timestamp: '3m',
              status: ChatStatusType.read,
              prefixSubtitle: 'You: ',
              onTap: () {},
            ),
            WnChatListItem(
              title: 'Failed (from you)',
              subtitle: 'Message failed to send',
              timestamp: '4m',
              status: ChatStatusType.failed,
              prefixSubtitle: 'You: ',
              onTap: () {},
            ),
            WnChatListItem(
              title: 'Request',
              subtitle: 'Chat request from someone new',
              timestamp: '5m',
              status: ChatStatusType.request,
              onTap: () {},
            ),
            WnChatListItem(
              title: 'Unread',
              subtitle: 'New messages from them',
              timestamp: '6m',
              status: ChatStatusType.unreadCount,
              unreadCount: 5,
              onTap: () {},
            ),
            const SizedBox(height: 32),
            Divider(color: colors.borderTertiary),
            const SizedBox(height: 24),
            Text(
              'Two-Line Messages',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.backgroundContentPrimary,
              ),
            ),
            const SizedBox(height: 16),
            WnChatListItem(
              title: 'Long Message (from you)',
              subtitle:
                  'This is a much longer message that should'
                  ' wrap onto two lines before truncating'
                  ' with ellipsis',
              timestamp: '7m',
              status: ChatStatusType.sending,
              prefixSubtitle: 'You: ',
              onTap: () {},
            ),
            WnChatListItem(
              title: 'Long Message (from them)',
              subtitle:
                  'This is a much longer message that should'
                  ' wrap onto two lines before truncating'
                  ' with ellipsis',
              timestamp: '8m',
              status: ChatStatusType.unreadCount,
              unreadCount: 1,
              onTap: () {},
            ),
          ],
        ),
      ),
    ),
  );
}
