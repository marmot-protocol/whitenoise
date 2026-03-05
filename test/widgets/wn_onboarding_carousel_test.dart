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

      testWidgets('renders with correct key for page view', (tester) async {
        await mountWidget(const WnOnboardingCarousel(), tester);
        expect(find.byKey(const Key('login_carousel_page_view')), findsOneWidget);
      });

      testWidgets('does not render carousel indicator internally', (tester) async {
        await mountWidget(const WnOnboardingCarousel(), tester);
        expect(find.byType(WnCarouselIndicator), findsNothing);
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

    group('onSlideChanged callback', () {
      testWidgets('calls onSlideChanged with correct index when swiping', (tester) async {
        int? lastIndex;
        Color? lastColor;
        await mountWidget(
          WnOnboardingCarousel(
            onSlideChanged: (index, color) {
              lastIndex = index;
              lastColor = color;
            },
          ),
          tester,
        );
        await tester.pumpAndSettle();
        await tester.drag(
          find.byKey(const Key('login_carousel_page_view')),
          const Offset(-400, 0),
        );
        await tester.pumpAndSettle();
        expect(lastIndex, 1);
        expect(lastColor, isNotNull);
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
          const Offset(testDesignWidth, 0),
        );
        await tester.pumpAndSettle();

        expect(find.text('Privacy and security'), findsOneWidget);
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

      testWidgets('respects custom height parameter', (tester) async {
        await mountWidget(
          const WnOnboardingCarousel(height: 320),
          tester,
        );
        await tester.pumpAndSettle();
        final carouselRect = tester.getRect(find.byType(WnOnboardingCarousel));
        expect(carouselRect.height, equals(320));
      });
    });
  });
}
