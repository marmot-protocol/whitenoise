import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:whitenoise/hooks/use_media_download.dart';
import 'package:whitenoise/src/rust/api/media_files.dart';
import 'package:whitenoise/widgets/wn_blurhash_placeholder.dart';
import 'package:whitenoise/widgets/wn_media_error_placeholder.dart';

const _doubleTapScale = 2.5;
const _minScale = 1.0;
const _maxScale = 4.0;

double? _parseAspectRatio(String? dimensions) {
  if (dimensions == null) return null;
  final parts = dimensions.split('x');
  if (parts.length != 2) return null;
  final w = double.tryParse(parts[0]);
  final h = double.tryParse(parts[1]);
  if (w == null || h == null || w <= 0 || h <= 0) return null;
  return w / h;
}

Matrix4 _buildZoomMatrix(Offset focalPoint, double scale) {
  return Matrix4.identity()
    ..translateByDouble(focalPoint.dx, focalPoint.dy, 0, 1)
    ..scaleByDouble(scale, scale, 1, 1)
    ..translateByDouble(-focalPoint.dx, -focalPoint.dy, 0, 1);
}

class MediaImage extends HookWidget {
  final MediaFile mediaFile;
  final ValueChanged<bool>? onZoomChanged;
  final VoidCallback? onTap;

  const MediaImage({
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
    final doubleTapPosition = useState<Offset?>(null);

    final zoomAnimationController = useAnimationController(
      duration: const Duration(milliseconds: 250),
    );

    final zoomAnimation = useState<Animation<Matrix4>?>(null);

    useEffect(() {
      void animationListener() {
        if (zoomAnimation.value != null) {
          transformationController.value = zoomAnimation.value!.value;
        }
      }

      zoomAnimationController.addListener(animationListener);
      return () => zoomAnimationController.removeListener(animationListener);
    }, [zoomAnimationController]);

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

    void animateToMatrix(Matrix4 target) {
      zoomAnimation.value =
          Matrix4Tween(
            begin: transformationController.value,
            end: target,
          ).animate(
            CurvedAnimation(
              parent: zoomAnimationController,
              curve: Curves.easeOutCubic,
            ),
          );
      zoomAnimationController.forward(from: 0);
    }

    void handleDoubleTap() {
      final position = doubleTapPosition.value;
      if (position == null) return;

      final target = isZoomed.value
          ? Matrix4.identity()
          : _buildZoomMatrix(position, _doubleTapScale);
      animateToMatrix(target);
    }

    final blurhash = mediaFile.fileMetadata?.blurhash;
    final dimensions = mediaFile.fileMetadata?.dimensions;
    final aspectRatio = _parseAspectRatio(dimensions);

    final fadeController = useAnimationController(
      duration: const Duration(milliseconds: 300),
      initialValue: status == MediaDownloadStatus.success ? 1.0 : 0.0,
    );

    final showBlurhash = useState(status != MediaDownloadStatus.success);

    useEffect(() {
      void statusListener(AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          showBlurhash.value = false;
        } else if (status == AnimationStatus.dismissed) {
          showBlurhash.value = true;
        }
      }

      fadeController.addStatusListener(statusListener);
      return () => fadeController.removeStatusListener(statusListener);
    }, [fadeController]);

    useEffect(() {
      if (status == MediaDownloadStatus.success) {
        if (fadeController.value < 1.0) {
          fadeController.forward();
        }
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
          onRetry: retry!,
          blurhash: blurhash,
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      onDoubleTapDown: (details) => doubleTapPosition.value = details.localPosition,
      onDoubleTap: handleDoubleTap,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          if (showBlurhash.value)
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
                width: double.infinity,
                height: double.infinity,
              ),
          if (status == MediaDownloadStatus.success)
            _buildLoadedImage(
              aspectRatio: aspectRatio,
              blurhash: blurhash,
              fadeController: fadeController,
              transformationController: transformationController,
              localPath: localPath!,
            ),
        ],
      ),
    );
  }

  static Widget _buildLoadedImage({
    required double? aspectRatio,
    required String? blurhash,
    required AnimationController fadeController,
    required TransformationController transformationController,
    required String localPath,
  }) {
    final loadedImage = FadeTransition(
      key: const Key('fade_transition'),
      opacity: fadeController,
      child: InteractiveViewer(
        key: const Key('media_image_viewer'),
        transformationController: transformationController,
        minScale: _minScale,
        maxScale: _maxScale,
        child: Center(
          child: Image.file(
            File(localPath),
            key: const Key('media_image_file'),
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, _, _) => aspectRatio != null
                ? AspectRatio(
                    aspectRatio: aspectRatio,
                    child: WnBlurhashPlaceholder(
                      key: const Key('media_image_error_fallback'),
                      blurhash: blurhash,
                    ),
                  )
                : WnBlurhashPlaceholder(
                    key: const Key('media_image_error_fallback'),
                    blurhash: blurhash,
                  ),
          ),
        ),
      ),
    );

    return loadedImage;
  }
}
