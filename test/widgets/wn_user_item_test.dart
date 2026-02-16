import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/widgets/wn_avatar.dart';
import 'package:whitenoise/widgets/wn_user_item.dart';

import '../test_helpers.dart';

void main() {
  group('WnUserItem', () {
    testWidgets('displays name and avatar', (tester) async {
      await mountWidget(
        const WnUserItem(displayName: 'Alice'),
        tester,
      );

      expect(find.byKey(const Key('user_item_name')), findsOneWidget);
      expect(find.text('Alice'), findsAtLeast(1));
      expect(find.byType(WnAvatar), findsOneWidget);
    });

    testWidgets('displays label when provided', (tester) async {
      await mountWidget(
        const WnUserItem(displayName: 'Alice', label: 'Admin'),
        tester,
      );

      expect(find.byKey(const Key('user_item_label')), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);
    });

    testWidgets('hides label when not provided', (tester) async {
      await mountWidget(
        const WnUserItem(displayName: 'Alice'),
        tester,
      );

      expect(find.byKey(const Key('user_item_label')), findsNothing);
    });

    testWidgets('uses xSmall avatar size', (tester) async {
      await mountWidget(
        const WnUserItem(displayName: 'Alice'),
        tester,
      );

      final avatar = tester.widget<WnAvatar>(find.byType(WnAvatar));
      expect(avatar.size, WnAvatarSize.xSmall);
    });

    testWidgets('passes pictureUrl to avatar', (tester) async {
      await mountWidget(
        const WnUserItem(
          displayName: 'Alice',
          pictureUrl: 'https://example.com/avatar.png',
        ),
        tester,
      );

      final avatar = tester.widget<WnAvatar>(find.byType(WnAvatar));
      expect(avatar.pictureUrl, 'https://example.com/avatar.png');
    });

    testWidgets('passes avatarColor to avatar', (tester) async {
      await mountWidget(
        const WnUserItem(
          displayName: 'Alice',
          avatarColor: AvatarColor.blue,
        ),
        tester,
      );

      final avatar = tester.widget<WnAvatar>(find.byType(WnAvatar));
      expect(avatar.color, AvatarColor.blue);
    });

    testWidgets('uses neutral avatar color by default', (tester) async {
      await mountWidget(
        const WnUserItem(displayName: 'Alice'),
        tester,
      );

      final avatar = tester.widget<WnAvatar>(find.byType(WnAvatar));
      expect(avatar.color, AvatarColor.neutral);
    });

    testWidgets('passes imageProvider to avatar', (tester) async {
      await mountWidget(
        WnUserItem(
          displayName: 'Alice',
          imageProvider: testImageProvider,
        ),
        tester,
      );

      final avatar = tester.widget<WnAvatar>(find.byType(WnAvatar));
      expect(avatar.imageProvider, testImageProvider);
    });

    testWidgets('name truncates with ellipsis on overflow', (tester) async {
      await mountWidget(
        const SizedBox(
          width: 150,
          child: WnUserItem(
            displayName: 'This is a very long display name that should be truncated',
          ),
        ),
        tester,
      );

      final nameWidget = tester.widget<Text>(
        find.byKey(const Key('user_item_name')),
      );
      expect(nameWidget.overflow, TextOverflow.ellipsis);
      expect(nameWidget.maxLines, 1);
    });

    testWidgets('label truncates with ellipsis on overflow', (tester) async {
      await mountWidget(
        const SizedBox(
          width: 150,
          child: WnUserItem(
            displayName: 'Alice',
            label: 'This is a very long label that should be truncated with ellipsis',
          ),
        ),
        tester,
      );

      final labelWidget = tester.widget<Text>(
        find.byKey(const Key('user_item_label')),
      );
      expect(labelWidget.overflow, TextOverflow.ellipsis);
      expect(labelWidget.maxLines, 1);
    });

    testWidgets('passes displayName to avatar', (tester) async {
      await mountWidget(
        const WnUserItem(displayName: 'Bob'),
        tester,
      );

      final avatar = tester.widget<WnAvatar>(find.byType(WnAvatar));
      expect(avatar.displayName, 'Bob');
    });

    testWidgets('renders with all properties set', (tester) async {
      await mountWidget(
        WnUserItem(
          displayName: 'Charlie',
          label: 'Moderator',
          pictureUrl: 'https://example.com/charlie.png',
          avatarColor: AvatarColor.emerald,
          imageProvider: testImageProvider,
        ),
        tester,
      );

      expect(find.text('Charlie'), findsAtLeast(1));
      expect(find.text('Moderator'), findsOneWidget);

      final avatar = tester.widget<WnAvatar>(find.byType(WnAvatar));
      expect(avatar.color, AvatarColor.emerald);
      expect(avatar.imageProvider, testImageProvider);
    });
  });
}
