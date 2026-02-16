import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart' show Gap;
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_avatar.dart';

class WnUserItem extends StatelessWidget {
  const WnUserItem({
    super.key,
    required this.displayName,
    this.label,
    this.pictureUrl,
    this.avatarColor = AvatarColor.neutral,
    this.imageProvider,
  });

  final String displayName;
  final String? label;
  final String? pictureUrl;
  final AvatarColor avatarColor;
  final ImageProvider? imageProvider;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typographyScaled;

    return Row(
      children: [
        WnAvatar(
          pictureUrl: pictureUrl,
          displayName: displayName,
          size: WnAvatarSize.xSmall,
          color: avatarColor,
          imageProvider: imageProvider,
        ),
        Gap(9.w),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                key: const Key('user_item_name'),
                style: typography.medium16.copyWith(
                  color: colors.backgroundContentPrimary,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              if (label != null) ...[
                Gap(2.h),
                Text(
                  label!,
                  key: const Key('user_item_label'),
                  style: typography.semiBold12.copyWith(
                    color: colors.backgroundContentSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
