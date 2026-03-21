import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/widgets/wn_blurhash_placeholder.dart';

import '../test_helpers.dart';

void main() {
  group('WnBlurhashPlaceholder', () {
    testWidgets('renders neutral placeholder when blurhash is null', (tester) async {
      await mountWidget(const WnBlurhashPlaceholder(), tester);

      expect(find.byKey(const Key('neutral_placeholder')), findsOneWidget);
      expect(find.byKey(const Key('blurhash_placeholder')), findsNothing);
    });

    testWidgets('renders neutral placeholder when blurhash is empty', (tester) async {
      await mountWidget(const WnBlurhashPlaceholder(blurhash: ''), tester);

      expect(find.byKey(const Key('neutral_placeholder')), findsOneWidget);
      expect(find.byKey(const Key('blurhash_placeholder')), findsNothing);
    });

    testWidgets('renders blurhash when provided', (tester) async {
      await mountWidget(
        const WnBlurhashPlaceholder(blurhash: 'LEHV6nWB2yk8pyo0adR*.7kCMdnj'),
        tester,
      );

      expect(find.byKey(const Key('blurhash_placeholder')), findsOneWidget);
      expect(find.byKey(const Key('neutral_placeholder')), findsNothing);
      expect(find.byType(BlurHash), findsOneWidget);
    });

    testWidgets('uses provided width and height', (tester) async {
      await mountWidget(
        const WnBlurhashPlaceholder(width: 100, height: 150),
        tester,
      );

      final sizedBox = tester.widget<SizedBox>(find.byKey(const Key('neutral_placeholder')));
      expect(sizedBox.width, 100);
      expect(sizedBox.height, 150);
    });

    testWidgets('expands to fill available space when no dimensions provided', (tester) async {
      await mountWidget(
        const SizedBox(
          width: 200,
          height: 200,
          child: WnBlurhashPlaceholder(),
        ),
        tester,
      );

      expect(find.byKey(const Key('neutral_placeholder')), findsOneWidget);
      final sizedBox = tester.widget<SizedBox>(find.byKey(const Key('neutral_placeholder')));
      expect(sizedBox.width, double.infinity);
      expect(sizedBox.height, double.infinity);
      final renderBox = tester.renderObject<RenderBox>(
        find.byKey(const Key('neutral_placeholder')),
      );
      expect(renderBox.size, const Size(200, 200));
    });

    testWidgets('uses default height when only width is provided', (tester) async {
      await mountWidget(const WnBlurhashPlaceholder(width: 100), tester);

      final sizedBox = tester.widget<SizedBox>(find.byKey(const Key('neutral_placeholder')));
      expect(sizedBox.width, 100);
      expect(sizedBox.height, greaterThan(0));
    });

    testWidgets('blurhash expands when no dimensions provided', (tester) async {
      await mountWidget(
        const SizedBox(
          width: 150,
          height: 150,
          child: WnBlurhashPlaceholder(blurhash: 'LEHV6nWB2yk8pyo0adR*.7kCMdnj'),
        ),
        tester,
      );

      expect(find.byType(BlurHash), findsOneWidget);
      final renderBox = tester.renderObject<RenderBox>(find.byType(BlurHash));
      expect(renderBox.size, const Size(150, 150));
    });
  });
}
