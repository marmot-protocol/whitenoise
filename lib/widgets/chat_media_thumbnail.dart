import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/hooks/use_media_download.dart';
import 'package:whitenoise/src/rust/api/media_files.dart';
import 'package:whitenoise/widgets/wn_blurhash_placeholder.dart';
import 'package:whitenoise/widgets/wn_media_thumbnail.dart';

class ChatMediaThumbnail extends HookWidget {
  final MediaFile mediaFile;
  final bool isSelected;
  final WnMediaThumbnailSize size;
  final VoidCallback? onTap;

  const ChatMediaThumbnail({
    super.key,
    required this.mediaFile,
    this.isSelected = false,
    this.size = WnMediaThumbnailSize.medium,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (:status, :localPath, retry: _) = useMediaDownload(mediaFile: mediaFile);
    final fadeController = useAnimationController(
      duration: const Duration(milliseconds: 300),
    );

    useEffect(() {
      if (status == MediaDownloadStatus.success) {
        fadeController.forward();
      } else {
        fadeController.reset();
      }
      return null;
    }, [status]);

    final blurhash = mediaFile.fileMetadata?.blurhash;
    final thumbnailSize = size == WnMediaThumbnailSize.large ? 56.w : 44.w;

    final Widget content;
    if (status == MediaDownloadStatus.error) {
      content = const _ErrorPlaceholder(key: Key('thumbnail_error'));
    } else {
      content = _MediaContent(
        status: status,
        localPath: localPath,
        fadeController: fadeController,
        blurhash: blurhash,
        thumbnailSize: thumbnailSize,
      );
    }

    return WnMediaThumbnail(
      size: size,
      isSelected: isSelected,
      onTap: onTap,
      child: content,
    );
  }
}

class _ErrorPlaceholder extends StatelessWidget {
  const _ErrorPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(color: Color(0xFF333333));
  }
}

class _MediaContent extends StatelessWidget {
  const _MediaContent({
    required this.status,
    required this.localPath,
    required this.fadeController,
    required this.blurhash,
    required this.thumbnailSize,
  });

  final MediaDownloadStatus status;
  final String? localPath;
  final AnimationController fadeController;
  final String? blurhash;
  final double thumbnailSize;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        WnBlurhashPlaceholder(
          key: const Key('thumbnail_loading'),
          blurhash: blurhash,
          width: thumbnailSize,
          height: thumbnailSize,
        ),
        if (status == MediaDownloadStatus.success)
          FadeTransition(
            key: const Key('fade_transition'),
            opacity: fadeController,
            child: Image.file(
              File(localPath!),
              key: const Key('thumbnail_image'),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => WnBlurhashPlaceholder(
                key: const Key('thumbnail_error_fallback'),
                blurhash: blurhash,
                width: thumbnailSize,
                height: thumbnailSize,
              ),
            ),
          ),
      ],
    );
  }
}
