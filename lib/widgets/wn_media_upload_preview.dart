import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/hooks/use_media_upload.dart' show MediaUploadItem, MediaUploadStatus;
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_icon.dart';
import 'package:whitenoise/widgets/wn_spinner.dart';

class WnMediaUploadPreview extends StatelessWidget {
  final List<MediaUploadItem> items;
  final void Function(String filePath) onRemove;
  final VoidCallback onAddMore;

  const WnMediaUploadPreview({
    super.key,
    required this.items,
    required this.onRemove,
    required this.onAddMore,
  });

  @override
  Widget build(BuildContext context) {
    final thumbnailSize = 56.w;

    return SizedBox(
      height: thumbnailSize + 8.h,
      child: ListView.separated(
        key: const Key('media_upload_preview_list'),
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
        itemCount: items.length + 1,
        separatorBuilder: (_, _) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          if (index == items.length) {
            return _AddMoreButton(
              key: const Key('add_more_button'),
              size: thumbnailSize,
              onTap: onAddMore,
            );
          }

          final item = items[index];
          return _ThumbnailItem(
            key: Key('thumbnail_${item.filePath}'),
            item: item,
            size: thumbnailSize,
            onRemove: () => onRemove(item.filePath),
          );
        },
      ),
    );
  }
}

class _ThumbnailItem extends StatelessWidget {
  final MediaUploadItem item;
  final double size;
  final VoidCallback onRemove;

  const _ThumbnailItem({
    super.key,
    required this.item,
    required this.size,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: Image.file(
              File(item.filePath),
              key: const Key('thumbnail_image'),
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                key: const Key('thumbnail_error_placeholder'),
                color: colors.fillSecondary,
                child: Center(
                  child: WnIcon(
                    WnIcons.image,
                    color: colors.backgroundContentTertiary,
                    size: 20.sp,
                  ),
                ),
              ),
            ),
          ),
          if (item.status == MediaUploadStatus.uploading)
            Positioned.fill(
              child: Container(
                key: const Key('uploading_overlay'),
                decoration: BoxDecoration(
                  color: colors.backgroundPrimary.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: const Center(child: WnSpinner()),
              ),
            ),
          if (item.status == MediaUploadStatus.error)
            Positioned.fill(
              child: GestureDetector(
                key: const Key('error_overlay'),
                onTap: item.retry,
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.fillDestructive.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Center(
                    child: WnIcon(
                      WnIcons.error,
                      color: colors.backgroundContentPrimary,
                      size: 24.sp,
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            top: 2.h,
            right: 2.w,
            child: GestureDetector(
              key: const Key('remove_button'),
              onTap: onRemove,
              child: Container(
                width: 18.w,
                height: 18.h,
                decoration: BoxDecoration(
                  color: colors.backgroundPrimary.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: WnIcon(
                    WnIcons.closeSmall,
                    color: colors.backgroundContentPrimary,
                    size: 12.sp,
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

class _AddMoreButton extends StatelessWidget {
  final double size;
  final VoidCallback onTap;

  const _AddMoreButton({
    super.key,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colors.backgroundTertiary,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: colors.borderTertiary),
        ),
        child: Center(
          child: WnIcon(
            WnIcons.addLarge,
            color: colors.backgroundContentSecondary,
            size: 24.sp,
          ),
        ),
      ),
    );
  }
}
