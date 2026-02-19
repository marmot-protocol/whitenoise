import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/widgets/wn_media_thumbnail.dart';

import '../test_helpers.dart';

void main() {
  group('WnMediaThumbnail', () {
    testWidgets('renders child widget', (tester) async {
      await mountWidget(
        WnMediaThumbnail(
          child: Container(
            key: const Key('test_child'),
            color: Colors.red,
          ),
        ),
        tester,
      );

      expect(find.byKey(const Key('thumbnail_container')), findsOneWidget);
      expect(find.byKey(const Key('test_child')), findsOneWidget);
    });

    testWidgets('renders medium size by default (44px)', (tester) async {
      await mountWidget(
        const WnMediaThumbnail(child: SizedBox()),
        tester,
      );

      final container = tester.widget<Container>(
        find.byKey(const Key('thumbnail_container')),
      );
      expect(container.constraints?.maxWidth, 44.0);
      expect(container.constraints?.maxHeight, 44.0);
    });

    testWidgets('renders large size (56px)', (tester) async {
      await mountWidget(
        const WnMediaThumbnail(
          size: WnMediaThumbnailSize.large,
          child: SizedBox(),
        ),
        tester,
      );

      final container = tester.widget<Container>(
        find.byKey(const Key('thumbnail_container')),
      );
      expect(container.constraints?.maxWidth, 56.0);
      expect(container.constraints?.maxHeight, 56.0);
    });

    testWidgets('shows border when selected', (tester) async {
      await mountWidget(
        const WnMediaThumbnail(isSelected: true, child: SizedBox()),
        tester,
      );

      final container = tester.widget<Container>(
        find.byKey(const Key('thumbnail_container')),
      );
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.border, isNotNull);
    });

    testWidgets('shows no border when not selected', (tester) async {
      await mountWidget(
        const WnMediaThumbnail(child: SizedBox()),
        tester,
      );

      final container = tester.widget<Container>(
        find.byKey(const Key('thumbnail_container')),
      );
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.border, isNull);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await mountWidget(
        WnMediaThumbnail(
          onTap: () => tapped = true,
          child: const SizedBox(),
        ),
        tester,
      );

      await tester.tap(find.byKey(const Key('thumbnail_container')));
      expect(tapped, isTrue);
    });

    testWidgets('does not crash when onTap is null', (tester) async {
      await mountWidget(
        const WnMediaThumbnail(child: SizedBox()),
        tester,
      );

      await tester.tap(find.byKey(const Key('thumbnail_container')));
      // No exception means success
    });

    testWidgets('clips child with rounded corners', (tester) async {
      await mountWidget(
        const WnMediaThumbnail(child: SizedBox()),
        tester,
      );

      final clipRRect = tester.widget<ClipRRect>(
        find.descendant(
          of: find.byKey(const Key('thumbnail_container')),
          matching: find.byType(ClipRRect),
        ),
      );
      expect(clipRRect.borderRadius, isNotNull);
    });

    testWidgets('large size shows border when selected', (tester) async {
      await mountWidget(
        const WnMediaThumbnail(
          size: WnMediaThumbnailSize.large,
          isSelected: true,
          child: SizedBox(),
        ),
        tester,
      );

      final container = tester.widget<Container>(
        find.byKey(const Key('thumbnail_container')),
      );
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.border, isNotNull);
    });
  });
}
