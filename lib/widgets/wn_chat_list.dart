import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/theme.dart';

const _kAnimationDuration = Duration(milliseconds: 200);

// Fraction of header revealed before it snaps closed when dragging back up.
const _kDismissThreshold = 0.7;

// Fraction of header revealed before it snaps open when pulling down.
const _kOpenThreshold = 0.5;

class WnChatList extends HookWidget {
  const WnChatList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.isLoading = false,
    this.isSearchActive = false,
    this.topPadding = 0,
    this.header,
    this.headerHeight = 0,
    this.pinnedHeader,
    this.pinnedHeaderHeight = 0,
    this.emptyStateContent,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final bool isLoading;
  final bool isSearchActive;
  final double topPadding;

  final Widget? header;
  final double headerHeight;

  final Widget? pinnedHeader;
  final double pinnedHeaderHeight;

  final Widget? emptyStateContent;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final horizontalPadding = 10.w;
    final canScrollUp = useState(false);
    final hasHeader = header != null && headerHeight > 0;
    final hasPinnedHeader = pinnedHeader != null && pinnedHeaderHeight > 0;

    final headerRevealController = useAnimationController(
      duration: _kAnimationDuration,
    );
    final headerRevealAnimation = useAnimation(headerRevealController);
    final headerOpen = useState(false);
    final isAnimatingClosed = useRef(false);
    final peakReveal = useRef(0.0);
    final scrollController = useScrollController();

    if (isLoading && itemCount == 0) {
      return Center(
        key: const Key('chat_list_loading'),
        child: CircularProgressIndicator(color: colors.backgroundContentPrimary),
      );
    }

    useEffect(() {
      if (isSearchActive && hasHeader) {
        headerOpen.value = true;
        headerRevealController.animateTo(1.0, curve: Curves.easeOut);
      }
      return null;
    }, [isSearchActive, hasHeader]);

    void updateScrollState(ScrollMetrics metrics) {
      final newValue = metrics.extentBefore > 0;
      if (canScrollUp.value == newValue) return;
      if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          canScrollUp.value = newValue;
        });
      } else {
        canScrollUp.value = newValue;
      }
    }

    bool handleScrollNotification(ScrollNotification notification) {
      updateScrollState(notification.metrics);

      if (!hasHeader) return false;

      if (isAnimatingClosed.value) {
        if (notification is ScrollEndNotification) {
          isAnimatingClosed.value = false;
        }
        return false;
      }

      if (headerOpen.value) {
        if (notification is ScrollUpdateNotification) {
          final pixels = notification.metrics.pixels;
          if (pixels > 0 && notification.dragDetails != null) {
            final reveal = (1.0 - pixels / headerHeight).clamp(0.0, 1.0);
            headerRevealController.value = reveal;
            if (reveal <= _kDismissThreshold) {
              headerOpen.value = false;
              isAnimatingClosed.value = true;
              headerRevealController.animateTo(0.0, curve: Curves.easeOut).then((_) {
                isAnimatingClosed.value = false;
              });
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!scrollController.hasClients) return;
                scrollController.animateTo(
                  0,
                  duration: _kAnimationDuration,
                  curve: Curves.easeOut,
                );
              });
              return false;
            }
          }
        }
        return false;
      }

      if (notification is ScrollUpdateNotification) {
        final pixels = notification.metrics.pixels;
        if (pixels < 0) {
          final reveal = (-pixels / headerHeight).clamp(0.0, 1.0);
          headerRevealController.value = reveal;
          if (reveal > peakReveal.value) {
            peakReveal.value = reveal;
          }
          if (peakReveal.value >= _kOpenThreshold && notification.dragDetails != null) {
            headerOpen.value = true;
            headerRevealController.animateTo(1.0, curve: Curves.easeOut);
            peakReveal.value = 1.0;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!scrollController.hasClients) return;
              scrollController.animateTo(
                0,
                duration: _kAnimationDuration,
                curve: Curves.easeOut,
              );
            });
            return false;
          }
        } else if (headerRevealController.value > 0) {
          headerRevealController.value = 0.0;
        }
      }

      if (notification is ScrollEndNotification) {
        if (notification.metrics.pixels < 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!scrollController.hasClients) return;
            scrollController.animateTo(
              0,
              duration: _kAnimationDuration,
              curve: Curves.easeOut,
            );
            headerRevealController.animateTo(0.0, curve: Curves.easeOut);
          });
        }
        peakReveal.value = 0.0;
      }

      return false;
    }

    final effectiveHeaderHeight = isAnimatingClosed.value
        ? headerHeight
        : headerHeight * headerRevealAnimation;
    final emptyStateTopInset = topPadding + effectiveHeaderHeight + pinnedHeaderHeight;
    final listPadding = EdgeInsets.only(
      top:
          topPadding + effectiveHeaderHeight + pinnedHeaderHeight + (hasPinnedHeader ? 24.h : 16.h),
      left: horizontalPadding,
      right: horizontalPadding,
    );

    if (itemCount == 0 && emptyStateContent != null && !isSearchActive) {
      if (canScrollUp.value) {
        if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            canScrollUp.value = false;
          });
        } else {
          canScrollUp.value = false;
        }
      }
    }

    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (notification) {
        updateScrollState(notification.metrics);
        return false;
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: handleScrollNotification,
        child: Stack(
          children: [
            if (itemCount == 0 && emptyStateContent != null && !isSearchActive)
              Positioned.fill(
                key: const Key('chat_list_empty'),
                top: emptyStateTopInset,
                bottom: pinnedHeaderHeight,
                child: Center(
                  child: emptyStateContent,
                ),
              )
            else if (isSearchActive && itemCount == 0)
              Positioned.fill(
                key: const Key('chat_list_no_results'),
                child: Center(
                  child: Text(
                    context.l10n.noResults,
                    style: context.typographyScaled.medium16.copyWith(
                      color: colors.backgroundContentTertiary,
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                key: const Key('chat_list'),
                controller: scrollController,
                padding: listPadding,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                itemCount: itemCount,
                itemBuilder: itemBuilder,
              ),
            if (hasHeader && (headerOpen.value || headerRevealAnimation > 0))
              Positioned(
                key: const Key('chat_list_header'),
                top: topPadding,
                left: horizontalPadding,
                right: horizontalPadding,
                child: ClipRect(
                  child: Align(
                    alignment: Alignment.topCenter,
                    heightFactor: headerRevealAnimation.clamp(0.0, 1.0),
                    child: header,
                  ),
                ),
              ),
            if (hasPinnedHeader)
              Positioned(
                key: const Key('chat_list_pinned_header'),
                top: topPadding + effectiveHeaderHeight,
                left: horizontalPadding,
                right: horizontalPadding,
                height: pinnedHeaderHeight,
                child: pinnedHeader!,
              ),
            if (canScrollUp.value)
              Positioned(
                key: const Key('chat_list_scroll_edge'),
                top: 0,
                left: 0,
                right: 0,
                height: topPadding,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          colors.backgroundPrimary,
                          colors.backgroundPrimary.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
