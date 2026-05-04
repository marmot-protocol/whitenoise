import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/theme.dart';

class WnPill extends StatelessWidget {
  const WnPill({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: ShapeDecoration(
        color: colors.fillSecondary,
        shape: StadiumBorder(side: BorderSide(color: colors.borderTertiary)),
      ),
      child: Text(
        label,
        style: context.typographyScaled.medium10.copyWith(
          color: colors.backgroundContentSecondary,
        ),
      ),
    );
  }
}
