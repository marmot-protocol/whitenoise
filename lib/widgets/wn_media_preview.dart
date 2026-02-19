import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_icon.dart';
import 'package:whitenoise/widgets/wn_media_thumbnail.dart';

class WnMediaPreview extends HookWidget {
  const WnMediaPreview({
    super.key,
    required this.children,
    required this.selectedIndex,
    this.onSelectedChanged,
    this.onDelete,
  });

  final List<Widget> children;
  final int selectedIndex;
  final ValueChanged<int>? onSelectedChanged;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    final colors = context.colors;
    final pageController = usePageController(initialPage: selectedIndex);

    useEffect(() {
      if (pageController.hasClients && pageController.page?.round() != selectedIndex) {
        pageController.animateToPage(
          selectedIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
      return null;
    }, [selectedIndex]);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Stack(
            children: [
              PageView.builder(
                key: const Key('media_preview_page_view'),
                controller: pageController,
                itemCount: children.length,
                onPageChanged: onSelectedChanged,
                itemBuilder: (_, index) => ClipRRect(
                  borderRadius: BorderRadius.circular(4.r),
                  child: children[index],
                ),
              ),
              if (onDelete != null)
                Positioned(
                  top: 10.h,
                  right: 10.w,
                  child: _DeleteButton(
                    key: const Key('media_preview_delete_button'),
                    onTap: onDelete!,
                    colors: colors,
                  ),
                ),
            ],
          ),
        ),
        if (children.length > 1) ...[
          Gap(4.h),
          _ThumbnailStrip(
            key: const Key('media_preview_thumbnail_strip'),
            selectedIndex: selectedIndex,
            onThumbnailTap: onSelectedChanged,
            children: children,
          ),
        ],
      ],
    );
  }
}

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({
    super.key,
    required this.onTap,
    required this.colors,
  });

  final VoidCallback onTap;
  final SemanticColors colors;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44.w,
        height: 44.h,
        decoration: BoxDecoration(
          color: colors.fillSecondary,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: colors.borderTertiary),
        ),
        child: Center(
          child: WnIcon(
            WnIcons.trashCan,
            color: colors.backgroundContentPrimary,
            size: 18.sp,
          ),
        ),
      ),
    );
  }
}

class _ThumbnailStrip extends StatelessWidget {
  const _ThumbnailStrip({
    super.key,
    required this.children,
    required this.selectedIndex,
    this.onThumbnailTap,
  });

  final List<Widget> children;
  final int selectedIndex;
  final ValueChanged<int>? onThumbnailTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(children.length, (index) {
          return Padding(
            padding: EdgeInsets.only(right: index < children.length - 1 ? 4.w : 0),
            child: WnMediaThumbnail(
              key: Key('media_preview_thumbnail_$index'),
              isSelected: index == selectedIndex,
              onTap: onThumbnailTap != null ? () => onThumbnailTap!(index) : null,
              child: children[index],
            ),
          );
        }),
      ),
    );
  }
}
