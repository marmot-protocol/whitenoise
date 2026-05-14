import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise_frb/src/rust/api/media_files.dart';
import 'package:whitenoise/hooks/use_media_download.dart';
import 'package:whitenoise/widgets/local_video_player.dart';
import 'package:whitenoise/widgets/wn_media_error_placeholder.dart';
import 'package:whitenoise/widgets/wn_media_placeholder.dart';

class MediaVideo extends HookWidget {
  const MediaVideo({
    super.key,
    required this.mediaFile,
    this.overlay,
  });

  final MediaFile mediaFile;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    final (:status, :localPath, :retry) = useMediaDownload(mediaFile: mediaFile);
    final thumbHash = mediaFile.fileMetadata?.thumbhash;
    final blurhash = mediaFile.fileMetadata?.blurhash;

    if (status == MediaDownloadStatus.error) {
      return _withOverlay(
        WnMediaErrorPlaceholder(
          key: const Key('media_video_error'),
          onRetry: retry!,
          thumbHash: thumbHash,
          blurhash: blurhash,
        ),
      );
    }

    if (status != MediaDownloadStatus.success) {
      return _withOverlay(
        WnMediaPlaceholder(
          key: const Key('media_video_loading'),
          thumbHash: thumbHash,
          blurhash: blurhash,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    }

    return LocalVideoPlayer(
      key: const Key('media_video_player'),
      filePath: localPath!,
      thumbHash: thumbHash,
      blurhash: blurhash,
      overlay: overlay,
    );
  }

  Widget _withOverlay(Widget child) {
    if (overlay == null) return child;
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        Positioned(top: 12.h, right: 12.w, child: overlay!),
      ],
    );
  }
}
