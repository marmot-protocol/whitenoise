import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_icon.dart';
import 'package:whitenoise/widgets/wn_icon_button.dart';

enum CalloutType {
  neutral,
  info,
  warning,
  success,
  error,
}

class WnCallout extends StatelessWidget {
  const WnCallout({
    super.key,
    required this.title,
    this.description,
    this.type = CalloutType.neutral,
    this.onDismiss,
  });

  final String title;
  final String? description;
  final CalloutType type;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typographyScaled;
    final colorScheme = _getColorScheme(colors);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: colorScheme.backgroundColor,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: colors.borderTertiary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              SizedBox(
                width: 36.w,
                height: 36.w,
                child: Center(
                  child: WnIcon(
                    colorScheme.icon,
                    key: const Key('callout_icon'),
                    size: 20.w,
                    color: colorScheme.iconColor,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: 16.w),
                  child: Text(
                    title,
                    style: typography.bold14.copyWith(color: colorScheme.titleColor),
                  ),
                ),
              ),
              if (onDismiss != null)
                WnIconButton(
                  key: const Key('callout_dismiss'),
                  icon: WnIcons.closeLarge,
                  onPressed: onDismiss,
                ),
            ],
          ),
          if (description != null) ...[
            Padding(
              padding: EdgeInsets.only(left: 8.w, right: 8.w, top: 4.h, bottom: 13.h),
              child: Text(
                description!,
                style: typography.medium14.copyWith(color: colorScheme.descriptionColor),
              ),
            ),
          ],
        ],
      ),
    );
  }

  _CalloutColorScheme _getColorScheme(SemanticColors colors) {
    switch (type) {
      case CalloutType.neutral:
        return _CalloutColorScheme(
          backgroundColor: colors.fillSecondary,
          iconColor: colors.backgroundContentPrimary,
          titleColor: colors.backgroundContentPrimary,
          descriptionColor: colors.backgroundContentSecondary,
          icon: WnIcons.helpFilled,
        );
      case CalloutType.info:
        return _CalloutColorScheme(
          backgroundColor: colors.intentionInfoBackground,
          iconColor: colors.intentionInfoContent,
          titleColor: colors.intentionInfoContent,
          descriptionColor: colors.backgroundContentQuaternary,
          icon: WnIcons.informationFilled,
        );
      case CalloutType.warning:
        return _CalloutColorScheme(
          backgroundColor: colors.intentionWarningBackground,
          iconColor: colors.intentionWarningContent,
          titleColor: colors.intentionWarningContent,
          descriptionColor: colors.backgroundContentQuaternary,
          icon: WnIcons.warningFilled,
        );
      case CalloutType.success:
        return _CalloutColorScheme(
          backgroundColor: colors.intentionSuccessBackground,
          iconColor: colors.intentionSuccessContent,
          titleColor: colors.intentionSuccessContent,
          descriptionColor: colors.backgroundContentQuaternary,
          icon: WnIcons.checkmarkFilled,
        );
      case CalloutType.error:
        return _CalloutColorScheme(
          backgroundColor: colors.intentionErrorBackground,
          iconColor: colors.intentionErrorContent,
          titleColor: colors.intentionErrorContent,
          descriptionColor: colors.backgroundContentQuaternary,
          icon: WnIcons.errorFilled,
        );
    }
  }
}

class _CalloutColorScheme {
  const _CalloutColorScheme({
    required this.backgroundColor,
    required this.iconColor,
    required this.titleColor,
    required this.descriptionColor,
    required this.icon,
  });

  final Color backgroundColor;
  final Color iconColor;
  final Color titleColor;
  final Color descriptionColor;
  final WnIcons icon;
}
