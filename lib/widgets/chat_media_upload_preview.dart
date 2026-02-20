import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/hooks/use_media_upload.dart' show MediaUploadItem, MediaUploadStatus;
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_icon.dart';
import 'package:whitenoise/widgets/wn_media_preview.dart';
import 'package:whitenoise/widgets/wn_spinner.dart';

class ChatMediaUploadPreview extends HookWidget {
  const ChatMediaUploadPreview({
    super.key,
    required this.items,
    required this.onRemove,
  });

  final List<MediaUploadItem> items;
  final void Function(String filePath) onRemove;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final selectedIndex = useState(0);

    useEffect(() {
      if (selectedIndex.value >= items.length) {
        selectedIndex.value = items.isNotEmpty ? items.length - 1 : 0;
      }
      return null;
    }, [items.length]);

    final currentItem = items[selectedIndex.value];

    return _MediaPreviewWithOverlay(
      items: items,
      selectedIndex: selectedIndex.value,
      onSelectedChanged: (index) => selectedIndex.value = index,
      onDelete: () => onRemove(currentItem.filePath),
      currentItem: currentItem,
    );
  }
}

class _MediaPreviewWithOverlay extends StatelessWidget {
  const _MediaPreviewWithOverlay({
    required this.items,
    required this.selectedIndex,
    required this.onSelectedChanged,
    required this.onDelete,
    required this.currentItem,
  });

  final List<MediaUploadItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelectedChanged;
  final VoidCallback onDelete;
  final MediaUploadItem currentItem;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Stack(
      children: [
        WnMediaPreview(
          key: const Key('chat_media_upload_preview'),
          selectedIndex: selectedIndex,
          onSelectedChanged: onSelectedChanged,
          onDelete: onDelete,
          children: items.map((item) => _buildImageTile(item, colors)).toList(),
        ),
        if (currentItem.status == MediaUploadStatus.uploading)
          const Positioned.fill(
            child: _UploadingOverlay(key: Key('main_uploading_overlay')),
          ),
        if (currentItem.status == MediaUploadStatus.error)
          Positioned.fill(
            child: _ErrorOverlay(
              key: const Key('main_error_overlay'),
              onRetry: currentItem.retry,
            ),
          ),
      ],
    );
  }

  Widget _buildImageTile(MediaUploadItem item, SemanticColors colors) {
    return Image.file(
      File(item.filePath),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        key: const Key('image_tile_error_fallback'),
        color: colors.fillSecondary,
        child: Center(
          child: WnIcon(
            WnIcons.image,
            color: colors.backgroundContentTertiary,
            size: 48.sp,
          ),
        ),
      ),
    );
  }
}

class _UploadingOverlay extends StatelessWidget {
  const _UploadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          color: colors.backgroundPrimary.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(4.r),
        ),
        child: const Center(child: WnSpinner()),
      ),
    );
  }
}

class _ErrorOverlay extends StatelessWidget {
  const _ErrorOverlay({
    super.key,
    this.onRetry,
  });

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onRetry,
      child: Container(
        decoration: BoxDecoration(
          color: colors.fillDestructive.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(4.r),
        ),
        child: Center(
          child: WnIcon(
            WnIcons.error,
            color: colors.backgroundContentPrimary,
            size: 48.sp,
          ),
        ),
      ),
    );
  }
}
