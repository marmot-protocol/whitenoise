import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/widgets/wn_avatar.dart';

class WnSlateAvatarHeader extends StatelessWidget {
  const WnSlateAvatarHeader({
    super.key,
    this.avatarUrl,
    this.displayName,
    this.avatarColor,
    this.avatarKey,
    this.onAvatarTap,
    this.action,
  });

  final String? avatarUrl;
  final String? displayName;
  final AvatarColor? avatarColor;
  final Key? avatarKey;
  final VoidCallback? onAvatarTap;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80.h,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            key: avatarKey,
            onTap: onAvatarTap,
            behavior: HitTestBehavior.opaque,
            child: Container(
              height: 80.h,
              padding: EdgeInsets.fromLTRB(16.w, 0, 24.w, 0),
              alignment: Alignment.center,
              child: WnAvatar(
                pictureUrl: avatarUrl,
                displayName: displayName,
                color: avatarColor ?? AvatarColor.neutral,
              ),
            ),
          ),
          if (action != null)
            Container(
              height: 80.h,
              padding: EdgeInsets.only(left: 16.w, right: 12.w),
              alignment: Alignment.centerRight,
              child: action!,
            ),
        ],
      ),
    );
  }
}
