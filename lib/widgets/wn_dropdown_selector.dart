import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart' show Gap;
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_icon.dart';

class WnDropdownController extends ChangeNotifier {
  String? _openItemKey;

  String? get openItemKey => _openItemKey;

  void open(String key) {
    if (_openItemKey != key) {
      _openItemKey = key;
      notifyListeners();
    }
  }

  void close() {
    if (_openItemKey != null) {
      _openItemKey = null;
      notifyListeners();
    }
  }

  bool isOpen(String key) => _openItemKey == key;
}

class WnDropdownScope extends InheritedNotifier<WnDropdownController> {
  const WnDropdownScope({
    super.key,
    required WnDropdownController controller,
    required super.child,
  }) : super(notifier: controller);

  static WnDropdownController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<WnDropdownScope>()?.notifier;
  }
}

class WnDropdownOption<T> {
  const WnDropdownOption({
    required this.value,
    required this.label,
  });

  final T value;
  final String label;
}

enum WnDropdownSize {
  small,
  large,
}

class WnDropdownSelector<T> extends HookWidget {
  const WnDropdownSelector({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.size = WnDropdownSize.small,
    this.helperText,
    this.isError = false,
    this.isDisabled = false,
  });

  final String label;
  final List<WnDropdownOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;
  final WnDropdownSize size;
  final String? helperText;
  final bool isError;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typographyScaled;

    final dropdownHeight = size == WnDropdownSize.small ? 44.h : 56.h;
    final itemHeight = size == WnDropdownSize.small ? 44.h : 48.h;
    const maxVisibleItems = 5;

    final controller = WnDropdownScope.maybeOf(context);
    final widgetKey = key;
    final effectiveKey = useMemoized(() {
      if (widgetKey is ValueKey) return widgetKey.value.toString();
      if (widgetKey != null) return widgetKey.toString();
      return label;
    }, [widgetKey, label]);

