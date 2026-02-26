import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/src/rust/api/messages.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_chat_status.dart';
import 'package:whitenoise/widgets/wn_reaction.dart';

export 'package:whitenoise/src/rust/api/messages.dart' show EmojiReaction;

const _timestampMinPadding = 16.0;
const _chatStatusW = 18.0;
const _chatStatusGap = 4.0;

enum MessageDirection { incoming, outgoing }

enum BubbleLeadingVariant { none, tail, avatar }

const _tailW = 16.0;
const _tailH = 10.0;
const _tailOverhang = 8.0;

class _TextWithTimestamp extends StatelessWidget {
  const _TextWithTimestamp({
    required this.content,
    required this.timestamp,
    required this.textStyle,
    required this.tsStyle,
    required this.isOutgoing,
  });

  final String content;
  final String timestamp;
  final TextStyle textStyle;
  final TextStyle tsStyle;
  final bool isOutgoing;

  @override
  Widget build(BuildContext context) {
    final reservedWidth = _timestampReservedWidth(timestamp, tsStyle, isOutgoing);

    return Stack(
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: content, style: textStyle),
              WidgetSpan(child: SizedBox(width: reservedWidth)),
            ],
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(timestamp, style: tsStyle),
              if (isOutgoing) ...[
                SizedBox(width: _chatStatusGap.w),
                const WnChatStatus(status: ChatStatusType.sent),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  const _BubbleTailPainter({required this.color, required this.incoming});

  final Color color;
  final bool incoming;

  @override
  void paint(Canvas canvas, Size size) {
    if (!incoming) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }
    canvas.drawPath(
      Path()
        ..moveTo(size.width, 0)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close(),
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_BubbleTailPainter old) => old.color != color || old.incoming != incoming;
}

BorderRadius _bubbleBorderRadius({
  required bool isOutgoing,
  required bool showTail,
  required double r,
}) {
  if (!showTail) return BorderRadius.circular(r);
  return BorderRadius.only(
    topLeft: Radius.circular(r),
    topRight: Radius.circular(r),
    bottomLeft: isOutgoing ? Radius.circular(r) : Radius.zero,
    bottomRight: isOutgoing ? Radius.zero : Radius.circular(r),
  );
}

double _timestampReservedWidth(String timestamp, TextStyle tsStyle, bool isOutgoing) {
  final painter = TextPainter(
    text: TextSpan(text: timestamp, style: tsStyle),
    textDirection: TextDirection.ltr,
  );
  try {
    painter.layout();
    final tsWidth = painter.width;
    final statusWidth = isOutgoing ? (_chatStatusGap.w + _chatStatusW.w) : 0.0;
    return _timestampMinPadding.w + tsWidth + statusWidth;
  } finally {
    painter.dispose();
  }
}

class WnMessageBubble extends StatelessWidget {
  final MessageDirection direction;
  final bool isDeleted;
  final bool showTail;
  final String? content;
  final Widget? mediaContent;
  final Widget? replyContent;
  final String? timestamp;
  final List<EmojiReaction> reactions;
  final String? currentUserPubkey;
  final VoidCallback? onLongPress;
  final void Function(String emoji)? onReaction;
  final Widget? avatar;
  final String? senderName;
  final Color? senderNameColor;
  final BubbleLeadingVariant leadingVariant;

  const WnMessageBubble({
    super.key,
    required this.direction,
    required this.isDeleted,
    this.showTail = false,
    this.content,
    this.mediaContent,
    this.replyContent,
    this.timestamp,
    this.reactions = const [],
    this.currentUserPubkey,
    this.onLongPress,
    this.onReaction,
    this.avatar,
    this.senderName,
    this.senderNameColor,
    this.leadingVariant = BubbleLeadingVariant.none,
  });

  bool get _isOutgoing => direction == MessageDirection.outgoing;

