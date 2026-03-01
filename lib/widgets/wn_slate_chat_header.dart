import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_avatar.dart';
import 'package:whitenoise/widgets/wn_icon.dart';

class WnSlateChatHeader extends StatelessWidget {
  const WnSlateChatHeader({
    super.key,
    required this.displayName,
    required this.avatarColor,
    this.pictureUrl,
    required this.onBack,
    required this.onAvatarTap,
    this.onNameTap,
    this.trailingWidget,
  });

  final String displayName;
  final AvatarColor avatarColor;
  final String? pictureUrl;
  final VoidCallback onBack;
  final VoidCallback onAvatarTap;
  final VoidCallback? onNameTap;
  final Widget? trailingWidget;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 16.h),
      child: Row(
        spacing: 16.w,
        children: [
          GestureDetector(
            key: const Key('back_button'),
            onTap: onBack,
            child: WnIcon(
              WnIcons.chevronLeft,
              size: 24.w,
              color: colors.backgroundContentSecondary,
            ),
          ),
          GestureDetector(
            key: const Key('header_avatar_tap_area'),
            onTap: onAvatarTap,
            child: WnAvatar(pictureUrl: pictureUrl, displayName: displayName, color: avatarColor),
          ),
          Expanded(
            child: GestureDetector(
              key: const Key('header_name_tap_area'),
              onTap: onNameTap ?? onAvatarTap,
              behavior: HitTestBehavior.opaque,
              child: Text(
                displayName,
                style: context.typographyScaled.semiBold16.copyWith(
                  color: colors.backgroundContentPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          if (trailingWidget != null) trailingWidget!,
        ],
      ),
    );
  }
}
