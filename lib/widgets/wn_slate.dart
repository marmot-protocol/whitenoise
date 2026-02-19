import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_scroll_edge_effect.dart';
import 'package:whitenoise/widgets/wn_slate_content_transition.dart';

class WnSlate extends HookWidget {
  const WnSlate({
    super.key,
    this.tag = 'wn-slate',
    this.header,
    this.padding,
    this.showTopScrollEffect = false,
    this.showBottomScrollEffect = false,
    this.systemNotice,
    this.child,
    this.footer,
    this.animateContent = true,
    this.shrinkWrapContent = false,
  });

  final String tag;
  final Widget? header;
  final EdgeInsetsGeometry? padding;
  final bool showTopScrollEffect;
  final bool showBottomScrollEffect;
  final Widget? systemNotice;
  final Widget? child;
  final Widget? footer;
  final bool animateContent;
  final bool shrinkWrapContent;

  BoxDecoration _decoration(SemanticColors colors) {
    return BoxDecoration(
      color: colors.backgroundSecondary,
      borderRadius: BorderRadius.circular(16.r),
      border: Border.all(color: colors.borderTertiary),
      boxShadow: [
        BoxShadow(
          color: colors.shadow.withValues(alpha: 0.1),
          offset: const Offset(0, 1),
          blurRadius: 2.r,
          spreadRadius: (-1).r,
        ),
        BoxShadow(
          color: colors.shadow.withValues(alpha: 0.1),
          offset: const Offset(0, 1),
          blurRadius: 3.r,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final route = ModalRoute.of(context);
    final animation = route?.animation ?? kAlwaysCompleteAnimation;

    final canScrollUp = useState(false);
    final canScrollDown = useState(false);

    final hasScrollEffects = showTopScrollEffect || showBottomScrollEffect;

    void updateScrollState(ScrollMetrics metrics) {
      canScrollUp.value = metrics.extentBefore > 0;
      canScrollDown.value = metrics.extentAfter > 0;
    }

    Widget? childWidget;
    if (child != null) {
      if (hasScrollEffects) {
        childWidget = NotificationListener<ScrollMetricsNotification>(
          onNotification: (notification) {
            updateScrollState(notification.metrics);
            return false;
          },
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              updateScrollState(notification.metrics);
              return false;
            },
            child: Stack(
              children: [
                child!,
                if (showTopScrollEffect && canScrollUp.value)
                  WnScrollEdgeEffect.slateTop(color: colors.backgroundSecondary),
                if (showBottomScrollEffect && canScrollDown.value)
                  WnScrollEdgeEffect.slateBottom(color: colors.backgroundSecondary),
              ],
            ),
          ),
        );
      } else {
        childWidget = child;
      }
    }

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (systemNotice != null) systemNotice!,
        if (header != null) header!,
        if (childWidget != null)
          if (shrinkWrapContent) childWidget else Flexible(child: childWidget),
        if (footer != null) footer!,
      ],
    );

    return Hero(
      tag: tag,
      flightShuttleBuilder:
          (
            flightContext,
            animation,
            flightDirection,
            fromHeroContext,
            toHeroContext,
          ) {
            return Material(
              type: MaterialType.transparency,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 10.w),
                padding: padding,
                decoration: _decoration(colors),
              ),
            );
          },
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 10.w),
          padding: padding,
          decoration: _decoration(colors),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.r),
            child: animateContent
                ? WnSlateContentTransition(
                    routeAnimation: animation,
                    child: content,
                  )
                : content,
          ),
        ),
      ),
    );
  }
}
