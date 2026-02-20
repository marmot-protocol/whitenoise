import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/widgets/wn_slate_content_transition.dart';
import '../test_helpers.dart';

void main() {
  group('WnSlateContentTransition', () {
    group('static properties', () {
      test('duration is 200ms', () {
        expect(WnSlateContentTransition.duration, const Duration(milliseconds: 200));
      });

      test('curve is easeInOutCubicEmphasized', () {
        expect(WnSlateContentTransition.curve, Curves.easeInOutCubicEmphasized);
      });

      test('reverseCurve is flipped easeInOutCubicEmphasized', () {
        final reverseCurve = WnSlateContentTransition.reverseCurve;
        final expectedCurve = Curves.easeInOutCubicEmphasized.flipped;
        expect(reverseCurve.transform(0.5), closeTo(expectedCurve.transform(0.5), 0.001));
      });

      test('maxBlurSigma is 4', () {
        expect(WnSlateContentTransition.maxBlurSigma, 4.0);
      });
    });

    group('self-animating behavior', () {
      testWidgets('renders child content', (tester) async {
        await mountWidget(
          const WnSlateContentTransition(
            child: Text('Test Content'),
          ),
          tester,
        );

        expect(find.text('Test Content'), findsOneWidget);
      });

      testWidgets('starts with opacity 0 when no route animation', (tester) async {
        await mountWidget(
          const WnSlateContentTransition(
            child: Text('Content'),
          ),
          tester,
        );

        final fadeTransition = tester.widget<FadeTransition>(
          find.descendant(
            of: find.byType(WnSlateContentTransition),
            matching: find.byType(FadeTransition),
          ),
        );
        expect(fadeTransition.opacity.value, 0.0);
      });

      testWidgets('animates to opacity 1 over duration', (tester) async {
        await mountWidget(
          const WnSlateContentTransition(
            child: Text('Content'),
          ),
          tester,
        );

        await tester.pump(WnSlateContentTransition.duration);

        final fadeTransition = tester.widget<FadeTransition>(
          find.descendant(
            of: find.byType(WnSlateContentTransition),
            matching: find.byType(FadeTransition),
          ),
        );
        expect(fadeTransition.opacity.value, 1.0);
      });

      testWidgets('uses ImageFiltered for blur effect', (tester) async {
        await mountWidget(
          const WnSlateContentTransition(
            child: Text('Content'),
          ),
          tester,
        );

        expect(
          find.descendant(
            of: find.byType(WnSlateContentTransition),
            matching: find.byType(ImageFiltered),
          ),
          findsOneWidget,
        );
      });
    });

    group('with route animation', () {
      testWidgets('waits for route animation to complete before animating', (tester) async {
        final routeController = AnimationController(
          vsync: const TestVSync(),
          duration: const Duration(milliseconds: 300),
        );

        await mountWidget(
          WnSlateContentTransition(
            routeAnimation: routeController,
            child: const Text('Content'),
          ),
          tester,
        );

        // Content should be invisible while route animation is not complete
        var fadeTransition = tester.widget<FadeTransition>(
          find.descendant(
            of: find.byType(WnSlateContentTransition),
            matching: find.byType(FadeTransition),
          ),
        );
        expect(fadeTransition.opacity.value, 0.0);

        // Advance route animation partway
        routeController.value = 0.5;
        await tester.pump();

        // Still invisible - waiting for route to complete
        fadeTransition = tester.widget<FadeTransition>(
          find.descendant(
            of: find.byType(WnSlateContentTransition),
            matching: find.byType(FadeTransition),
          ),
        );
        expect(fadeTransition.opacity.value, 0.0);

        // Complete route animation
        routeController.forward();
        await tester.pumpAndSettle();

        // After route + content animation complete, should be visible
        fadeTransition = tester.widget<FadeTransition>(
          find.descendant(
            of: find.byType(WnSlateContentTransition),
            matching: find.byType(FadeTransition),
          ),
        );
        expect(fadeTransition.opacity.value, 1.0);

        routeController.dispose();
      });
      testWidgets('animates immediately if route animation already completed', (tester) async {
        final routeController = AnimationController(
          vsync: const TestVSync(),
          duration: const Duration(milliseconds: 300),
        );
        routeController.value = 1.0;

        await mountWidget(
          WnSlateContentTransition(
            routeAnimation: routeController,
            child: const Text('Content'),
          ),
          tester,
        );

        // Should start animating immediately since route is complete
        await tester.pump(WnSlateContentTransition.duration);

        final fadeTransition = tester.widget<FadeTransition>(
          find.descendant(
            of: find.byType(WnSlateContentTransition),
            matching: find.byType(FadeTransition),
          ),
        );
        expect(fadeTransition.opacity.value, 1.0);

        routeController.dispose();
      });
    });
  });
}
