import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/widgets/wn_icon.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';
import '../test_helpers.dart';

void main() {
  group('WnSlateNavigationHeader', () {
    testWidgets('renders title', (tester) async {
      await mountWidget(
        const WnSlateNavigationHeader(
          title: 'Test Title',
        ),
        tester,
      );

      expect(find.text('Test Title'), findsOneWidget);
    });

    testWidgets('does not render action when onNavigate is null', (tester) async {
      await mountWidget(
        const WnSlateNavigationHeader(
          title: 'Test Title',
        ),
        tester,
      );

      expect(find.byType(GestureDetector), findsNothing);
    });

    group('close type', () {
      testWidgets('renders close icon on right side when onNavigate provided', (tester) async {
        await mountWidget(
          WnSlateNavigationHeader(
            title: 'Test Title',
            onNavigate: () {},
          ),
          tester,
        );

        final iconFinder = find.byType(WnIcon);
        expect(iconFinder, findsOneWidget);
        final icon = tester.widget<WnIcon>(iconFinder);
        expect(icon.icon, WnIcons.closeLarge);
      });

      testWidgets('calls onNavigate when close button tapped', (tester) async {
        var tapped = false;
        await mountWidget(
          WnSlateNavigationHeader(
            title: 'Test Title',
            onNavigate: () => tapped = true,
          ),
          tester,
        );

        await tester.tap(find.byType(GestureDetector));
        expect(tapped, isTrue);
      });
    });

    group('titleWidget', () {
      testWidgets('renders titleWidget instead of title text', (tester) async {
        await mountWidget(
          WnSlateNavigationHeader(
            titleWidget: const Text('Custom Widget Title'),
            onNavigate: () {},
          ),
          tester,
        );

        expect(find.text('Custom Widget Title'), findsOneWidget);
      });

      testWidgets('titleWidget takes precedence over title', (tester) async {
        await mountWidget(
          WnSlateNavigationHeader(
            title: 'String Title',
            titleWidget: const Text('Widget Title'),
            onNavigate: () {},
          ),
          tester,
        );

        expect(find.text('Widget Title'), findsOneWidget);
        expect(find.text('String Title'), findsNothing);
      });
    });

    group('back type', () {
      testWidgets('renders back icon on left side when onNavigate provided', (tester) async {
        await mountWidget(
          WnSlateNavigationHeader(
            title: 'Test Title',
            type: WnSlateNavigationType.back,
            onNavigate: () {},
          ),
          tester,
        );

        final iconFinder = find.byType(WnIcon);
        expect(iconFinder, findsOneWidget);
        final icon = tester.widget<WnIcon>(iconFinder);
        expect(icon.icon, WnIcons.chevronLeft);
      });

      testWidgets('calls onNavigate when back button tapped', (tester) async {
        var tapped = false;
        await mountWidget(
          WnSlateNavigationHeader(
            title: 'Test Title',
            type: WnSlateNavigationType.back,
            onNavigate: () => tapped = true,
          ),
          tester,
        );

        await tester.tap(find.byType(GestureDetector));
        expect(tapped, isTrue);
      });
    });
  });
}
