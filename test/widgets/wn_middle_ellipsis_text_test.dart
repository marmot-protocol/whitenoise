import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/widgets/wn_middle_ellipsis_text.dart';
import '../test_helpers.dart';

void main() {
  group('WnMiddleEllipsisText', () {
    const longText = 'npub1zuuajd7u3sx8xu92yav9jwxpr839cs0kc3q6t56vd5u9q033xmhsk6c2uc';
    const last8Chars = 'hsk6c2uc';

    Future<void> pump(
      WidgetTester tester, {
      required String text,
      double width = 390,
      int maxLines = 1,
      int suffixLength = 8,
      TextStyle? style,
      bool snapToWords = false,
    }) async {
      await mountWidget(
        SizedBox(
          width: width,
          child: WnMiddleEllipsisText(
            text: text,
            maxLines: maxLines,
            suffixLength: suffixLength,
            style: style,
            snapToWords: snapToWords,
          ),
        ),
        tester,
      );
    }

    group('without truncation', () {
      testWidgets('displays full text when it fits', (tester) async {
        const shortText = 'short text';
        await pump(tester, text: shortText);
        expect(find.text(shortText), findsOneWidget);
      });

      testWidgets('displays full text when container is wide enough', (tester) async {
        await pump(tester, text: longText, width: 350, maxLines: 4);
        expect(find.text(longText), findsOneWidget);
      });

      testWidgets('returns full text when truncated would not be shorter', (tester) async {
        const mediumText = 'medium length text';
        await pump(tester, text: mediumText, width: 300, maxLines: 2);
        final textWidget = tester.widget<Text>(find.byType(Text));
        expect(textWidget.data, mediumText);
      });

      testWidgets('omits ellipsis when text fits', (tester) async {
        const mediumText = 'medium length text';
        await pump(tester, text: mediumText, width: 300, maxLines: 2);
        final textWidget = tester.widget<Text>(find.byType(Text));
        expect(textWidget.data!.contains('...'), isFalse);
      });
    });

    group('with truncation', () {
      testWidgets('adds ellipsis when text does not fit', (tester) async {
        await pump(tester, text: longText, width: 200);
        final textWidget = tester.widget<Text>(find.byType(Text));
        expect(textWidget.data!.contains('...'), isTrue);
      });

      testWidgets('shortens displayed text when truncated', (tester) async {
        await pump(tester, text: longText, width: 200);
        final textWidget = tester.widget<Text>(find.byType(Text));
        expect(textWidget.data!.length, lessThan(longText.length));
      });

      testWidgets('preserves suffix when truncating', (tester) async {
        await pump(tester, text: longText, width: 200);
        final textWidget = tester.widget<Text>(find.byType(Text));
        expect(textWidget.data!.endsWith(last8Chars), isTrue);
      });

      testWidgets('uses custom suffix length', (tester) async {
        const customSuffixLength = 4;
        final last4Chars = longText.substring(longText.length - 4);
        await pump(
          tester,
          text: longText,
          width: 200,
          suffixLength: customSuffixLength,
        );
        final textWidget = tester.widget<Text>(find.byType(Text));
        expect(textWidget.data!.endsWith(last4Chars), isTrue);
      });
    });

    group('snapToWords', () {
      testWidgets('defaults to false', (tester) async {
        await pump(tester, text: 'word1 word2', width: 100);
        final ellipsis = tester.widget<WnMiddleEllipsisText>(find.byType(WnMiddleEllipsisText));
        expect(ellipsis.snapToWords, isFalse);
      });

      testWidgets('cuts mid-word without snapToWords', (tester) async {
        const text = 'alpha bravo charlie delta echo foxtrot golf hotel';
        await pump(tester, text: text, width: 280, suffixLength: 5);
        final displayed = tester.widget<Text>(find.byType(Text)).data!;

        expect(displayed, 'alpha bra ... hotel');
      });

      testWidgets('preserves prefix for space-free strings', (tester) async {
        await pump(tester, text: longText, width: 200, snapToWords: true);
        final displayed = tester.widget<Text>(find.byType(Text)).data!;

        expect(displayed.contains('...'), isTrue);
        expect(displayed, isNot(' ... $last8Chars'));
      });
    });

    group('maxLines', () {
      testWidgets('defaults to maxLines 1', (tester) async {
        await pump(tester, text: longText, width: 200);
        final textWidget = tester.widget<Text>(find.byType(Text));
        expect(textWidget.maxLines, 1);
      });

      testWidgets('respects maxLines 2', (tester) async {
        await pump(tester, text: longText, width: 200, maxLines: 2);
        final textWidget = tester.widget<Text>(find.byType(Text));
        expect(textWidget.maxLines, 2);
      });

      testWidgets('shows more text with maxLines 2 than maxLines 1', (tester) async {
        await pump(tester, text: longText, width: 200);
        final displayedText1 = tester.widget<Text>(find.byType(Text)).data!;

        await pump(tester, text: longText, width: 200, maxLines: 2);
        final displayedText2 = tester.widget<Text>(find.byType(Text)).data!;

        expect(displayedText2.length, greaterThan(displayedText1.length));
      });
    });

    group('style', () {
      testWidgets('displays full text when style has no fontFamily (theme inherits)', (
        tester,
      ) async {
        const mediumText = 'medium length text';
        const styleWithoutFontFamily = TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        );
        await pump(
          tester,
          text: mediumText,
          width: 300,
          maxLines: 2,
          style: styleWithoutFontFamily,
        );
        final textWidget = tester.widget<Text>(find.byType(Text));
        expect(textWidget.data, mediumText);
        expect(textWidget.data!.contains('...'), isFalse);
      });

      testWidgets('applies provided style', (tester) async {
        const testStyle = TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.red,
        );
        await pump(
          tester,
          text: 'styled text',
          style: testStyle,
        );
        final textWidget = tester.widget<Text>(find.byType(Text));
        expect(textWidget.style, testStyle);
      });

      testWidgets('works without style', (tester) async {
        await pump(tester, text: 'unstyled text');
        expect(find.text('unstyled text'), findsOneWidget);
      });
    });

    group('edge cases', () {
      testWidgets('handles empty text', (tester) async {
        await pump(tester, text: '', width: 200);
        expect(find.text(''), findsOneWidget);
      });

      testWidgets('handles text shorter than suffix length', (tester) async {
        const shortText = 'abc';
        await pump(tester, text: shortText, width: 5, suffixLength: 10);
        final textWidget = tester.widget<Text>(find.byType(Text));
        expect(textWidget.data!.contains('...'), isTrue);
      });

      testWidgets('handles very narrow container', (tester) async {
        await pump(tester, text: longText, width: 30);
        final textWidget = tester.widget<Text>(find.byType(Text));
        expect(textWidget.data!.contains('...'), isTrue);
      });

      testWidgets('handles suffixLength 0', (tester) async {
        await pump(
          tester,
          text: longText,
          width: 100,
          suffixLength: 0,
        );
        final textWidget = tester.widget<Text>(find.byType(Text));
        expect(textWidget.data!.contains('...'), isTrue);
        expect(textWidget.data!.endsWith(' ... '), isTrue);
      });

      testWidgets('asserts when suffixLength is negative', (tester) async {
        await expectLater(
          pump(tester, text: longText, suffixLength: -1),
          throwsAssertionError,
        );
      });
    });
  });
}
