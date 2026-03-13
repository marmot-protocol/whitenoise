import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/widgets/wn_logo_slogan.dart';

import '../test_helpers.dart';

void main() {
  group('WnLogoSlogan', () {
    testWidgets('renders logo with key', (tester) async {
      await mountWidget(
        const WnLogoSlogan(
          texts: ['First', 'Second', 'Third'],
        ),
        tester,
      );

      expect(find.byKey(const ValueKey('whitenoise_logo')), findsOneWidget);
    });

    group('slogan', () {
      testWidgets('shows first slogan initially', (tester) async {
        await mountWidget(
          const WnLogoSlogan(
            texts: ['First', 'Second', 'Third'],
          ),
          tester,
        );

        expect(find.text('First'), findsOneWidget);
      });

      testWidgets('rotates to next slogan after interval', (tester) async {
        await mountWidget(
          const WnLogoSlogan(
            texts: ['First', 'Second', 'Third'],
          ),
          tester,
        );

        await tester.pump(const Duration(seconds: 3));
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('Second'), findsOneWidget);
      });

      testWidgets('cycles back to first slogan after all shown', (tester) async {
        await mountWidget(
          const WnLogoSlogan(
            texts: ['First', 'Second', 'Third'],
          ),
          tester,
        );

        await tester.pump(const Duration(seconds: 3));
        await tester.pump(const Duration(milliseconds: 500));

        await tester.pump(const Duration(seconds: 3));
        await tester.pump(const Duration(milliseconds: 500));

        await tester.pump(const Duration(seconds: 3));
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('First'), findsOneWidget);
      });
    });
  });
}
