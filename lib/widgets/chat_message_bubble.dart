import 'package:flutter/material.dart';
import 'package:whitenoise/hooks/use_chat_messages.dart' show ChatMessageQuoteData;
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/src/rust/api/messages.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/utils/bubble_grouping.dart' show leadingVariant;
import 'package:whitenoise/widgets/chat_message_media.dart';
import 'package:whitenoise/widgets/chat_message_quote.dart';
import 'package:whitenoise/widgets/media_modal.dart';
import 'package:whitenoise/widgets/wn_avatar.dart';
import 'package:whitenoise/widgets/wn_chat_status.dart';
import 'package:whitenoise/widgets/wn_message_bubble.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isOwnMessage;
  final String? currentUserPubkey;
  final VoidCallback? onLongPress;
  final void Function(String emoji)? onReaction;
  final ChatMessageQuoteData? replyPreview;
  final VoidCallback? onReplyTap;
  final VoidCallback? onHorizontalDragEnd;
  final VoidCallback? onRetry;
  final String? senderName;
  final String? senderPictureUrl;
  final bool showAvatar;
  final bool showTail;
  final bool isGroupChat;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isOwnMessage,
    this.currentUserPubkey,
    this.onLongPress,
    this.onReaction,
    this.replyPreview,
    this.onReplyTap,
    this.onHorizontalDragEnd,
    this.onRetry,
    this.senderName,
    this.senderPictureUrl,
    this.showAvatar = false,
    this.showTail = true,
    this.isGroupChat = false,
  });

  ChatStatusType? get _deliveryStatusType {
    final status = message.deliveryStatus;
    if (status == null) return null;
    return switch (status) {
      DeliveryStatus_Sending() => ChatStatusType.sending,
      DeliveryStatus_Sent() => ChatStatusType.sent,
      DeliveryStatus_Failed() => ChatStatusType.failed,
      DeliveryStatus_Retried() => null,
    };
  }

  void _showMediaModal(BuildContext context, int index) {
    MediaModal.show(
      context: context,
      mediaFiles: message.mediaAttachments,
      initialIndex: index,
      senderName: senderName,
      senderPictureUrl: senderPictureUrl,
      senderPubkey: message.pubkey,
      timestamp: message.createdAt,
    );
  }

  static String _formatTime(DateTime datetime) {
    final local = datetime.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    if (isOwnMessage && message.deliveryStatus is DeliveryStatus_Retried) {
      return const SizedBox.shrink();
    }

    final avatarColor = AvatarColor.fromPubkey(message.pubkey);
    final colorSet = avatarColor.toColorSet(context.colors);

    final replyAuthorColor = isGroupChat && replyPreview != null && !replyPreview!.isNotFound
        ? AvatarColor.fromPubkey(replyPreview!.authorPubkey).toColorSet(context.colors).content
        : null;

    final showStatus = showTail || _deliveryStatusType == ChatStatusType.failed;
    return WnMessageBubble(
      direction: isOwnMessage ? MessageDirection.outgoing : MessageDirection.incoming,
      isDeleted: message.isDeleted,
      deletedLabel: message.isDeleted
          ? (isOwnMessage ? context.l10n.youDeletedThisMessage : context.l10n.thisMessageWasDeleted)
          : null,
      showTail: showTail,
      content: message.content.isNotEmpty ? message.content : null,
      mediaContent: message.mediaAttachments.isNotEmpty
          ? ChatMessageMedia(
              key: const Key('message_media'),
              mediaFiles: message.mediaAttachments,
              onMediaTap: (index) => _showMediaModal(context, index),
            )
          : null,
      replyContent: replyPreview != null
          ? ChatMessageQuote(
              data: replyPreview!,
              currentUserPubkey: currentUserPubkey,
              onTap: onReplyTap,
              authorColor: replyAuthorColor,
            )
          : null,
      timestamp: showStatus ? _formatTime(message.createdAt) : null,
      reactions: message.reactions.byEmoji,
      currentUserPubkey: currentUserPubkey,
      onLongPress: onLongPress,
      onReaction: onReaction,
      onHorizontalDragEnd: onHorizontalDragEnd,
      avatar: !isOwnMessage && showAvatar
          ? WnAvatar(
              pictureUrl: senderPictureUrl,
              displayName: senderName,
              size: WnAvatarSize.xSmall,
              color: avatarColor,
            )
          : null,
      senderName: !isOwnMessage && showAvatar ? senderName : null,
      senderNameColor: colorSet.content,
      leadingVariant: leadingVariant(
        isOwnMessage: isOwnMessage,
        showTail: showTail,
        isGroupChat: isGroupChat,
      ),
      deliveryStatus: isOwnMessage ? _deliveryStatusType : null,
      onStatusTap: _deliveryStatusType == ChatStatusType.failed ? onRetry : null,
    );
  }
}
