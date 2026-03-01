import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/widgets/wn_chat_list_context_menu.dart';
import 'package:whitenoise/widgets/wn_icon.dart';

import '../test_helpers.dart' show mountWidget;

void main() {
  group('WnChatListContextMenu', () {
    WnChatListContextMenuController? activeController;

    tearDown(() {
      activeController?.dispose();
      activeController = null;
    });

    Future<void> openContextMenu(
      WidgetTester tester, {
      required List<WnChatListContextMenuAction> actions,
      String childText = 'Chat Item',
    }) async {
      final triggerKey = GlobalKey();

      await mountWidget(
        Center(
          child: Builder(
            builder: (context) {
              return GestureDetector(
                key: triggerKey,
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  final renderBox = triggerKey.currentContext!.findRenderObject() as RenderBox;
                  activeController = WnChatListContextMenu.show(
                    context,
                    childRenderBox: renderBox,
                    child: Text(childText),
                    actions: actions,
                  );
                },
                child: const ColoredBox(
                  key: Key('trigger'),
                  color: Colors.transparent,
                  child: SizedBox(width: 100, height: 50),
                ),
              );
            },
          ),
        ),
        tester,
      );

      await tester.tap(find.byKey(const Key('trigger')));
      await tester.pumpAndSettle();
    }

    group('rendering', () {
      testWidgets('renders context menu card', (tester) async {
        await openContextMenu(
          tester,
          actions: [
            WnChatListContextMenuAction(
              id: 'pin',
              label: 'Pin',
              icon: WnIcons.pin,
              onTap: () {},
            ),
          ],
        );

        expect(
          find.byKey(const Key('context_menu_card')),
          findsOneWidget,
        );
      });

      testWidgets('shows child widget inside the menu', (tester) async {
        await openContextMenu(
          tester,
          actions: [
            WnChatListContextMenuAction(
              id: 'pin',
              label: 'Pin',
              icon: WnIcons.pin,
              onTap: () {},
            ),
          ],
          childText: 'My Chat Preview',
        );

        expect(find.text('My Chat Preview'), findsOneWidget);
      });

      testWidgets('renders all action buttons with correct labels', (tester) async {
        await openContextMenu(
          tester,
          actions: [
            WnChatListContextMenuAction(
              id: 'pin',
              label: 'Pin',
              icon: WnIcons.pin,
              onTap: () {},
            ),
            WnChatListContextMenuAction(
              id: 'archive',
              label: 'Archive',
              icon: WnIcons.archive,
              onTap: () {},
            ),
            WnChatListContextMenuAction(
              id: 'delete',
              label: 'Delete',
              icon: WnIcons.trashCan,
              onTap: () {},
              isDestructive: true,
            ),
          ],
        );

        expect(find.text('Pin'), findsOneWidget);
        expect(find.text('Archive'), findsOneWidget);
        expect(find.text('Delete'), findsOneWidget);
      });

      testWidgets('renders action buttons with correct keys', (tester) async {
        await openContextMenu(
          tester,
          actions: [
            WnChatListContextMenuAction(
              id: 'pin',
              label: 'Pin',
              icon: WnIcons.pin,
              onTap: () {},
            ),
            WnChatListContextMenuAction(
              id: 'archive',
              label: 'Archive',
              icon: WnIcons.archive,
              onTap: () {},
            ),
          ],
        );

        expect(
          find.byKey(const Key('context_menu_action_pin')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('context_menu_action_archive')),
          findsOneWidget,
        );
      });

      testWidgets('renders destructive action button', (tester) async {
        await openContextMenu(
          tester,
          actions: [
            WnChatListContextMenuAction(
              id: 'delete',
              label: 'Delete',
              icon: WnIcons.trashCan,
              onTap: () {},
              isDestructive: true,
            ),
          ],
        );

        expect(
          find.byKey(const Key('context_menu_action_delete')),
          findsOneWidget,
        );
        expect(find.text('Delete'), findsOneWidget);
      });

      testWidgets('renders overlay background', (tester) async {
        await openContextMenu(
          tester,
          actions: [
            WnChatListContextMenuAction(
              id: 'pin',
              label: 'Pin',
              icon: WnIcons.pin,
              onTap: () {},
            ),
          ],
        );

        expect(find.byType(BackdropFilter), findsOneWidget);
      });

      testWidgets('renders single action', (tester) async {
        await openContextMenu(
          tester,
          actions: [
            WnChatListContextMenuAction(
              id: 'mute',
              label: 'Mute',
              icon: WnIcons.notificationOff,
              onTap: () {},
            ),
          ],
        );

        expect(
          find.byKey(const Key('context_menu_action_mute')),
          findsOneWidget,
        );
      });
    });

    group('interaction', () {
      testWidgets('action button tap calls onTap callback', (tester) async {
        var pinCalled = false;

        await openContextMenu(
          tester,
          actions: [
            WnChatListContextMenuAction(
              id: 'pin',
              label: 'Pin',
              icon: WnIcons.pin,
              onTap: () => pinCalled = true,
            ),
          ],
        );

        await tester.tap(
          find.byKey(const Key('context_menu_action_pin')),
        );
        await tester.pumpAndSettle();

        expect(pinCalled, isTrue);
      });

      testWidgets('action button tap dismisses the menu', (tester) async {
        await openContextMenu(
          tester,
          actions: [
            WnChatListContextMenuAction(
              id: 'pin',
              label: 'Pin',
              icon: WnIcons.pin,
              onTap: () {},
            ),
          ],
        );

        expect(
          find.byKey(const Key('context_menu_card')),
          findsOneWidget,
        );

        await tester.tap(
          find.byKey(const Key('context_menu_action_pin')),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('context_menu_card')),
          findsNothing,
        );
      });

      testWidgets('tapping outside dismisses context menu', (tester) async {
        await openContextMenu(
          tester,
          actions: [
            WnChatListContextMenuAction(
              id: 'pin',
              label: 'Pin',
              icon: WnIcons.pin,
              onTap: () {},
            ),
          ],
        );

        expect(
          find.byKey(const Key('context_menu_card')),
          findsOneWidget,
        );

        await tester.tapAt(Offset.zero);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('context_menu_card')),
          findsNothing,
        );
      });

      testWidgets('tapping on menu card does not dismiss', (tester) async {
        await openContextMenu(
          tester,
          actions: [
            WnChatListContextMenuAction(
              id: 'pin',
              label: 'Pin',
              icon: WnIcons.pin,
              onTap: () {},
            ),
          ],
          childText: 'Card Content',
        );

        expect(
          find.byKey(const Key('context_menu_card')),
          findsOneWidget,
        );

        final cardRect = tester.getRect(find.byKey(const Key('context_menu_card')));
        await tester.tapAt(cardRect.topLeft + const Offset(8, 8));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('context_menu_card')),
          findsOneWidget,
        );
      });

      testWidgets('tapping correct action among multiple calls correct callback', (tester) async {
        var pinCalled = false;
        var archiveCalled = false;
        var deleteCalled = false;

        await openContextMenu(
          tester,
          actions: [
            WnChatListContextMenuAction(
              id: 'pin',
              label: 'Pin',
              icon: WnIcons.pin,
              onTap: () => pinCalled = true,
            ),
            WnChatListContextMenuAction(
              id: 'archive',
              label: 'Archive',
              icon: WnIcons.archive,
              onTap: () => archiveCalled = true,
            ),
            WnChatListContextMenuAction(
              id: 'delete',
              label: 'Delete',
              icon: WnIcons.trashCan,
              onTap: () => deleteCalled = true,
              isDestructive: true,
            ),
          ],
        );

        await tester.tap(
          find.byKey(const Key('context_menu_action_archive')),
        );
        await tester.pumpAndSettle();

        expect(pinCalled, isFalse);
        expect(archiveCalled, isTrue);
        expect(deleteCalled, isFalse);
      });
    });

    group('show method', () {
      testWidgets('inserts overlay with the context menu', (tester) async {
        await openContextMenu(
          tester,
          actions: [
            WnChatListContextMenuAction(
              id: 'pin',
              label: 'Pin',
              icon: WnIcons.pin,
              onTap: () {},
            ),
          ],
        );

        expect(
          find.byType(WnChatListContextMenu),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('context_menu_card')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('context_menu_dismiss')),
          findsOneWidget,
        );
      });

      testWidgets('menu is dismissible via vertical drag', (tester) async {
        await openContextMenu(
          tester,
          actions: [
            WnChatListContextMenuAction(
              id: 'pin',
              label: 'Pin',
              icon: WnIcons.pin,
              onTap: () {},
            ),
          ],
        );

        expect(
          find.byKey(const Key('context_menu_card')),
          findsOneWidget,
        );

        await tester.dragFrom(Offset.zero, const Offset(0, 100));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('context_menu_card')),
          findsNothing,
        );
      });
    });

    group('controller', () {
      test('isShowing returns false when no overlay is set', () {
        final controller = WnChatListContextMenuController();
        expect(controller.isShowing, isFalse);
      });

      testWidgets('isShowing returns true after show()', (tester) async {
        await openContextMenu(
          tester,
          actions: [
            WnChatListContextMenuAction(
              id: 'pin',
              label: 'Pin',
              icon: WnIcons.pin,
              onTap: () {},
            ),
          ],
        );

        expect(activeController!.isShowing, isTrue);
      });

      test('dismiss on fresh controller is a no-op', () {
        final controller = WnChatListContextMenuController();
        controller.dismiss();
        expect(controller.isShowing, isFalse);
      });

      test('dispose on fresh controller is a no-op', () {
        final controller = WnChatListContextMenuController();
        controller.dispose();
        expect(controller.isShowing, isFalse);
      });

      testWidgets(
        'isShowing returns false after dismiss',
        (tester) async {
          await openContextMenu(
            tester,
            actions: [
              WnChatListContextMenuAction(
                id: 'pin',
                label: 'Pin',
                icon: WnIcons.pin,
                onTap: () {},
              ),
            ],
          );

          expect(activeController!.isShowing, isTrue);

          activeController!.dismiss();
          await tester.pumpAndSettle();

          expect(activeController!.isShowing, isFalse);
        },
      );
    });

    group('WnChatListContextMenuAction', () {
      test('defaults isDestructive to false', () {
        final action = WnChatListContextMenuAction(
          id: 'pin',
          label: 'Pin',
          icon: WnIcons.pin,
          onTap: () {},
        );

        expect(action.isDestructive, isFalse);
      });

      test('stores id, label and icon', () {
        final action = WnChatListContextMenuAction(
          id: 'archive',
          label: 'Archive',
          icon: WnIcons.archive,
          onTap: () {},
        );

        expect(action.id, 'archive');
        expect(action.label, 'Archive');
        expect(action.icon, WnIcons.archive);
      });

      test('stores isDestructive when set to true', () {
        final action = WnChatListContextMenuAction(
          id: 'delete',
          label: 'Delete',
          icon: WnIcons.trashCan,
          onTap: () {},
          isDestructive: true,
        );

        expect(action.isDestructive, isTrue);
      });
    });
  });
}
