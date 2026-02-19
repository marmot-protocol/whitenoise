import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/widgets/wn_message_media.dart';

import '../test_helpers.dart';

Widget _tile(int index) => Container(key: Key('tile_$index'), color: Colors.grey);

void main() {
  group('WnMessageMedia', () {
    testWidgets('returns empty when tiles is empty', (tester) async {
      await mountWidget(const WnMessageMedia(tiles: []), tester);

      expect(find.byType(SizedBox), findsWidgets);
      expect(find.byType(Container), findsNothing);
    });

    group('one tile layout', () {
      testWidgets('renders one_layout key', (tester) async {
        await mountWidget(WnMessageMedia(tiles: [_tile(0)]), tester);

        expect(find.byKey(const Key('one_layout')), findsOneWidget);
        expect(find.byKey(const Key('tile_0')), findsOneWidget);
      });

      testWidgets('uses square aspect ratio', (tester) async {
        await mountWidget(WnMessageMedia(tiles: [_tile(0)]), tester);

        final aspectRatio = tester.widget<AspectRatio>(find.byType(AspectRatio).first);
        expect(aspectRatio.aspectRatio, 1.0);
      });

      testWidgets('creates tappable tile with correct key', (tester) async {
        await mountWidget(
          WnMessageMedia(tiles: [_tile(0)], onTileTap: (_) {}),
          tester,
        );

        expect(find.byKey(const Key('tappable_media_tile_0')), findsOneWidget);
      });
    });

    group('two tiles layout', () {
      testWidgets('renders two_layout key', (tester) async {
        await mountWidget(
          WnMessageMedia(tiles: [_tile(0), _tile(1)]),
          tester,
        );

        expect(find.byKey(const Key('two_layout')), findsOneWidget);
        expect(find.byKey(const Key('tile_0')), findsOneWidget);
        expect(find.byKey(const Key('tile_1')), findsOneWidget);
      });

      testWidgets('creates tappable tiles with correct keys', (tester) async {
        await mountWidget(
          WnMessageMedia(tiles: [_tile(0), _tile(1)], onTileTap: (_) {}),
          tester,
        );

        expect(find.byKey(const Key('tappable_media_tile_0')), findsOneWidget);
        expect(find.byKey(const Key('tappable_media_tile_1')), findsOneWidget);
      });
    });

    group('three tiles layout', () {
      testWidgets('renders three_layout key', (tester) async {
        await mountWidget(
          WnMessageMedia(tiles: [_tile(0), _tile(1), _tile(2)]),
          tester,
        );

        expect(find.byKey(const Key('three_layout')), findsOneWidget);
        expect(find.byKey(const Key('tile_2')), findsOneWidget);
      });

      testWidgets('creates tappable tiles with correct keys', (tester) async {
        await mountWidget(
          WnMessageMedia(tiles: [_tile(0), _tile(1), _tile(2)], onTileTap: (_) {}),
          tester,
        );

        for (var i = 0; i < 3; i++) {
          expect(find.byKey(Key('tappable_media_tile_$i')), findsOneWidget);
        }
      });
    });

    group('four tiles layout', () {
      testWidgets('renders four_layout key', (tester) async {
        await mountWidget(
          WnMessageMedia(tiles: List.generate(4, _tile)),
          tester,
        );

        expect(find.byKey(const Key('four_layout')), findsOneWidget);
        for (var i = 0; i < 4; i++) {
          expect(find.byKey(Key('tile_$i')), findsOneWidget);
        }
      });

      testWidgets('does not show overflow indicator', (tester) async {
        await mountWidget(
          WnMessageMedia(tiles: List.generate(4, _tile)),
          tester,
        );

        expect(find.byKey(const Key('overflow_indicator')), findsNothing);
      });

      testWidgets('creates tappable tiles with correct keys', (tester) async {
        await mountWidget(
          WnMessageMedia(tiles: List.generate(4, _tile), onTileTap: (_) {}),
          tester,
        );

        for (var i = 0; i < 4; i++) {
          expect(find.byKey(Key('tappable_media_tile_$i')), findsOneWidget);
        }
      });
    });

    group('five tiles layout', () {
      testWidgets('renders five_layout key', (tester) async {
        await mountWidget(
          WnMessageMedia(tiles: List.generate(5, _tile)),
          tester,
        );

        expect(find.byKey(const Key('five_layout')), findsOneWidget);
        for (var i = 0; i < 5; i++) {
          expect(find.byKey(Key('tile_$i')), findsOneWidget);
        }
      });

      testWidgets('does not show overflow indicator', (tester) async {
        await mountWidget(
          WnMessageMedia(tiles: List.generate(5, _tile)),
          tester,
        );

        expect(find.byKey(const Key('overflow_indicator')), findsNothing);
      });

      testWidgets('creates tappable tiles with correct keys', (tester) async {
        await mountWidget(
          WnMessageMedia(tiles: List.generate(5, _tile), onTileTap: (_) {}),
          tester,
        );

        for (var i = 0; i < 5; i++) {
          expect(find.byKey(Key('tappable_media_tile_$i')), findsOneWidget);
        }
      });
    });

    group('six tiles layout', () {
      testWidgets('renders six_plus_layout key', (tester) async {
        await mountWidget(
          WnMessageMedia(tiles: List.generate(6, _tile)),
          tester,
        );

        expect(find.byKey(const Key('six_plus_layout')), findsOneWidget);
        for (var i = 0; i < 6; i++) {
          expect(find.byKey(Key('tile_$i')), findsOneWidget);
        }
      });

      testWidgets('does not show overflow indicator for exactly 6', (tester) async {
        await mountWidget(
          WnMessageMedia(tiles: List.generate(6, _tile)),
          tester,
        );

        expect(find.byKey(const Key('overflow_indicator')), findsNothing);
      });

      testWidgets('creates tappable tiles with correct keys', (tester) async {
        await mountWidget(
          WnMessageMedia(tiles: List.generate(6, _tile), onTileTap: (_) {}),
          tester,
        );

        for (var i = 0; i < 6; i++) {
          expect(find.byKey(Key('tappable_media_tile_$i')), findsOneWidget);
        }
      });
    });

    group('overflow (7+ tiles)', () {
      testWidgets('shows overflow indicator for 7 tiles', (tester) async {
        await mountWidget(
          WnMessageMedia(tiles: List.generate(7, _tile)),
          tester,
        );

        expect(find.byKey(const Key('six_plus_layout')), findsOneWidget);
        expect(find.byKey(const Key('overflow_indicator')), findsOneWidget);
        expect(find.text('+1'), findsOneWidget);
      });

      testWidgets('shows correct overflow count for 8 tiles', (tester) async {
        await mountWidget(
          WnMessageMedia(tiles: List.generate(8, _tile)),
          tester,
        );

        expect(find.text('+2'), findsOneWidget);
      });

      testWidgets('shows correct overflow count for many tiles', (tester) async {
        await mountWidget(
          WnMessageMedia(tiles: List.generate(10, _tile)),
          tester,
        );

        expect(find.text('+4'), findsOneWidget);
      });

      testWidgets('only shows first 6 tiles', (tester) async {
        await mountWidget(
          WnMessageMedia(tiles: List.generate(10, _tile), onTileTap: (_) {}),
          tester,
        );

        for (var i = 0; i < 6; i++) {
          expect(find.byKey(Key('tappable_media_tile_$i')), findsOneWidget);
        }
        expect(find.byKey(const Key('tappable_media_tile_6')), findsNothing);
      });
    });

    group('tap handling', () {
      testWidgets('calls onTileTap with correct index when tapped', (tester) async {
        var tappedIndex = -1;

        await mountWidget(
          SizedBox(
            width: 300,
            child: WnMessageMedia(
              tiles: [_tile(0)],
              onTileTap: (index) => tappedIndex = index,
            ),
          ),
          tester,
        );

        await tester.pumpAndSettle();
        expect(find.byKey(const Key('tappable_media_tile_0')), findsOneWidget);
        await tester.tap(find.byKey(const Key('tappable_media_tile_0')));
        await tester.pumpAndSettle();
        expect(tappedIndex, 0);
      });

      testWidgets('does not crash when onTileTap is null', (tester) async {
        await mountWidget(
          SizedBox(width: 300, child: WnMessageMedia(tiles: [_tile(0)])),
          tester,
        );

        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('tappable_media_tile_0')));
      });
    });
  });
}
