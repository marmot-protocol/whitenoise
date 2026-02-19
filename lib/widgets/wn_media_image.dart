import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:whitenoise/hooks/use_media_download.dart';
import 'package:whitenoise/src/rust/api/media_files.dart';
import 'package:whitenoise/widgets/wn_blurhash_placeholder.dart';
import 'package:whitenoise/widgets/wn_media_error_placeholder.dart';

double? _parseAspectRatio(String? dimensions) {
  if (dimensions == null) return null;
  final parts = dimensions.split('x');
  if (parts.length != 2) return null;
  final w = double.tryParse(parts[0]);
  final h = double.tryParse(parts[1]);
  if (w == null || h == null || w <= 0 || h <= 0) return null;
  return w / h;
}

class WnMediaImage extends HookWidget {
  final MediaFile mediaFile;
  final ValueChanged<bool>? onZoomChanged;
  final VoidCallback? onTap;

  const WnMediaImage({
    super.key,
    required this.mediaFile,
    this.onZoomChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (:status, :localPath, :retry) = useMediaDownload(mediaFile: mediaFile);
    final transformationController = useMemoized(() => TransformationController());
    final isZoomed = useState(false);

    useEffect(() {
      void listener() {
        final scale = transformationController.value.getMaxScaleOnAxis();
        final zoomed = scale > 1.01;
        if (zoomed != isZoomed.value) {
          isZoomed.value = zoomed;
          onZoomChanged?.call(zoomed);
        }
      }

      transformationController.addListener(listener);
      return () => transformationController.removeListener(listener);
    }, [transformationController]);

    useEffect(() => transformationController.dispose, [transformationController]);

    final blurhash = mediaFile.fileMetadata?.blurhash;
    final aspectRatio = _parseAspectRatio(mediaFile.fileMetadata?.dimensions);

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

    if (status == MediaDownloadStatus.error) {
      return GestureDetector(
        onTap: onTap,
        child: WnMediaErrorPlaceholder(
          key: const Key('media_image_error'),
          onRetry: retry ?? () {},
          blurhash: blurhash,
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          if (aspectRatio != null)
            Center(
              child: AspectRatio(
                aspectRatio: aspectRatio,
                child: WnBlurhashPlaceholder(
                  key: const Key('media_image_loading'),
                  blurhash: blurhash,
                ),
              ),
            )
          else
            WnBlurhashPlaceholder(
              key: const Key('media_image_loading'),
              blurhash: blurhash,
            ),
          if (status == MediaDownloadStatus.success)
            FadeTransition(
              key: const Key('fade_transition'),
              opacity: fadeController,
              child: InteractiveViewer(
                key: const Key('media_image_viewer'),
                transformationController: transformationController,
                minScale: 1.0,
                maxScale: 4.0,
                child: Center(
                  child: Image.file(
                    File(localPath!),
                    key: const Key('media_image_file'),
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => WnBlurhashPlaceholder(
                      key: const Key('media_image_error_fallback'),
                      blurhash: blurhash,
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
