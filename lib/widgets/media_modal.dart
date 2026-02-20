import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/providers/locale_provider.dart';
import 'package:whitenoise/src/rust/api/media_files.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/chat_media_thumbnail.dart';
import 'package:whitenoise/widgets/media_image.dart';
import 'package:whitenoise/widgets/wn_avatar.dart';
import 'package:whitenoise/widgets/wn_icon.dart';
import 'package:whitenoise/widgets/wn_overlay.dart';
import 'package:whitenoise/widgets/wn_slate.dart';

class MediaModal extends HookWidget {
  final List<MediaFile> mediaFiles;
  final int initialIndex;
  final String? senderName;
  final String? senderPictureUrl;
  final String? senderPubkey;
  final DateTime? timestamp;

  const MediaModal({
    super.key,
    required this.mediaFiles,
    this.initialIndex = 0,
    this.senderName,
    this.senderPictureUrl,
    this.senderPubkey,
    this.timestamp,
  });

  static Future<void> show({
    required BuildContext context,
    required List<MediaFile> mediaFiles,
    int initialIndex = 0,
    String? senderName,
    String? senderPictureUrl,
    String? senderPubkey,
    DateTime? timestamp,
  }) {
    return showDialog<void>(
      context: context,
      useSafeArea: false,
      barrierColor: Colors.transparent,
      builder: (_) => MediaModal(
        mediaFiles: mediaFiles,
        initialIndex: initialIndex,
        senderName: senderName,
        senderPictureUrl: senderPictureUrl,
        senderPubkey: senderPubkey,
        timestamp: timestamp,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = useState(initialIndex);
    final isFullscreen = useState(false);
    final isZoomed = useState(false);
    final pageController = useMemoized(
      () => PageController(initialPage: initialIndex),
    );

    useEffect(() => pageController.dispose, [pageController]);

    final showOverlays = !isFullscreen.value && !isZoomed.value;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const WnOverlay(variant: WnOverlayVariant.light),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: SizedBox(
                height:
                    MediaQuery.sizeOf(context).height -
                    MediaQuery.paddingOf(context).top -
                    MediaQuery.paddingOf(context).bottom -
                    16.h,
                child: WnSlate(
                  key: const Key('media_modal_slate'),
                  animateContent: false,
                  header: AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: showOverlays
                        ? _MediaModalHeader(
                            senderName: senderName,
                            senderPictureUrl: senderPictureUrl,
                            senderPubkey: senderPubkey,
                            timestamp: timestamp,
                            onClose: () => Navigator.of(context).pop(),
                          )
                        : const SizedBox.shrink(),
                  ),
                  child: _MediaContent(
                    mediaFiles: mediaFiles,
                    pageController: pageController,
                    isZoomed: isZoomed.value,
                    showOverlays: showOverlays,
                    currentIndex: currentIndex.value,
                    onTap: () {
                      if (!isZoomed.value) isFullscreen.value = !isFullscreen.value;
                    },
                    onZoomChanged: (zoomed) => isZoomed.value = zoomed,
                    onPageChanged: (index) => currentIndex.value = index,
                    onThumbnailTap: (index) {
                      pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
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

class _MediaContent extends StatelessWidget {
  final List<MediaFile> mediaFiles;
  final PageController pageController;
  final bool isZoomed;
  final bool showOverlays;
  final int currentIndex;
  final VoidCallback onTap;
  final ValueChanged<bool> onZoomChanged;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onThumbnailTap;

  const _MediaContent({
    required this.mediaFiles,
    required this.pageController,
    required this.isZoomed,
    required this.showOverlays,
    required this.currentIndex,
    required this.onTap,
    required this.onZoomChanged,
    required this.onPageChanged,
    required this.onThumbnailTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('media_content_tap_area'),
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              key: const Key('media_page_view'),
              controller: pageController,
              itemCount: mediaFiles.length,
              physics: isZoomed ? const NeverScrollableScrollPhysics() : const PageScrollPhysics(),
              onPageChanged: onPageChanged,
              itemBuilder: (_, index) {
                return MediaImage(
                  key: Key('media_image_$index'),
                  mediaFile: mediaFiles[index],
                  onZoomChanged: onZoomChanged,
                );
              },
            ),
          ),
          if (mediaFiles.length > 1)
            _ThumbnailStrip(
              key: const Key('media_thumbnail_strip'),
              visible: showOverlays,
              mediaFiles: mediaFiles,
              currentIndex: currentIndex,
              onThumbnailTap: onThumbnailTap,
            ),
        ],
      ),
    );
  }
}

class _MediaModalHeader extends ConsumerWidget {
  final String? senderName;
  final String? senderPictureUrl;
  final String? senderPubkey;
  final DateTime? timestamp;
  final VoidCallback onClose;

  const _MediaModalHeader({
    this.senderName,
    this.senderPictureUrl,
    this.senderPubkey,
    this.timestamp,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final typography = context.typographyScaled;
    final formatters = ref.watch(localeFormattersProvider);

    return SizedBox(
      height: 80.h,
      child: Row(
        children: [
          Container(
            height: 80.h,
            padding: EdgeInsets.fromLTRB(16.w, 0, 12.w, 0),
            alignment: Alignment.center,
            child: WnAvatar(
              pictureUrl: senderPictureUrl,
              displayName: senderName,
              color: senderPubkey != null
                  ? AvatarColor.fromPubkey(senderPubkey!)
                  : AvatarColor.neutral,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  senderName ?? context.l10n.unknownUser,
                  key: const Key('media_modal_sender_name'),
                  style: typography.semiBold14.copyWith(
                    color: colors.backgroundContentPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (timestamp != null)
                  Text(
                    formatters.formatRelativeTime(timestamp!, context.l10n),
                    key: const Key('media_modal_timestamp'),
                    style: typography.medium12.copyWith(
                      color: colors.backgroundContentTertiary,
                    ),
                  ),
              ],
            ),
          ),
          GestureDetector(
            key: const Key('media_modal_close'),
            onTap: onClose,
            behavior: HitTestBehavior.opaque,
            child: Container(
              height: 80.h,
              padding: EdgeInsets.only(left: 16.w, right: 24.w),
              alignment: Alignment.center,
              child: WnIcon(
                WnIcons.closeLarge,
                color: colors.backgroundContentPrimary,
                size: 24.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThumbnailStrip extends StatelessWidget {
  final bool visible;
  final List<MediaFile> mediaFiles;
  final int currentIndex;
  final ValueChanged<int> onThumbnailTap;

  const _ThumbnailStrip({
    super.key,
    required this.visible,
    required this.mediaFiles,
    required this.currentIndex,
    required this.onThumbnailTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: visible
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              child: Row(
                children: List.generate(mediaFiles.length, (index) {
                  return Padding(
                    padding: EdgeInsets.only(right: index < mediaFiles.length - 1 ? 8.w : 0),
                    child: ChatMediaThumbnail(
                      key: Key('thumbnail_$index'),
                      mediaFile: mediaFiles[index],
                      isSelected: index == currentIndex,
                      onTap: () => onThumbnailTap(index),
                    ),
                  );
                }),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
