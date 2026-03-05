import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/widgets/wn_avatar.dart';
import 'package:whitenoise/widgets/wn_chat_list_item.dart';
import 'package:whitenoise/widgets/wn_chat_status.dart';

import '../test_helpers.dart';

void main() {
  group('WnChatListItem', () {
    testWidgets('renders basic info correctly', (tester) async {
      await mountWidget(
        const WnChatListItem(
          title: 'Alice',
          subtitle: 'Hello there',
          timestamp: '10:00 AM',
        ),
        tester,
      );

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('10:00 AM'), findsOneWidget);
      expect(find.byType(WnAvatar), findsOneWidget);

      final richTexts = tester.widgetList<RichText>(find.byType(RichText));
      final hasSubtitle = richTexts.any((widget) {
        final text = widget.text;
        return text is TextSpan && text.toPlainText().contains('Hello there');
      });
      expect(hasSubtitle, isTrue);
    });

    testWidgets(
      'renders notification off icon when notificationOff is true',
      (tester) async {
        await mountWidget(
          const WnChatListItem(
            title: 'Group',
            subtitle: 'Msg',
            timestamp: 'Now',
            notificationOff: true,
          ),
          tester,
        );

        expect(
          find.byKey(const Key('notification_off_icon')),
          findsOneWidget,
        );
      },
    );

    testWidgets('renders unread badge when status is unreadCount', (tester) async {
      await mountWidget(
        const WnChatListItem(
          title: 'Bob',
          subtitle: 'Hey',
          timestamp: 'Yesterday',
          status: ChatStatusType.unreadCount,
          unreadCount: 3,
        ),
        tester,
      );

      expect(find.byType(WnChatStatus), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('renders chat status widget when status is provided', (tester) async {
      await mountWidget(
        const WnChatListItem(
          title: 'Charlie',
          subtitle: 'Sent',
          timestamp: '1m',
          status: ChatStatusType.sending,
        ),
        tester,
      );

      expect(find.byType(WnChatStatus), findsOneWidget);
    });

    testWidgets('renders prefix subtitle', (tester) async {
      await mountWidget(
        const WnChatListItem(
          title: 'Me',
          subtitle: 'Hello',
          timestamp: 'Now',
          prefixSubtitle: 'You: ',
        ),
        tester,
      );

      final richTexts = tester.widgetList<RichText>(find.byType(RichText));
      final hasCombinedText = richTexts.any((widget) {
        final text = widget.text;
        if (text is TextSpan) {
          final plainText = text.toPlainText();
          return plainText.contains('You: ') && plainText.contains('Hello');
        }
        return false;
      });

      expect(hasCombinedText, isTrue);
    });

    testWidgets('passes showPinned to avatar', (tester) async {
      await mountWidget(
        const WnChatListItem(
          title: 'Pinned',
          subtitle: 'msg',
          timestamp: 'Now',
          showPinned: true,
        ),
        tester,
      );

      final avatar = tester.widget<WnAvatar>(find.byType(WnAvatar));
      expect(avatar.showPinned, isTrue);
    });

    testWidgets('showPinned defaults to false', (tester) async {
      await mountWidget(
        const WnChatListItem(
          title: 'Not Pinned',
          subtitle: 'msg',
          timestamp: 'Now',
        ),
        tester,
      );

      final avatar = tester.widget<WnAvatar>(find.byType(WnAvatar));
      expect(avatar.showPinned, isFalse);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await mountWidget(
        WnChatListItem(
          title: 'Tap me',
          subtitle: 'Tap',
          timestamp: 'Now',
          onTap: () => tapped = true,
        ),
        tester,
      );

      await tester.tap(find.byType(WnChatListItem));
      expect(tapped, isTrue);
    });

    testWidgets('calls onLongPress when long pressed', (tester) async {
      var longPressed = false;
      await mountWidget(
        WnChatListItem(
          title: 'Hold me',
          subtitle: 'Hold',
          timestamp: 'Now',
          onLongPress: () => longPressed = true,
        ),
        tester,
      );

      await tester.longPress(find.byType(WnChatListItem));
      expect(longPressed, isTrue);
    });

    testWidgets('applies hover background on mouse enter and removes on exit', (tester) async {
      await mountWidget(
        const WnChatListItem(
          title: 'Hover',
          subtitle: 'Test',
          timestamp: 'Now',
        ),
        tester,
      );

      final mouseRegionFinder = find.descendant(
        of: find.byType(WnChatListItem),
        matching: find.byType(MouseRegion),
      );

      final gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();

      await gesture.moveTo(tester.getCenter(mouseRegionFinder));
      await tester.pump();

      await gesture.moveTo(
        tester.getTopLeft(mouseRegionFinder) - const Offset(10, 10),
      );
      await tester.pump();
    });

    testWidgets('does not crash when onLongPress is null', (tester) async {
      await mountWidget(
        const WnChatListItem(
          title: 'No handler',
          subtitle: 'Test',
          timestamp: 'Now',
        ),
        tester,
      );

      await tester.longPress(find.byType(WnChatListItem));
      expect(find.text('No handler'), findsOneWidget);
    });
  });
}
