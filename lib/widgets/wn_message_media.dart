import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/theme.dart';

class WnMessageMedia extends StatelessWidget {
  final List<Widget> tiles;
  final ValueChanged<int>? onTileTap;

  const WnMessageMedia({super.key, required this.tiles, this.onTileTap});

  @override
  Widget build(BuildContext context) {
    if (tiles.isEmpty) return const SizedBox.shrink();

    final colors = context.colors;
    final typography = context.typographyScaled;

    return switch (tiles.length) {
      1 => _buildOneLayout(),
      2 => _buildTwoLayout(),
      3 => _buildThreeLayout(),
      4 => _buildFourLayout(),
      5 => _buildFiveLayout(),
      _ => _buildSixPlusLayout(colors, typography),
    };
  }

  Widget _tappableTile(int index) {
    return GestureDetector(
      key: Key('tappable_media_tile_$index'),
      onTap: onTileTap != null ? () => onTileTap!(index) : null,
      child: tiles[index],
    );
  }

  Widget _buildOneLayout() {
    return AspectRatio(
      key: const Key('one_layout'),
      aspectRatio: 1,
      child: _tappableTile(0),
    );
  }

  Widget _buildTwoLayout() {
    return IntrinsicHeight(
      key: const Key('two_layout'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: AspectRatio(aspectRatio: 1, child: _tappableTile(0))),
          Gap(4.w),
          Expanded(child: AspectRatio(aspectRatio: 1, child: _tappableTile(1))),
        ],
      ),
    );
  }

  Widget _buildThreeLayout() {
    return IntrinsicHeight(
      key: const Key('three_layout'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: AspectRatio(aspectRatio: 1, child: _tappableTile(0))),
          Gap(4.w),
          Expanded(child: AspectRatio(aspectRatio: 1, child: _tappableTile(1))),
          Gap(4.w),
          Expanded(child: AspectRatio(aspectRatio: 1, child: _tappableTile(2))),
        ],
      ),
    );
  }

  Widget _buildFourLayout() {
    return Column(
      key: const Key('four_layout'),
      mainAxisSize: MainAxisSize.min,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: AspectRatio(aspectRatio: 1, child: _tappableTile(0))),
              Gap(4.w),
              Expanded(child: AspectRatio(aspectRatio: 1, child: _tappableTile(1))),
            ],
          ),
        ),
        Gap(4.h),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: AspectRatio(aspectRatio: 1, child: _tappableTile(2))),
              Gap(4.w),
              Expanded(child: AspectRatio(aspectRatio: 1, child: _tappableTile(3))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFiveLayout() {
    return Column(
      key: const Key('five_layout'),
      mainAxisSize: MainAxisSize.min,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: AspectRatio(aspectRatio: 1, child: _tappableTile(0))),
              Gap(4.w),
              Expanded(child: AspectRatio(aspectRatio: 1, child: _tappableTile(1))),
              Gap(4.w),
              Expanded(child: AspectRatio(aspectRatio: 1, child: _tappableTile(2))),
            ],
          ),
        ),
        Gap(4.h),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: AspectRatio(aspectRatio: 1, child: _tappableTile(3))),
              Gap(4.w),
              Expanded(child: AspectRatio(aspectRatio: 1, child: _tappableTile(4))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSixPlusLayout(SemanticColors colors, AppTypography typography) {
    final overflowCount = tiles.length - 6;

    return Column(
      key: const Key('six_plus_layout'),
      mainAxisSize: MainAxisSize.min,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: AspectRatio(aspectRatio: 1, child: _tappableTile(0))),
              Gap(4.w),
              Expanded(child: AspectRatio(aspectRatio: 1, child: _tappableTile(1))),
              Gap(4.w),
              Expanded(child: AspectRatio(aspectRatio: 1, child: _tappableTile(2))),
            ],
          ),
        ),
        Gap(4.h),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: AspectRatio(aspectRatio: 1, child: _tappableTile(3))),
              Gap(4.w),
              Expanded(child: AspectRatio(aspectRatio: 1, child: _tappableTile(4))),
              Gap(4.w),
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _tappableTile(5),
                      if (overflowCount > 0)
                        IgnorePointer(
                          child: Container(
                            key: const Key('overflow_indicator'),
                            decoration: BoxDecoration(
                              color: colors.overlayTertiary,
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Center(
                              child: Text(
                                '+$overflowCount',
                                style: typography.semiBold18.copyWith(
                                  color: colors.fillContentQuaternary,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
