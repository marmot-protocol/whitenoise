import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/widgets/wn_carousel_indicator.dart';
import 'package:whitenoise/widgets/wn_onboarding_carousel.dart';

import '../test_helpers.dart';

void main() {
  group('WnOnboardingCarousel', () {
    group('rendering', () {
      testWidgets('renders PageView', (tester) async {
        await mountWidget(const WnOnboardingCarousel(), tester);
        expect(find.byType(PageView), findsOneWidget);
      });

      testWidgets('renders carousel indicator', (tester) async {
        await mountWidget(const WnOnboardingCarousel(), tester);
        expect(find.byType(WnCarouselIndicator), findsOneWidget);
      });

      testWidgets('renders with correct key for page view', (tester) async {
        await mountWidget(const WnOnboardingCarousel(), tester);
        expect(find.byKey(const Key('login_carousel_page_view')), findsOneWidget);
      });

      testWidgets('renders with correct key for indicator', (tester) async {
        await mountWidget(const WnOnboardingCarousel(), tester);
        expect(find.byKey(const Key('login_carousel_indicator')), findsOneWidget);
      });
    });

    group('slide content', () {
      testWidgets('displays first slide title', (tester) async {
        await mountWidget(const WnOnboardingCarousel(), tester);
        await tester.pumpAndSettle();
        expect(find.text('Privacy and security'), findsOneWidget);
      });

      testWidgets('displays first slide description', (tester) async {
        await mountWidget(const WnOnboardingCarousel(), tester);
        await tester.pumpAndSettle();
        expect(
          find.text(
            'Keep your conversations private. Even in case of a breach, your messages remain secure.',
          ),
          findsOneWidget,
        );
      });
    });

    group('swipe navigation', () {
      testWidgets('swiping left shows second slide', (tester) async {
        await mountWidget(const WnOnboardingCarousel(), tester);
        await tester.pumpAndSettle();
        await tester.drag(
          find.byKey(const Key('login_carousel_page_view')),
          const Offset(-400, 0),
        );
        await tester.pumpAndSettle();

        expect(find.text('Choose your identity'), findsOneWidget);
      });

      testWidgets('swiping left twice shows third slide', (tester) async {
        await mountWidget(const WnOnboardingCarousel(), tester);
        await tester.pumpAndSettle();
        await tester.drag(
          find.byKey(const Key('login_carousel_page_view')),
          const Offset(-400, 0),
        );
        await tester.pumpAndSettle();

        await tester.drag(
          find.byKey(const Key('login_carousel_page_view')),
          const Offset(-400, 0),
        );
        await tester.pumpAndSettle();

        expect(find.text('Decentralized and permissionless'), findsOneWidget);
      });

      testWidgets('can swipe right from second slide to first', (tester) async {
        await mountWidget(const WnOnboardingCarousel(), tester);
        await tester.pumpAndSettle();

        await tester.drag(
          find.byKey(const Key('login_carousel_page_view')),
          const Offset(-400, 0),
        );
        await tester.pumpAndSettle();

        expect(find.text('Choose your identity'), findsOneWidget);

        await tester.drag(
          find.byKey(const Key('login_carousel_page_view')),
          const Offset(400, 0),
        );
        await tester.pumpAndSettle();

        expect(find.text('Privacy and security'), findsOneWidget);
      });
    });

    group('carousel indicator', () {
      testWidgets('indicator has 3 items', (tester) async {
        await mountWidget(const WnOnboardingCarousel(), tester);
        await tester.pumpAndSettle();
        final indicator = tester.widget<WnCarouselIndicator>(
          find.byKey(const Key('login_carousel_indicator')),
        );
        expect(indicator.itemCount, 3);
      });

      testWidgets('indicator starts at index 0', (tester) async {
        await mountWidget(const WnOnboardingCarousel(), tester);
        await tester.pumpAndSettle();
        final indicator = tester.widget<WnCarouselIndicator>(
          find.byKey(const Key('login_carousel_indicator')),
        );
        expect(indicator.activeIndex, 0);
      });

      testWidgets('indicator updates when swiping', (tester) async {
        await mountWidget(const WnOnboardingCarousel(), tester);
        await tester.pumpAndSettle();
        await tester.drag(
          find.byKey(const Key('login_carousel_page_view')),
          const Offset(-400, 0),
        );
        await tester.pumpAndSettle();

        final indicator = tester.widget<WnCarouselIndicator>(
          find.byKey(const Key('login_carousel_indicator')),
        );
        expect(indicator.activeIndex, 1);
      });
    });

    group('infinite scrolling', () {
      testWidgets('can scroll past third slide and loops back', (tester) async {
        await mountWidget(const WnOnboardingCarousel(), tester);
        await tester.pumpAndSettle();

        for (var i = 0; i < 3; i++) {
          await tester.drag(
            find.byKey(const Key('login_carousel_page_view')),
            const Offset(-400, 0),
          );
          await tester.pumpAndSettle();
        }

        expect(find.text('Privacy and security'), findsOneWidget);
      });
    });

    group('layout', () {
      testWidgets('renders without overflow in compact height container', (tester) async {
        await mountWidget(
          const SizedBox(height: 300, child: WnOnboardingCarousel()),
          tester,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(PageView), findsOneWidget);
      });

      testWidgets('indicator is visible below the PageView', (tester) async {
        await mountWidget(const WnOnboardingCarousel(), tester);
        await tester.pumpAndSettle();
        final pageViewBottom = tester.getBottomLeft(find.byType(PageView)).dy;
        final indicatorTop = tester
            .getTopLeft(find.byKey(const Key('login_carousel_indicator')))
            .dy;
        expect(indicatorTop, greaterThan(pageViewBottom));
      });

      testWidgets('indicator is positioned below center of carousel', (tester) async {
        await mountWidget(const WnOnboardingCarousel(), tester);
        await tester.pumpAndSettle();
        final carouselRect = tester.getRect(find.byType(WnOnboardingCarousel));
        final indicatorRect = tester.getRect(find.byKey(const Key('login_carousel_indicator')));
        final centerY = carouselRect.center.dy;
        expect(indicatorRect.center.dy, greaterThan(centerY));
      });
    });
  });
}
