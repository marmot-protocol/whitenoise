import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart' show Gap;
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/utils/formatting.dart';
import 'package:whitenoise/widgets/wn_avatar.dart';
import 'package:whitenoise/widgets/wn_icon.dart';
import 'package:whitenoise/widgets/wn_middle_ellipsis_text.dart';

class WnProfileSwitcherItem extends StatelessWidget {
  const WnProfileSwitcherItem({
    super.key,
    required this.pubkey,
    this.displayName,
    this.pictureUrl,
    this.isSelected = false,
    required this.onTap,
  });

  final String pubkey;
  final String? displayName;
  final String? pictureUrl;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typographyScaled;
    final formattedPubkey = formatPublicKey(npubFromHex(pubkey) ?? pubkey);

    final backgroundColor = isSelected ? colors.fillTertiaryActive : colors.fillTertiary;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            WnAvatar(
              pictureUrl: pictureUrl,
              displayName: displayName,
              size: WnAvatarSize.medium,
              color: AvatarColor.fromPubkey(pubkey),
            ),
            Gap(8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (displayName != null)
                    Text(
                      displayName!,
                      style: typography.medium16.copyWith(
                        color: colors.backgroundContentPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    )
                  else
                    WnMiddleEllipsisText(
                      text: formattedPubkey,
                      style: typography.medium16.copyWith(
                        color: colors.backgroundContentPrimary,
                      ),
                      snapToWords: true,
                    ),
                  Gap(4.h),
                  WnMiddleEllipsisText(
                    text: formattedPubkey,
                    style: typography.medium12.copyWith(
                      color: colors.backgroundContentSecondary,
                    ),
                    snapToWords: true,
                  ),
                ],
              ),
            ),
            if (isSelected) ...[
              Gap(8.w),
              WnIcon(
                WnIcons.checkmark,
                key: const Key('profile_switcher_item_checkmark'),
                color: colors.backgroundContentSecondary,
                size: 18.sp,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
