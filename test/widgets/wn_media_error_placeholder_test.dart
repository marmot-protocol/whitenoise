import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/widgets/wn_media_error_placeholder.dart';

import '../test_helpers.dart';

void main() {
  group('WnMediaErrorPlaceholder', () {
    testWidgets('renders overlay with retry icon', (tester) async {
      await mountWidget(WnMediaErrorPlaceholder(onRetry: () {}), tester);

      expect(find.byKey(const Key('retry_button')), findsOneWidget);
      expect(find.byKey(const Key('error_overlay')), findsOneWidget);
      expect(find.byKey(const Key('retry_icon')), findsOneWidget);
    });

    testWidgets('calls onRetry when tapped', (tester) async {
      var retryCalled = false;
      await mountWidget(WnMediaErrorPlaceholder(onRetry: () => retryCalled = true), tester);

      await tester.tap(find.byKey(const Key('retry_button')));

      expect(retryCalled, isTrue);
    });

    testWidgets('uses provided width and height', (tester) async {
      await mountWidget(
        WnMediaErrorPlaceholder(onRetry: () {}, width: 200, height: 150),
        tester,
      );

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, 200);
      expect(sizedBox.height, 150);
    });

    testWidgets('uses default height when not provided', (tester) async {
      await mountWidget(WnMediaErrorPlaceholder(onRetry: () {}), tester);

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.height, 200);
    });

    testWidgets('shows blurhash placeholder when blurhash is provided', (tester) async {
      await mountWidget(
        WnMediaErrorPlaceholder(
          onRetry: () {},
          blurhash: 'LEHV6nWB2yk8pyo0adR*.7kCMdnj',
        ),
        tester,
      );

      expect(find.byKey(const Key('blurhash_placeholder')), findsOneWidget);
      expect(find.byKey(const Key('retry_button')), findsOneWidget);
    });

    testWidgets('shows neutral placeholder when blurhash is null', (tester) async {
      await mountWidget(WnMediaErrorPlaceholder(onRetry: () {}), tester);

      expect(find.byKey(const Key('neutral_placeholder')), findsOneWidget);
      expect(find.byKey(const Key('retry_button')), findsOneWidget);
    });

    testWidgets('shows thumbhash placeholder when thumbHash is provided', (tester) async {
      await mountWidget(
        WnMediaErrorPlaceholder(
          onRetry: () {},
          thumbHash: 'YJqGPQw7sFlslqhFafSE+Q6oJ1h2iHB2Rw==',
        ),
        tester,
      );

      expect(find.byKey(const Key('thumbhash_placeholder')), findsOneWidget);
      expect(find.byKey(const Key('retry_button')), findsOneWidget);
    });

    testWidgets('prefers thumbhash over blurhash when both provided', (tester) async {
      await mountWidget(
        WnMediaErrorPlaceholder(
          onRetry: () {},
          thumbHash: 'YJqGPQw7sFlslqhFafSE+Q6oJ1h2iHB2Rw==',
          blurhash: 'LEHV6nWB2yk8pyo0adR*.7kCMdnj',
        ),
        tester,
      );

      expect(find.byKey(const Key('thumbhash_placeholder')), findsOneWidget);
      expect(find.byKey(const Key('blurhash_placeholder')), findsNothing);
      expect(find.byKey(const Key('retry_button')), findsOneWidget);
    });
  });
}
