import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/widgets/wn_avatar.dart';
import 'package:whitenoise/widgets/wn_user_bubble.dart';

import '../test_helpers.dart';

void main() {
  group('WnUserBubble', () {
    testWidgets('displays name text', (tester) async {
      await mountWidget(
        const WnUserBubble(displayName: 'Alice'),
        tester,
      );

      expect(find.byKey(const Key('user_bubble_name')), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets('displays avatar with bubble size', (tester) async {
      await mountWidget(
        const WnUserBubble(displayName: 'Alice'),
        tester,
      );

      expect(find.byKey(const Key('user_bubble_avatar')), findsOneWidget);
      final avatar = tester.widget<WnAvatar>(find.byType(WnAvatar));
      expect(avatar.size, WnAvatarSize.bubble);
    });

    testWidgets('displays close icon', (tester) async {
      await mountWidget(
        const WnUserBubble(displayName: 'Alice'),
        tester,
      );

      expect(find.byKey(const Key('user_bubble_close')), findsOneWidget);
    });

    testWidgets('passes avatar color', (tester) async {
      await mountWidget(
        const WnUserBubble(
          displayName: 'Alice',
          avatarColor: AvatarColor.violet,
        ),
        tester,
      );

      final avatar = tester.widget<WnAvatar>(find.byType(WnAvatar));
      expect(avatar.color, AvatarColor.violet);
    });

    testWidgets('is tappable when onTap is provided', (tester) async {
      var tapped = false;
      await mountWidget(
        WnUserBubble(
          displayName: 'Alice',
          onTap: () => tapped = true,
        ),
        tester,
      );

      await tester.tap(find.byKey(const Key('user_bubble_tap_target')));
      expect(tapped, isTrue);
    });
  });
}
