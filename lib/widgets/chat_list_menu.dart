import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_icon.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';

const _animationDuration = Duration(milliseconds: 150);

class _BackObserver extends WidgetsBindingObserver {
  final bool Function() _onPop;
  _BackObserver({required bool Function() onPop}) : _onPop = onPop;

  @override
  Future<bool> didPopRoute() async => _onPop();
}

class ChatListAction {
  final String id;
  final String label;
  final WnIcons icon;
  final Future<void> Function()? onTap;
  final bool isDestructive;
  final bool autoDismiss;

  const ChatListAction({
    required this.id,
    required this.label,
    required this.icon,
    this.onTap,
    this.isDestructive = false,
    this.autoDismiss = true,
  });
}

class ChatListMenuController {
  OverlayEntry? _overlay;
  Future<void> Function()? _animatedDismiss;
  bool _dismissing = false;
  void Function(List<ChatListAction>, Widget?, String?, VoidCallback?)? _applyUpdate;
  VoidCallback? _onBack;

  bool get isShowing => _overlay != null;

  void dismiss() {
    if (_dismissing) return;

    final animatedDismiss = _animatedDismiss;
    if (animatedDismiss != null) {
      _dismissing = true;
      _animatedDismiss = null;
      animatedDismiss().then((_) {
        _overlay?.remove();
        _overlay = null;
        _dismissing = false;
      });
    } else {
      _overlay?.remove();
      _overlay = null;
    }
  }

  void updateState(
    List<ChatListAction> actions, {
    Widget? middleContent,
    String? title,
    VoidCallback? onBack,
  }) {
    _applyUpdate?.call(actions, middleContent, title, onBack);
  }
}

class ChatListMenu extends HookWidget {
  const ChatListMenu({
    super.key,
    required this.child,
    required this.itemPosition,
    required this.itemHeight,
    required this.actions,
    required this.onDismiss,
    required this.controller,
  });

  final Widget child;
  final Offset itemPosition;
  final double itemHeight;
  final List<ChatListAction> actions;
  final VoidCallback onDismiss;
  final ChatListMenuController controller;

  static ChatListMenuController show(
    BuildContext context, {
    required Widget child,
    required RenderBox childRenderBox,
    required List<ChatListAction> actions,
  }) {
    final menuController = ChatListMenuController();

    final position = childRenderBox.localToGlobal(Offset.zero);
    final height = childRenderBox.size.height;
    final overlay = Overlay.of(context);

    final entry = OverlayEntry(
      builder: (_) => ChatListMenu(
        itemPosition: position,
        itemHeight: height,
        actions: actions,
        onDismiss: () => menuController.dismiss(),
        controller: menuController,
        child: child,
      ),
    );

    menuController._overlay = entry;
    overlay.insert(entry);

    return menuController;
  }

