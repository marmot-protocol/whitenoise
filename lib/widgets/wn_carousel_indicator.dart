import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart' show HookWidget, useRef;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/theme.dart';

class WnCarouselIndicator extends HookWidget {
  const WnCarouselIndicator({
    super.key,
    required this.itemCount,
    required this.activeIndex,
    this.activeColor,
  }) : assert(itemCount > 0, 'itemCount must be greater than 0'),
       assert(
         activeIndex >= 0 && activeIndex < itemCount,
         'activeIndex must be between 0 and itemCount - 1',
       );

  static const Duration animationDuration = Duration(milliseconds: 600);
  static const Duration colorAnimationDuration = Duration(milliseconds: 150);
  static const Curve animationCurve = Curves.elasticOut;
  static const Curve colorAnimationCurve = Curves.easeOut;

  final int itemCount;
  final int activeIndex;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final previousIndexRef = useRef<int?>(null);
    final movingForwardRef = useRef<bool>(true);

    final previousIndex = previousIndexRef.value;
    if (previousIndex != null && previousIndex != activeIndex) {
      movingForwardRef.value = activeIndex > previousIndex;
    }

    final movingForward = movingForwardRef.value;
    final wasActiveIndex = (previousIndex != null && previousIndex != activeIndex)
        ? previousIndex
        : null;

    previousIndexRef.value = activeIndex;

    return SizedBox(
      height: 8.h,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(itemCount, (index) {
          final isActive = index == activeIndex;
          final wasActive = index == wasActiveIndex;
          return Padding(
            padding: EdgeInsets.only(left: index > 0 ? 8.w : 0),
            child: _WnCarouselIndicatorItem(
              key: ValueKey('carousel_indicator_item_$index'),
              isActive: isActive,
              wasActive: wasActive,
              movingForward: movingForward,
              activeColor: activeColor ?? colors.fillPrimary,
              inactiveColor: colors.fillSecondary,
            ),
          );
        }),
      ),
    );
  }
}

class _WnCarouselIndicatorItem extends StatelessWidget {
  const _WnCarouselIndicatorItem({
    super.key,
    required this.isActive,
    required this.wasActive,
    required this.movingForward,
    required this.activeColor,
    required this.inactiveColor,
  });

  final bool isActive;
  final bool wasActive;
  final bool movingForward;
  final Color activeColor;
  final Color inactiveColor;

  Alignment _getAlignment() {
    if (isActive) {
      return movingForward ? Alignment.centerRight : Alignment.centerLeft;
    }
    if (wasActive) {
      return movingForward ? Alignment.centerLeft : Alignment.centerRight;
    }
    return Alignment.center;
  }

  @override
  Widget build(BuildContext context) {
    final targetWidth = isActive ? 28.w : 8.w;
    final targetColor = isActive ? activeColor : inactiveColor;

    return AnimatedAlign(
      duration: WnCarouselIndicator.animationDuration,
      curve: WnCarouselIndicator.animationCurve,
      alignment: _getAlignment(),
      child: AnimatedContainer(
        duration: WnCarouselIndicator.animationDuration,
        curve: WnCarouselIndicator.animationCurve,
        width: targetWidth,
        height: 8.h,
        child: TweenAnimationBuilder<Color?>(
          duration: WnCarouselIndicator.colorAnimationDuration,
          curve: WnCarouselIndicator.colorAnimationCurve,
          tween: ColorTween(end: targetColor),
          builder: (context, color, _) => DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
        ),
      ),
    );
  }
}
