import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_icon.dart';

enum WnButtonType { primary, outline, ghost, overlay, destructive }

enum WnButtonSize { large, medium, small, xsmall }

class WnButton extends StatelessWidget {
  const WnButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.type = WnButtonType.primary,
    this.size = WnButtonSize.large,
    this.loading = false,
    this.disabled = false,
    this.leadingIcon,
    this.trailingIcon,
  });

  final String text;
  final VoidCallback? onPressed;
  final WnButtonType type;
  final WnButtonSize size;
  final bool loading;
  final bool disabled;
  final WnIcons? leadingIcon;
  final WnIcons? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return switch (type) {
      WnButtonType.primary => _buildPrimaryButton(colors),
      WnButtonType.outline => _buildOutlineButton(colors),
      WnButtonType.ghost => _buildGhostButton(colors),
      WnButtonType.overlay => _buildOverlayButton(colors),
      WnButtonType.destructive => _buildDestructiveButton(colors),
    };
  }

  Widget _buildPrimaryButton(SemanticColors colors) {
    return _buildButton(
      backgroundColor: colors.fillPrimary,
      overlayColor: colors.fillPrimaryHover,
      contentColor: colors.fillContentPrimary,
      borderSide: BorderSide.none,
    );
  }

  Widget _buildOutlineButton(SemanticColors colors) {
    return _buildButton(
      backgroundColor: colors.fillQuaternary,
      overlayColor: colors.fillQuaternaryHover,
      contentColor: colors.fillContentSecondary,
      borderSide: BorderSide(color: colors.borderTertiary),
    );
  }

  Widget _buildGhostButton(SemanticColors colors) {
    return _buildButton(
      backgroundColor: colors.fillTertiary,
      overlayColor: colors.fillTertiaryHover,
      contentColor: colors.fillContentSecondary,
      borderSide: BorderSide.none,
    );
  }

  Widget _buildOverlayButton(SemanticColors colors) {
    return _buildButton(
      backgroundColor: colors.fillQuaternary,
      overlayColor: colors.fillQuaternaryHover,
      contentColor: colors.backgroundContentPrimary,
      borderSide: BorderSide.none,
    );
  }

  Widget _buildDestructiveButton(SemanticColors colors) {
    return _buildButton(
      backgroundColor: colors.fillDestructive,
      overlayColor: colors.fillDestructiveHover,
      contentColor: colors.fillContentQuaternary,
      borderSide: BorderSide.none,
    );
  }

  Widget _buildButton({
    required Color backgroundColor,
    required Color overlayColor,
    required Color contentColor,
    required BorderSide borderSide,
  }) {
    final verticalPadding = _getVerticalPadding();
    final horizontalPadding = _getHorizontalPadding();
    final borderRadius = _getBorderRadius();
    final iconSize = _getIconSize();
    final fontSize = _getFontSize();
    final iconPadding = (size == WnButtonSize.small || size == WnButtonSize.xsmall) ? 4.w : 8.w;

    final Widget button = FilledButton(
      onPressed: (loading || disabled) ? null : onPressed,
      style: FilledButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: verticalPadding, horizontal: horizontalPadding),
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: borderSide,
        ),
        overlayColor: overlayColor,
      ),
      child: loading
          ? _buildLoadingIndicator(contentColor)
          : _buildContent(contentColor, iconSize, fontSize, iconPadding),
    );

    return button;
  }

  Widget _buildLoadingIndicator(Color color) {
    final indicatorSize = (size == WnButtonSize.small || size == WnButtonSize.xsmall) ? 14.w : 18.w;
    return SizedBox.square(
      dimension: indicatorSize,
      child: CircularProgressIndicator(
        key: const Key('loading_indicator'),
        strokeWidth: 2.w,
        strokeCap: StrokeCap.round,
        color: color,
      ),
    );
  }

  Widget _buildContent(Color contentColor, double iconSize, double fontSize, double iconPadding) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final typography = context.typographyScaled;
        final isBounded = constraints.maxWidth.isFinite;
        final baseStyle = size == WnButtonSize.small ? typography.medium12 : typography.medium14;
        final textWidget = Text(
          text,
          style: baseStyle.copyWith(color: contentColor),
          overflow: TextOverflow.ellipsis,
        );

        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leadingIcon != null) ...[
              WnIcon(
                leadingIcon!,
                size: iconSize,
                color: contentColor,
                key: const Key('leading_icon'),
              ),
              SizedBox(width: iconPadding),
            ],
            if (isBounded) Flexible(child: textWidget) else textWidget,
            if (trailingIcon != null) ...[
              SizedBox(width: iconPadding),
              WnIcon(
                trailingIcon!,
                size: iconSize,
                color: contentColor,
                key: const Key('trailing_icon'),
              ),
            ],
          ],
        );
      },
    );
  }

  double _getVerticalPadding() {
    return switch (size) {
      WnButtonSize.large => 18.h,
      WnButtonSize.medium => 12.h,
      WnButtonSize.small => 6.h,
      WnButtonSize.xsmall => 0.h,
    };
  }

  double _getHorizontalPadding() {
    return switch (size) {
      WnButtonSize.large => 8.w,
      WnButtonSize.medium => 8.w,
      WnButtonSize.small => 8.w,
      WnButtonSize.xsmall => 12.w,
    };
  }

  double _getBorderRadius() {
    return switch (size) {
      WnButtonSize.large => 8.r,
      WnButtonSize.medium => 8.r,
      WnButtonSize.small => 8.r,
      WnButtonSize.xsmall => 6.r,
    };
  }

  double _getIconSize() {
    return switch (size) {
      WnButtonSize.large => 18.w,
      WnButtonSize.medium => 18.w,
      WnButtonSize.small => 16.w,
      WnButtonSize.xsmall => 16.w,
    };
  }

  double _getFontSize() {
    return switch (size) {
      WnButtonSize.large => 14.sp,
      WnButtonSize.medium => 14.sp,
      WnButtonSize.small => 12.sp,
      WnButtonSize.xsmall => 14.sp,
    };
  }
}
