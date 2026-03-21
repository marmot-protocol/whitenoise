import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/theme.dart';

class WnBlurhashPlaceholder extends StatelessWidget {
  final String? blurhash;
  final double? width;
  final double? height;

  const WnBlurhashPlaceholder({super.key, this.blurhash, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final useExpand = width == null && height == null;

    final hasValidBlurhash = blurhash != null && blurhash!.isNotEmpty;
    final key = Key(hasValidBlurhash ? 'blurhash_placeholder' : 'neutral_placeholder');
    final child = hasValidBlurhash
        ? BlurHash(hash: blurhash!)
        : ColoredBox(color: colors.fillSecondary);

    if (useExpand) {
      return SizedBox.expand(key: key, child: child);
    }
    return SizedBox(
      key: key,
      width: width ?? double.infinity,
      height: height ?? 200.h,
      child: child,
    );
  }
}
