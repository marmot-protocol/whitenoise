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

      final container = tester.widget<Container>(find.byKey(const Key('neutral_placeholder')));
      expect(container.constraints?.maxWidth, 100);
      expect(container.constraints?.maxHeight, 150);
    });

    testWidgets('uses default height when not provided', (tester) async {
      await mountWidget(const WnBlurhashPlaceholder(), tester);

      final container = tester.widget<Container>(find.byKey(const Key('neutral_placeholder')));
      expect(container.constraints?.maxHeight, 200);
    });
  });
}
