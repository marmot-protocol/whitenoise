import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/theme.dart';

enum WnOverlayVariant {
  heavy,
  light,
}

class WnOverlay extends StatelessWidget {
  const WnOverlay({
    super.key,
    this.variant = WnOverlayVariant.heavy,
  });

  final WnOverlayVariant variant;

  double get _sigmaX => variant == WnOverlayVariant.heavy ? 40.0.r : 4.0.r;
  double get _sigmaY => variant == WnOverlayVariant.heavy ? 40.0.r : 4.0.r;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final overlayColor = variant == WnOverlayVariant.heavy
        ? colors.overlayPrimary
        : colors.overlaySecondary;

    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: _sigmaX, sigmaY: _sigmaY),
        child: ColoredBox(color: overlayColor),
      ),
    );
  }
}
