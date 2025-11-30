import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import 'package:whitenoise/config/states/chat_search_state.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/ui/chat/widgets/chat_bubble/bubble.dart';
import 'package:whitenoise/ui/chat/widgets/media_modal.dart';
import 'package:whitenoise/ui/chat/widgets/message_media_grid.dart';
import 'package:whitenoise/ui/chat/widgets/message_reply_box.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_avatar.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';
import 'package:whitenoise/utils/media_layout_calculator.dart';

class MessageWidget extends StatelessWidget {
  final MessageModel message;
  final bool isGroupMessage;
  final bool isSameSenderAsPrevious;
  final bool isSameSenderAsNext;
  final VoidCallback? onTap;
  final Function(String)? onReactionTap;
  final Function(String)? onReplyTap;
  final SearchMatch? searchMatch;
  final bool isActiveSearchMatch;
  final SearchMatch? currentActiveMatch;
  final bool isSearchActive;

  const MessageWidget({
    super.key,
    required this.message,
    required this.isGroupMessage,
    required this.isSameSenderAsPrevious,
    required this.isSameSenderAsNext,
    this.onTap,
    this.onReactionTap,
    this.onReplyTap,
    this.searchMatch,
    this.isActiveSearchMatch = false,
    this.currentActiveMatch,
    this.isSearchActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final messageContentStack = Stack(
      clipBehavior: Clip.none,
      children: [
        ChatMessageBubble(
          isSender: message.isMe,
          color: message.isMe ? context.colors.meChatBubble : context.colors.otherChatBubble,
          tail: !isSameSenderAsPrevious,
          child: _buildMessageContent(context),
        ),
        if (message.reactions.isNotEmpty)
          Positioned(
            bottom: -10.h,
            left: message.isMe ? 4.w : null,
            right: message.isMe ? null : 4.w,
            child: ReactionsRow(
              message: message,
              onReactionTap: onReactionTap,
              bubbleColor:
                  message.isMe ? context.colors.meChatBubble : context.colors.otherChatBubble,
            ),
          ),
      ],
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(
          top: isSameSenderAsPrevious ? 4.w : 12.w,
          bottom: message.reactions.isNotEmpty ? 12.w : 0,
        ),
        color: Colors.transparent,
        width: double.infinity,
        child: Row(
          mainAxisAlignment: message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Always reserve space for avatar in group messages to keep tails aligned
            if (isGroupMessage && !message.isMe) ...[
              if (!isSameSenderAsPrevious) ...[
                WnAvatar(
                  imageUrl: message.sender.imagePath ?? '',
                  size: 32.w,
                  displayName: message.sender.displayName,
                  pubkey: message.sender.publicKey,
                  showBorder: true,
                ),
                Gap(4.w),
              ] else ...[
                // Add spacer to maintain consistent tail alignment
                SizedBox(width: 32.w + 4.w), // Same width as avatar + gap
              ],
            ],
            messageContentStack,
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxBubbleWidth = screenWidth * 0.74;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxBubbleWidth,
          ),
          child: Container(
            padding: EdgeInsets.only(
              right: message.isMe ? 8.w : 0,
              left: message.isMe ? 0 : 8.w,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isGroupMessage && !isSameSenderAsPrevious && !message.isMe) ...[
                  Text(
                    message.sender.displayName,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: context.colors.mutedForeground,
                    ),
                  ),
                  Gap(4.h),
                ],
                MessageReplyBox(
                  replyingTo: message.replyTo,
                  onTap:
                      message.replyTo != null ? () => onReplyTap?.call(message.replyTo!.id) : null,
                ),
                if (message.mediaAttachments.isNotEmpty) ...[
                  MessageMediaGrid(
                    mediaFiles: message.mediaAttachments,
                    onMediaTap: (index) => _handleMediaTap(context, index),
                  ),
                  Gap(4.h),
                ],
                Builder(
                  builder: (context) {
                    double? mediaWidth;
                    if (message.mediaAttachments.isNotEmpty) {
                      final layoutConfig = MediaLayoutCalculator.calculateLayout(
                        message.mediaAttachments.length,
                      );
                      mediaWidth = layoutConfig.gridWidth.w;
                    }
                    return _buildMessageWithTimestamp(
                      context,
                      maxBubbleWidth - 16.w,
                      hasMedia: message.mediaAttachments.isNotEmpty,
                      mediaWidth: mediaWidth,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageWithTimestamp(
    BuildContext context,
    double maxWidth, {
    bool hasMedia = false,
    double? mediaWidth,
  }) {
    final textStyle = TextStyle(
      fontSize: 16.sp,
      fontWeight: FontWeight.w500,
      color: message.isMe ? context.colors.meChatBubbleText : context.colors.otherChatBubbleText,
    );

    final messageContent = message.content ?? '';
    final timestampWidth = _getTimestampWidth(context);

    // If message content is empty, just show the timestamp
    if (messageContent.isEmpty) {
      // If media exists, timestamp should align to media width on the right
      if (hasMedia && mediaWidth != null) {
        return SizedBox(
          width: mediaWidth,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TimeAndStatus(message: message, context: context),
            ],
          ),
        );
      }
      // No media, normal timestamp display
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          TimeAndStatus(message: message, context: context),
        ],
      );
    }

    final textWidget = _buildHighlightedText(messageContent, textStyle, context);

    final textPainter = TextPainter(
      text: TextSpan(text: messageContent, style: textStyle),
      textDirection: Directionality.of(context),
    );

    textPainter.layout(maxWidth: maxWidth);
    final lines = textPainter.computeLineMetrics();

    if (lines.isEmpty) {
      return const SizedBox.shrink();
    }

    final minPadding = 0.0;

    final longestLineWidth = lines.map((line) => line.width).reduce((a, b) => a > b ? a : b);
    final lastLineWidth = lines.last.width;
    final lastLineHeight = lines.last.height;

    final timestampTextPainter = TextPainter(
      text: TextSpan(
        text: message.isMe ? '${message.timeSent} ' : message.timeSent,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: Directionality.of(context),
    );
    timestampTextPainter.layout();
    final timestampHeight = timestampTextPainter.height;

    final availableWidth = maxWidth - lastLineWidth;
    final canFitInline = availableWidth >= (timestampWidth + minPadding);

    final bubbleWidth = longestLineWidth > maxWidth ? maxWidth : longestLineWidth;
    
    double textMaxWidth;
    double containerWidth;
    
    if (hasMedia && mediaWidth != null) {
      containerWidth = mediaWidth;
      textMaxWidth = canFitInline ? mediaWidth - timestampWidth : mediaWidth;
    } else {
      if (canFitInline) {
        containerWidth = bubbleWidth + timestampWidth - 8.w;
        textMaxWidth = bubbleWidth;
      } else {
        containerWidth = bubbleWidth > timestampWidth ? bubbleWidth : timestampWidth;
        textMaxWidth = containerWidth - timestampWidth;
        if (textMaxWidth < 0) {
          textMaxWidth = containerWidth;
        }
      }
    }

    final heightDifference = lastLineHeight - timestampHeight;
    final bottomOffset = heightDifference > 0 ? (heightDifference * 0.3).toDouble() : 0.0;

    return SizedBox(
      width: containerWidth,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            width: textMaxWidth,
            child: textWidget,
          ),
          Positioned(
            bottom: bottomOffset,
            right: 0,
            child: TimeAndStatus(message: message, context: context),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightedText(String text, TextStyle baseStyle, BuildContext context) {
    // No search is active, show normal text.
    if (!isSearchActive) {
      return Text(
        text,
        style: baseStyle,
      );
    }
    // Search is active, but this message has no matches. Dim the whole text.
    if (searchMatch == null || searchMatch!.textMatches.isEmpty) {
      return Text(
        text,
        style: baseStyle.copyWith(
          color: context.colors.mutedForeground,
        ),
      );
    }
    // Search is active and this message has matches. Highlight them.
    final spans = <TextSpan>[];
    int currentIndex = 0;

    final sortedMatches = List<TextMatch>.from(searchMatch!.textMatches)
      ..sort((a, b) => a.start.compareTo(b.start));

    for (final match in sortedMatches) {
      if (currentIndex < match.start) {
        spans.add(
          TextSpan(
            text: text.substring(currentIndex, match.start),
            style: baseStyle.copyWith(
              color: context.colors.mutedForeground,
            ),
          ),
        );
      }

      spans.add(
        TextSpan(
          text: text.substring(match.start, match.end),
          style: baseStyle,
        ),
      );

      currentIndex = match.end;
    }

    if (currentIndex < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(currentIndex),
          style: baseStyle.copyWith(
            color: context.colors.mutedForeground,
          ),
        ),
      );
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  double _getTimestampWidth(BuildContext context) {
    final timestampText = message.isMe ? '${message.timeSent} ' : message.timeSent;

    final textPainter = TextPainter(
      text: TextSpan(
        text: timestampText,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: Directionality.of(context),
    );

    textPainter.layout();
    final statusIconWidth = message.isMe ? (8.w + 14.w) : 0;
    return textPainter.width + statusIconWidth;
  }

  void _handleMediaTap(BuildContext context, int index) {
    showDialog(
      context: context,
      barrierColor: context.colors.overlay.withValues(alpha: 0.5),
      builder:
          (context) => MediaModal(
            mediaFiles: message.mediaAttachments,
            initialIndex: index,
            senderName: message.sender.displayName,
            senderImagePath: message.sender.imagePath,
            timestamp: message.createdAt,
          ),
    );
  }
}

class ReactionsRow extends StatelessWidget {
  const ReactionsRow({
    super.key,
    required this.message,
    required this.onReactionTap,
    required this.bubbleColor,
  });

  final MessageModel message;
  final Function(String p1)? onReactionTap;
  final Color bubbleColor;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4.w,
      children: [
        ...(() {
          final reactionGroups = <String, List<Reaction>>{};
          for (final reaction in message.reactions) {
            reactionGroups.putIfAbsent(reaction.emoji, () => []).add(reaction);
          }
          return reactionGroups.entries.take(3).map((entry) {
            final emoji = entry.key;
            final count = entry.value.length;
            return GestureDetector(
              onTap: () {
                onReactionTap?.call(emoji);
              },
              child: Container(
                height: 20.h,
                padding: EdgeInsets.symmetric(horizontal: 7.w),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.circular(999.r),
                  border: Border.all(
                    color: context.colors.surface,
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Platform.isIOS
                        ? Transform.translate(
                          offset: const Offset(1, -1),
                          child: Text(
                            emoji,
                            style: TextStyle(
                              fontSize: 13.sp,
                              height: 1.0,
                              color:
                                  message.isMe
                                      ? context.colors.meChatBubbleText
                                      : context.colors.otherChatBubbleText,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                        : Text(
                          emoji,
                          style: TextStyle(
                            fontSize: 13.sp,
                            height: 1.0,
                            color:
                                message.isMe
                                    ? context.colors.meChatBubbleText
                                    : context.colors.otherChatBubbleText,
                          ),
                          textAlign: TextAlign.center,
                        ),
                    if (count > 1)
                      Platform.isIOS
                          ? Transform.translate(
                            offset: const Offset(1, -1),
                            child: Text(
                              ' ${count > 99 ? '99+' : count}',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                height: 1.0,
                                color:
                                    message.isMe
                                        ? context.colors.meChatBubbleText
                                        : context.colors.otherChatBubbleText,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                          : Text(
                            ' ${count > 99 ? '99+' : count}',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              height: 1.0,
                              color:
                                  message.isMe
                                      ? context.colors.meChatBubbleText
                                      : context.colors.otherChatBubbleText,
                            ),
                            textAlign: TextAlign.center,
                          ),
                  ],
                ),
              ),
            );
          }).toList();
        })(),
        if (message.reactions.length > 3)
          Text(
            '...',
            style: TextStyle(
              fontSize: 13.sp,
              color:
                  message.isMe
                      ? context.colors.meChatBubbleText
                      : context.colors.otherChatBubbleText,
            ),
          ),
      ],
    );
  }
}

class TimeAndStatus extends StatelessWidget {
  const TimeAndStatus({
    super.key,
    required this.message,
    required this.context,
  });

  final MessageModel message;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message.timeSent,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: context.colors.mutedForeground,
          ),
        ),
        if (message.isMe) ...[
          Gap(2.w),
          WnImage(
            message.status.imagePath,
            size: 14.w,
            color: message.status.bubbleStatusColor(context),
          ),
        ],
      ],
    );
  }
}
