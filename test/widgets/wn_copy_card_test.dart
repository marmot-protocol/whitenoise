import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/widgets/wn_copy_card.dart';
import 'package:whitenoise/widgets/wn_middle_ellipsis_text.dart';
import '../mocks/mock_clipboard.dart';
import '../test_helpers.dart';

void main() {
  group('WnCopyCard', () {
    testWidgets('displays text', (tester) async {
      await mountWidget(
        const WnCopyCard(textToDisplay: 'npub1abc123', textToCopy: 'npub1abc123'),
        tester,
      );
      expect(find.text('npub1abc123'), findsOneWidget);
    });

    testWidgets('displays copy icon', (tester) async {
      await mountWidget(
        const WnCopyCard(textToDisplay: 'test', textToCopy: 'test'),
        tester,
      );
      expect(find.byKey(const Key('copy_icon')), findsOneWidget);
    });

    testWidgets('shows up to 2 lines', (tester) async {
      await mountWidget(
        const WnCopyCard(textToDisplay: 'my text', textToCopy: 'copy my text'),
        tester,
      );
      final textWidget = tester.widget<WnMiddleEllipsisText>(find.byType(WnMiddleEllipsisText));
      expect(textWidget.maxLines, 2);
    });

    group('snapToWords', () {
      testWidgets('defaults to false', (tester) async {
        await mountWidget(
          const WnCopyCard(textToDisplay: testNpubA, textToCopy: testNpubA),
          tester,
        );
        final ellipsis = tester.widget<WnMiddleEllipsisText>(
          find.byType(WnMiddleEllipsisText),
        );
        expect(ellipsis.snapToWords, isFalse);
      });

      testWidgets('forwards true to WnMiddleEllipsisText', (tester) async {
        await mountWidget(
          const WnCopyCard(textToDisplay: testNpubA, textToCopy: testNpubA, snapToWords: true),
          tester,
        );
        final ellipsis = tester.widget<WnMiddleEllipsisText>(
          find.byType(WnMiddleEllipsisText),
        );
        expect(ellipsis.snapToWords, isTrue);
      });
    });

    group('copy functionality', () {
      late String? Function() getClipboard;

      setUp(() {
        getClipboard = mockClipboard();
      });

      testWidgets('copies text to clipboard on tap', (tester) async {
        await mountWidget(
          const WnCopyCard(textToDisplay: 'npub1abc123', textToCopy: 'copiable npub'),
          tester,
        );
        await tester.tap(find.byKey(const Key('copy_button')));
        expect(getClipboard(), 'copiable npub');
      });

      testWidgets('calls onCopySuccess callback after copying', (tester) async {
        var onCopySuccessCalled = false;
        await mountWidget(
          WnCopyCard(
            textToDisplay: 'test',
            textToCopy: 'test',
            onCopySuccess: () => onCopySuccessCalled = true,
          ),
          tester,
        );
        await tester.tap(find.byKey(const Key('copy_button')));
        await tester.pumpAndSettle();
        expect(onCopySuccessCalled, isTrue);
      });

      testWidgets('works without onCopySuccess callback', (tester) async {
        await mountWidget(
          const WnCopyCard(textToDisplay: 'test', textToCopy: 'test'),
          tester,
        );
        await tester.tap(find.byKey(const Key('copy_button')));
        expect(getClipboard(), 'test');
      });

      testWidgets('calls onCopyError when copy fails', (tester) async {
        mockClipboardFailing();
        addTearDown(clearClipboardMock);
        var onCopyErrorCalled = false;
        await mountWidget(
          WnCopyCard(
            textToDisplay: 'test',
            textToCopy: 'test',
            onCopyError: () => onCopyErrorCalled = true,
          ),
          tester,
        );
        await tester.tap(find.byKey(const Key('copy_button')));
        await tester.pumpAndSettle();
        expect(onCopyErrorCalled, isTrue);
      });
    });
  });
}
