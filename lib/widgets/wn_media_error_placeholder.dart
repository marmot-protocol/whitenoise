import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_blurhash_placeholder.dart';
import 'package:whitenoise/widgets/wn_icon.dart';

class WnMediaErrorPlaceholder extends StatelessWidget {
  final VoidCallback onRetry;
  final String? blurhash;
  final double? width;
  final double? height;

  const WnMediaErrorPlaceholder({
    super.key,
    required this.onRetry,
    this.blurhash,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      key: const Key('retry_button'),
      onTap: onRetry,
      child: SizedBox(
        width: width ?? double.infinity,
        height: height ?? 200.h,
        child: Stack(
          fit: StackFit.expand,
          children: [
            WnBlurhashPlaceholder(blurhash: blurhash, width: width, height: height),
            Container(
              key: const Key('error_overlay'),
              color: colors.overlayTertiary,
              child: Center(
                child: WnIcon(
                  WnIcons.retry,
                  key: const Key('retry_icon'),
                  size: 24.w,
                  color: colors.fillContentQuaternary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
