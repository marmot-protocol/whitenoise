import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/widgets/wn_media_preview.dart';
import 'package:whitenoise/widgets/wn_media_thumbnail.dart';

import '../test_helpers.dart';

void main() {
  Widget buildTestChild(int index, {Color? color}) {
    return Container(
      key: Key('test_child_$index'),
      color: color ?? Colors.primaries[index % Colors.primaries.length],
    );
  }

  group('WnMediaPreview', () {
    group('empty state', () {
      testWidgets('renders nothing when children is empty', (tester) async {
        await mountWidget(
          const WnMediaPreview(
            selectedIndex: 0,
            children: [],
          ),
          tester,
        );

        expect(find.byType(WnMediaPreview), findsOneWidget);
        expect(find.byKey(const Key('media_preview_page_view')), findsNothing);
      });
    });

    group('single item', () {
      testWidgets('renders main image without thumbnails', (tester) async {
        await mountWidget(
          WnMediaPreview(
            selectedIndex: 0,
            children: [buildTestChild(0)],
          ),
          tester,
        );

        expect(find.byKey(const Key('media_preview_page_view')), findsOneWidget);
        expect(find.byKey(const Key('test_child_0')), findsOneWidget);
        expect(find.byKey(const Key('media_preview_thumbnail_strip')), findsNothing);
      });

      testWidgets('shows delete button when onDelete is provided', (tester) async {
        await mountWidget(
          WnMediaPreview(
            selectedIndex: 0,
            onDelete: () {},
            children: [buildTestChild(0)],
          ),
          tester,
        );

        expect(find.byKey(const Key('media_preview_delete_button')), findsOneWidget);
      });

      testWidgets('hides delete button when onDelete is null', (tester) async {
        await mountWidget(
          WnMediaPreview(
            selectedIndex: 0,
            children: [buildTestChild(0)],
          ),
          tester,
        );

        expect(find.byKey(const Key('media_preview_delete_button')), findsNothing);
      });
    });

    group('multiple items', () {
      testWidgets('renders main image and thumbnail strip', (tester) async {
        await mountWidget(
          WnMediaPreview(
            selectedIndex: 0,
            children: [buildTestChild(0), buildTestChild(1), buildTestChild(2)],
          ),
          tester,
        );

        expect(find.byKey(const Key('media_preview_page_view')), findsOneWidget);
        expect(find.byKey(const Key('media_preview_thumbnail_strip')), findsOneWidget);
        expect(find.byType(WnMediaThumbnail), findsNWidgets(3));
      });

      testWidgets('shows selected state on correct thumbnail', (tester) async {
        await mountWidget(
          WnMediaPreview(
            selectedIndex: 1,
            children: [buildTestChild(0), buildTestChild(1), buildTestChild(2)],
          ),
          tester,
        );

        final thumbnails = tester.widgetList<WnMediaThumbnail>(
          find.byType(WnMediaThumbnail),
        );

        expect(thumbnails.elementAt(0).isSelected, isFalse);
        expect(thumbnails.elementAt(1).isSelected, isTrue);
        expect(thumbnails.elementAt(2).isSelected, isFalse);
      });

      testWidgets('calls onSelectedChanged when thumbnail is tapped', (tester) async {
        int? selectedIndex;
        await mountWidget(
          WnMediaPreview(
            selectedIndex: 0,
            onSelectedChanged: (index) => selectedIndex = index,
            children: [buildTestChild(0), buildTestChild(1), buildTestChild(2)],
          ),
          tester,
        );

        await tester.tap(find.byKey(const Key('media_preview_thumbnail_1')));
        await tester.pump();

        expect(selectedIndex, 1);
      });

      testWidgets('calls onSelectedChanged when swiping', (tester) async {
        int? selectedIndex;
        await mountWidget(
          WnMediaPreview(
            selectedIndex: 0,
            onSelectedChanged: (index) => selectedIndex = index,
            children: [buildTestChild(0), buildTestChild(1)],
          ),
          tester,
        );

        await tester.drag(
          find.byKey(const Key('media_preview_page_view')),
          const Offset(-400, 0),
        );
        await tester.pumpAndSettle();

        expect(selectedIndex, 1);
      });
    });

    group('delete button', () {
      testWidgets('calls onDelete when tapped', (tester) async {
        var deleteCalled = false;
        await mountWidget(
          WnMediaPreview(
            selectedIndex: 0,
            onDelete: () => deleteCalled = true,
            children: [buildTestChild(0)],
          ),
          tester,
        );

        await tester.tap(find.byKey(const Key('media_preview_delete_button')));
        await tester.pump();

        expect(deleteCalled, isTrue);
      });
    });

    group('page synchronization', () {
      testWidgets('syncs page view when selectedIndex changes externally', (tester) async {
        var currentIndex = 0;
        late StateSetter setState;

        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setStateCallback) {
                setState = setStateCallback;
                return Scaffold(
                  body: SizedBox(
                    width: 300,
                    height: 400,
                    child: WnMediaPreview(
                      selectedIndex: currentIndex,
                      onSelectedChanged: (index) {
                        setState(() => currentIndex = index);
                      },
                      children: [buildTestChild(0), buildTestChild(1), buildTestChild(2)],
                    ),
                  ),
                );
              },
            ),
          ),
        );

        final pageView = tester.widget<PageView>(
          find.byKey(const Key('media_preview_page_view')),
        );
        expect(pageView.controller!.initialPage, 0);

        setState(() => currentIndex = 2);
        await tester.pumpAndSettle();

        final thumbnails = tester.widgetList<WnMediaThumbnail>(
          find.byType(WnMediaThumbnail),
        );
        expect(thumbnails.elementAt(2).isSelected, isTrue);
      });
    });

    group('thumbnail callbacks', () {
      testWidgets('does not crash when onSelectedChanged is null', (tester) async {
        await mountWidget(
          WnMediaPreview(
            selectedIndex: 0,
            children: [buildTestChild(0), buildTestChild(1)],
          ),
          tester,
        );

        await tester.tap(find.byKey(const Key('media_preview_thumbnail_1')));
        await tester.pump();
      });
    });

    group('styling', () {
      testWidgets('clips main image with rounded corners', (tester) async {
        await mountWidget(
          WnMediaPreview(
            selectedIndex: 0,
            children: [buildTestChild(0)],
          ),
          tester,
        );

        final clipRRect = tester.widget<ClipRRect>(
          find.descendant(
            of: find.byKey(const Key('media_preview_page_view')),
            matching: find.byType(ClipRRect),
          ),
        );
        expect(clipRRect.borderRadius, isNotNull);
      });

      testWidgets('main image has square aspect ratio', (tester) async {
        await mountWidget(
          WnMediaPreview(
            selectedIndex: 0,
            children: [buildTestChild(0)],
          ),
          tester,
        );

        final aspectRatio = tester.widget<AspectRatio>(find.byType(AspectRatio));
        expect(aspectRatio.aspectRatio, 1.0);
      });
    });
  });
}
