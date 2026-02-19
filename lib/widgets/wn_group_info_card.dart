import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/utils/avatar_color.dart';
import 'package:whitenoise/widgets/wn_avatar.dart' show WnAvatar, WnAvatarSize;

class WnGroupInfoCard extends StatelessWidget {
  const WnGroupInfoCard({
    super.key,
    required this.groupId,
    this.name,
    this.description,
    this.imagePath,
  });

  final String groupId;
  final String? name;
  final String? description;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasName = name != null && name!.isNotEmpty;
    final hasDescription = description != null && description!.isNotEmpty;

    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          WnAvatar(
            key: const Key('group_info_avatar'),
            pictureUrl: imagePath,
            displayName: name ?? '',
            size: WnAvatarSize.large,
            color: AvatarColor.fromPubkey(groupId),
          ),
          Gap(16.h),
          if (hasName)
            Text(
              name!,
              key: const Key('group_info_name'),
              style: context.typographyScaled.semiBold20.copyWith(
                color: colors.backgroundContentPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          else
            SizedBox(height: 26.h),
          if (hasDescription) ...[
            Gap(8.h),
            Text(
              description!,
              key: const Key('group_info_description'),
              style: context.typographyScaled.medium14.copyWith(
                color: colors.backgroundContentSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