    final localIsOpen = useState(false);
    final isPressed = useState(false);

    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 120),
    );

    final expandAnimation = useMemoized(
      () => CurvedAnimation(parent: animationController, curve: Curves.easeOut),
      [animationController],
    );

    final isOpen = controller != null ? controller.isOpen(effectiveKey) : localIsOpen.value;

    useEffect(() {
      if (controller == null) return null;
      void onControllerChanged() {
        final nowOpen = controller.isOpen(effectiveKey);
        if (nowOpen) {
          animationController.forward();
        } else {
          animationController.reverse();
        }
      }

      controller.addListener(onControllerChanged);
      return () => controller.removeListener(onControllerChanged);
    }, [controller, effectiveKey]);

    useEffect(() {
      if (isDisabled && localIsOpen.value) {
        localIsOpen.value = false;
        animationController.reverse();
      }
      if (isDisabled && controller != null && controller.isOpen(effectiveKey)) {
        WidgetsBinding.instance.addPostFrameCallback((_) => controller.close());
      }
      return null;
    }, [isDisabled]);

    final selectedOption = useMemoized(() {
      final selected = options.where((o) => o.value == value);
      return selected.isNotEmpty ? selected.first : null;
    }, [options, value]);

    final hasSelection = selectedOption != null;
    final displayLabel = selectedOption?.label ?? 'Select';

    void toggleDropdown() {
      if (isDisabled) return;

      if (controller != null) {
        if (controller.isOpen(effectiveKey)) {
          controller.close();
        } else {
          controller.open(effectiveKey);
        }
      } else {
        localIsOpen.value = !localIsOpen.value;
        if (localIsOpen.value) {
          animationController.forward();
        } else {
          animationController.reverse();
        }
      }
    }

    void selectOption(T optionValue) {
      if (isDisabled) return;

      if (controller != null) {
        controller.close();
      } else {
        localIsOpen.value = false;
        animationController.reverse();
      }
      onChanged(optionValue);
    }

    final borderColor = isDisabled
        ? colors.borderTertiary
        : isError
        ? colors.borderDestructivePrimary
        : isPressed.value
        ? colors.borderSecondary
        : isOpen
        ? colors.borderPrimary
        : colors.borderTertiary;

    final textColor = isDisabled
        ? colors.backgroundContentTertiary
        : hasSelection
        ? colors.backgroundContentPrimary
        : colors.backgroundContentSecondary;

    final iconColor = isDisabled
        ? colors.backgroundContentTertiary
        : colors.backgroundContentPrimary;

    final labelColor = isDisabled
        ? colors.backgroundContentTertiary
        : colors.backgroundContentPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 2.w),
          child: Text(
            label,
            style: typography.medium14.copyWith(color: labelColor),
          ),
        ),
        Gap(4.h),
        AnimatedBuilder(
          animation: expandAnimation,
          builder: (context, child) {
            final totalOptionsHeight = options.length * itemHeight;
            final maxOptionsHeight = maxVisibleItems * itemHeight;
            final constrainedOptionsHeight = totalOptionsHeight < maxOptionsHeight
                ? totalOptionsHeight
                : maxOptionsHeight;
            final animatedOptionsHeight = constrainedOptionsHeight * expandAnimation.value;
            final currentHeight = dropdownHeight + animatedOptionsHeight;

            return Container(
              height: currentHeight + 2,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: borderColor),
                color: isDisabled ? colors.backgroundSecondary : colors.backgroundPrimary,
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: toggleDropdown,
                    onTapDown: (_) {
                      if (!isDisabled) isPressed.value = true;
                    },
                    onTapUp: (_) => isPressed.value = false,
                    onTapCancel: () => isPressed.value = false,
                    child: Container(
                      height: dropdownHeight,
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.all(8.w),
                              child: Text(
                                displayLabel,
                                style: typography.medium14.copyWith(color: textColor),
                              ),
                            ),
                          ),
                          _DropdownIconButton(
                            isOpen: isOpen,
                            iconColor: iconColor,
                            size: size,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (expandAnimation.value > 0)
                    Expanded(
                      child: _ScrollableDropdownList(
                        options: options,
                        value: value,
                        itemHeight: itemHeight,
                        onSelect: selectOption,
                        showScrollIndicators: options.length > maxVisibleItems,
                        size: size,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        if (helperText != null) ...[
          Gap(4.h),
          Padding(
            padding: EdgeInsets.only(left: 2.w),
            child: Text(
              helperText!,
              style: typography.medium14.copyWith(
                color: isError
                    ? colors.backgroundContentDestructive
                    : colors.backgroundContentSecondary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DropdownIconButton extends StatelessWidget {
  const _DropdownIconButton({
    required this.isOpen,
    required this.iconColor,
    required this.size,
  });

  final bool isOpen;
  final Color iconColor;
  final WnDropdownSize size;

  @override
  Widget build(BuildContext context) {
    final wrapperSize = size == WnDropdownSize.large ? 48.w : 36.w;

    return SizedBox(
      width: wrapperSize,
      height: wrapperSize,
      child: Center(
        child: WnIcon(
          isOpen ? WnIcons.closeLarge : WnIcons.chevronDown,
          key: const Key('dropdown_icon'),
          color: iconColor,
          size: 16.sp,
        ),
      ),
    );
  }
}

class _ScrollableDropdownList<T> extends HookWidget {
  const _ScrollableDropdownList({
    required this.options,
    required this.value,
    required this.itemHeight,
    required this.onSelect,
    required this.showScrollIndicators,
    required this.size,
  });

  final List<WnDropdownOption<T>> options;
  final T value;
  final double itemHeight;
  final ValueChanged<T> onSelect;
  final bool showScrollIndicators;
  final WnDropdownSize size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final scrollController = useScrollController();
    final showTopFade = useState(false);
    final showBottomFade = useState(showScrollIndicators);

    useEffect(() {
      void onScroll() {
        final position = scrollController.position;
        showTopFade.value = position.pixels > 0;
        showBottomFade.value = position.pixels < position.maxScrollExtent;
      }

      scrollController.addListener(onScroll);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          onScroll();
        }
      });
      return () => scrollController.removeListener(onScroll);
    }, [scrollController]);

    return ClipRRect(
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(7.r),
        bottomRight: Radius.circular(7.r),
      ),
      child: Stack(
        children: [
          ListView.builder(
            controller: scrollController,
            padding: EdgeInsets.zero,
            physics: const BouncingScrollPhysics(),
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options[index];
              final isSelected = option.value == value;
              return _DropdownItem(
                label: option.label,
                isSelected: isSelected,
                height: itemHeight,
                onTap: () => onSelect(option.value),
                size: size,
              );
            },
          ),
          if (showScrollIndicators)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: showTopFade.value ? 1.0 : 0.0,
                  child: Container(
                    height: 40.h,
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
            ),
          if (showScrollIndicators)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: showBottomFade.value ? 1.0 : 0.0,
                  child: Container(
                    height: 40.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(7.r),
                        bottomRight: Radius.circular(7.r),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          colors.backgroundPrimary,
                          colors.backgroundPrimary.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DropdownItem extends StatelessWidget {
  const _DropdownItem({
    required this.label,
    required this.isSelected,
    required this.height,
    required this.onTap,
    required this.size,
  });

  final String label;
  final bool isSelected;
  final double height;
  final VoidCallback onTap;
  final WnDropdownSize size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typographyScaled;
    final backgroundColor = isSelected ? colors.backgroundTertiary : colors.backgroundPrimary;
    final textColor = isSelected
        ? colors.backgroundContentPrimary
        : colors.backgroundContentSecondary;
    final checkmarkColor = colors.backgroundContentSecondary;
    final iconWrapperSize = size == WnDropdownSize.large ? 48.w : 36.w;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: height,
        width: double.infinity,
        padding: EdgeInsets.only(left: 12.w, right: 4.w),
        color: backgroundColor,
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: Text(
                  label,
                  style: typography.medium14.copyWith(color: textColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            SizedBox(
              width: iconWrapperSize,
              height: iconWrapperSize,
              child: isSelected
                  ? Center(
                      child: WnIcon(
                        WnIcons.checkmark,
                        key: const Key('checkmark_icon'),
                        color: checkmarkColor,
                        size: 16.sp,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
