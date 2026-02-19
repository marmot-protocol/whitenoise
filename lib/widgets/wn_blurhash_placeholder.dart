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
    final size = Size(width ?? double.infinity, height ?? 200.h);

    if (blurhash == null || blurhash!.isEmpty) {
      return Container(
        key: const Key('neutral_placeholder'),
        width: size.width,
        height: size.height,
        color: colors.fillSecondary,
      );
    }

    return SizedBox(
      key: const Key('blurhash_placeholder'),
      width: size.width,
      height: size.height,
      child: BlurHash(hash: blurhash!),
    );
  }
}
