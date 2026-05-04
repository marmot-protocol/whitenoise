import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:whitenoise/hooks/use_media_download.dart';
import 'package:whitenoise/src/rust/api/media_files.dart';
import 'package:whitenoise/widgets/local_video_player.dart';
import 'package:whitenoise/widgets/wn_media_error_placeholder.dart';
import 'package:whitenoise/widgets/wn_media_placeholder.dart';

class MediaVideo extends HookWidget {
  const MediaVideo({
    super.key,
    required this.mediaFile,
  });

  final MediaFile mediaFile;

  @override
  Widget build(BuildContext context) {
    final (:status, :localPath, :retry) = useMediaDownload(mediaFile: mediaFile);
    final thumbHash = mediaFile.fileMetadata?.thumbhash;
    final blurhash = mediaFile.fileMetadata?.blurhash;

    if (status == MediaDownloadStatus.error) {
      return WnMediaErrorPlaceholder(
        key: const Key('media_video_error'),
        onRetry: retry!,
        thumbHash: thumbHash,
        blurhash: blurhash,
      );
    }

    if (status != MediaDownloadStatus.success) {
      return WnMediaPlaceholder(
        key: const Key('media_video_loading'),
        thumbHash: thumbHash,
        blurhash: blurhash,
        width: double.infinity,
        height: double.infinity,
      );
    }

    return LocalVideoPlayer(
      key: const Key('media_video_player'),
      filePath: localPath!,
      thumbHash: thumbHash,
      blurhash: blurhash,
    );
  }
}
