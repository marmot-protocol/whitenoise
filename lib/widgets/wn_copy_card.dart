import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_icon.dart';
import 'package:whitenoise/widgets/wn_middle_ellipsis_text.dart';

class WnCopyCard extends StatelessWidget {
  const WnCopyCard({
    super.key,
    required this.textToDisplay,
    required this.textToCopy,
    this.onCopySuccess,
    this.onCopyError,
    this.snapToWords = false,
  });

  final String textToDisplay;
  final String textToCopy;
  final VoidCallback? onCopySuccess;
  final VoidCallback? onCopyError;
  final bool snapToWords;

  void _handleTap(BuildContext context) async {
    try {
      await Clipboard.setData(ClipboardData(text: textToCopy));
      if (context.mounted) {
        onCopySuccess?.call();
      }
    } catch (_) {
      if (context.mounted) {
        onCopyError?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = context.typographyScaled.medium14.copyWith(
      color: colors.backgroundContentSecondary,
    );

    return Material(
      color: colors.fillSecondary,
      borderRadius: BorderRadius.circular(8.r),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const Key('copy_button'),
        onTap: () => _handleTap(context),
        hoverColor: colors.fillSecondaryHover,
        splashColor: colors.fillSecondaryActive,
        highlightColor: colors.fillSecondaryActive,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          child: Row(
            spacing: 16.w,
            children: [
              Expanded(
                child: WnMiddleEllipsisText(
                  key: const Key('copy_card_text'),
                  text: textToDisplay,
                  style: style,
                  maxLines: 2,
                  snapToWords: snapToWords,
                ),
              ),
              WnIcon(
                WnIcons.copy,
                key: const Key('copy_icon'),
                size: 18.w,
                color: colors.backgroundContentSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
