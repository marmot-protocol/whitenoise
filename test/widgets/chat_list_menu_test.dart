import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/widgets/chat_list_menu.dart';
import 'package:whitenoise/widgets/wn_icon.dart';

import '../test_helpers.dart' show mountWidget;

void main() {
  group('ChatListMenu', () {
    ChatListMenuController? activeController;

    tearDown(() {
      activeController?.dismiss();
      activeController = null;
    });

    Future<void> openContextMenu(
      WidgetTester tester, {
      required List<ChatListAction> actions,
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
                  activeController = ChatListMenu.show(
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
            ChatListAction(
              id: 'pin',
              label: 'Pin',
              icon: WnIcons.pin,
              onTap: () async {},
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
            ChatListAction(
              id: 'pin',
              label: 'Pin',
              icon: WnIcons.pin,
              onTap: () async {},
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
            ChatListAction(
              id: 'pin',
              label: 'Pin',
              icon: WnIcons.pin,
              onTap: () async {},
            ),
            ChatListAction(
              id: 'archive',
              label: 'Archive',
              icon: WnIcons.archive,
              onTap: () async {},
            ),
            ChatListAction(
              id: 'delete',
              label: 'Delete',
              icon: WnIcons.trashCan,
              onTap: () async {},
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
            ChatListAction(
              id: 'pin',
              label: 'Pin',
              icon: WnIcons.pin,
              onTap: () async {},
            ),
            ChatListAction(
              id: 'archive',
              label: 'Archive',
              icon: WnIcons.archive,
              onTap: () async {},
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
            ChatListAction(
              id: 'delete',
              label: 'Delete',
              icon: WnIcons.trashCan,
              onTap: () async {},
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
            ChatListAction(
              id: 'pin',
              label: 'Pin',
              icon: WnIcons.pin,
              onTap: () async {},
            ),
          ],
        );

        expect(find.byType(BackdropFilter), findsOneWidget);
      });

      testWidgets('renders single action', (tester) async {
        await openContextMenu(
          tester,
          actions: [
            ChatListAction(
              id: 'mute',
              label: 'Mute',
              icon: WnIcons.notificationOff,
              onTap: () async {},
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
            ChatListAction(
              id: 'pin',
              label: 'Pin',
              icon: WnIcons.pin,
              onTap: () async => pinCalled = true,
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
            ChatListAction(
              id: 'pin',
              label: 'Pin',
              icon: WnIcons.pin,
              onTap: () async {},
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
            ChatListAction(
              id: 'pin',
              label: 'Pin',
              icon: WnIcons.pin,
              onTap: () async {},
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
            ChatListAction(
              id: 'pin',
              label: 'Pin',
              icon: WnIcons.pin,
              onTap: () async {},
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
            ChatListAction(
              id: 'pin',
              label: 'Pin',
              icon: WnIcons.pin,
              onTap: () async => pinCalled = true,
            ),
            ChatListAction(
              id: 'archive',
              label: 'Archive',
              icon: WnIcons.archive,
              onTap: () async => archiveCalled = true,
            ),
            ChatListAction(
              id: 'delete',
              label: 'Delete',
              icon: WnIcons.trashCan,
              onTap: () async => deleteCalled = true,
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
            ChatListAction(
              id: 'pin',
              label: 'Pin',
              icon: WnIcons.pin,
              onTap: () async {},
            ),
          ],
        );

        expect(
          find.byType(ChatListMenu),
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
            ChatListAction(
              id: 'pin',
              label: 'Pin',
              icon: WnIcons.pin,
              onTap: () async {},
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
        final controller = ChatListMenuController();
        expect(controller.isShowing, isFalse);
      });

      testWidgets('isShowing returns true after show()', (tester) async {
        await openContextMenu(
          tester,
          actions: [
            ChatListAction(
              id: 'pin',
              label: 'Pin',
              icon: WnIcons.pin,
              onTap: () async {},
            ),
          ],
        );

        expect(activeController!.isShowing, isTrue);
      });

      test('dismiss on fresh controller is a no-op', () {
        final controller = ChatListMenuController();
        controller.dismiss();
        expect(controller.isShowing, isFalse);
      });

      testWidgets(
        'isShowing returns false after dismiss',
        (tester) async {
          await openContextMenu(
            tester,
            actions: [
              ChatListAction(
                id: 'pin',
                label: 'Pin',
                icon: WnIcons.pin,
                onTap: () async {},
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

    group('ChatListAction', () {
      test('defaults isDestructive to false', () {
        final action = ChatListAction(
          id: 'pin',
          label: 'Pin',
          icon: WnIcons.pin,
          onTap: () async {},
        );

        expect(action.isDestructive, isFalse);
      });

      test('defaults autoDismiss to true', () {
        final action = ChatListAction(
          id: 'pin',
          label: 'Pin',
          icon: WnIcons.pin,
          onTap: () async {},
        );

        expect(action.autoDismiss, isTrue);
      });

      test('stores id, label and icon', () {
        final action = ChatListAction(
          id: 'archive',
          label: 'Archive',
          icon: WnIcons.archive,
          onTap: () async {},
        );

        expect(action.id, 'archive');
        expect(action.label, 'Archive');
        expect(action.icon, WnIcons.archive);
      });

      test('stores isDestructive when set to true', () {
        final action = ChatListAction(
          id: 'delete',
          label: 'Delete',
          icon: WnIcons.trashCan,
          onTap: () async {},
          isDestructive: true,
        );

        expect(action.isDestructive, isTrue);
      });

      test('stores autoDismiss when set to false', () {
        final action = ChatListAction(
          id: 'leave_group',
          label: 'Leave group',
          icon: WnIcons.leave,
          onTap: () async {},
          autoDismiss: false,
        );

        expect(action.autoDismiss, isFalse);
      });
    });

    group('PopScope / Android back', () {
      testWidgets('Android back dismisses overlay when no onBack registered', (tester) async {
        await openContextMenu(
          tester,
          actions: [
            ChatListAction(
              id: 'pin',
              label: 'Pin',
              icon: WnIcons.pin,
              onTap: () async {},
            ),
          ],
        );

        expect(find.byKey(const Key('context_menu_card')), findsOneWidget);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('context_menu_card')), findsNothing);
      });

      testWidgets('Android back calls onBack when registered', (tester) async {
        var onBackCalled = false;

        await openContextMenu(
          tester,
          actions: [
            ChatListAction(
              id: 'pin',
              label: 'Pin',
              icon: WnIcons.pin,
              onTap: () async {},
            ),
          ],
        );

        activeController!.updateState(
          [
            ChatListAction(
              id: 'confirm',
              label: 'Confirm',
              icon: WnIcons.pin,
              onTap: () async {},
            ),
          ],
          title: 'Step 2',
          onBack: () => onBackCalled = true,
        );
        await tester.pumpAndSettle();

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        expect(onBackCalled, isTrue);
        expect(find.byKey(const Key('context_menu_card')), findsOneWidget);
      });
    });

    group('title header', () {
      testWidgets('no title renders no navigation header', (tester) async {
        await openContextMenu(
          tester,
          actions: [
            ChatListAction(
              id: 'pin',
              label: 'Pin',
              icon: WnIcons.pin,
              onTap: () async {},
            ),
          ],
        );

        expect(
          find.byKey(const Key('context_menu_navigation_header')),
          findsNothing,
        );
      });

      testWidgets('title renders header text after updateState', (tester) async {
        await openContextMenu(
          tester,
          actions: [
            ChatListAction(
              id: 'pin',
              label: 'Pin',
              icon: WnIcons.pin,
              onTap: () async {},
            ),
          ],
        );

        activeController!.updateState(
          [
            ChatListAction(
              id: 'confirm',
              label: 'Confirm',
              icon: WnIcons.pin,
              onTap: () async {},
            ),
          ],
          title: 'Leave group',
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('context_menu_navigation_header')), findsOneWidget);
        expect(find.text('Leave group'), findsOneWidget);
      });

      testWidgets('title back arrow calls onBack', (tester) async {
        var onBackCalled = false;

        await openContextMenu(
          tester,
          actions: [
            ChatListAction(
              id: 'pin',
              label: 'Pin',
              icon: WnIcons.pin,
              onTap: () async {},
            ),
          ],
        );

        activeController!.updateState(
          [
            ChatListAction(
              id: 'confirm',
              label: 'Confirm',
              icon: WnIcons.pin,
              onTap: () async {},
            ),
          ],
          title: 'Step 2',
          onBack: () => onBackCalled = true,
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('slate_back_button')));
        await tester.pumpAndSettle();

        expect(onBackCalled, isTrue);
      });

      testWidgets('no back arrow when title set but no onBack', (tester) async {
        await openContextMenu(
          tester,
          actions: [
            ChatListAction(
              id: 'pin',
              label: 'Pin',
              icon: WnIcons.pin,
              onTap: () async {},
            ),
          ],
        );

        activeController!.updateState(
          [
            ChatListAction(
              id: 'confirm',
              label: 'Confirm',
              icon: WnIcons.pin,
              onTap: () async {},
            ),
          ],
          title: 'Step 2',
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('slate_back_button')), findsNothing);
      });
    });

    group('updateState', () {
      testWidgets('updateState replaces action buttons', (tester) async {
        await openContextMenu(
          tester,
          actions: [
            ChatListAction(
              id: 'pin',
              label: 'Pin',
              icon: WnIcons.pin,
              onTap: () async {},
            ),
          ],
        );

        expect(find.byKey(const Key('context_menu_action_pin')), findsOneWidget);

        activeController!.updateState([
          ChatListAction(
            id: 'confirm',
            label: 'Confirm action',
            icon: WnIcons.pin,
            onTap: () async {},
          ),
        ]);
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('context_menu_action_pin')), findsNothing);
        expect(find.byKey(const Key('context_menu_action_confirm')), findsOneWidget);
      });

      testWidgets('action with autoDismiss false does not dismiss on tap', (tester) async {
        var tapCalled = false;

        await openContextMenu(
          tester,
          actions: [
            ChatListAction(
              id: 'no_dismiss',
              label: 'No dismiss',
              icon: WnIcons.pin,
              autoDismiss: false,
              onTap: () async => tapCalled = true,
            ),
          ],
        );

        await tester.tap(find.byKey(const Key('context_menu_action_no_dismiss')));
        await tester.pumpAndSettle();

        expect(tapCalled, isTrue);
        expect(find.byKey(const Key('context_menu_card')), findsOneWidget);
      });

      testWidgets('middleContent is shown after updateState', (tester) async {
        await openContextMenu(
          tester,
          actions: [
            ChatListAction(
              id: 'pin',
              label: 'Pin',
              icon: WnIcons.pin,
              onTap: () async {},
            ),
          ],
        );

        activeController!.updateState(
          [
            ChatListAction(
              id: 'confirm',
              label: 'Confirm',
              icon: WnIcons.pin,
              onTap: () async {},
            ),
          ],
          middleContent: const Text('Warning message'),
        );
        await tester.pumpAndSettle();

        expect(find.text('Warning message'), findsOneWidget);
      });

      testWidgets('systemNotice is shown after updateState', (tester) async {
        await openContextMenu(
          tester,
          actions: [
            ChatListAction(
              id: 'pin',
              label: 'Pin',
              icon: WnIcons.pin,
              onTap: () async {},
            ),
          ],
        );

        activeController!.updateState(
          [
            ChatListAction(
              id: 'confirm',
              label: 'Confirm',
              icon: WnIcons.pin,
              onTap: () async {},
            ),
          ],
          systemNotice: const Text('System notice message'),
        );
        await tester.pumpAndSettle();

        expect(find.text('System notice message'), findsOneWidget);
      });

      testWidgets('menu card remains visible when systemNotice is shown', (tester) async {
        await openContextMenu(
          tester,
          actions: [
            ChatListAction(
              id: 'pin',
              label: 'Pin',
              icon: WnIcons.pin,
              onTap: () async {},
            ),
          ],
        );

        activeController!.updateState(
          [
            ChatListAction(
              id: 'confirm',
              label: 'Confirm',
              icon: WnIcons.pin,
              onTap: () async {},
            ),
          ],
          systemNotice: const Text('System notice message'),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('context_menu_card')), findsOneWidget);
      });
    });
  });
}
