import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_carousel_indicator.dart';

import '../test_helpers.dart' show mountWidget;

class _TestCarouselWrapper extends HookWidget {
  const _TestCarouselWrapper({
    required this.initialIndex,
    required this.targetIndex,
  });

  final int initialIndex;
  final int targetIndex;

  @override
  Widget build(BuildContext context) {
    final activeIndex = useState(initialIndex);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        WnCarouselIndicator(itemCount: 3, activeIndex: activeIndex.value),
        ElevatedButton(
          onPressed: () => activeIndex.value = targetIndex,
          child: const Text('Change'),
        ),
      ],
    );
  }
}

void main() {
  group('WnCarouselIndicator widget', () {
    group('basic rendering', () {
      testWidgets('renders with required parameters', (tester) async {
        await mountWidget(
          const WnCarouselIndicator(itemCount: 3, activeIndex: 0),
          tester,
        );

        expect(find.byType(WnCarouselIndicator), findsOneWidget);
      });

      testWidgets('renders correct number of indicator items', (tester) async {
        await mountWidget(
          const WnCarouselIndicator(itemCount: 5, activeIndex: 2),
          tester,
        );

        final containers = find.descendant(
          of: find.byType(WnCarouselIndicator),
          matching: find.byType(AnimatedContainer),
        );

        expect(containers, findsNWidgets(5));
      });

      testWidgets('renders single item correctly', (tester) async {
        await mountWidget(
          const WnCarouselIndicator(itemCount: 1, activeIndex: 0),
          tester,
        );

        expect(find.byType(WnCarouselIndicator), findsOneWidget);

        final containers = find.descendant(
          of: find.byType(WnCarouselIndicator),
          matching: find.byType(AnimatedContainer),
        );
        expect(containers, findsOneWidget);
      });

      testWidgets('renders many items correctly', (tester) async {
        await mountWidget(
          const WnCarouselIndicator(itemCount: 10, activeIndex: 5),
          tester,
        );

        final containers = find.descendant(
          of: find.byType(WnCarouselIndicator),
          matching: find.byType(AnimatedContainer),
        );
        expect(containers, findsNWidgets(10));
      });
    });

    group('active index behavior', () {
      testWidgets('first item is active when activeIndex is 0', (tester) async {
        await mountWidget(
          const WnCarouselIndicator(itemCount: 3, activeIndex: 0),
          tester,
        );

        final decoratedBoxes = tester
            .widgetList<DecoratedBox>(
              find.descendant(
                of: find.byType(WnCarouselIndicator),
                matching: find.byType(DecoratedBox),
              ),
            )
            .toList();

        final firstDecoration = decoratedBoxes.first.decoration as BoxDecoration;
        expect(firstDecoration.color, SemanticColors.light.fillPrimary);
      });

      testWidgets('middle item is active when activeIndex is in middle', (tester) async {
        await mountWidget(
          const WnCarouselIndicator(itemCount: 5, activeIndex: 2),
          tester,
        );

        final decoratedBoxes = tester
            .widgetList<DecoratedBox>(
              find.descendant(
                of: find.byType(WnCarouselIndicator),
                matching: find.byType(DecoratedBox),
              ),
            )
            .toList();

        final middleDecoration = decoratedBoxes[2].decoration as BoxDecoration;
        expect(middleDecoration.color, SemanticColors.light.fillPrimary);
      });

      testWidgets('last item is active when activeIndex is last', (tester) async {
        await mountWidget(
          const WnCarouselIndicator(itemCount: 4, activeIndex: 3),
          tester,
        );

        final decoratedBoxes = tester
            .widgetList<DecoratedBox>(
              find.descendant(
                of: find.byType(WnCarouselIndicator),
                matching: find.byType(DecoratedBox),
              ),
            )
            .toList();

        final lastDecoration = decoratedBoxes.last.decoration as BoxDecoration;
        expect(lastDecoration.color, SemanticColors.light.fillPrimary);
      });

      testWidgets('inactive items have secondary fill color', (tester) async {
        await mountWidget(
          const WnCarouselIndicator(itemCount: 3, activeIndex: 1),
          tester,
        );

        final decoratedBoxes = tester
            .widgetList<DecoratedBox>(
              find.descendant(
                of: find.byType(WnCarouselIndicator),
                matching: find.byType(DecoratedBox),
              ),
            )
            .toList();

        final firstDecoration = decoratedBoxes[0].decoration as BoxDecoration;
        final lastDecoration = decoratedBoxes[2].decoration as BoxDecoration;

        expect(firstDecoration.color, SemanticColors.light.fillSecondary);
        expect(lastDecoration.color, SemanticColors.light.fillSecondary);
      });
    });

    group('item sizing', () {
      testWidgets('active item AnimatedContainer has wider width than inactive', (tester) async {
        await mountWidget(
          const WnCarouselIndicator(itemCount: 3, activeIndex: 1),
          tester,
        );

        final containers = tester
            .widgetList<AnimatedContainer>(
              find.descendant(
                of: find.byType(WnCarouselIndicator),
                matching: find.byType(AnimatedContainer),
              ),
            )
            .toList();

        final inactiveWidth = containers[0].constraints?.maxWidth ?? 0;
        final activeWidth = containers[1].constraints?.maxWidth ?? 0;

        expect(activeWidth, greaterThan(inactiveWidth));
      });

      testWidgets('active item is wider than inactive items', (tester) async {
        await mountWidget(
          const WnCarouselIndicator(itemCount: 3, activeIndex: 1),
          tester,
        );

        final containers = tester
            .widgetList<AnimatedContainer>(
              find.descendant(
                of: find.byType(WnCarouselIndicator),
                matching: find.byType(AnimatedContainer),
              ),
            )
            .toList();

        final firstWidth = containers[0].constraints?.maxWidth ?? 0;
        final secondWidth = containers[1].constraints?.maxWidth ?? 0;
        final thirdWidth = containers[2].constraints?.maxWidth ?? 0;

        expect(secondWidth, greaterThan(firstWidth));
        expect(secondWidth, greaterThan(thirdWidth));
        expect(firstWidth, equals(thirdWidth));
      });
    });

    group('item decoration', () {
      testWidgets('items have rounded corners', (tester) async {
        await mountWidget(
          const WnCarouselIndicator(itemCount: 2, activeIndex: 0),
          tester,
        );

        final decoratedBoxes = tester.widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(WnCarouselIndicator),
            matching: find.byType(DecoratedBox),
          ),
        );

        for (final box in decoratedBoxes) {
          final decoration = box.decoration as BoxDecoration;
          expect(decoration.borderRadius, isNotNull);
        }
      });
    });

    group('animation configuration', () {
      test('animationDuration is 600 milliseconds', () {
        expect(
          WnCarouselIndicator.animationDuration,
          const Duration(milliseconds: 600),
        );
      });

      test('colorAnimationDuration is 150 milliseconds', () {
        expect(
          WnCarouselIndicator.colorAnimationDuration,
          const Duration(milliseconds: 150),
        );
      });

      test('animationCurve is elasticOut', () {
        expect(
          WnCarouselIndicator.animationCurve,
          Curves.elasticOut,
        );
      });

      test('colorAnimationCurve is easeOut', () {
        expect(
          WnCarouselIndicator.colorAnimationCurve,
          Curves.easeOut,
        );
      });

      testWidgets('items use AnimatedContainer for transitions', (tester) async {
        await mountWidget(
          const WnCarouselIndicator(itemCount: 3, activeIndex: 0),
          tester,
        );

        final animatedContainers = find.descendant(
          of: find.byType(WnCarouselIndicator),
          matching: find.byType(AnimatedContainer),
        );

        expect(animatedContainers, findsNWidgets(3));
      });

      testWidgets('items use AnimatedAlign for directional animation', (tester) async {
        await mountWidget(
          const WnCarouselIndicator(itemCount: 3, activeIndex: 0),
          tester,
        );

        final animatedAligns = find.descendant(
          of: find.byType(WnCarouselIndicator),
          matching: find.byType(AnimatedAlign),
        );

        expect(animatedAligns, findsNWidgets(3));
      });

      testWidgets('AnimatedContainer has correct duration', (tester) async {
        await mountWidget(
          const WnCarouselIndicator(itemCount: 3, activeIndex: 0),
          tester,
        );

        final container = tester.widget<AnimatedContainer>(
          find
              .descendant(
                of: find.byType(WnCarouselIndicator),
                matching: find.byType(AnimatedContainer),
              )
              .first,
        );

        expect(container.duration, WnCarouselIndicator.animationDuration);
      });

      testWidgets('AnimatedContainer has correct curve', (tester) async {
        await mountWidget(
          const WnCarouselIndicator(itemCount: 3, activeIndex: 0),
          tester,
        );

        final container = tester.widget<AnimatedContainer>(
          find
              .descendant(
                of: find.byType(WnCarouselIndicator),
                matching: find.byType(AnimatedContainer),
              )
              .first,
        );

        expect(container.curve, WnCarouselIndicator.animationCurve);
      });

      testWidgets('AnimatedAlign has correct duration', (tester) async {
        await mountWidget(
          const WnCarouselIndicator(itemCount: 3, activeIndex: 0),
          tester,
        );

        final align = tester.widget<AnimatedAlign>(
          find
              .descendant(
                of: find.byType(WnCarouselIndicator),
                matching: find.byType(AnimatedAlign),
              )
              .first,
        );

        expect(align.duration, WnCarouselIndicator.animationDuration);
      });

      testWidgets('AnimatedAlign has correct curve', (tester) async {
        await mountWidget(
          const WnCarouselIndicator(itemCount: 3, activeIndex: 0),
          tester,
        );

        final align = tester.widget<AnimatedAlign>(
          find
              .descendant(
                of: find.byType(WnCarouselIndicator),
                matching: find.byType(AnimatedAlign),
              )
              .first,
        );

        expect(align.curve, WnCarouselIndicator.animationCurve);
      });
    });

    group('directional animation', () {
      testWidgets('active item aligns right when moving forward', (tester) async {
        await mountWidget(
          const _TestCarouselWrapper(initialIndex: 0, targetIndex: 1),
          tester,
        );

        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        final aligns = tester
            .widgetList<AnimatedAlign>(
              find.descendant(
                of: find.byType(WnCarouselIndicator),
                matching: find.byType(AnimatedAlign),
              ),
            )
            .toList();

        expect(aligns[1].alignment, Alignment.centerRight);
      });

      testWidgets('active item aligns left when moving backward', (tester) async {
        await mountWidget(
          const _TestCarouselWrapper(initialIndex: 2, targetIndex: 1),
          tester,
        );

        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        final aligns = tester
            .widgetList<AnimatedAlign>(
              find.descendant(
                of: find.byType(WnCarouselIndicator),
                matching: find.byType(AnimatedAlign),
              ),
            )
            .toList();

        expect(aligns[1].alignment, Alignment.centerLeft);
      });

      testWidgets('previously active item aligns opposite to direction', (tester) async {
        await mountWidget(
          const _TestCarouselWrapper(initialIndex: 0, targetIndex: 1),
          tester,
        );

        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        final aligns = tester
            .widgetList<AnimatedAlign>(
              find.descendant(
                of: find.byType(WnCarouselIndicator),
                matching: find.byType(AnimatedAlign),
              ),
            )
            .toList();

        expect(aligns[0].alignment, Alignment.centerLeft);
      });
    });

    group('layout behavior', () {
      testWidgets('renders with non-zero height', (tester) async {
        await mountWidget(
          const WnCarouselIndicator(itemCount: 3, activeIndex: 0),
          tester,
        );

        final size = tester.getSize(find.byType(WnCarouselIndicator));
        expect(size.height, greaterThan(0));
      });

      testWidgets('uses Row with mainAxisSize.min', (tester) async {
        await mountWidget(
          const WnCarouselIndicator(itemCount: 3, activeIndex: 0),
          tester,
        );

        final row = tester.widget<Row>(
          find.descendant(
            of: find.byType(WnCarouselIndicator),
            matching: find.byType(Row),
          ),
        );

        expect(row.mainAxisSize, MainAxisSize.min);
      });

      testWidgets('items have spacing between them', (tester) async {
        await mountWidget(
          const WnCarouselIndicator(itemCount: 3, activeIndex: 0),
          tester,
        );

        final firstItemBox = tester.renderObject<RenderBox>(
          find.byKey(const Key('carousel_indicator_item_0')),
        );
        final secondItemBox = tester.renderObject<RenderBox>(
          find.byKey(const Key('carousel_indicator_item_1')),
        );

        final firstItemPosition = firstItemBox.localToGlobal(Offset.zero);
        final secondItemPosition = secondItemBox.localToGlobal(Offset.zero);

        final gap = secondItemPosition.dx - (firstItemPosition.dx + firstItemBox.size.width);
        expect(gap, greaterThan(0));
      });

      testWidgets('can be placed in a Center widget', (tester) async {
        await mountWidget(
          const Center(
            child: WnCarouselIndicator(itemCount: 3, activeIndex: 1),
          ),
          tester,
        );

        expect(find.byType(WnCarouselIndicator), findsOneWidget);
      });

      testWidgets('can be placed in a Column', (tester) async {
        await mountWidget(
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Above'),
              WnCarouselIndicator(itemCount: 3, activeIndex: 1),
              Text('Below'),
            ],
          ),
          tester,
        );

        expect(find.byType(WnCarouselIndicator), findsOneWidget);
        expect(find.text('Above'), findsOneWidget);
        expect(find.text('Below'), findsOneWidget);
      });
    });

    group('widget properties', () {
      testWidgets('exposes itemCount property', (tester) async {
        await mountWidget(
          const WnCarouselIndicator(itemCount: 7, activeIndex: 3),
          tester,
        );

        final indicator = tester.widget<WnCarouselIndicator>(
          find.byType(WnCarouselIndicator),
        );
        expect(indicator.itemCount, 7);
      });

      testWidgets('exposes activeIndex property', (tester) async {
        await mountWidget(
          const WnCarouselIndicator(itemCount: 5, activeIndex: 2),
          tester,
        );

        final indicator = tester.widget<WnCarouselIndicator>(
          find.byType(WnCarouselIndicator),
        );
        expect(indicator.activeIndex, 2);
      });
    });

    group('key generation', () {
      testWidgets('each item has a unique key', (tester) async {
        await mountWidget(
          const WnCarouselIndicator(itemCount: 4, activeIndex: 0),
          tester,
        );

        for (var i = 0; i < 4; i++) {
          expect(find.byKey(Key('carousel_indicator_item_$i')), findsOneWidget);
        }
      });
    });

    group('edge cases', () {
      testWidgets('handles two items correctly', (tester) async {
        await mountWidget(
          const WnCarouselIndicator(itemCount: 2, activeIndex: 1),
          tester,
        );

        final containers = find.descendant(
          of: find.byType(WnCarouselIndicator),
          matching: find.byType(AnimatedContainer),
        );
        expect(containers, findsNWidgets(2));
      });

      testWidgets('handles moderate itemCount', (tester) async {
        await mountWidget(
          const SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: WnCarouselIndicator(itemCount: 10, activeIndex: 5),
          ),
          tester,
        );

        final containers = find.descendant(
          of: find.byType(WnCarouselIndicator),
          matching: find.byType(AnimatedContainer),
        );
        expect(containers, findsNWidgets(10));
      });
    });

    group('rebuilds correctly', () {
      testWidgets('updates when activeIndex changes', (tester) async {
        await mountWidget(
          const WnCarouselIndicator(itemCount: 3, activeIndex: 0),
          tester,
        );

        var decoratedBoxes = tester
            .widgetList<DecoratedBox>(
              find.descendant(
                of: find.byType(WnCarouselIndicator),
                matching: find.byType(DecoratedBox),
              ),
            )
            .toList();

        final firstDecoration = decoratedBoxes[0].decoration as BoxDecoration;
        expect(firstDecoration.color, SemanticColors.light.fillPrimary);

        await mountWidget(
          const WnCarouselIndicator(itemCount: 3, activeIndex: 2),
          tester,
        );
        await tester.pumpAndSettle();

        decoratedBoxes = tester
            .widgetList<DecoratedBox>(
              find.descendant(
                of: find.byType(WnCarouselIndicator),
                matching: find.byType(DecoratedBox),
              ),
            )
            .toList();

        final lastDecoration = decoratedBoxes[2].decoration as BoxDecoration;
        expect(lastDecoration.color, SemanticColors.light.fillPrimary);
      });

      testWidgets('updates when itemCount changes', (tester) async {
        await mountWidget(
          const WnCarouselIndicator(itemCount: 3, activeIndex: 0),
          tester,
        );

        var containers = find.descendant(
          of: find.byType(WnCarouselIndicator),
          matching: find.byType(AnimatedContainer),
        );
        expect(containers, findsNWidgets(3));

        await mountWidget(
          const WnCarouselIndicator(itemCount: 5, activeIndex: 0),
          tester,
        );

        containers = find.descendant(
          of: find.byType(WnCarouselIndicator),
          matching: find.byType(AnimatedContainer),
        );
        expect(containers, findsNWidgets(5));
      });
    });
  });
}
