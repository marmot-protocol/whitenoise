import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:thumbhash/thumbhash.dart' as thumbhash;
import 'package:whitenoise/theme.dart';

class WnMediaPlaceholder extends StatelessWidget {
  final String? thumbHash;
  final String? blurhash;
  final double? width;
  final double? height;

  const WnMediaPlaceholder({super.key, this.thumbHash, this.blurhash, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final useExpand = width == null && height == null;

    final thumbHashBytes = _decodeThumbHash(thumbHash);
    final hasValidBlurhash = blurhash != null && blurhash!.isNotEmpty;

    final Widget child;
    final Key key;

    if (thumbHashBytes != null) {
      key = const Key('thumbhash_placeholder');
      final image = thumbhash.thumbHashToRGBA(thumbHashBytes);
      final bmpBytes = thumbhash.rgbaToBmp(image);
      child = Image.memory(
        bmpBytes,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    } else if (hasValidBlurhash) {
      key = const Key('blurhash_placeholder');
      child = BlurHash(hash: blurhash!);
    } else {
      key = const Key('neutral_placeholder');
      child = ColoredBox(color: colors.fillSecondary);
    }

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

  static Uint8List? _decodeThumbHash(String? hash) {
    if (hash == null || hash.isEmpty) return null;
    try {
      return base64Decode(hash);
    } catch (_) {
      return null;
    }
  }
}
