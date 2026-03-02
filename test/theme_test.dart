import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/theme.dart';
import 'test_helpers.dart';

void main() {
  group('lightTheme', () {
    test('has light brightness', () {
      expect(lightTheme.brightness, Brightness.light);
    });

    test('uses Manrope font family', () {
      expect(lightTheme.textTheme.bodyMedium?.fontFamily, 'Manrope');
    });

    test('includes SemanticColors.light extension', () {
      final semanticColors = lightTheme.extension<SemanticColors>();
      expect(semanticColors, isNotNull);
      expect(
        semanticColors!.backgroundPrimary,
        SemanticColors.light.backgroundPrimary,
      );
    });

    test('includes AppTypography extension', () {
      final typography = lightTheme.extension<AppTypography>();
      expect(typography, isNotNull);
      expect(typography!.medium14.fontSize, AppTypography.instance.medium14.fontSize);
    });
  });

  group('darkTheme', () {
    test('has dark brightness', () {
      expect(darkTheme.brightness, Brightness.dark);
    });

    test('uses Manrope font family', () {
      expect(darkTheme.textTheme.bodyMedium?.fontFamily, 'Manrope');
    });

    test('includes SemanticColors.dark extension', () {
      final semanticColors = darkTheme.extension<SemanticColors>();
      expect(semanticColors, isNotNull);
      expect(
        semanticColors!.backgroundPrimary,
        SemanticColors.dark.backgroundPrimary,
      );
    });

    test('includes AppTypography extension', () {
      final typography = darkTheme.extension<AppTypography>();
      expect(typography, isNotNull);
      expect(typography!.medium14.fontSize, AppTypography.instance.medium14.fontSize);
    });
  });

  group('SemanticColors', () {
    test('light and dark have different background colors', () {
      expect(
        SemanticColors.light.backgroundPrimary,
        isNot(SemanticColors.dark.backgroundPrimary),
      );
    });

    test('light and dark have different fill colors', () {
      expect(
        SemanticColors.light.fillPrimary,
        isNot(SemanticColors.dark.fillPrimary),
      );
    });

    group('copyWith', () {
      test('updates single color', () {
        const newColor = Color(0xFFFF0000);
        final updated = SemanticColors.light.copyWith(
          backgroundPrimary: newColor,
        );

        expect(updated.backgroundPrimary, newColor);
        expect(updated.backgroundSecondary, SemanticColors.light.backgroundSecondary);
      });

      test('updates multiple colors', () {
        final updated = SemanticColors.light.copyWith(
          backgroundPrimary: const Color(0xFF111111),
          fillPrimary: const Color(0xFF222222),
          borderPrimary: const Color(0xFF333333),
        );

        expect(updated.backgroundPrimary, const Color(0xFF111111));
        expect(updated.fillPrimary, const Color(0xFF222222));
        expect(updated.borderPrimary, const Color(0xFF333333));
      });

      test('preserves accent colors when not specified', () {
        final updated = SemanticColors.light.copyWith(
          backgroundPrimary: const Color(0xFF999999),
        );

        expect(updated.accent.blue.fill, SemanticColors.light.accent.blue.fill);
      });
    });

    group('lerp', () {
      test('with t=0 returns original colors', () {
        final result = SemanticColors.light.lerp(SemanticColors.dark, 0.0);

        expect(result.backgroundPrimary, SemanticColors.light.backgroundPrimary);
        expect(result.fillPrimary, SemanticColors.light.fillPrimary);
      });

      test('with t=1 returns target colors', () {
        final result = SemanticColors.light.lerp(SemanticColors.dark, 1.0);

        expect(result.backgroundPrimary, SemanticColors.dark.backgroundPrimary);
        expect(result.fillPrimary, SemanticColors.dark.fillPrimary);
      });

      test('with t=0.5 interpolates colors', () {
        final halfway = SemanticColors.light.lerp(SemanticColors.dark, 0.5);

        expect(
          halfway.backgroundPrimary.toARGB32(),
          lessThan(SemanticColors.light.backgroundPrimary.toARGB32()),
        );
        expect(
          halfway.backgroundPrimary.toARGB32(),
          greaterThan(SemanticColors.dark.backgroundPrimary.toARGB32()),
        );
      });

      test('with null other returns this', () {
        final result = SemanticColors.light.lerp(null, 0.5);
        expect(result, SemanticColors.light);
      });
    });
  });

  group('AccentColorSet', () {
    const colorSetA = AccentColorSet(
      fill: Color(0xFF0000FF),
      contentPrimary: Color(0xFF00FF00),
      contentSecondary: Color(0xFFFF0000),
      border: Color(0xFFFFFF00),
    );

    group('copyWith', () {
      test('updates single color', () {
        final updated = colorSetA.copyWith(fill: const Color(0xFFFF00FF));

        expect(updated.fill, const Color(0xFFFF00FF));
        expect(updated.contentPrimary, colorSetA.contentPrimary);
        expect(updated.contentSecondary, colorSetA.contentSecondary);
        expect(updated.border, colorSetA.border);
      });

      test('preserves all colors when called with no args', () {
        final copy = colorSetA.copyWith();

        expect(copy.fill, colorSetA.fill);
        expect(copy.contentPrimary, colorSetA.contentPrimary);
        expect(copy.contentSecondary, colorSetA.contentSecondary);
        expect(copy.border, colorSetA.border);
      });
    });

    group('lerp', () {
      const colorSetB = AccentColorSet(
        fill: Color(0xFFFFFFFF),
        contentPrimary: Color(0xFFFFFFFF),
        contentSecondary: Color(0xFFFFFFFF),
        border: Color(0xFFFFFFFF),
      );

      test('with t=0 returns first set', () {
        final result = AccentColorSet.lerp(colorSetA, colorSetB, 0.0);
        expect(result.fill, colorSetA.fill);
      });

      test('with t=1 returns second set', () {
        final result = AccentColorSet.lerp(colorSetA, colorSetB, 1.0);
        expect(result.fill, colorSetB.fill);
      });

      test('interpolates at midpoint', () {
        final midpoint = AccentColorSet.lerp(colorSetA, colorSetB, 0.5);

        expect(midpoint.fill.toARGB32(), greaterThan(colorSetA.fill.toARGB32()));
        expect(midpoint.fill.toARGB32(), lessThan(colorSetB.fill.toARGB32()));
      });
    });
  });

  group('SemanticAccentColors', () {
    test('all 12 accent colors are defined in light theme', () {
      expect(SemanticColors.light.accent.blue, isNotNull);
      expect(SemanticColors.light.accent.cyan, isNotNull);
      expect(SemanticColors.light.accent.emerald, isNotNull);
      expect(SemanticColors.light.accent.fuchsia, isNotNull);
      expect(SemanticColors.light.accent.indigo, isNotNull);
      expect(SemanticColors.light.accent.lime, isNotNull);
      expect(SemanticColors.light.accent.orange, isNotNull);
      expect(SemanticColors.light.accent.rose, isNotNull);
      expect(SemanticColors.light.accent.sky, isNotNull);
      expect(SemanticColors.light.accent.teal, isNotNull);
      expect(SemanticColors.light.accent.violet, isNotNull);
      expect(SemanticColors.light.accent.amber, isNotNull);
    });

    test('light and dark accent fills differ', () {
      expect(
        SemanticColors.light.accent.blue.fill,
        isNot(SemanticColors.dark.accent.blue.fill),
      );
    });

    test('lerp transitions accent colors', () {
      final midway = SemanticAccentColors.lerp(
        SemanticColors.light.accent,
        SemanticColors.dark.accent,
        0.5,
      );

      expect(
        midway.blue.fill.toARGB32(),
        lessThan(SemanticColors.light.accent.blue.fill.toARGB32()),
      );
      expect(
        midway.blue.fill.toARGB32(),
        greaterThan(SemanticColors.dark.accent.blue.fill.toARGB32()),
      );
    });
  });

  group('SemanticColorsExtension', () {
    testWidgets('provides colors via BuildContext in light theme', (tester) async {
      late SemanticColors colors;

      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                colors = context.colors;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(colors.backgroundPrimary, SemanticColors.light.backgroundPrimary);
    });

    testWidgets('provides colors via BuildContext in dark theme', (tester) async {
      late SemanticColors colors;

      await tester.pumpWidget(
        MaterialApp(
          theme: darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                colors = context.colors;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(colors.backgroundPrimary, SemanticColors.dark.backgroundPrimary);
    });

    testWidgets('falls back to light when extension missing', (tester) async {
      late SemanticColors colors;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                colors = context.colors;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(colors.backgroundPrimary, SemanticColors.light.backgroundPrimary);
    });
  });

  group('AppTypographyExtension', () {
    testWidgets('provides typography via BuildContext in light theme', (tester) async {
      late AppTypography typography;

      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                typography = context.typography;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(typography, isNotNull);
      expect(typography.medium14.fontSize, AppTypography.instance.medium14.fontSize);
    });

    testWidgets('provides typography via BuildContext in dark theme', (tester) async {
      late AppTypography typography;

      await tester.pumpWidget(
        MaterialApp(
          theme: darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                typography = context.typography;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(typography, isNotNull);
      expect(typography.medium14.fontSize, AppTypography.instance.medium14.fontSize);
    });

    testWidgets('falls back to instance when extension missing', (tester) async {
      late AppTypography typography;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                typography = context.typography;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(typography, isNotNull);
      expect(typography.medium14.fontSize, AppTypography.instance.medium14.fontSize);
    });

    testWidgets('typographyScaled applies ScreenUtil scaling in light theme', (tester) async {
      late AppTypography scaled;

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: testDesignSize,
          builder: (context, child) {
            return MaterialApp(
              theme: lightTheme,
              home: Scaffold(
                body: Builder(
                  builder: (context) {
                    scaled = context.typographyScaled;
                    return const SizedBox();
                  },
                ),
              ),
            );
          },
        ),
      );

      expect(scaled.medium14.fontSize, 14.sp);
      expect(scaled.bold24.fontSize, 24.sp);
    });

    testWidgets('typographyScaled applies ScreenUtil scaling in dark theme', (tester) async {
      late AppTypography scaled;

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: testDesignSize,
          builder: (context, child) {
            return MaterialApp(
              theme: darkTheme,
              home: Scaffold(
                body: Builder(
                  builder: (context) {
                    scaled = context.typographyScaled;
                    return const SizedBox();
                  },
                ),
              ),
            );
          },
        ),
      );

      expect(scaled.medium14.fontSize, 14.sp);
      expect(scaled.bold24.fontSize, 24.sp);
    });
  });
}
