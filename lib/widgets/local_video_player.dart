import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:logging/logging.dart';
import 'package:video_player/video_player.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_media_placeholder.dart';

final _logger = Logger('LocalVideoPlayer');

class LocalVideoPlayer extends HookWidget {
  const LocalVideoPlayer({
    super.key,
    required this.filePath,
    this.thumbHash,
    this.blurhash,
    this.fit = BoxFit.contain,
    this.showControls = true,
    this.autoplay = false,
  });

  final String filePath;
  final String? thumbHash;
  final String? blurhash;
  final BoxFit fit;
  final bool showControls;
  final bool autoplay;

  @override
  Widget build(BuildContext context) {
    final controller = useState<VideoPlayerController?>(null);
    final controllerRef = useRef<VideoPlayerController?>(null);
    final generation = useRef(0);
    final isInitialized = useState(false);
    final hasError = useState(false);

    useEffect(() {
      return () {
        final activeController = controllerRef.value;
        controllerRef.value = null;
        if (activeController != null) {
          unawaited(activeController.dispose());
        }
      };
    }, const []);

    useEffect(() {
      generation.value++;
      final currentGeneration = generation.value;

      var cancelled = false;
      isInitialized.value = false;
      hasError.value = false;

      Future<void> initialize() async {
        final previousController = controllerRef.value;
        if (previousController != null) {
          controllerRef.value = null;
          controller.value = null;
          await previousController.dispose();
        }

        if (cancelled || generation.value != currentGeneration) return;

        final nextController = VideoPlayerController.file(File(filePath));
        controllerRef.value = nextController;
        controller.value = nextController;

        try {
          await nextController.initialize();
          await nextController.setLooping(false);
          if (autoplay) await nextController.play();
          if (!cancelled && generation.value == currentGeneration) {
            isInitialized.value = true;
          }
        } catch (error, stackTrace) {
          _logger.warning('Failed to initialize local video player', error, stackTrace);
          if (!cancelled && generation.value == currentGeneration) {
            hasError.value = true;
          }
        }
      }

      unawaited(initialize());
      return () {
        cancelled = true;
      };
    }, [filePath, autoplay]);

    final activeController = useListenable(controller.value);

    Future<void> togglePlayback() async {
      if (activeController == null || !isInitialized.value || hasError.value) return;
      if (activeController.value.isPlaying) {
        await activeController.pause();
      } else {
        await activeController.play();
      }
    }

    return GestureDetector(
      key: const Key('local_video_tap_area'),
      behavior: HitTestBehavior.opaque,
      onTap: showControls ? () => unawaited(togglePlayback()) : null,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (!isInitialized.value || hasError.value)
            WnMediaPlaceholder(
              key: hasError.value
                  ? const Key('video_error_placeholder')
                  : const Key('video_loading_placeholder'),
              thumbHash: thumbHash,
              blurhash: blurhash,
              width: double.infinity,
              height: double.infinity,
            ),
          if (activeController != null && isInitialized.value && !hasError.value)
            FittedBox(
              fit: fit,
              child: SizedBox(
                width: activeController.value.size.width,
                height: activeController.value.size.height,
                child: VideoPlayer(
                  activeController,
                  key: const Key('video_player'),
                ),
              ),
            ),
          if (showControls || hasError.value)
            VideoPlayIndicator(
              key: const Key('video_play_indicator'),
              visible:
                  !isInitialized.value ||
                  hasError.value ||
                  activeController?.value.isPlaying != true,
            ),
        ],
      ),
    );
  }
}

class VideoPlayIndicator extends StatelessWidget {
  const VideoPlayIndicator({
    super.key,
    this.visible = true,
    this.size,
  });

  final bool visible;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final resolvedSize = size ?? 48.w;

    return IgnorePointer(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: visible ? 1 : 0,
        child: Center(
          child: Container(
            width: resolvedSize,
            height: resolvedSize,
            decoration: BoxDecoration(
              color: colors.overlayTertiary,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Icons.play_arrow_rounded,
              key: const Key('video_play_icon'),
              color: colors.fillContentQuaternary,
              size: resolvedSize * 0.72,
            ),
          ),
        ),
      ),
    );
  }
}
