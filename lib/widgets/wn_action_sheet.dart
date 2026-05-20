import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_icon.dart';
import 'package:whitenoise/widgets/wn_slate.dart';

class WnActionSheetAction<T> {
  const WnActionSheetAction({
    required this.value,
    required this.label,
    this.icon,
    this.type = WnButtonType.outline,
    this.key,
  });

  final T value;
  final String label;
  final WnIcons? icon;
  final WnButtonType type;
  final Key? key;
}

class WnActionSheet<T> extends StatelessWidget {
  const WnActionSheet({
    super.key,
    required this.actions,
  });

  final List<WnActionSheetAction<T>> actions;

  static Future<T?> show<T>({
    required BuildContext context,
    required List<WnActionSheetAction<T>> actions,
  }) {
    final colors = context.colors;
    return showDialog<T>(
      context: context,
      barrierColor: colors.backgroundPrimary.withValues(alpha: 0.8),
      builder: (dialogContext) => WnActionSheet<T>(actions: actions),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      child: WnSlate(
        shrinkWrapContent: true,
        child: Padding(
          padding: EdgeInsets.all(14.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0) Gap(8.h),
                WnButton(
                  key: actions[i].key,
                  text: actions[i].label,
                  type: actions[i].type,
                  size: WnButtonSize.medium,
                  trailingIcon: actions[i].icon,
                  onPressed: () => Navigator.of(context).pop(actions[i].value),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
