import 'package:flutter/material.dart';

class KeyboardDismissOnTap extends StatelessWidget {
  const KeyboardDismissOnTap({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) {
        final currentFocus = FocusScope.of(context);
        currentFocus.unfocus();
      },
      child: child,
    );
  }
}
