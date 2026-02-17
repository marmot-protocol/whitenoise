import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/widgets/wn_avatar.dart';
import 'package:whitenoise/widgets/wn_middle_ellipsis_text.dart';
import 'package:whitenoise/widgets/wn_user_item.dart';

import '../test_helpers.dart';

void main() {
  group('WnUserItem', () {
    group('small size', () {
      testWidgets('displays name and avatar', (tester) async {
        await mountWidget(
          const WnUserItem(displayName: 'Alice'),
          tester,
        );

        expect(find.byKey(const Key('user_item_name')), findsOneWidget);
        expect(find.text('Alice'), findsAtLeast(1));
        expect(find.byType(WnAvatar), findsOneWidget);
      });

      testWidgets('uses xSmall avatar size', (tester) async {
        await mountWidget(
          const WnUserItem(displayName: 'Alice'),
          tester,
        );

        final avatar = tester.widget<WnAvatar>(find.byType(WnAvatar));
        expect(avatar.size, WnAvatarSize.xSmall);
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

      testWidgets('does not show checkbox', (tester) async {
        await mountWidget(
          const WnUserItem(displayName: 'Alice', showCheckbox: true),
          tester,
        );

        expect(find.byKey(const Key('user_item_checkbox')), findsNothing);
      });

      testWidgets('does not show container', (tester) async {
        await mountWidget(
          const WnUserItem(displayName: 'Alice'),
          tester,
        );

        expect(find.byKey(const Key('user_item_container')), findsNothing);
      });
    });

    group('medium size', () {
      testWidgets('uses small avatar size', (tester) async {
        await mountWidget(
          const WnUserItem(
            displayName: 'Alice',
            size: WnUserItemSize.medium,
          ),
          tester,
        );

        final avatar = tester.widget<WnAvatar>(find.byType(WnAvatar));
        expect(avatar.size, WnAvatarSize.small);
      });

      testWidgets('displays npub with middle ellipsis', (tester) async {
        await mountWidget(
          const WnUserItem(
            displayName: 'Alice',
            npub: 'npub1zuuajd7u3sx8xu92yav9jwxpr839cs0kc3q6t56vd5u9q033xmhsk6c2uc',
            size: WnUserItemSize.medium,
          ),
          tester,
        );

        expect(find.byKey(const Key('user_item_npub')), findsOneWidget);
        expect(find.byType(WnMiddleEllipsisText), findsOneWidget);
      });

      testWidgets('npub allows two lines', (tester) async {
        await mountWidget(
          const WnUserItem(
            displayName: 'Alice',
            npub: 'npub1zuuajd7u3sx8xu92yav9jwxpr839cs0kc3q6t56vd5u9q033xmhsk6c2uc',
            size: WnUserItemSize.medium,
          ),
          tester,
        );

        final ellipsisText = tester.widget<WnMiddleEllipsisText>(
          find.byType(WnMiddleEllipsisText),
        );
        expect(ellipsisText.maxLines, 2);
      });

      testWidgets('hides npub when not provided', (tester) async {
        await mountWidget(
          const WnUserItem(
            displayName: 'Alice',
            size: WnUserItemSize.medium,
          ),
          tester,
        );

        expect(find.byKey(const Key('user_item_npub')), findsNothing);
      });

      testWidgets('shows checkbox when enabled', (tester) async {
        await mountWidget(
          const WnUserItem(
            displayName: 'Alice',
            size: WnUserItemSize.medium,
            showCheckbox: true,
          ),
          tester,
        );

        expect(find.byKey(const Key('user_item_checkbox')), findsOneWidget);
      });

      testWidgets('hides checkbox when not enabled', (tester) async {
        await mountWidget(
          const WnUserItem(
            displayName: 'Alice',
            size: WnUserItemSize.medium,
          ),
          tester,
        );

        expect(find.byKey(const Key('user_item_checkbox')), findsNothing);
      });

      testWidgets('shows checked icon when selected', (tester) async {
        await mountWidget(
          const WnUserItem(
            displayName: 'Alice',
            size: WnUserItemSize.medium,
            showCheckbox: true,
            isSelected: true,
          ),
          tester,
        );

        expect(find.byKey(const Key('user_item_checkbox')), findsOneWidget);
      });

      testWidgets('shows container with decoration', (tester) async {
        await mountWidget(
          const WnUserItem(
            displayName: 'Alice',
            size: WnUserItemSize.medium,
          ),
          tester,
        );

        final container = tester.widget<Container>(
          find.byKey(const Key('user_item_container')),
        );
        expect(container.decoration, isNotNull);
      });
    });

    group('big size', () {
      testWidgets('uses medium avatar size', (tester) async {
        await mountWidget(
          const WnUserItem(
            displayName: 'Alice',
            size: WnUserItemSize.big,
          ),
          tester,
        );

        final avatar = tester.widget<WnAvatar>(find.byType(WnAvatar));
        expect(avatar.size, WnAvatarSize.medium);
      });

      testWidgets('has fixed height container', (tester) async {
        await mountWidget(
          const WnUserItem(
            displayName: 'Alice',
            size: WnUserItemSize.big,
          ),
          tester,
        );

        final container = tester.widget<Container>(
          find.byKey(const Key('user_item_container')),
        );
        final constraints = container.constraints;
        expect(constraints, isNotNull);
      });

      testWidgets('displays npub with middle ellipsis', (tester) async {
        await mountWidget(
          const WnUserItem(
            displayName: 'Alice',
            npub: 'npub1zuuajd7u3sx8xu92yav9jwxpr839cs0kc3q6t56vd5u9q033xmhsk6c2uc',
            size: WnUserItemSize.big,
          ),
          tester,
        );

        expect(find.byKey(const Key('user_item_npub')), findsOneWidget);
        expect(find.byType(WnMiddleEllipsisText), findsOneWidget);
      });

      testWidgets('shows checkbox when enabled', (tester) async {
        await mountWidget(
          const WnUserItem(
            displayName: 'Alice',
            size: WnUserItemSize.big,
            showCheckbox: true,
          ),
          tester,
        );

        expect(find.byKey(const Key('user_item_checkbox')), findsOneWidget);
      });
    });

    group('shared properties', () {
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

      testWidgets('passes displayName to avatar', (tester) async {
        await mountWidget(
          const WnUserItem(displayName: 'Bob'),
          tester,
        );

        final avatar = tester.widget<WnAvatar>(find.byType(WnAvatar));
        expect(avatar.displayName, 'Bob');
      });

      testWidgets('wraps in GestureDetector when onTap provided', (tester) async {
        var tapped = false;

        await mountWidget(
          WnUserItem(
            displayName: 'Alice',
            onTap: () => tapped = true,
          ),
          tester,
        );

        await tester.tap(find.byKey(const Key('user_item_tap_target')));
        await tester.pumpAndSettle();

        expect(tapped, true);
      });

      testWidgets('does not wrap in GestureDetector when onTap is null', (tester) async {
        await mountWidget(
          const WnUserItem(displayName: 'Alice'),
          tester,
        );

        expect(find.byKey(const Key('user_item_tap_target')), findsNothing);
      });

      testWidgets('renders with all properties set', (tester) async {
        await mountWidget(
          WnUserItem(
            displayName: 'Charlie',
            label: 'Moderator',
            npub: 'npub1zuuajd7u3sx8xu92yav9jwxpr839cs0kc3q6t56vd5u9q033xmhsk6c2uc',
            pictureUrl: 'https://example.com/charlie.png',
            avatarColor: AvatarColor.emerald,
            imageProvider: testImageProvider,
            size: WnUserItemSize.medium,
            showCheckbox: true,
            isSelected: true,
            onTap: () {},
          ),
          tester,
        );

        expect(find.text('Charlie'), findsAtLeast(1));
        expect(find.byKey(const Key('user_item_npub')), findsOneWidget);
        expect(find.byKey(const Key('user_item_checkbox')), findsOneWidget);
        expect(find.byKey(const Key('user_item_tap_target')), findsOneWidget);

        final avatar = tester.widget<WnAvatar>(find.byType(WnAvatar));
        expect(avatar.color, AvatarColor.emerald);
        expect(avatar.imageProvider, testImageProvider);
      });
    });
  });
}
