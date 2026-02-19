import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/theme.dart';

enum WnMediaThumbnailSize { medium, large }

class WnMediaThumbnail extends StatelessWidget {
  final WnMediaThumbnailSize size;
  final bool isSelected;
  final VoidCallback? onTap;
  final Widget child;

  const WnMediaThumbnail({
    super.key,
    this.size = WnMediaThumbnailSize.medium,
    this.isSelected = false,
    this.onTap,
    required this.child,
  });

  double _getSize() {
    return switch (size) {
      WnMediaThumbnailSize.medium => 44.w,
      WnMediaThumbnailSize.large => 56.w,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final thumbnailSize = _getSize();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        key: const Key('thumbnail_container'),
        width: thumbnailSize,
        height: thumbnailSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4.r),
          border: isSelected
              ? Border.all(
                  color: colors.borderPrimary,
                  width: 1.w,
                )
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4.r),
          child: child,
        ),
      ),
    );
  }
}