  @override
  Widget build(BuildContext context) {
    if (isDeleted) {
      return const SizedBox.shrink();
    }

    final colors = context.colors;
    final bubbleColor = _isOutgoing ? colors.fillPrimary : colors.backgroundTertiary;
    final textColor = _isOutgoing ? colors.fillContentPrimary : colors.backgroundContentPrimary;
    final timestampColor = colors.backgroundContentTertiary;

    final viewportWidth = MediaQuery.sizeOf(context).width;
    final hasAvatar = !_isOutgoing && avatar != null;
    final avatarColW = hasAvatar ? 44.w : 0.0;
    final leadingIndent = switch (leadingVariant) {
      BubbleLeadingVariant.none => 0.0,
      BubbleLeadingVariant.tail => _tailOverhang.w,
      BubbleLeadingVariant.avatar => 44.w + _tailOverhang.w,
    };
    final maxBubbleWidth = (viewportWidth - 20.w - avatarColW - leadingIndent) * 0.8;

    final tailW = _tailW.w;
    final tailH = _tailH.h;
    final tailOverhang = _tailOverhang.w;
    final radius = 8.r;

    final hasText = content != null && content!.isNotEmpty;
    final hasTimestamp = timestamp != null;
    final hasReactions = reactions.isNotEmpty;
    final hasSenderName = !_isOutgoing && senderName != null && senderName!.isNotEmpty;

    final reactionType = _isOutgoing ? WnReactionType.outgoing : WnReactionType.incoming;
    final textStyle = context.typographyScaled.medium14.copyWith(color: textColor);
    final tsStyle = context.typographyScaled.medium12.copyWith(color: timestampColor);

    final bubble = Align(
      alignment: _isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxBubbleWidth),
        child: Padding(
          padding: EdgeInsets.only(
            left: showTail && !_isOutgoing ? tailOverhang : 0,
            right: _isOutgoing && showTail ? tailOverhang : 0,
          ),
          child: IntrinsicWidth(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onLongPress: onLongPress,
                  child: Container(
                    padding: EdgeInsets.only(
                      left: 10.w,
                      right: 10.w,
                      top: 10.h,
                      bottom: 12.h,
                    ),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: _bubbleBorderRadius(
                        isOutgoing: _isOutgoing,
                        showTail: showTail,
                        r: radius,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasSenderName) ...[
                          Text(
                            senderName!,
                            style: context.typographyScaled.semiBold12.copyWith(
                              color: senderNameColor ?? colors.backgroundContentTertiary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 8.h),
                        ],
                        if (replyContent != null) ...[
                          replyContent!,
                          SizedBox(height: 8.h),
                        ],
                        if (mediaContent != null) ...[
                          mediaContent!,
                          if (hasText || hasTimestamp) SizedBox(height: 8.h),
                        ],
                        if (hasText && hasTimestamp)
                          _TextWithTimestamp(
                            content: content!,
                            timestamp: timestamp!,
                            textStyle: textStyle,
                            tsStyle: tsStyle,
                            isOutgoing: _isOutgoing,
                          )
                        else if (hasText)
                          Text(content!, style: textStyle)
                        else if (hasTimestamp) ...[
                          SizedBox(height: 2.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(timestamp!, style: tsStyle),
                              if (_isOutgoing) ...[
                                SizedBox(width: _chatStatusGap.w),
                                const WnChatStatus(status: ChatStatusType.sent),
                              ],
                            ],
                          ),
                        ],
                        if (hasReactions) ...[
                          SizedBox(height: 8.h),
                          Wrap(
                            spacing: 4.w,
                            runSpacing: 4.h,
                            children: [
                              for (final reaction in reactions)
                                WnReaction(
                                  key: ValueKey(reaction.emoji),
                                  emoji: reaction.emoji,
                                  count: reaction.count.toInt(),
                                  type: reactionType,
                                  isSelected: reaction.users.contains(currentUserPubkey),
                                  onTap: onReaction != null
                                      ? () => onReaction!(reaction.emoji)
                                      : null,
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (showTail)
                  Positioned(
                    bottom: 0,
                    left: _isOutgoing ? null : -tailOverhang,
                    right: _isOutgoing ? -tailOverhang : null,
                    child: CustomPaint(
                      size: Size(tailW, tailH),
                      painter: _BubbleTailPainter(
                        color: bubbleColor,
                        incoming: !_isOutgoing,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    final bottomMargin = showTail ? 12.h : 4.h;

    if (!hasAvatar) {
      return Padding(
        padding: EdgeInsets.only(left: leadingIndent, bottom: bottomMargin),
        child: bubble,
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: bottomMargin),
      child: Row(
        key: const Key('bubble_avatar_row'),
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 36.w, child: avatar),
          SizedBox(width: 8.w),
          Flexible(child: bubble),
        ],
      ),
    );
  }
}
