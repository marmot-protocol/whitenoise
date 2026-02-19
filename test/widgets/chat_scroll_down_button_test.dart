import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/widgets/chat_scroll_down_button.dart';

import '../test_helpers.dart';

void main() {
  group('ChatScrollDownButton', () {
    testWidgets('renders nothing when show is false', (tester) async {
      await mountWidget(
        const ChatScrollDownButton(show: false),
        tester,
      );

      expect(find.byKey(const Key('scroll_down_button')), findsNothing);
    });

    testWidgets('renders button when show is true', (tester) async {
      await mountWidget(
        const ChatScrollDownButton(show: true),
        tester,
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('scroll_down_button')), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await mountWidget(
        ChatScrollDownButton(
          show: true,
          onTap: () => tapped = true,
        ),
        tester,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('scroll_down_button')));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('contains arrow down icon', (tester) async {
      await mountWidget(
        const ChatScrollDownButton(show: true),
        tester,
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('scroll_down_button_icon')), findsOneWidget);
    });
  });
}
