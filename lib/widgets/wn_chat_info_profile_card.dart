import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/utils/formatting.dart';
import 'package:whitenoise/widgets/wn_avatar.dart';
import 'package:whitenoise/widgets/wn_copy_card.dart';

class WnChatInfoProfileCard extends StatelessWidget {
  const WnChatInfoProfileCard({
    super.key,
    required this.userPubkey,
    this.displayName,
    this.pictureUrl,
    required this.avatarColor,
    this.onPublicKeyCopied,
    this.onPublicKeyCopyError,
  });

  final String userPubkey;
  final String? displayName;
  final String? pictureUrl;
  final AvatarColor avatarColor;
  final VoidCallback? onPublicKeyCopied;
  final VoidCallback? onPublicKeyCopyError;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final name = displayName;
    final npub = npubFromHex(userPubkey);
    final formattedNpub = formatPublicKey(npub ?? userPubkey);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        WnAvatar(
          pictureUrl: pictureUrl,
          displayName: name != null && name.isNotEmpty ? name : null,
          size: WnAvatarSize.large,
          color: avatarColor,
        ),
        Gap(16.h),
        if (name != null && name.isNotEmpty)
          Text(
            name,
            key: const Key('chat_info_display_name'),
            style: context.typographyScaled.semiBold20.copyWith(
              color: colors.backgroundContentPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          )
        else
          SizedBox(height: 26.h),
        if (npub != null) ...[
          Gap(16.h),
          WnCopyCard(
            textToDisplay: formattedNpub,
            textToCopy: npub,
            onCopySuccess: onPublicKeyCopied,
            onCopyError: onPublicKeyCopyError,
            snapToWords: true,
          ),
        ],
      ],
    );
  }
}
