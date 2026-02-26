import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_icon.dart';

class WnMessageQuote extends StatelessWidget {
  const WnMessageQuote({
    super.key,
    required this.author,
    required this.text,
    this.onCancel,
    this.onTap,
    this.image,
    this.authorColor,
  });

  final String author;
  final String text;
  final VoidCallback? onCancel;
  final VoidCallback? onTap;
  final ImageProvider? image;
  final Color? authorColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typographyScaled;

    return GestureDetector(
      key: onTap != null ? const Key('message_quote_tap_area') : null,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: onCancel != null ? colors.backgroundTertiary : colors.backgroundPrimary,
          borderRadius: BorderRadius.circular(4.r),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                key: const Key('quote_bar'),
                width: 2.w,
                decoration: BoxDecoration(
                  color: colors.borderTertiary,
                  borderRadius: BorderRadius.circular(1.w),
                ),
              ),
              Gap(4.w),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: 6.w, top: 2.h, bottom: 2.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        author,
                        style: typography.semiBold12.copyWith(
                          color: authorColor ?? colors.backgroundContentTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Gap(4.h),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (text.isNotEmpty)
                            Flexible(
                              child: Text(
                                text,
                                style: typography.medium14Compact.copyWith(
                                  color: colors.backgroundContentSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (image != null) ...[
                Gap(10.w),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4.r),
                  child: Image(
                    key: const Key('quote_thumbnail'),
                    image: image!,
                    fit: BoxFit.cover,
                    width: 40.w,
                    height: 40.w,
                  ),
                ),
              ],
              if (onCancel != null) ...[
                Gap(4.w),
                IconButton(
                  key: const Key('cancel_quote_button'),
                  onPressed: onCancel,
                  icon: WnIcon(
                    WnIcons.closeSmall,
                    color: colors.backgroundContentTertiary,
                    size: 18.w,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
