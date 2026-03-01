import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/theme.dart';

class DebugKeyValueRow extends StatelessWidget {
  const DebugKeyValueRow({
    super.key,
    required this.label,
    required this.value,
    this.labelWidth,
    this.valueKey,
  });

  final String label;
  final String value;
  final double? labelWidth;
  final Key? valueKey;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typographyScaled;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: labelWidth,
          child: Text(
            '$label: ',
            style: typography.semiBold10.copyWith(
              color: colors.backgroundContentSecondary,
              fontFamily: 'monospace',
              letterSpacing: 0.1.sp,
            ),
          ),
        ),
        Expanded(
          child: SelectableText(
            key: valueKey,
            value,
            style: typography.medium10.copyWith(
              color: colors.backgroundContentPrimary,
              fontFamily: 'monospace',
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
