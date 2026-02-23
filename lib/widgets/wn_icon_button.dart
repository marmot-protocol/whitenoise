import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_icon.dart';

enum WnIconButtonType { primary, outline, ghost }

enum WnIconButtonSize { size44, size56 }

class WnIconButton extends StatelessWidget {
  const WnIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.type = WnIconButtonType.ghost,
    this.size = WnIconButtonSize.size44,
    this.disabled = false,
  });

  final WnIcons icon;
  final VoidCallback? onPressed;
  final WnIconButtonType type;
  final WnIconButtonSize size;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimension = size == WnIconButtonSize.size56 ? 56.w : 44.w;
    final iconSize = size == WnIconButtonSize.size56 ? 24.w : 18.w;
    final borderRadius = 8.r;

    return SizedBox.square(
      dimension: dimension,
      child: FilledButton(
        onPressed: disabled ? null : onPressed,
        style: ButtonStyle(
          padding: WidgetStateProperty.all(EdgeInsets.zero),
          minimumSize: WidgetStateProperty.all(Size.zero),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return switch (type) {
                WnIconButtonType.primary => colors.fillSecondary,
                WnIconButtonType.outline || WnIconButtonType.ghost => Colors.transparent,
              };
            }
            if (states.contains(WidgetState.pressed)) {
              return switch (type) {
                WnIconButtonType.primary => colors.fillPrimaryActive,
                WnIconButtonType.outline => colors.fillSecondaryActive,
                WnIconButtonType.ghost => colors.fillTertiaryActive,
              };
            }
            if (states.contains(WidgetState.hovered)) {
              return switch (type) {
                WnIconButtonType.primary => colors.fillPrimaryHover,
                WnIconButtonType.outline => colors.fillSecondaryHover,
                WnIconButtonType.ghost => colors.fillTertiaryHover,
              };
            }
            return switch (type) {
              WnIconButtonType.primary => colors.fillPrimary,
              WnIconButtonType.outline => colors.fillSecondary,
              WnIconButtonType.ghost => colors.fillTertiary,
            };
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colors.backgroundContentTertiary;
            }
            return switch (type) {
              WnIconButtonType.primary => colors.fillContentPrimary,
              WnIconButtonType.outline || WnIconButtonType.ghost => colors.fillContentSecondary,
            };
          }),
          side: WidgetStateProperty.resolveWith((states) {
            if (type == WnIconButtonType.outline) {
              final borderColor = states.contains(WidgetState.disabled)
                  ? colors.borderTertiary.withValues(alpha: 0.5)
                  : colors.borderTertiary;
              return BorderSide(color: borderColor);
            }
            return BorderSide.none;
          }),
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          elevation: WidgetStateProperty.all(0),
        ),
        child: WnIcon(
          icon,
          size: iconSize,
        ),
      ),
    );
  }
}
