import 'package:flutter/material.dart' show Key;
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/widgets/wn_chat_status.dart';
import 'package:whitenoise/widgets/wn_icon.dart';
import '../test_helpers.dart' show mountWidget;

void main() {
  group('WnChatStatus tests', () {
    group('Icon status types', () {
      testWidgets('displays checkmark_dashed icon for sending status', (WidgetTester tester) async {
        await mountWidget(const WnChatStatus(status: ChatStatusType.sending), tester);

        expect(find.byKey(const Key('chat_status_icon')), findsOneWidget);
        final icon = tester.widget<WnIcon>(find.byKey(const Key('chat_status_wn_icon')));
        expect(icon.icon, WnIcons.checkmarkDashed);
      });

      testWidgets('displays checkmark_outline icon for sent status', (
        WidgetTester tester,
      ) async {
        await mountWidget(const WnChatStatus(status: ChatStatusType.sent), tester);

        expect(find.byKey(const Key('chat_status_icon')), findsOneWidget);
        final icon = tester.widget<WnIcon>(find.byKey(const Key('chat_status_wn_icon')));
        expect(icon.icon, WnIcons.checkmarkOutline);
      });

      testWidgets('displays checkmark_filled icon for read status', (WidgetTester tester) async {
        await mountWidget(const WnChatStatus(status: ChatStatusType.read), tester);

        expect(find.byKey(const Key('chat_status_icon')), findsOneWidget);
        final icon = tester.widget<WnIcon>(find.byKey(const Key('chat_status_wn_icon')));
        expect(icon.icon, WnIcons.checkmarkFilled);
      });

      testWidgets('displays error icon for failed status', (WidgetTester tester) async {
        await mountWidget(const WnChatStatus(status: ChatStatusType.failed), tester);

        expect(find.byKey(const Key('chat_status_icon')), findsOneWidget);
        final icon = tester.widget<WnIcon>(find.byKey(const Key('chat_status_wn_icon')));
        expect(icon.icon, WnIcons.error);
      });

      testWidgets('displays add_filled icon for request status', (WidgetTester tester) async {
        await mountWidget(const WnChatStatus(status: ChatStatusType.request), tester);

        expect(find.byKey(const Key('chat_status_icon')), findsOneWidget);
        final icon = tester.widget<WnIcon>(find.byKey(const Key('chat_status_wn_icon')));
        expect(icon.icon, WnIcons.addFilled);
      });
    });

    group('Unread count badge', () {
      testWidgets('displays single digit count correctly', (WidgetTester tester) async {
        await mountWidget(
          const WnChatStatus(status: ChatStatusType.unreadCount, unreadCount: 1),
          tester,
        );

        expect(find.byKey(const Key('chat_status_unread_badge')), findsOneWidget);
        expect(find.text('1'), findsOneWidget);
      });

      testWidgets('displays single digit 9 correctly', (WidgetTester tester) async {
        await mountWidget(
          const WnChatStatus(status: ChatStatusType.unreadCount, unreadCount: 9),
          tester,
        );

        expect(find.text('9'), findsOneWidget);
      });

      testWidgets('displays double digit count correctly', (WidgetTester tester) async {
        await mountWidget(
          const WnChatStatus(status: ChatStatusType.unreadCount, unreadCount: 21),
          tester,
        );

        expect(find.byKey(const Key('chat_status_unread_badge')), findsOneWidget);
        expect(find.text('21'), findsOneWidget);
      });

      testWidgets('displays double digit 10 correctly', (WidgetTester tester) async {
        await mountWidget(
          const WnChatStatus(status: ChatStatusType.unreadCount, unreadCount: 10),
          tester,
        );

        expect(find.text('10'), findsOneWidget);
      });

      testWidgets('displays double digit 99 correctly', (WidgetTester tester) async {
        await mountWidget(
          const WnChatStatus(status: ChatStatusType.unreadCount, unreadCount: 99),
          tester,
        );

        expect(find.text('99'), findsOneWidget);
      });

      testWidgets('displays 99+ for counts over 99', (WidgetTester tester) async {
        await mountWidget(
          const WnChatStatus(status: ChatStatusType.unreadCount, unreadCount: 100),
          tester,
        );

        expect(find.byKey(const Key('chat_status_unread_badge')), findsOneWidget);
        expect(find.text('99+'), findsOneWidget);
      });

      testWidgets('displays 99+ for count 999', (WidgetTester tester) async {
        await mountWidget(
          const WnChatStatus(status: ChatStatusType.unreadCount, unreadCount: 999),
          tester,
        );

        expect(find.text('99+'), findsOneWidget);
      });

      testWidgets('displays 0 when unreadCount is 0', (WidgetTester tester) async {
        await mountWidget(
          const WnChatStatus(status: ChatStatusType.unreadCount, unreadCount: 0),
          tester,
        );

        expect(find.text('0'), findsOneWidget);
      });

      testWidgets('displays 0 when unreadCount is null', (WidgetTester tester) async {
        await mountWidget(const WnChatStatus(status: ChatStatusType.unreadCount), tester);

        expect(find.text('0'), findsOneWidget);
      });
    });

    group('Widget structure', () {
      testWidgets('icon status has correct widget structure', (WidgetTester tester) async {
        await mountWidget(const WnChatStatus(status: ChatStatusType.sending), tester);

        expect(find.byType(WnChatStatus), findsOneWidget);
        expect(find.byKey(const Key('chat_status_wn_icon')), findsOneWidget);
      });

      testWidgets('unread count has container with text', (WidgetTester tester) async {
        await mountWidget(
          const WnChatStatus(status: ChatStatusType.unreadCount, unreadCount: 5),
          tester,
        );

        expect(find.byType(WnChatStatus), findsOneWidget);
        expect(find.byKey(const Key('unread_count_container')), findsOneWidget);
        expect(find.byKey(const Key('unread_count_text')), findsOneWidget);
      });
    });

    group('Key parameter', () {
      testWidgets('respects custom key for sending status', (WidgetTester tester) async {
        await mountWidget(
          const WnChatStatus(key: Key('custom_chat_status'), status: ChatStatusType.sending),
          tester,
        );

        expect(find.byKey(const Key('custom_chat_status')), findsOneWidget);
      });

      testWidgets('respects custom key for unread count status', (WidgetTester tester) async {
        await mountWidget(
          const WnChatStatus(
            key: Key('custom_unread'),
            status: ChatStatusType.unreadCount,
            unreadCount: 3,
          ),
          tester,
        );

        expect(find.byKey(const Key('custom_unread')), findsOneWidget);
      });
    });

    group('All status types render', () {
      testWidgets('all ChatStatusType values render without errors', (WidgetTester tester) async {
        for (final status in ChatStatusType.values) {
          await mountWidget(
            WnChatStatus(
              status: status,
              unreadCount: status == ChatStatusType.unreadCount ? 5 : null,
            ),
            tester,
          );

          expect(find.byType(WnChatStatus), findsOneWidget);
        }
      });
    });
  });
}
