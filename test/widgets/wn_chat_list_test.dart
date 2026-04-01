import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/widgets/wn_chat_list.dart';

import '../test_helpers.dart';

void main() {
  group('WnChatList', () {
    group('loading state', () {
      testWidgets('shows loading indicator when loading with no items', (tester) async {
        await mountWidget(
          const WnChatList(itemCount: 0, isLoading: true, itemBuilder: _emptyBuilder),
          tester,
        );
        await tester.pump();

        expect(find.byKey(const Key('chat_list_loading')), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('does not show loading indicator when items exist', (tester) async {
        await mountWidget(
          const WnChatList(itemCount: 2, isLoading: true, itemBuilder: _textBuilder),
          tester,
        );
        await tester.pump();

        expect(find.byKey(const Key('chat_list_loading')), findsNothing);
        expect(find.byKey(const Key('chat_list')), findsOneWidget);
      });
    });

    group('empty state', () {
      testWidgets('uses list when empty with no emptyStateContent', (tester) async {
        await mountWidget(
          const WnChatList(itemCount: 0, itemBuilder: _emptyBuilder),
          tester,
        );
        await tester.pump();

        expect(find.byKey(const Key('chat_list')), findsOneWidget);
        expect(find.byKey(const Key('chat_list_empty')), findsNothing);
      });

      testWidgets('pull down does not reveal header when empty state is shown', (tester) async {
        await mountWidget(
          const WnChatList(
            itemCount: 0,
            itemBuilder: _emptyBuilder,
            header: Text('Header'),
            headerHeight: 142,
            emptyStateContent: Text('Empty'),
          ),
          tester,
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('chat_list_header')), findsNothing);

        final gesture = await tester.startGesture(const Offset(200, 400));
        await gesture.moveBy(const Offset(0, 200));
        await tester.pump();

        expect(find.byKey(const Key('chat_list_header')), findsNothing);
        await gesture.up();
        await tester.pumpAndSettle();
      });

      testWidgets('shows no results when search is active and no items match', (tester) async {
        await mountWidget(
          const WnChatList(itemCount: 0, isSearchActive: true, itemBuilder: _emptyBuilder),
          tester,
        );
        await tester.pump();

        expect(find.byKey(const Key('chat_list_no_results')), findsOneWidget);
        expect(find.text('No results'), findsOneWidget);
        expect(find.text('No chats yet'), findsNothing);
      });
    });

    group('list state', () {
      testWidgets('renders items via itemBuilder', (tester) async {
        await mountWidget(
          const WnChatList(itemCount: 3, itemBuilder: _textBuilder),
          tester,
        );
        await tester.pump();

        expect(find.byKey(const Key('chat_list')), findsOneWidget);
        expect(find.text('Item 0'), findsOneWidget);
        expect(find.text('Item 1'), findsOneWidget);
        expect(find.text('Item 2'), findsOneWidget);
      });

      testWidgets('list is scrollable', (tester) async {
        await mountWidget(
          WnChatList(
            itemCount: 50,
            itemBuilder: (context, index) => SizedBox(
              height: 76,
              child: Text('Item $index'),
            ),
          ),
          tester,
        );
        await tester.pump();

        expect(find.text('Item 0'), findsOneWidget);
        expect(find.text('Item 49'), findsNothing);

        await tester.drag(find.byKey(const Key('chat_list')), const Offset(0, -3000));
        await tester.pump();

        expect(find.text('Item 49'), findsOneWidget);
      });

      testWidgets('applies top padding including topPadding param', (tester) async {
        await mountWidget(
          const WnChatList(itemCount: 1, topPadding: 80, itemBuilder: _textBuilder),
          tester,
        );
        await tester.pump();

        final listView = tester.widget<ListView>(find.byType(ListView));
        final padding = listView.padding!;
        final resolved = padding.resolve(TextDirection.ltr);
        expect(resolved.top, greaterThanOrEqualTo(80));
      });

      testWidgets('applies horizontal padding', (tester) async {
        await mountWidget(
          const WnChatList(itemCount: 1, itemBuilder: _textBuilder),
          tester,
        );
        await tester.pump();

        final listView = tester.widget<ListView>(find.byType(ListView));
        final padding = listView.padding!;
        final resolved = padding.resolve(TextDirection.ltr);
        expect(resolved.left, greaterThan(0));
        expect(resolved.right, greaterThan(0));
      });
    });

    group('header', () {
      testWidgets('header is hidden initially', (tester) async {
        await mountWidget(
          const WnChatList(
            itemCount: 3,
            itemBuilder: _textBuilder,
            header: Text('Header'),
            headerHeight: 142,
          ),
          tester,
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('chat_list_header')), findsNothing);
      });

      testWidgets('header appears when pulling down', (tester) async {
        await mountWidget(
          WnChatList(
            itemCount: 50,
            itemBuilder: (context, index) => SizedBox(
              height: 76,
              child: Text('Item $index'),
            ),
            header: const Text('Header'),
            headerHeight: 142,
          ),
          tester,
        );
        await tester.pumpAndSettle();

        final gesture = await tester.startGesture(const Offset(200, 300));
        await gesture.moveBy(const Offset(0, 200));
        await tester.pump();

        expect(find.byKey(const Key('chat_list_header')), findsOneWidget);
        expect(find.text('Header'), findsOneWidget);
        await gesture.up();
        await tester.pumpAndSettle();
      });

      testWidgets('header snaps back to hidden on partial pull', (tester) async {
        await mountWidget(
          WnChatList(
            itemCount: 50,
            itemBuilder: (context, index) => SizedBox(
              height: 76,
              child: Text('Item $index'),
            ),
            header: const Text('Header'),
            headerHeight: 142,
          ),
          tester,
        );
        await tester.pumpAndSettle();

        final gesture = await tester.startGesture(const Offset(200, 300));
        await gesture.moveBy(const Offset(0, 50));
        await tester.pump();

        expect(find.byKey(const Key('chat_list_header')), findsOneWidget);

        await gesture.up();
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('chat_list_header')), findsNothing);
      });

      testWidgets('header stays open after pulling past threshold', (tester) async {
        await mountWidget(
          WnChatList(
            itemCount: 50,
            itemBuilder: (context, index) => SizedBox(
              height: 76,
              child: Text('Item $index'),
            ),
            header: const Text('Header'),
            headerHeight: 142,
          ),
          tester,
        );
        await tester.pumpAndSettle();

        final gesture = await tester.startGesture(const Offset(200, 300));
        await gesture.moveBy(const Offset(0, 200));
        await tester.pump();

        expect(find.byKey(const Key('chat_list_header')), findsOneWidget);

        await gesture.up();
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('chat_list_header')), findsOneWidget);

        final align = tester.widget<Align>(
          find.ancestor(of: find.text('Header'), matching: find.byType(Align)),
        );
        expect(align.heightFactor, 1.0);
      });

      testWidgets('header dismisses when scrolling up while open', (tester) async {
        await mountWidget(
          WnChatList(
            itemCount: 50,
            itemBuilder: (context, index) => SizedBox(
              height: 76,
              child: Text('Item $index'),
            ),
            header: const Text('Header'),
            headerHeight: 142,
          ),
          tester,
        );
        await tester.pumpAndSettle();

        final gesture = await tester.startGesture(const Offset(200, 300));
        await gesture.moveBy(const Offset(0, 200));
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('chat_list_header')), findsOneWidget);

        await tester.drag(find.byKey(const Key('chat_list')), const Offset(0, -300));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('chat_list_header')), findsNothing);
      });

      testWidgets('header snaps back on scroll end in overscroll territory', (tester) async {
        await mountWidget(
          WnChatList(
            itemCount: 50,
            itemBuilder: (context, index) => SizedBox(
              height: 76,
              child: Text('Item $index'),
            ),
            header: const Text('Header'),
            headerHeight: 142,
          ),
          tester,
        );
        await tester.pumpAndSettle();

        final gesture = await tester.startGesture(const Offset(200, 300));
        await gesture.moveBy(const Offset(0, 30));
        await tester.pump();

        expect(find.byKey(const Key('chat_list_header')), findsOneWidget);

        await gesture.up();
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('chat_list_header')), findsNothing);
      });

      testWidgets(
        'scroll events during header close animation are ignored',
        (tester) async {
          await mountWidget(
            WnChatList(
              itemCount: 50,
              itemBuilder: (context, index) => SizedBox(
                height: 76,
                child: Text('Item $index'),
              ),
              header: const Text('Header'),
              headerHeight: 142,
            ),
            tester,
          );
          await tester.pumpAndSettle();

          final gesture = await tester.startGesture(const Offset(200, 300));
          await gesture.moveBy(const Offset(0, 200));
          await tester.pump();
          await gesture.up();
          await tester.pumpAndSettle();

          expect(
            find.byKey(const Key('chat_list_header')),
            findsOneWidget,
          );

          final scrollGesture = await tester.startGesture(
            const Offset(200, 400),
          );
          await scrollGesture.moveBy(const Offset(0, -300));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 50));
          await scrollGesture.up();
          await tester.pumpAndSettle();

          expect(
            find.byKey(const Key('chat_list_header')),
            findsNothing,
          );
        },
      );

      testWidgets(
        'header stays hidden when ScrollEndNotification fires without prior open',
        (tester) async {
          await mountWidget(
            WnChatList(
              itemCount: 50,
              itemBuilder: (context, index) => SizedBox(
                height: 76,
                child: Text('Item $index'),
              ),
              header: const Text('Header'),
              headerHeight: 142,
            ),
            tester,
          );
          await tester.pumpAndSettle();

          final listFinder = find.byKey(const Key('chat_list'));
          final context = tester.element(listFinder);
          final metrics = FixedScrollMetrics(
            minScrollExtent: -142,
            maxScrollExtent: 3000,
            pixels: -20,
            viewportDimension: 800,
            axisDirection: AxisDirection.down,
            devicePixelRatio: 1.0,
          );

          ScrollEndNotification(
            metrics: metrics,
            context: context,
          ).dispatch(context);
          await tester.pumpAndSettle();

          expect(
            find.byKey(const Key('chat_list_header')),
            findsNothing,
          );
        },
      );

      testWidgets(
        'scroll notifications during close animation are absorbed until '
        'ScrollEndNotification resets the guard',
        (tester) async {
          await mountWidget(
            WnChatList(
              itemCount: 50,
              itemBuilder: (context, index) => SizedBox(
                height: 76,
                child: Text('Item $index'),
              ),
              header: const Text('Header'),
              headerHeight: 142,
            ),
            tester,
          );
          await tester.pumpAndSettle();

          final gesture = await tester.startGesture(
            const Offset(200, 300),
          );
          await gesture.moveBy(const Offset(0, 200));
          await tester.pump();
          await gesture.up();
          await tester.pumpAndSettle();

          expect(
            find.byKey(const Key('chat_list_header')),
            findsOneWidget,
          );

          final listFinder = find.byKey(const Key('chat_list'));
          final context = tester.element(listFinder);

          final dragMetrics = FixedScrollMetrics(
            minScrollExtent: 0,
            maxScrollExtent: 3000,
            pixels: 50,
            viewportDimension: 800,
            axisDirection: AxisDirection.down,
            devicePixelRatio: 1.0,
          );

          ScrollUpdateNotification(
            metrics: dragMetrics,
            context: context,
            scrollDelta: 50,
            dragDetails: DragUpdateDetails(
              globalPosition: const Offset(200, 250),
            ),
          ).dispatch(context);
          await tester.pump();

          final endMetrics = FixedScrollMetrics(
            minScrollExtent: 0,
            maxScrollExtent: 3000,
            pixels: 50,
            viewportDimension: 800,
            axisDirection: AxisDirection.down,
            devicePixelRatio: 1.0,
          );

          ScrollEndNotification(
            metrics: endMetrics,
            context: context,
          ).dispatch(context);
          await tester.pumpAndSettle();

          expect(
            find.byKey(const Key('chat_list_header')),
            findsNothing,
          );
        },
      );

      testWidgets('header is forced open when isSearchActive is true', (tester) async {
        await mountWidget(
          const WnChatList(
            itemCount: 0,
            isSearchActive: true,
            itemBuilder: _emptyBuilder,
            header: Text('Header'),
            headerHeight: 142,
          ),
          tester,
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('chat_list_header')), findsOneWidget);
        expect(find.text('Header'), findsOneWidget);
      });

      testWidgets('does not render header when header is null', (tester) async {
        await mountWidget(
          const WnChatList(itemCount: 3, itemBuilder: _textBuilder),
          tester,
        );
        await tester.pump();

        expect(find.byKey(const Key('chat_list_header')), findsNothing);
      });

      testWidgets('does not render header when headerHeight is 0', (tester) async {
        await mountWidget(
          const WnChatList(
            itemCount: 3,
            itemBuilder: _textBuilder,
            header: Text('Header'),
          ),
          tester,
        );
        await tester.pump();

        expect(find.byKey(const Key('chat_list_header')), findsNothing);
      });
    });

    group('pinnedHeader', () {
      testWidgets('renders pinned header immediately without pull', (tester) async {
        await mountWidget(
          const WnChatList(
            itemCount: 3,
            itemBuilder: _textBuilder,
            pinnedHeader: Text('Pinned'),
            pinnedHeaderHeight: 40,
          ),
          tester,
        );
        await tester.pump();

        expect(find.byKey(const Key('chat_list_pinned_header')), findsOneWidget);
        expect(find.text('Pinned'), findsOneWidget);
      });

      testWidgets('pinned header stays visible when scrolling down', (tester) async {
        await mountWidget(
          WnChatList(
            itemCount: 50,
            itemBuilder: (context, index) => SizedBox(height: 76, child: Text('Item $index')),
            pinnedHeader: const Text('Pinned'),
            pinnedHeaderHeight: 40,
          ),
          tester,
        );
        await tester.pumpAndSettle();

        await tester.drag(find.byKey(const Key('chat_list')), const Offset(0, -300));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('chat_list_pinned_header')), findsOneWidget);
      });

      testWidgets('renders pinned header when empty state is shown', (tester) async {
        await mountWidget(
          const WnChatList(
            itemCount: 0,
            itemBuilder: _emptyBuilder,
            pinnedHeader: Text('Pinned'),
            pinnedHeaderHeight: 40,
            emptyStateContent: Text('Empty placeholder'),
          ),
          tester,
        );
        await tester.pump();

        expect(find.byKey(const Key('chat_list_empty')), findsOneWidget);
        expect(find.byKey(const Key('chat_list_pinned_header')), findsOneWidget);
        expect(find.text('Pinned'), findsOneWidget);
      });

      testWidgets('renders custom empty state content', (tester) async {
        await mountWidget(
          const WnChatList(
            itemCount: 0,
            itemBuilder: _emptyBuilder,
            emptyStateContent: Text('Slogan'),
          ),
          tester,
        );
        await tester.pump();

        expect(find.byKey(const Key('chat_list_empty')), findsOneWidget);
        expect(find.text('Slogan'), findsOneWidget);
        expect(find.text('No chats yet'), findsNothing);
      });

      testWidgets('does not render pinned header when pinnedHeaderHeight is 0', (tester) async {
        await mountWidget(
          const WnChatList(
            itemCount: 3,
            itemBuilder: _textBuilder,
            pinnedHeader: Text('Pinned'),
          ),
          tester,
        );
        await tester.pump();

        expect(find.byKey(const Key('chat_list_pinned_header')), findsNothing);
      });

      testWidgets('does not render pinned header when pinnedHeader is null', (tester) async {
        await mountWidget(
          const WnChatList(itemCount: 3, itemBuilder: _textBuilder),
          tester,
        );
        await tester.pump();

        expect(find.byKey(const Key('chat_list_pinned_header')), findsNothing);
      });

      testWidgets('list top padding includes extra 24 spacing after pinned header', (tester) async {
        await mountWidget(
          const WnChatList(
            itemCount: 1,
            itemBuilder: _textBuilder,
            topPadding: 80,
            pinnedHeader: Text('Pinned'),
            pinnedHeaderHeight: 40,
          ),
          tester,
        );
        await tester.pump();

        final listView = tester.widget<ListView>(find.byType(ListView));
        final resolved = listView.padding!.resolve(TextDirection.ltr);
        expect(resolved.top, greaterThanOrEqualTo(80 + 40 + 24));
      });
    });

    group('scroll edge effect', () {
      testWidgets('does not show scroll edge effect at top initially', (tester) async {
        await mountWidget(
          WnChatList(
            itemCount: 50,
            itemBuilder: (context, index) => SizedBox(
              height: 76,
              child: Text('Item $index'),
            ),
          ),
          tester,
        );
        await tester.pump();

        expect(find.byKey(const Key('chat_list_scroll_edge')), findsNothing);
      });

      testWidgets('shows scroll edge effect after scrolling down', (tester) async {
        await mountWidget(
          WnChatList(
            itemCount: 50,
            itemBuilder: (context, index) => SizedBox(
              height: 76,
              child: Text('Item $index'),
            ),
          ),
          tester,
        );
        await tester.pump();

        await tester.drag(find.byKey(const Key('chat_list')), const Offset(0, -200));
        await tester.pump();

        expect(find.byKey(const Key('chat_list_scroll_edge')), findsOneWidget);
      });

      testWidgets('hides scroll edge effect when scrolled back to top', (tester) async {
        await mountWidget(
          WnChatList(
            itemCount: 50,
            itemBuilder: (context, index) => SizedBox(
              height: 76,
              child: Text('Item $index'),
            ),
          ),
          tester,
        );
        await tester.pump();

        await tester.drag(find.byKey(const Key('chat_list')), const Offset(0, -200));
        await tester.pump();
        expect(find.byKey(const Key('chat_list_scroll_edge')), findsOneWidget);

        await tester.drag(find.byKey(const Key('chat_list')), const Offset(0, 200));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('chat_list_scroll_edge')), findsNothing);
      });
    });
  });
}

Widget _emptyBuilder(BuildContext context, int index) => const SizedBox.shrink();

Widget _textBuilder(BuildContext context, int index) => SizedBox(
  height: 76,
  child: Text('Item $index'),
);
