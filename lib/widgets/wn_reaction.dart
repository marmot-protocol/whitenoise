import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/theme.dart';

enum WnReactionType { incoming, outgoing }

class WnReaction extends HookWidget {
  final String emoji;
  final int? count;
  final bool isSelected;
  final WnReactionType type;
  final VoidCallback? onTap;

  const WnReaction({
    super.key,
    required this.emoji,
    this.count,
    this.isSelected = false,
    this.type = WnReactionType.incoming,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isHovered = useState(false);
    final colors = context.colors;
    final reactionColors = type == WnReactionType.outgoing
        ? colors.reaction.outgoing
        : colors.reaction.incoming;

    final backgroundColor = isHovered.value
        ? reactionColors.fillHover
        : isSelected
        ? reactionColors.fillSelected
        : reactionColors.fill;
    final textColor = isHovered.value
        ? reactionColors.contentHover
        : isSelected
        ? reactionColors.contentSelected
        : reactionColors.content;

    final showCount = count != null && count! > 1;
    final displayCount = count != null && count! > 99 ? '99+' : count?.toString();

    final pill = Container(
      padding: EdgeInsets.fromLTRB(6.w, 4.h, showCount ? 7.w : 6.w, 4.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            emoji,
            style: TextStyle(fontSize: 16.sp, height: 1),
          ),
          if (showCount) ...[
            Gap(2.w),
            Text(
              displayCount!,
              style: context.typographyScaled.semiBold12.copyWith(color: textColor),
            ),
          ],
        ],
      ),
    );

    return MouseRegion(
      onEnter: (_) => isHovered.value = true,
      onExit: (_) => isHovered.value = false,
      child: onTap != null ? GestureDetector(onTap: onTap, child: pill) : pill,
    );
  }
}
