import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_overlay.dart';

import '../test_helpers.dart' show mountStackedWidget, setUpTestView, testDesignSize;

void main() {
  group('WnOverlay widget', () {
    group('rendering', () {
      testWidgets('renders correctly', (tester) async {
        await mountStackedWidget(const WnOverlay(), tester);

        expect(find.byType(WnOverlay), findsOneWidget);
        expect(find.byType(BackdropFilter), findsOneWidget);
        expect(
          find.descendant(of: find.byType(WnOverlay), matching: find.byType(ColoredBox)),
          findsOneWidget,
        );
      });

      testWidgets('is positioned to fill parent', (tester) async {
        await mountStackedWidget(const WnOverlay(), tester);

        expect(find.byType(Positioned), findsOneWidget);
        final positioned = tester.widget<Positioned>(find.byType(Positioned));
        expect(positioned.left, 0.0);
        expect(positioned.top, 0.0);
        expect(positioned.right, 0.0);
        expect(positioned.bottom, 0.0);
      });
    });

    group('backdrop filter', () {
      testWidgets('creates a blur filter', (tester) async {
        await mountStackedWidget(const WnOverlay(), tester);

        final backdropFilter = tester.widget<BackdropFilter>(find.byType(BackdropFilter));
        final blur = backdropFilter.filter;
        expect(blur, isNotNull);
      });
    });

    group('variant', () {
      testWidgets('defaults to heavy variant', (tester) async {
        await mountStackedWidget(const WnOverlay(), tester);

        final overlay = tester.widget<WnOverlay>(find.byType(WnOverlay));
        expect(overlay.variant, WnOverlayVariant.heavy);
      });

      testWidgets('accepts light variant', (tester) async {
        await mountStackedWidget(const WnOverlay(variant: WnOverlayVariant.light), tester);

        final overlay = tester.widget<WnOverlay>(find.byType(WnOverlay));
        expect(overlay.variant, WnOverlayVariant.light);
      });
    });

    group('color', () {
      testWidgets('heavy variant uses overlayPrimary color from light theme', (tester) async {
        await mountStackedWidget(const WnOverlay(), tester);

        final coloredBox = tester.widget<ColoredBox>(
          find.descendant(of: find.byType(WnOverlay), matching: find.byType(ColoredBox)),
        );
        expect(coloredBox.color, SemanticColors.light.overlayPrimary);
      });

      testWidgets('light variant uses overlaySecondary color from light theme', (tester) async {
        await mountStackedWidget(const WnOverlay(variant: WnOverlayVariant.light), tester);

        final coloredBox = tester.widget<ColoredBox>(
          find.descendant(of: find.byType(WnOverlay), matching: find.byType(ColoredBox)),
        );
        expect(coloredBox.color, SemanticColors.light.overlaySecondary);
      });

      testWidgets('heavy variant uses overlayPrimary color from dark theme', (tester) async {
        setUpTestView(tester);
        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: testDesignSize,
            builder: (_, _) => MaterialApp(
              theme: ThemeData.dark().copyWith(extensions: [SemanticColors.dark]),
              home: const Scaffold(
                body: Stack(children: [WnOverlay()]),
              ),
            ),
          ),
        );

        final coloredBox = tester.widget<ColoredBox>(
          find.descendant(of: find.byType(WnOverlay), matching: find.byType(ColoredBox)),
        );
        expect(coloredBox.color, SemanticColors.dark.overlayPrimary);
      });

      testWidgets('light variant uses overlaySecondary color from dark theme', (tester) async {
        setUpTestView(tester);
        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: testDesignSize,
            builder: (_, _) => MaterialApp(
              theme: ThemeData.dark().copyWith(extensions: [SemanticColors.dark]),
              home: const Scaffold(
                body: Stack(children: [WnOverlay(variant: WnOverlayVariant.light)]),
              ),
            ),
          ),
        );

        final coloredBox = tester.widget<ColoredBox>(
          find.descendant(of: find.byType(WnOverlay), matching: find.byType(ColoredBox)),
        );
        expect(coloredBox.color, SemanticColors.dark.overlaySecondary);
      });
    });

    group('layout behavior', () {
      testWidgets('fills available space in a Stack', (tester) async {
        await mountStackedWidget(
          const SizedBox(
            width: 300,
            height: 400,
            child: Stack(children: [WnOverlay()]),
          ),
          tester,
        );

        expect(find.byType(WnOverlay), findsOneWidget);
      });

      testWidgets('can be used with other widgets in Stack', (tester) async {
        await mountStackedWidget(
          const SizedBox(
            width: 300,
            height: 400,
            child: Stack(
              children: [
                Positioned.fill(child: Placeholder()),
                WnOverlay(),
                Center(child: Text('Content')),
              ],
            ),
          ),
          tester,
        );

        expect(find.byType(WnOverlay), findsOneWidget);
        expect(find.text('Content'), findsOneWidget);
        expect(find.byType(Placeholder), findsOneWidget);
      });
    });
  });

  group('WnOverlayVariant', () {
    test('has heavy variant', () {
      expect(WnOverlayVariant.heavy, isNotNull);
    });

    test('has light variant', () {
      expect(WnOverlayVariant.light, isNotNull);
    });

    test('variants are distinct', () {
      expect(WnOverlayVariant.heavy, isNot(WnOverlayVariant.light));
    });
  });
}
