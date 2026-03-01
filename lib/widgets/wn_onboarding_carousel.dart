import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart' show HookWidget;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/hooks/use_onboarding_carousel.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_carousel_indicator.dart';

class WnOnboardingCarousel extends HookWidget {
  const WnOnboardingCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typographyScaled;
    final l10n = context.l10n;

    final slides = [
      _CarouselSlide(
        title: l10n.carouselPrivacyTitle,
        description: l10n.carouselPrivacyDescription,
        accentColor: colors.accent.cyan.contentSecondary,
      ),
      _CarouselSlide(
        title: l10n.carouselIdentityTitle,
        description: l10n.carouselIdentityDescription,
        accentColor: colors.accent.violet.contentSecondary,
      ),
      _CarouselSlide(
        title: l10n.carouselDecentralizedTitle,
        description: l10n.carouselDecentralizedDescription,
        accentColor: colors.accent.orange.contentSecondary,
      ),
    ];

    final (:pageController, :currentIndex, :onPageChanged, goToPage: _) = useOnboardingCarousel();

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 260.h,
            child: PageView.builder(
              key: const Key('login_carousel_page_view'),
              controller: pageController,
              onPageChanged: onPageChanged,
              itemBuilder: (context, index) {
                final slide = slides[index % slides.length];
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 36.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        slide.title,
                        style: typography.bold36.copyWith(
                          color: slide.accentColor,
                          leadingDistribution: TextLeadingDistribution.proportional,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Gap(12.h),
                      Text(
                        slide.description,
                        style: typography.medium20.copyWith(
                          color: colors.backgroundContentSecondary,
                          leadingDistribution: TextLeadingDistribution.proportional,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Gap(16.h),
          WnCarouselIndicator(
            key: const Key('login_carousel_indicator'),
            itemCount: slides.length,
            activeIndex: currentIndex,
            activeColor: slides[currentIndex].accentColor,
          ),
        ],
      ),
    );
  }
}

class _CarouselSlide {
  final String title;
  final String description;
  final Color accentColor;

  const _CarouselSlide({
    required this.title,
    required this.description,
    required this.accentColor,
  });
}
