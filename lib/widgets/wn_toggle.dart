import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/theme.dart';

class WnToggle extends StatelessWidget {
  const WnToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.thumbKey,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;
  final Key? thumbKey;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final trackColor = value ? colors.backgroundContentPrimary : colors.backgroundPrimary;
    final thumbColor = value ? colors.backgroundPrimary : colors.backgroundContentTertiary;

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: GestureDetector(
        onTap: enabled ? () => onChanged(!value) : null,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          width: 56.w,
          height: 28.h,
          padding: EdgeInsets.all(4.r),
          decoration: BoxDecoration(
            color: trackColor,
            border: Border.all(color: colors.borderSecondary),
            borderRadius: BorderRadius.circular(999.r),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              key: thumbKey,
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(
                color: thumbColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
