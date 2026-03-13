import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_icon.dart';

class WnCheckbox extends StatelessWidget {
  const WnCheckbox({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.description,
    this.checkboxKey,
  });

  final String label;
  final String? description;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Key? checkboxKey;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typographyScaled;

    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
        onChanged(!value);
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 24.w,
                height: 24.h,
                child: Center(
                  child: WnIcon(
                    value ? WnIcons.checkboxChecked : WnIcons.checkbox,
                    key: checkboxKey,
                    size: 24.w,
                    color: colors.backgroundContentPrimary,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  label,
                  style: typography.medium14.copyWith(
                    color: colors.backgroundContentPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (description != null) ...[
            SizedBox(height: 2.h),
            Padding(
              padding: EdgeInsets.only(left: 24.w + 12.w),
              child: Text(
                description!,
                style: typography.medium12.copyWith(
                  color: colors.backgroundContentTertiary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
