import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/hooks/use_chat_messages.dart' show ChatMessageQuoteData;
import 'package:whitenoise/src/rust/api/messages.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/chat_message_media.dart';
import 'package:whitenoise/widgets/chat_message_quote.dart';
import 'package:whitenoise/widgets/media_modal.dart';
import 'package:whitenoise/widgets/wn_message_reactions.dart';

class WnMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isOwnMessage;
  final String? currentUserPubkey;
  final VoidCallback? onLongPress;
  final void Function(String emoji)? onReaction;
  final ChatMessageQuoteData? replyPreview;
  final VoidCallback? onReplyTap;
  final String? senderName;
  final String? senderPictureUrl;
  final double? maxWidth;

  const WnMessageBubble({
    super.key,
    required this.message,
    required this.isOwnMessage,
    this.currentUserPubkey,
    this.onLongPress,
    this.onReaction,
    this.replyPreview,
    this.onReplyTap,
    this.senderName,
    this.senderPictureUrl,
    this.maxWidth,
  });

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

  @override
  Widget build(BuildContext context) {
    if (message.isDeleted) {
      return const SizedBox.shrink();
    }

    final colors = context.colors;
    final hasReactions = message.reactions.byEmoji.isNotEmpty;
    final effectiveMaxWidth = maxWidth ?? MediaQuery.sizeOf(context).width * 0.75;

    return Align(
      alignment: isOwnMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
        child: Padding(
          padding: EdgeInsets.only(
            left: 12.w,
            right: 12.w,
            top: 4.h,
            bottom: hasReactions ? 14.h : 4.h,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onLongPress: onLongPress,
                child: Container(
                  padding: EdgeInsets.only(
                    left: 12.w,
                    right: 12.w,
                    top: 8.h,
                    bottom: hasReactions ? 14.h : 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: isOwnMessage ? colors.fillPrimary : colors.fillSecondary,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (replyPreview != null) ...[
                        ChatMessageQuote(
                          data: replyPreview!,
                          currentUserPubkey: currentUserPubkey,
                          onTap: onReplyTap,
                        ),
                        SizedBox(height: 8.h),
                      ],
                      if (message.mediaAttachments.isNotEmpty) ...[
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: 240.w),
                          child: ChatMessageMedia(
                            key: const Key('message_media'),
                            mediaFiles: message.mediaAttachments,
                            onMediaTap: (index) => _showMediaModal(context, index),
                          ),
                        ),
                        if (message.content.isNotEmpty) SizedBox(height: 8.h),
                      ],
                      if (message.content.isNotEmpty)
                        Text(
                          message.content,
                          style: context.typographyScaled.medium14.copyWith(
                            color: isOwnMessage
                                ? colors.fillContentPrimary
                                : colors.fillContentSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (hasReactions)
                Positioned(
                  bottom: -10.h,
                  left: isOwnMessage ? 4.w : null,
                  right: isOwnMessage ? null : 4.w,
                  child: WnMessageReactions(
                    reactions: message.reactions.byEmoji,
                    isOwnMessage: isOwnMessage,
                    currentUserPubkey: currentUserPubkey,
                    onReaction: onReaction,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
