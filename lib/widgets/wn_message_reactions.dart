import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/src/rust/api/messages.dart' show EmojiReaction;
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_message_bubble.dart' show MessageDirection;

class WnMessageReactions extends StatelessWidget {
  static const int maxVisibleReactions = 3;

  final List<EmojiReaction> reactions;
  final String? currentUserPubkey;
  final MessageDirection direction;
  final void Function(String emoji)? onReaction;

  const WnMessageReactions({
    super.key,
    required this.reactions,
    required this.direction,
    this.currentUserPubkey,
    this.onReaction,
  });

  bool get _isOutgoing => direction == MessageDirection.outgoing;

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) {
      return const SizedBox.shrink();
    }

    final colors = context.colors;
    final typography = context.typographyScaled;
    final bubbleColor = _isOutgoing ? colors.fillPrimary : colors.backgroundTertiary;
    final textColor = _isOutgoing ? colors.fillContentPrimary : colors.backgroundContentPrimary;
    final visibleReactions = reactions.take(maxVisibleReactions).toList();
    final hasOverflow = reactions.length > maxVisibleReactions;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final reaction in visibleReactions)
          _ReactionPill(
            emoji: reaction.emoji,
            count: reaction.count.toInt(),
            borderColor: colors.backgroundPrimary,
            backgroundColor: bubbleColor,
            textColor: textColor,
            onReaction: onReaction,
          ),
        if (hasOverflow)
          Padding(
            padding: EdgeInsets.only(left: 2.w),
            child: Text(
              '...',
              style: typography.medium10.copyWith(color: textColor),
            ),
          ),
      ],
    );
  }
}

class _ReactionPill extends StatelessWidget {
  final String emoji;
  final int count;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final void Function(String emoji)? onReaction;

  const _ReactionPill({
    required this.emoji,
    required this.count,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    this.onReaction,
  });

  @override
  Widget build(BuildContext context) {
    final typography = context.typographyScaled;
    final pill = Container(
      margin: EdgeInsets.only(right: 4.w),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: borderColor),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: typography.medium14),
            if (count > 1) ...[
              SizedBox(width: 2.w),
              Text(
                count > 99 ? '99+' : count.toString(),
                style: typography.medium10.copyWith(color: textColor),
              ),
            ],
          ],
        ),
      ),
    );

    if (onReaction != null) {
      return GestureDetector(
        onTap: () => onReaction!(emoji),
        child: pill,
      );
    }

    return pill;
  }
}
