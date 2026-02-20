import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_icon.dart';

class WnChatInfoActions extends StatelessWidget {
  const WnChatInfoActions({
    super.key,
    required this.isOwnProfile,
    required this.isFollowing,
    required this.isFollowLoading,
    required this.onFollowTap,
    required this.onSearchTap,
    required this.onAddToGroupTap,
  });

  final bool isOwnProfile;
  final bool isFollowing;
  final bool isFollowLoading;
  final VoidCallback onFollowTap;
  final VoidCallback onSearchTap;
  final VoidCallback onAddToGroupTap;

  @override
  Widget build(BuildContext context) {
    final contactLabel = isFollowing ? context.l10n.removeAsContact : context.l10n.addAsContact;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WnButton(
          key: const Key('search_button'),
          text: context.l10n.search,
          type: WnButtonType.outline,
          size: WnButtonSize.medium,
          trailingIcon: WnIcons.search,
          onPressed: onSearchTap,
        ),
        Gap(8.h),
        if (!isOwnProfile) ...[
          WnButton(
            key: const Key('contact_button'),
            text: contactLabel,
            type: WnButtonType.outline,
            size: WnButtonSize.medium,
            loading: isFollowLoading,
            trailingIcon: isFollowing ? WnIcons.userUnfollow : WnIcons.userFollow,
            onPressed: onFollowTap,
          ),
          Gap(8.h),
        ],
        WnButton(
          key: const Key('add_to_group_button'),
          text: context.l10n.addToGroup,
          type: WnButtonType.outline,
          size: WnButtonSize.medium,
          trailingIcon: WnIcons.newGroupChat,
          onPressed: onAddToGroupTap,
        ),
      ],
    );
  }
}
