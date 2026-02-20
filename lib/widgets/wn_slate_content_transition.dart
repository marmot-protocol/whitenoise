import 'dart:ui';

import 'package:flutter/material.dart';

class WnSlateContentTransition extends StatefulWidget {
  const WnSlateContentTransition({
    super.key,
    required this.child,
    this.routeAnimation,
  });

  final Widget child;
  final Animation<double>? routeAnimation;

  static const Duration duration = Duration(milliseconds: 200);
  static const Curve curve = Curves.easeInOutCubicEmphasized;
  static Curve get reverseCurve => Curves.easeInOutCubicEmphasized.flipped;
  static const double maxBlurSigma = 4.0;

  @override
  State<WnSlateContentTransition> createState() => _WnSlateContentTransitionState();
}

class _WnSlateContentTransitionState extends State<WnSlateContentTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacityAnimation;
  late final Animation<double> _blurAnimation;
  bool _hasStartedAnimation = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: WnSlateContentTransition.duration,
      vsync: this,
    );

    final curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: WnSlateContentTransition.curve,
      reverseCurve: WnSlateContentTransition.reverseCurve,
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation);
    _blurAnimation = Tween<double>(
      begin: WnSlateContentTransition.maxBlurSigma,
      end: 0.0,
    ).animate(curvedAnimation);

    _checkAndStartAnimation();
  }

  void _checkAndStartAnimation() {
    final routeAnimation = widget.routeAnimation;

    if (routeAnimation == null) {
      // No route animation, animate immediately
      _startAnimation();
    } else if (routeAnimation.isCompleted) {
      // Route already completed (e.g., returning to a cached route)
      _startAnimation();
    } else {
      // Wait for route animation to complete
      routeAnimation.addStatusListener(_onRouteAnimationStatus);
    }
  }

  void _onRouteAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_hasStartedAnimation) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    if (_hasStartedAnimation) return;
    _hasStartedAnimation = true;
    _controller.forward();
  }

  @override
  void dispose() {
    widget.routeAnimation?.removeStatusListener(_onRouteAnimationStatus);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ImageFiltered(
          imageFilter: ImageFilter.blur(
            sigmaX: _blurAnimation.value,
            sigmaY: _blurAnimation.value,
          ),
          child: FadeTransition(
            opacity: _opacityAnimation,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
