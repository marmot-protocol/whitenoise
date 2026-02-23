import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_icon.dart';
import 'package:whitenoise/widgets/wn_icon_button.dart';

class WnEmojiPicker extends StatelessWidget {
  const WnEmojiPicker({
    super.key,
    required this.onClose,
    required this.onEmojiSelected,
  });

  final VoidCallback onClose;
  final void Function(String emoji) onEmojiSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.backgroundSecondary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(8.r)),
        border: Border(
          top: BorderSide(color: colors.borderTertiary),
          left: BorderSide(color: colors.borderTertiary),
          right: BorderSide(color: colors.borderTertiary),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 8.h, right: 12.w, left: 12.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                WnIconButton(
                  key: const Key('emoji_picker_close_button'),
                  icon: WnIcons.closeLarge,
                  onPressed: onClose,
                ),
              ],
            ),
          ),
          SizedBox(
            height: 260.h,
            child: EmojiPicker(
              onEmojiSelected: (category, emoji) => onEmojiSelected(emoji.emoji),
              config: Config(
                emojiViewConfig: EmojiViewConfig(
                  columns: 8,
                  emojiSizeMax: 28.sp,
                  gridPadding: EdgeInsets.symmetric(horizontal: 8.w),
                  backgroundColor: colors.backgroundSecondary,
                  noRecents: Text(
                    'No recent emojis',
                    style: context.typographyScaled.medium14.copyWith(
                      color: colors.backgroundContentSecondary,
                    ),
                  ),
                ),
                categoryViewConfig: CategoryViewConfig(
                  initCategory: Category.SMILEYS,
                  backgroundColor: colors.backgroundSecondary,
                  dividerColor: colors.borderTertiary,
                  customCategoryView: (config, state, tabController, pageController) {
                    return _EmojiCategoryBar(
                      tabController: tabController,
                      pageController: pageController,
                      colors: colors,
                    );
                  },
                ),
                bottomActionBarConfig: const BottomActionBarConfig(
                  enabled: false,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmojiCategoryBar extends StatelessWidget {
  const _EmojiCategoryBar({
    required this.tabController,
    required this.pageController,
    required this.colors,
  });

  final TabController tabController;
  final PageController pageController;
  final SemanticColors colors;

  static const _categories = [
    Category.RECENT,
    Category.SMILEYS,
    Category.ANIMALS,
    Category.FOODS,
    Category.ACTIVITIES,
    Category.TRAVEL,
    Category.OBJECTS,
    Category.SYMBOLS,
    Category.FLAGS,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colors.backgroundSecondary,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _categories.asMap().entries.map((entry) {
          final index = entry.key;
          final category = entry.value;
          return Expanded(
            child: _CategoryTab(
              key: Key('emoji_category_${category.name.toLowerCase()}'),
              category: category,
              tabController: tabController,
              pageController: pageController,
              index: index,
              colors: colors,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CategoryTab extends StatelessWidget {
  const _CategoryTab({
    super.key,
    required this.category,
    required this.tabController,
    required this.pageController,
    required this.index,
    required this.colors,
  });

  final Category category;
  final TabController tabController;
  final PageController pageController;
  final int index;
  final SemanticColors colors;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: tabController,
      builder: (context, _) {
        final isSelected = tabController.index == index;
        return GestureDetector(
          onTap: () {
            tabController.animateTo(index);
            pageController.jumpToPage(index);
          },
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isSelected ? colors.backgroundContentPrimary : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Center(child: _buildIcon(isSelected)),
          ),
        );
      },
    );
  }

  Widget _buildIcon(bool isSelected) {
    final color = isSelected ? colors.backgroundContentPrimary : colors.backgroundContentSecondary;
    final size = 20.sp;

    switch (category) {
      case Category.RECENT:
        return WnIcon(WnIcons.time, color: color, size: size);
      case Category.SMILEYS:
        return WnIcon(WnIcons.faceSatisfied, color: color, size: size);
      case Category.ANIMALS:
        return WnIcon(WnIcons.beeBat, color: color, size: size);
      case Category.FOODS:
        return WnIcon(WnIcons.apple, color: color, size: size);
      case Category.ACTIVITIES:
        return WnIcon(WnIcons.building, color: color, size: size);
      case Category.TRAVEL:
        return WnIcon(WnIcons.running, color: color, size: size);
      case Category.OBJECTS:
        return WnIcon(WnIcons.idea, color: color, size: size);
      case Category.SYMBOLS:
        return WnIcon(WnIcons.hashtag, color: color, size: size);
      case Category.FLAGS:
        return WnIcon(WnIcons.flag, color: color, size: size);
    }
  }
}
