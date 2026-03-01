import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/theme.dart';

class DebugSectionCard extends StatelessWidget {
  const DebugSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.onCopy,
    this.borderColor,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final VoidCallback? onCopy;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typographyScaled;
    final resolvedBorderColor = borderColor ?? colors.borderTertiary;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: colors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: resolvedBorderColor.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.18),
            blurRadius: 14.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: typography.semiBold12.copyWith(
                        color: colors.backgroundContentPrimary,
                        letterSpacing: 0.2.sp,
                      ),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: 2.h),
                      Text(
                        subtitle!,
                        style: typography.medium10.copyWith(
                          color: colors.backgroundContentSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onCopy != null)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8.r),
                    onTap: onCopy,
                    child: Ink(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: colors.fillSecondary,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: colors.borderTertiary),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.copy_all_rounded,
                            size: 12.w,
                            color: colors.backgroundContentSecondary,
                          ),
                          SizedBox(width: 5.w),
                          Text(
                            'Copy',
                            style: typography.medium10.copyWith(
                              color: colors.backgroundContentSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 10.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: colors.backgroundPrimary.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: colors.borderTertiary.withValues(alpha: 0.85)),
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}
