import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_icon.dart';

enum WnSystemNoticeType {
  neutral,
  info,
  success,
  warning,
  error,
}

enum WnSystemNoticeVariant {
  temporary,
  dismissible,
  collapsed,
  expanded,
}

const _animationDuration = Duration(milliseconds: 200);
const _defaultAutoHideDuration = Duration(seconds: 3);

class WnSystemNotice extends HookWidget {
  const WnSystemNotice({
    super.key,
    required this.title,
    this.description,
    this.type = WnSystemNoticeType.success,
    this.variant = WnSystemNoticeVariant.temporary,
    this.primaryAction,
    this.secondaryAction,
    this.onDismiss,
    this.onToggle,
    this.autoHideDuration,
    this.animateEntrance = true,
  });

  final String title;
  final Widget? description;
  final WnSystemNoticeType type;
  final WnSystemNoticeVariant variant;
  final Widget? primaryAction;
  final Widget? secondaryAction;
  final VoidCallback? onDismiss;
  final VoidCallback? onToggle;
  final Duration? autoHideDuration;
  final bool animateEntrance;

  bool get _isCollapsed => variant == WnSystemNoticeVariant.collapsed;
  bool get _isExpanded => variant == WnSystemNoticeVariant.expanded;
  bool get _isDismissible => variant == WnSystemNoticeVariant.dismissible;
  bool get _isTemporary => variant == WnSystemNoticeVariant.temporary;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typographyScaled;
    final (bgColor, contentColor, icon) = _getStyle(colors);
    final bool shouldShowDetails =
        !_isCollapsed &&
        !_isTemporary &&
        (description != null || primaryAction != null || secondaryAction != null);
    final bool shouldShowActionIcon =
        (_isDismissible && onDismiss != null) ||
        ((_isCollapsed || _isExpanded) && onToggle != null);

    final slideController = useAnimationController(
      duration: _animationDuration,
    );

    final slideAnimation = useMemoized(
      () =>
          Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: slideController,
              curve: Curves.easeOut,
            ),
          ),
      [slideController],
    );

    final sizeAnimation = useMemoized(
      () =>
          Tween<double>(
            begin: 0,
            end: 1,
          ).animate(
            CurvedAnimation(
              parent: slideController,
              curve: Curves.easeOut,
            ),
          ),
      [slideController],
    );

    final isDismissing = useState(false);
    final autoHideTimer = useRef<Timer?>(null);

    void handleDismiss() {
      if (isDismissing.value) return;
      isDismissing.value = true;
      autoHideTimer.value?.cancel();
      slideController.reverse().then((_) {
        onDismiss?.call();
      });
    }

    useEffect(() {
      if (animateEntrance) {
        slideController.forward();
      } else {
        slideController.value = 1.0;
      }
      return null;
    }, const []);

    useEffect(() {
      final duration = autoHideDuration ?? (_isTemporary ? _defaultAutoHideDuration : null);
      if (duration != null && onDismiss != null) {
        autoHideTimer.value = Timer(duration, handleDismiss);
      }
      return () => autoHideTimer.value?.cancel();
    }, [autoHideDuration, _isTemporary, onDismiss]);

    return ClipRect(
      key: const Key('systemNotice_clipRect'),
      child: SizeTransition(
        sizeFactor: sizeAnimation,
        axisAlignment: -1,
        child: SlideTransition(
          key: const Key('systemNotice_slideTransition'),
          position: slideAnimation,
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: bgColor,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (icon != null) ...[
                      WnIcon(
                        icon,
                        key: const Key('systemNotice_leadingIcon'),
                        size: 20.w,
                        color: contentColor,
                      ),
                      Gap(8.w),
                    ],
                    Expanded(
                      child: Text(
                        title,
                        style: typography.bold14.copyWith(color: contentColor),
                      ),
                    ),
                    if (shouldShowActionIcon) ...[
                      Gap(8.w),
                      GestureDetector(
                        onTap: _isDismissible ? handleDismiss : onToggle,
                        behavior: HitTestBehavior.opaque,
                        child: WnIcon(
                          _getActionIcon(),
                          key: const Key('systemNotice_actionIcon'),
                          size: 20.w,
                          color: contentColor,
                        ),
                      ),
                    ],
                  ],
                ),
                AnimatedSize(
                  duration: _animationDuration,
                  curve: Curves.easeOut,
                  child: AnimatedOpacity(
                    duration: _animationDuration,
                    opacity: shouldShowDetails ? 1.0 : 0.0,
                    child: shouldShowDetails
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (description != null) ...[
                                Gap(4.h),
                                description!,
                              ],
                              if (primaryAction != null || secondaryAction != null) ...[
                                Gap(8.h),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    if (secondaryAction != null) ...[
                                      secondaryAction!,
                                      Gap(8.h),
                                    ],
                                    if (primaryAction != null) primaryAction!,
                                  ],
                                ),
                              ],
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  (Color, Color, WnIcons?) _getStyle(SemanticColors colors) {
    switch (type) {
      case WnSystemNoticeType.neutral:
        return (
          colors.backgroundTertiary,
          colors.backgroundContentPrimary,
          null,
        );
      case WnSystemNoticeType.info:
        return (
          colors.intentionInfoBackground,
          colors.intentionInfoContent,
          WnIcons.informationFilled,
        );
      case WnSystemNoticeType.success:
        return (
          colors.intentionSuccessBackground,
          colors.intentionSuccessContent,
          WnIcons.checkmarkFilled,
        );
      case WnSystemNoticeType.warning:
        return (
          colors.intentionWarningBackground,
          colors.intentionWarningContent,
          WnIcons.warningFilled,
        );
      case WnSystemNoticeType.error:
        return (
          colors.intentionErrorBackground,
          colors.intentionErrorContent,
          WnIcons.errorFilled,
        );
    }
  }

  WnIcons _getActionIcon() {
    if (_isCollapsed) return WnIcons.chevronDown;
    if (_isExpanded) return WnIcons.chevronUp;
    return WnIcons.closeLarge;
  }
}
