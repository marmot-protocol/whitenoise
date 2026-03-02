import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/theme/app_typography.dart';
import '../test_helpers.dart';

void main() {
  group('AppTypography', () {
    const typography = AppTypography.instance;

    group('text style definitions', () {
      test('96px styles have correct properties', () {
        expect(typography.medium96.fontSize, 96);
        expect(typography.medium96.height, 104 / 96);
        expect(typography.medium96.letterSpacing, -1.5);
        expect(typography.medium96.fontWeight, FontWeight.w500);
        expect(typography.medium96.fontFamily, isNull);
        expect(typography.medium96.leadingDistribution, TextLeadingDistribution.even);

        expect(typography.semiBold96.fontWeight, FontWeight.w600);
        expect(typography.bold96.fontWeight, FontWeight.w700);
      });

      test('72px styles have correct properties', () {
        expect(typography.medium72.fontSize, 72);
        expect(typography.medium72.height, 80 / 72);
        expect(typography.medium72.letterSpacing, -1.2);
        expect(typography.medium72.fontWeight, FontWeight.w500);

        expect(typography.semiBold72.fontWeight, FontWeight.w600);
        expect(typography.bold72.fontWeight, FontWeight.w700);
      });

      test('60px styles have correct properties', () {
        expect(typography.medium60.fontSize, 60);
        expect(typography.medium60.height, 68 / 60);
        expect(typography.medium60.letterSpacing, -1.0);
        expect(typography.medium60.fontWeight, FontWeight.w500);

        expect(typography.semiBold60.fontWeight, FontWeight.w600);
        expect(typography.bold60.fontWeight, FontWeight.w700);
      });

      test('48px styles have correct properties', () {
        expect(typography.medium48.fontSize, 48);
        expect(typography.medium48.height, 56 / 48);
        expect(typography.medium48.letterSpacing, -0.6);
        expect(typography.medium48.fontWeight, FontWeight.w500);

        expect(typography.semiBold48.fontWeight, FontWeight.w600);
        expect(typography.bold48.fontWeight, FontWeight.w700);
      });

      test('36px styles have correct properties', () {
        expect(typography.medium36.fontSize, 36);
        expect(typography.medium36.height, 44 / 36);
        expect(typography.medium36.letterSpacing, -0.4);
        expect(typography.medium36.fontWeight, FontWeight.w500);

        expect(typography.semiBold36.fontWeight, FontWeight.w600);
        expect(typography.bold36.fontWeight, FontWeight.w700);
      });

      test('32px styles have correct properties', () {
        expect(typography.medium32.fontSize, 32);
        expect(typography.medium32.height, 38 / 32);
        expect(typography.medium32.letterSpacing, -0.3);
        expect(typography.medium32.fontWeight, FontWeight.w500);

        expect(typography.semiBold32.fontWeight, FontWeight.w600);
        expect(typography.bold32.fontWeight, FontWeight.w700);
      });

      test('28px styles have correct properties', () {
        expect(typography.medium28.fontSize, 28);
        expect(typography.medium28.height, 34 / 28);
        expect(typography.medium28.letterSpacing, -0.2);
        expect(typography.medium28.fontWeight, FontWeight.w500);

        expect(typography.semiBold28.fontWeight, FontWeight.w600);
        expect(typography.bold28.fontWeight, FontWeight.w700);
      });

      test('24px styles have correct properties', () {
        expect(typography.medium24.fontSize, 24);
        expect(typography.medium24.height, 30 / 24);
        expect(typography.medium24.letterSpacing, -0.1);
        expect(typography.medium24.fontWeight, FontWeight.w500);

        expect(typography.semiBold24.fontWeight, FontWeight.w600);
        expect(typography.bold24.fontWeight, FontWeight.w700);
      });

      test('20px styles have correct properties', () {
        expect(typography.medium20.fontSize, 20);
        expect(typography.medium20.height, 26 / 20);
        expect(typography.medium20.letterSpacing, 0);
        expect(typography.medium20.fontWeight, FontWeight.w500);

        expect(typography.semiBold20.fontWeight, FontWeight.w600);
        expect(typography.bold20.fontWeight, FontWeight.w700);
      });

      test('18px styles have correct properties', () {
        expect(typography.medium18.fontSize, 18);
        expect(typography.medium18.height, 24 / 18);
        expect(typography.medium18.letterSpacing, 0.1);
        expect(typography.medium18.fontWeight, FontWeight.w500);

        expect(typography.semiBold18.fontWeight, FontWeight.w600);
        expect(typography.bold18.fontWeight, FontWeight.w700);
      });

      test('16px styles have correct properties', () {
        expect(typography.medium16.fontSize, 16);
        expect(typography.medium16.height, 22 / 16);
        expect(typography.medium16.letterSpacing, 0.2);
        expect(typography.medium16.fontWeight, FontWeight.w500);

        expect(typography.semiBold16.fontWeight, FontWeight.w600);
        expect(typography.bold16.fontWeight, FontWeight.w700);
      });

      test('14px styles have correct properties', () {
        expect(typography.medium14.fontSize, 14);
        expect(typography.medium14.height, 18 / 14);
        expect(typography.medium14.letterSpacing, 0.4);
        expect(typography.medium14.fontWeight, FontWeight.w500);

        expect(typography.semiBold14.fontWeight, FontWeight.w600);
        expect(typography.bold14.fontWeight, FontWeight.w700);
      });

      test('16px compact styles have correct properties', () {
        expect(typography.medium16Compact.fontSize, 16);
        expect(typography.medium16Compact.height, 18 / 16);
        expect(typography.medium16Compact.letterSpacing, 0.2);
        expect(typography.medium16Compact.fontWeight, FontWeight.w500);

        expect(typography.semiBold16Compact.fontWeight, FontWeight.w600);
        expect(typography.bold16Compact.fontWeight, FontWeight.w700);
      });

      test('14px compact styles have correct properties', () {
        expect(typography.medium14Compact.fontSize, 14);
        expect(typography.medium14Compact.height, 16 / 14);
        expect(typography.medium14Compact.letterSpacing, 0.4);
        expect(typography.medium14Compact.fontWeight, FontWeight.w500);

        expect(typography.semiBold14Compact.fontWeight, FontWeight.w600);
        expect(typography.bold14Compact.fontWeight, FontWeight.w700);
      });

      test('12px styles have correct properties', () {
        expect(typography.medium12.fontSize, 12);
        expect(typography.medium12.height, 16 / 12);
        expect(typography.medium12.letterSpacing, 0.6);
        expect(typography.medium12.fontWeight, FontWeight.w500);

        expect(typography.semiBold12.fontWeight, FontWeight.w600);
        expect(typography.bold12.fontWeight, FontWeight.w700);
      });

      test('12px compact styles have correct properties', () {
        expect(typography.medium12Compact.fontSize, 12);
        expect(typography.medium12Compact.height, 13 / 12);
        expect(typography.medium12Compact.letterSpacing, 0.6);
        expect(typography.medium12Compact.fontWeight, FontWeight.w500);

        expect(typography.semiBold12Compact.fontWeight, FontWeight.w600);
        expect(typography.bold12Compact.fontWeight, FontWeight.w700);
      });

      test('10px styles have correct properties', () {
        expect(typography.medium10.fontSize, 10);
        expect(typography.medium10.height, 14 / 10);
        expect(typography.medium10.letterSpacing, 0.8);
        expect(typography.medium10.fontWeight, FontWeight.w500);

        expect(typography.semiBold10.fontWeight, FontWeight.w600);
        expect(typography.bold10.fontWeight, FontWeight.w700);
      });

      test('all styles use vertical trim (even leading distribution)', () {
        expect(typography.medium96.leadingDistribution, TextLeadingDistribution.even);
        expect(typography.medium14.leadingDistribution, TextLeadingDistribution.even);
        expect(typography.medium12.leadingDistribution, TextLeadingDistribution.even);
        expect(typography.medium10.leadingDistribution, TextLeadingDistribution.even);
        expect(typography.bold24.leadingDistribution, TextLeadingDistribution.even);
      });
    });

    group('copyWith', () {
      test('updates single style', () {
        const newStyle = TextStyle(fontSize: 100, fontWeight: FontWeight.w900);
        final updated = typography.copyWith(medium96: newStyle);

        expect(updated.medium96, newStyle);
        expect(updated.semiBold96, typography.semiBold96);
        expect(updated.medium14, typography.medium14);
      });

      test('updates multiple styles', () {
        const newStyle96 = TextStyle(fontSize: 100);
        const newStyle14 = TextStyle(fontSize: 20);
        final updated = typography.copyWith(medium96: newStyle96, medium14: newStyle14);

        expect(updated.medium96, newStyle96);
        expect(updated.medium14, newStyle14);
      });

      test('with no arguments returns equivalent instance', () {
        final updated = typography.copyWith();

        expect(updated.medium96.fontSize, typography.medium96.fontSize);
        expect(updated.medium14.fontSize, typography.medium14.fontSize);
        expect(updated.bold12.fontWeight, typography.bold12.fontWeight);
      });
    });

    group('lerp', () {
      test('with t=0 returns original styles', () {
        final other = typography.copyWith(
          medium96: const TextStyle(fontSize: 200, fontWeight: FontWeight.w900),
        );
        final result = typography.lerp(other, 0.0);

        expect(result.medium96.fontSize, typography.medium96.fontSize);
      });

      test('with t=1 returns target styles', () {
        final other = typography.copyWith(
          medium96: const TextStyle(fontSize: 200, fontWeight: FontWeight.w900),
        );
        final result = typography.lerp(other, 1.0);

        expect(result.medium96.fontSize, 200);
      });

      test('with null other returns this', () {
        final result = typography.lerp(null, 0.5);
        expect(result, typography);
      });

      test('interpolates all style properties', () {
        final other = typography.copyWith(
          medium14: typography.medium14.copyWith(fontSize: 28),
          bold12: typography.bold12.copyWith(fontSize: 24),
        );
        final halfway = typography.lerp(other, 0.5);

        expect(halfway.medium14.fontSize, closeTo((14 + 28) / 2, 0.01));
        expect(halfway.bold12.fontSize, closeTo((12 + 24) / 2, 0.01));
      });
    });
  });

  group('AppTypographyExtension', () {
    testWidgets('returns AppTypography from theme', (tester) async {
      late AppTypography typography;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: const [AppTypography.instance]),
          home: Builder(
            builder: (context) {
              typography = context.typography;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(typography.medium14.fontSize, AppTypography.instance.medium14.fontSize);
    });

    testWidgets('returns instance as fallback when extension is missing', (tester) async {
      late AppTypography typography;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(),
          home: Builder(
            builder: (context) {
              typography = context.typography;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(typography.medium14.fontSize, AppTypography.instance.medium14.fontSize);
    });

    testWidgets('typographyScaled applies ScreenUtil scaling', (tester) async {
      late AppTypography scaled;

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: testDesignSize,
          builder: (context, child) {
            return MaterialApp(
              theme: ThemeData(extensions: const [AppTypography.instance]),
              home: Builder(
                builder: (context) {
                  scaled = context.typographyScaled;
                  return const SizedBox();
                },
              ),
            );
          },
        ),
      );

      expect(scaled.medium14.fontSize, 14.sp);
      expect(scaled.bold24.fontSize, 24.sp);
      expect(scaled.semiBold96.fontSize, 96.sp);
      expect(scaled.medium10.fontSize, 10.sp);
    });
  });
}
