import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_avatar.dart';
import 'package:whitenoise/widgets/wn_icon.dart';

class WnUserBubble extends StatelessWidget {
  const WnUserBubble({
    super.key,
    required this.displayName,
    this.pictureUrl,
    this.avatarColor = AvatarColor.neutral,
    this.onTap,
  });

  final String displayName;
  final String? pictureUrl;
  final AvatarColor avatarColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typographyScaled;

    return GestureDetector(
      key: const Key('user_bubble_tap_target'),
      onTap: onTap,
      child: Container(
        height: 28.h,
        constraints: BoxConstraints(maxWidth: 126.w),
        padding: EdgeInsets.only(top: 4.h, bottom: 4.h, left: 4.w, right: 8.w),
        decoration: BoxDecoration(
          color: colors.fillPrimary,
          borderRadius: BorderRadius.circular(999.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            WnAvatar(
              key: const Key('user_bubble_avatar'),
              size: WnAvatarSize.bubble,
              pictureUrl: pictureUrl,
              displayName: displayName,
              color: avatarColor,
            ),
            Gap(4.w),
            Flexible(
              child: Text(
                displayName,
                key: const Key('user_bubble_name'),
                style: typography.medium12.copyWith(
                  color: colors.fillContentPrimary,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            Gap(4.w),
            WnIcon(
              WnIcons.closeSmall,
              key: const Key('user_bubble_close'),
              size: 14.w,
              color: colors.fillContentPrimary,
            ),
          ],
        ),
      ),
    );
  }
}
