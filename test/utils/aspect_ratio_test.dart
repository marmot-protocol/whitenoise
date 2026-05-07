import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/utils/aspect_ratio.dart';

void main() {
  group('getAspectRatioFromDimensions', () {
    group('returns null', () {
      test('with null input', () {
        expect(getAspectRatioFromDimensions(null), isNull);
      });

      test('with empty string', () {
        expect(getAspectRatioFromDimensions(''), isNull);
      });

      test('with missing separator', () {
        expect(getAspectRatioFromDimensions('1920'), isNull);
      });

      test('with more than two parts', () {
        expect(getAspectRatioFromDimensions('1920x1080x10'), isNull);
      });

      test('with non-numeric width', () {
        expect(getAspectRatioFromDimensions('foox1080'), isNull);
      });

      test('with non-numeric height', () {
        expect(getAspectRatioFromDimensions('1920xbar'), isNull);
      });

      test('with zero width', () {
        expect(getAspectRatioFromDimensions('0x1080'), isNull);
      });

      test('with zero height', () {
        expect(getAspectRatioFromDimensions('1920x0'), isNull);
      });

      test('with negative width', () {
        expect(getAspectRatioFromDimensions('-1920x1080'), isNull);
      });

      test('with negative height', () {
        expect(getAspectRatioFromDimensions('1920x-1080'), isNull);
      });
    });

    group('returns aspect ratio', () {
      test('for landscape dimensions', () {
        expect(getAspectRatioFromDimensions('1920x1080'), 1920 / 1080);
      });

      test('for portrait dimensions', () {
        expect(getAspectRatioFromDimensions('1080x1920'), 1080 / 1920);
      });

      test('for square dimensions', () {
        expect(getAspectRatioFromDimensions('500x500'), 1.0);
      });

      test('for decimal dimensions', () {
        expect(getAspectRatioFromDimensions('100.5x50.25'), 100.5 / 50.25);
      });
    });
  });
}
