import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_icon.dart';

enum WnInputFieldButtonSize {
  size36(36, 16),
  size40(40, 18),
  size48(48, 18)
  ;

  const WnInputFieldButtonSize(this.dimension, this.iconSize);
  final int dimension;
  final int iconSize;
}

class WnInputFieldButton extends StatelessWidget {
  const WnInputFieldButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.buttonSize = WnInputFieldButtonSize.size48,
    this.filled = true,
  });

  final WnIcons icon;
  final VoidCallback onPressed;
  final WnInputFieldButtonSize buttonSize;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: buttonSize.dimension.w,
        height: buttonSize.dimension.h,
        decoration: BoxDecoration(
          color: filled ? colors.fillTertiary : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Center(
          child: WnIcon(
            icon,
            size: buttonSize.iconSize.w,
            color: colors.backgroundContentPrimary,
          ),
        ),
      ),
    );
  }
}
