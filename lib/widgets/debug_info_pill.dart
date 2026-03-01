import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/theme.dart';

class DebugInfoPill extends StatelessWidget {
  const DebugInfoPill({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typographyScaled;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: colors.fillSecondary,
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: colors.borderTertiary),
      ),
      child: Text(
        label,
        style: typography.medium10.copyWith(color: colors.backgroundContentSecondary),
      ),
    );
  }
}
