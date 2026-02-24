import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/utils/formatting.dart';
import 'package:whitenoise/utils/metadata.dart' show presentName;
import 'package:whitenoise/widgets/wn_avatar.dart';
import 'package:whitenoise/widgets/wn_copy_card.dart';

class WnChatInfoProfileCard extends StatelessWidget {
  const WnChatInfoProfileCard({
    super.key,
    required this.userPubkey,
    this.metadata,
    this.onPublicKeyCopied,
    this.onPublicKeyCopyError,
  });

  final String userPubkey;
  final FlutterMetadata? metadata;
  final VoidCallback? onPublicKeyCopied;
  final VoidCallback? onPublicKeyCopyError;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final displayName = presentName(metadata);
    final hasDisplayName = displayName != null && displayName.isNotEmpty;
    final npub = npubFromHex(userPubkey);
    final formattedNpub = formatPublicKey(npub ?? userPubkey);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        WnAvatar(
          pictureUrl: metadata?.picture,
          displayName: displayName,
          size: WnAvatarSize.large,
          color: AvatarColor.fromPubkey(userPubkey),
        ),
        Gap(16.h),
        if (hasDisplayName)
          Text(
            displayName,
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
