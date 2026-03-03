import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_avatar.dart';
import 'package:whitenoise/widgets/wn_chat_status.dart';
import 'package:whitenoise/widgets/wn_icon.dart';

class WnChatListItem extends HookWidget {
  const WnChatListItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    this.avatarUrl,
    this.avatarName,
    this.avatarColor = AvatarColor.neutral,
    this.showPinned = false,
    this.status,
    this.unreadCount,
    this.notificationOff = false,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.prefixSubtitle,
    this.subtitleIcon,
  });

  final String title;
  final String subtitle;
  final String timestamp;
  final String? avatarUrl;
  final String? avatarName;
  final AvatarColor avatarColor;
  final bool showPinned;
  final ChatStatusType? status;
  final int? unreadCount;
  final bool notificationOff;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final String? prefixSubtitle;
  final Widget? subtitleIcon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typographyScaled;
    final isHovered = useState(false);

    return MouseRegion(
      onEnter: (_) => isHovered.value = true,
      onExit: (_) => isHovered.value = false,
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            color: (isSelected || isHovered.value) ? colors.fillTertiary : Colors.transparent,
            borderRadius: BorderRadius.circular(8.r),
          ),
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
          child: Row(
            children: [
              Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: WnAvatar(
                  size: WnAvatarSize.medium,
                  pictureUrl: avatarUrl,
                  displayName: avatarName,
                  color: avatarColor,
                  showPinned: showPinned,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: typography.medium16.copyWith(
                              color: colors.backgroundContentPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (notificationOff) ...[
                          SizedBox(width: 4.w),
                          WnIcon(
                            WnIcons.notificationOff,
                            key: const Key('notification_off_icon'),
                            size: 14.w,
                            color: colors.backgroundContentSecondary,
                          ),
                        ],
                        SizedBox(width: 4.w),
                        Text(
                          timestamp,
                          style: typography.medium12.copyWith(
                            color: colors.backgroundContentSecondary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              style: typography.medium14Compact.copyWith(
                                color: colors.backgroundContentSecondary,
                              ),
                              children: [
                                if (prefixSubtitle != null)
                                  TextSpan(
                                    text: prefixSubtitle,
                                    style: typography.medium14Compact.copyWith(
                                      color: colors.backgroundContentPrimary,
                                    ),
                                  ),
                                if (subtitleIcon != null) ...[
                                  WidgetSpan(
                                    alignment: PlaceholderAlignment.middle,
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        top: defaultTargetPlatform == TargetPlatform.iOS ? 2.h : 0,
                                      ),
                                      child: subtitleIcon,
                                    ),
                                  ),
                                  const TextSpan(text: ' '),
                                ],
                                TextSpan(text: subtitle),
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (status != null) ...[
                          SizedBox(width: 8.w),
                          WnChatStatus(
                            status: status!,
                            unreadCount: unreadCount,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
