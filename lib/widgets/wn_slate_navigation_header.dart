import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_icon.dart';

enum WnSlateNavigationType { close, back }

class WnSlateNavigationHeader extends StatelessWidget {
  const WnSlateNavigationHeader({
    super.key,
    this.title,
    this.titleWidget,
    this.type = WnSlateNavigationType.close,
    this.onNavigate,
  }) : assert(title != null || titleWidget != null, 'title or titleWidget is required');

  final String? title;
  final Widget? titleWidget;
  final WnSlateNavigationType type;
  final VoidCallback? onNavigate;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isBack = type == WnSlateNavigationType.back;
    final hasAction = onNavigate != null;
    final hasLeadingAction = isBack && hasAction;
    final hasTrailingAction = !isBack && hasAction;

    return SizedBox(
      height: 80.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 56.w),
            child:
                titleWidget ??
                Text(
                  title!,
                  textAlign: TextAlign.center,
                  style: context.typographyScaled.semiBold16.copyWith(
                    color: colors.backgroundContentPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (hasLeadingAction)
                _SlateHeaderAction(
                  key: const Key('slate_back_button'),
                  isBack: true,
                  onPressed: onNavigate!,
                )
              else
                const SizedBox.shrink(),
              if (hasTrailingAction)
                _SlateHeaderAction(
                  key: const Key('slate_close_button'),
                  isBack: false,
                  onPressed: onNavigate!,
                )
              else
                const SizedBox.shrink(),
            ],
          ),
        ],
      ),
    );
  }
}

class _SlateHeaderAction extends StatelessWidget {
  const _SlateHeaderAction({
    super.key,
    required this.isBack,
    required this.onPressed,
  });

  final bool isBack;
  final VoidCallback onPressed;

  WnIcons get _icon => isBack ? WnIcons.chevronLeft : WnIcons.closeLarge;

  EdgeInsetsGeometry get _padding =>
      isBack ? EdgeInsets.only(left: 24.w, right: 32.w) : EdgeInsets.only(left: 16.w, right: 14.w);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 80.h,
        padding: _padding,
        alignment: isBack ? Alignment.centerLeft : Alignment.centerRight,
        child: WnIcon(
          _icon,
          size: 24.w,
          color: colors.backgroundContentSecondary,
        ),
      ),
    );
  }
}
