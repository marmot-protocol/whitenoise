import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:whitenoise/hooks/use_chat_messages.dart' show ChatMessageQuoteData;
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/screens/start_chat_screen.dart';
import 'package:whitenoise/src/rust/api/markdown.dart';
import 'package:whitenoise/src/rust/api/messages.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/utils/bubble_grouping.dart' show leadingVariant;
import 'package:whitenoise/utils/deep_links.dart';
import 'package:whitenoise/utils/encoding.dart' show hexFromNpub;
import 'package:whitenoise/widgets/chat_message_media.dart';
import 'package:whitenoise/widgets/chat_message_quote.dart';
import 'package:whitenoise/widgets/markdown_text.dart';
import 'package:whitenoise/widgets/media_modal.dart';
import 'package:whitenoise/widgets/wn_avatar.dart';
import 'package:whitenoise/widgets/wn_chat_status.dart';
import 'package:whitenoise/widgets/wn_message_bubble.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final List<HighlightSpan>? highlightSpans;
  final bool isOwnMessage;
  final String? currentUserPubkey;
  final ChatMessageQuoteData? replyPreview;
  final String? senderName;
  final String? senderPictureUrl;
  final bool showAvatar;
  final bool showTail;
  final bool isGroupChat;
  final int? contentMaxLines;
  final double bubbleWidthFactor;
  final bool forceTightHeight;
  final VoidCallback? onLongPress;
  final void Function(String emoji)? onReaction;
  final VoidCallback? onReplyTap;
  final VoidCallback? onHorizontalDragEnd;
  final VoidCallback? onRetry;
  final String? Function(String hexPubkey)? mentionDisplayName;

  const ChatMessageBubble({
    super.key,
    required this.message,
    this.highlightSpans,
    required this.isOwnMessage,
    this.currentUserPubkey,
    this.replyPreview,
    this.senderName,
    this.senderPictureUrl,
    this.showAvatar = false,
    this.showTail = true,
    this.isGroupChat = false,
    this.contentMaxLines,
    this.bubbleWidthFactor = 0.8,
    this.forceTightHeight = false,
    this.onLongPress,
    this.onReaction,
    this.onReplyTap,
    this.onHorizontalDragEnd,
    this.onRetry,
    this.mentionDisplayName,
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

  Future<void> _handleLinkTap(BuildContext context, String url) async {
    if (!isSafeMarkdownUrl(url)) return;
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return;
    final scheme = uri.scheme.toLowerCase();
    if (scheme == DeepLinks.productionScheme || scheme == DeepLinks.stagingScheme) {
      final target = DeepLinks.parse(uri);
      if (target == null) {
        if (context.mounted) await _showUnsupportedDeepLinkDialog(context);
        return;
      }
      if (target.type == DeepLinkTargetType.user) {
        final hex = hexFromNpub(uri.pathSegments.first);
        if (hex != null && context.mounted) {
          await StartChatScreen.show(context, userPubkey: hex);
        }
        return;
      }
      if (context.mounted) GoRouter.of(context).go(target.location);
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _showUnsupportedDeepLinkDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('unsupported_deep_link_dialog'),
        title: Text(dialogContext.l10n.unsupportedDeepLinkTitle),
        content: Text(dialogContext.l10n.unsupportedDeepLinkMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(MaterialLocalizations.of(dialogContext).okButtonLabel),
          ),
        ],
      ),
    );
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
      document: message.content.isNotEmpty ? message.contentTokens : null,
      highlightSpans: highlightSpans,
      onLinkTap: (url) => _handleLinkTap(context, url),
      onNostrTap: (hrp, bech32) async {
        if (hrp == MarkdownNostrHrp.npub) {
          final hex = hexFromNpub(bech32);
          if (hex != null && context.mounted) {
            await StartChatScreen.show(context, userPubkey: hex);
          }
          return;
        }
        final uri = Uri.tryParse('nostr:$bech32');
        if (uri == null) return;
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      },
      mentionDisplayName: mentionDisplayName,
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
      onLongPress: onLongPress,
      onReaction: onReaction,
      onHorizontalDragEnd: onHorizontalDragEnd,
      onStatusTap: _deliveryStatusType == ChatStatusType.failed ? onRetry : null,
      contentMaxLines: contentMaxLines,
      bubbleWidthFactor: bubbleWidthFactor,
      forceTightHeight: forceTightHeight,
    );
  }
}
