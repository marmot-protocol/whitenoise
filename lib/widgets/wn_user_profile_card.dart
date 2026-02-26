import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/utils/formatting.dart';
import 'package:whitenoise/utils/metadata.dart' show presentName, sanitizeForDisplay;
import 'package:whitenoise/widgets/wn_avatar.dart';
import 'package:whitenoise/widgets/wn_copy_card.dart';

class WnUserProfileCard extends StatelessWidget {
  const WnUserProfileCard({
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
    final typography = context.typographyScaled;
    final displayName = presentName(metadata);
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
        if (displayName != null)
          Text(
            displayName,
            style: typography.semiBold20.copyWith(color: colors.backgroundContentPrimary),
            textAlign: TextAlign.center,
          ),
        if (metadata?.nip05 != null && metadata!.nip05!.isNotEmpty) ...[
          Gap(4.h),
          Text(
            sanitizeForDisplay(metadata!.nip05!),
            style: typography.medium14.copyWith(color: colors.backgroundContentTertiary),
            textAlign: TextAlign.center,
          ),
        ],
        if (metadata?.about != null && metadata!.about!.isNotEmpty) ...[
          Gap(16.h),
          Text(
            sanitizeForDisplay(metadata!.about!),
            style: typography.medium14.copyWith(color: colors.backgroundContentSecondary),
            textAlign: TextAlign.center,
            maxLines: 10,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (npub != null) ...[
          Gap(24.h),
          WnCopyCard(
            textToDisplay: formattedNpub,
            textToCopy: npub,
            onCopySuccess: () => onPublicKeyCopied?.call(),
            onCopyError: () => onPublicKeyCopyError?.call(),
            snapToWords: true,
          ),
        ],
      ],
    );
  }
}
