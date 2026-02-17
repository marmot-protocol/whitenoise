import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart' show Gap;
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_avatar.dart';
import 'package:whitenoise/widgets/wn_icon.dart';
import 'package:whitenoise/widgets/wn_middle_ellipsis_text.dart';

enum WnUserItemSize { small, medium, big }

class WnUserItem extends StatelessWidget {
  const WnUserItem({
    super.key,
    required this.displayName,
    this.label,
    this.npub,
    this.pictureUrl,
    this.avatarColor = AvatarColor.neutral,
    this.imageProvider,
    this.size = WnUserItemSize.small,
    this.isSelected = false,
    this.showCheckbox = false,
    this.onTap,
  });

  final String displayName;
  final String? label;
  final String? npub;
  final String? pictureUrl;
  final AvatarColor avatarColor;
  final ImageProvider? imageProvider;
  final WnUserItemSize size;
  final bool isSelected;
  final bool showCheckbox;
  final VoidCallback? onTap;

  WnAvatarSize get _avatarSize => switch (size) {
    WnUserItemSize.small => WnAvatarSize.xSmall,
    WnUserItemSize.medium => WnAvatarSize.small,
    WnUserItemSize.big => WnAvatarSize.medium,
  };

  @override
  Widget build(BuildContext context) {
    final child = switch (size) {
      WnUserItemSize.small => _SmallLayout(
        displayName: displayName,
        label: label,
        pictureUrl: pictureUrl,
        avatarColor: avatarColor,
        avatarSize: _avatarSize,
        imageProvider: imageProvider,
      ),
      WnUserItemSize.medium || WnUserItemSize.big => _MediumBigLayout(
        displayName: displayName,
        npub: npub,
        pictureUrl: pictureUrl,
        avatarColor: avatarColor,
        avatarSize: _avatarSize,
        imageProvider: imageProvider,
        isSelected: isSelected,
        showCheckbox: showCheckbox,
        isBig: size == WnUserItemSize.big,
      ),
    };

    if (onTap != null) {
      return GestureDetector(
        key: const Key('user_item_tap_target'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: child,
      );
    }

    return child;
  }
}

class _SmallLayout extends StatelessWidget {
  const _SmallLayout({
    required this.displayName,
    this.label,
    this.pictureUrl,
    required this.avatarColor,
    required this.avatarSize,
    this.imageProvider,
  });

  final String displayName;
  final String? label;
  final String? pictureUrl;
  final AvatarColor avatarColor;
  final WnAvatarSize avatarSize;
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
          size: avatarSize,
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

class _MediumBigLayout extends StatelessWidget {
  const _MediumBigLayout({
    required this.displayName,
    this.npub,
    this.pictureUrl,
    required this.avatarColor,
    required this.avatarSize,
    this.imageProvider,
    required this.isSelected,
    required this.showCheckbox,
    required this.isBig,
  });

  final String displayName;
  final String? npub;
  final String? pictureUrl;
  final AvatarColor avatarColor;
  final WnAvatarSize avatarSize;
  final ImageProvider? imageProvider;
  final bool isSelected;
  final bool showCheckbox;
  final bool isBig;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typographyScaled;

    return Container(
      key: const Key('user_item_container'),
      constraints: isBig ? BoxConstraints(minHeight: 76.h) : null,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: colors.fillTertiary,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                WnAvatar(
                  pictureUrl: pictureUrl,
                  displayName: displayName,
                  size: avatarSize,
                  color: avatarColor,
                  imageProvider: imageProvider,
                ),
                Gap(8.w),
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
                      if (npub != null) ...[
                        Gap(6.h),
                        WnMiddleEllipsisText(
                          key: const Key('user_item_npub'),
                          text: npub!,
                          style: typography.medium14Compact.copyWith(
                            color: colors.backgroundContentSecondary,
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (showCheckbox) ...[
            Gap(16.w),
            WnIcon(
              isSelected ? WnIcons.checkboxChecked : WnIcons.checkbox,
              key: const Key('user_item_checkbox'),
              size: 24.w,
              color: isSelected
                  ? colors.backgroundContentPrimary
                  : colors.backgroundContentTertiary,
            ),
          ],
        ],
      ),
    );
  }
}
