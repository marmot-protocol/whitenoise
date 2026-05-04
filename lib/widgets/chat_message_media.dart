import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/hooks/use_media_download.dart';
import 'package:whitenoise/src/rust/api/media_files.dart';
import 'package:whitenoise/utils/media_type.dart';
import 'package:whitenoise/widgets/local_video_player.dart';
import 'package:whitenoise/widgets/wn_media_error_placeholder.dart';
import 'package:whitenoise/widgets/wn_media_placeholder.dart';
import 'package:whitenoise/widgets/wn_message_media.dart';

class ChatMessageMedia extends StatelessWidget {
  final List<MediaFile> mediaFiles;
  final ValueChanged<int>? onMediaTap;

  const ChatMessageMedia({super.key, required this.mediaFiles, this.onMediaTap});

  @override
  Widget build(BuildContext context) {
    return WnMessageMedia(
      tiles: mediaFiles.map((mf) => _ChatMessageMediaTile(mediaFile: mf)).toList(),
      onTileTap: onMediaTap,
    );
  }
}

class _ChatMessageMediaTile extends HookWidget {
  final MediaFile mediaFile;

  const _ChatMessageMediaTile({required this.mediaFile});

  @override
  Widget build(BuildContext context) {
    final (:status, :localPath, :retry) = useMediaDownload(mediaFile: mediaFile);
    final fadeController = useAnimationController(
      duration: const Duration(milliseconds: 300),
    );
    final isVideo = isVideoMediaFile(mediaFile);

    useEffect(() {
      if (status == MediaDownloadStatus.success) {
        fadeController.forward();
      } else {
        fadeController.reset();
      }
      return null;
    }, [status]);

    if (status == MediaDownloadStatus.error) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4.r),
        child: WnMediaErrorPlaceholder(
          key: const Key('error_placeholder'),
          onRetry: retry!,
          thumbHash: mediaFile.fileMetadata?.thumbhash,
          blurhash: mediaFile.fileMetadata?.blurhash,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(4.r),
      child: Stack(
        fit: StackFit.expand,
        children: [
          WnMediaPlaceholder(
            key: const Key('loading_placeholder'),
            thumbHash: mediaFile.fileMetadata?.thumbhash,
            blurhash: mediaFile.fileMetadata?.blurhash,
          ),
          if (status == MediaDownloadStatus.success)
            if (isVideo)
              Stack(
                fit: StackFit.expand,
                children: [
                  LocalVideoPlayer(
                    key: const Key('media_video'),
                    filePath: localPath!,
                    thumbHash: mediaFile.fileMetadata?.thumbhash,
                    blurhash: mediaFile.fileMetadata?.blurhash,
                    fit: BoxFit.cover,
                    showControls: false,
                  ),
                  const VideoPlayIndicator(key: Key('media_video_indicator')),
                ],
              )
            else
              FadeTransition(
                key: const Key('fade_transition'),
                opacity: fadeController,
                child: Image.file(
                  File(localPath!),
                  key: const Key('media_image'),
                  fit: BoxFit.cover,
                ),
              ),
          if (isVideo && status != MediaDownloadStatus.success)
            const VideoPlayIndicator(key: Key('media_video_loading_indicator')),
        ],
      ),
    );
  }
}