  @override
  Widget build(BuildContext context) {
    final actionsState = useState(actions);
    final titleState = useState<String?>(null);
    final middleContentState = useState<Widget?>(null);

    final colors = context.colors;
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;
    final safeTop = mediaQuery.padding.top;
    final safeBottom = mediaQuery.padding.bottom;

    final menuPadding = 16.w;
    final buttonSpacing = 8.h;
    final containerGap = 12.h;
    final menuHorizontalInset = 10.w;

    final currentActions = actionsState.value;
    final currentTitle = titleState.value;
    final currentMiddleContent = middleContentState.value;

    final buttonCount = currentActions.length;
    final estimatedButtonHeight = 44.h;
    final totalButtonsHeight =
        (estimatedButtonHeight * buttonCount) + (buttonSpacing * (buttonCount - 1));
    final estimatedHeaderHeight = currentTitle != null ? 80.h : 0.0;
    final estimatedMiddleContentHeight = currentMiddleContent != null ? 80.h : 0.0;
    final menuContentHeight =
        menuPadding +
        estimatedHeaderHeight +
        itemHeight +
        containerGap +
        estimatedMiddleContentHeight +
        totalButtonsHeight +
        menuPadding;

    final idealTop = itemPosition.dy - menuPadding;
    final minTop = safeTop;
    final maxTop = (screenHeight - safeBottom - menuContentHeight).clamp(minTop, double.infinity);
    final clampedTop = idealTop.clamp(minTop, maxTop);

    final menuWidth = screenWidth - (menuHorizontalInset * 2);
    final itemCenterInMenu = menuPadding + estimatedHeaderHeight + (itemHeight / 2);
    final alignX = (itemPosition.dx - menuHorizontalInset) / menuWidth;
    final alignY = (itemCenterInMenu / menuContentHeight) * 2 - 1;

    final animController = useAnimationController(duration: _animationDuration);
    final curvedAnimation = useMemoized(
      () => CurvedAnimation(parent: animController, curve: Curves.easeOut),
      [animController],
    );

    useEffect(() {
      animController.forward();
      controller._animatedDismiss = () => animController.reverse();
      controller._applyUpdate = (newActions, middleContent, title, onBack) {
        actionsState.value = newActions;
        middleContentState.value = middleContent;
        titleState.value = title;
        controller._onBack = onBack;
      };
      final backObserver = _BackObserver(
        onPop: () {
          if (controller._onBack != null) {
            controller._onBack!();
          } else {
            onDismiss();
          }
          return true;
        },
      );
      WidgetsBinding.instance.addObserver(backObserver);
      return () {
        controller._animatedDismiss = null;
        controller._applyUpdate = null;
        WidgetsBinding.instance.removeObserver(backObserver);
        curvedAnimation.dispose();
      };
    }, const []);

    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        key: const Key('context_menu_dismiss'),
        behavior: HitTestBehavior.opaque,
        onTap: onDismiss,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onVerticalDragStart: (_) => onDismiss(),
                child: FadeTransition(
                  opacity: curvedAnimation,
                  child: BackdropFilter(
                    key: const Key('context_menu_overlay'),
                    filter: ImageFilter.blur(sigmaX: 10.0.r, sigmaY: 10.0.r),
                    child: ColoredBox(color: colors.overlaySecondary),
                  ),
                ),
              ),
            ),
            Positioned(
              top: clampedTop,
              left: menuHorizontalInset,
              right: menuHorizontalInset,
              child: FadeTransition(
                opacity: curvedAnimation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.9, end: 1.0).animate(curvedAnimation),
                  alignment: Alignment(alignX.clamp(-1.0, 1.0), alignY.clamp(-1.0, 1.0)),
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      key: const Key('context_menu_card'),
                      decoration: BoxDecoration(
                        color: colors.backgroundSecondary,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: colors.borderTertiary),
                        boxShadow: [
                          BoxShadow(
                            color: colors.shadow.withValues(alpha: 0.1),
                            offset: Offset(0.w, 1.h),
                            blurRadius: 2.r,
                            spreadRadius: (-1).r,
                          ),
                          BoxShadow(
                            color: colors.shadow.withValues(alpha: 0.1),
                            offset: Offset(0.w, 1.h),
                            blurRadius: 3.r,
                          ),
                        ],
                      ),
                      padding: EdgeInsets.symmetric(vertical: menuPadding),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (currentTitle != null)
                            WnSlateNavigationHeader(
                              key: const Key('context_menu_navigation_header'),
                              title: currentTitle,
                              onNavigate: controller._onBack,
                            ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: menuPadding),
                            child: Container(
                              decoration: BoxDecoration(
                                color: colors.backgroundPrimary,
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(color: colors.borderTertiary),
                              ),
                              child: IgnorePointer(child: child),
                            ),
                          ),
                          SizedBox(height: containerGap),
                          if (currentMiddleContent != null) ...[
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: menuPadding),
                              child: currentMiddleContent,
                            ),
                            SizedBox(height: containerGap),
                          ],
                          ...List.generate(currentActions.length, (index) {
                            final action = currentActions[index];

                            return Padding(
                              padding: EdgeInsets.only(
                                top: index > 0 ? buttonSpacing : 0,
                                left: menuPadding,
                                right: menuPadding,
                              ),
                              child: SizedBox(
                                key: Key('context_menu_action_${action.id}'),
                                width: double.infinity,
                                child: WnButton(
                                  text: action.label,
                                  trailingIcon: action.icon,
                                  type: action.isDestructive
                                      ? WnButtonType.destructive
                                      : WnButtonType.outline,
                                  size: WnButtonSize.medium,
                                  onPressed: action.onTap != null
                                      ? () {
                                          if (action.autoDismiss) onDismiss();
                                          action.onTap!();
                                        }
                                      : null,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
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
