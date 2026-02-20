import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_chat_info_actions.dart';
import 'package:whitenoise/widgets/wn_icon.dart';

import '../test_helpers.dart';

void main() {
  Future<void> pumpActions(
    WidgetTester tester, {
    required bool isOwnProfile,
    bool isFollowing = false,
    bool isFollowLoading = false,
    VoidCallback? onFollowTap,
    VoidCallback? onSearchTap,
    VoidCallback? onAddToGroupTap,
  }) async {
    await mountWidget(
      WnChatInfoActions(
        isOwnProfile: isOwnProfile,
        isFollowing: isFollowing,
        isFollowLoading: isFollowLoading,
        onFollowTap: onFollowTap ?? () {},
        onSearchTap: onSearchTap ?? () {},
        onAddToGroupTap: onAddToGroupTap ?? () {},
      ),
      tester,
    );
  }

  group('WnChatInfoActions', () {
    testWidgets('shows base action buttons', (tester) async {
      await pumpActions(tester, isOwnProfile: false);

      expect(find.byKey(const Key('search_button')), findsOneWidget);
      expect(find.byKey(const Key('contact_button')), findsOneWidget);
      expect(find.byKey(const Key('add_to_group_button')), findsOneWidget);
    });

    testWidgets('hides contact button for own profile', (tester) async {
      await pumpActions(tester, isOwnProfile: true);

      expect(find.byKey(const Key('contact_button')), findsNothing);
      expect(find.byKey(const Key('search_button')), findsOneWidget);
      expect(find.byKey(const Key('add_to_group_button')), findsOneWidget);
    });

    testWidgets('shows add as contact label when not following', (tester) async {
      await pumpActions(tester, isOwnProfile: false);
      expect(find.text('Add as contact'), findsOneWidget);
    });

    testWidgets('shows remove as contact label when following', (tester) async {
      await pumpActions(tester, isOwnProfile: false, isFollowing: true);
      expect(find.text('Remove as contact'), findsOneWidget);
    });

    testWidgets('shows loading on contact button', (tester) async {
      await pumpActions(
        tester,
        isOwnProfile: false,
        isFollowLoading: true,
      );

      final contactButton = tester.widget<WnButton>(find.byKey(const Key('contact_button')));
      expect(contactButton.loading, isTrue);
    });

    testWidgets('uses trailing icons from design', (tester) async {
      await pumpActions(tester, isOwnProfile: false);

      expect(
        tester.widget<WnButton>(find.byKey(const Key('search_button'))).trailingIcon,
        WnIcons.search,
      );
      expect(
        tester.widget<WnButton>(find.byKey(const Key('contact_button'))).trailingIcon,
        WnIcons.userFollow,
      );
      expect(
        tester.widget<WnButton>(find.byKey(const Key('add_to_group_button'))).trailingIcon,
        WnIcons.newGroupChat,
      );
    });

    testWidgets('uses unfollow icon when following', (tester) async {
      await pumpActions(tester, isOwnProfile: false, isFollowing: true);

      expect(
        tester.widget<WnButton>(find.byKey(const Key('contact_button'))).trailingIcon,
        WnIcons.userUnfollow,
      );
    });

    testWidgets('calls follow callback', (tester) async {
      var tapped = false;
      await pumpActions(
        tester,
        isOwnProfile: false,
        onFollowTap: () => tapped = true,
      );

      await tester.tap(find.byKey(const Key('contact_button')));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('calls search callback', (tester) async {
      var tapped = false;
      await pumpActions(
        tester,
        isOwnProfile: false,
        onSearchTap: () => tapped = true,
      );

      await tester.tap(find.byKey(const Key('search_button')));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('uses darker gray action button style', (tester) async {
      await pumpActions(tester, isOwnProfile: false);

      expect(
        tester.widget<WnButton>(find.byKey(const Key('search_button'))).type,
        WnButtonType.outline,
      );
      expect(
        tester.widget<WnButton>(find.byKey(const Key('contact_button'))).type,
        WnButtonType.outline,
      );
      expect(
        tester.widget<WnButton>(find.byKey(const Key('add_to_group_button'))).type,
        WnButtonType.outline,
      );
    });

    testWidgets('uses medium button size for action rows', (tester) async {
      await pumpActions(tester, isOwnProfile: false);

      expect(
        tester.widget<WnButton>(find.byKey(const Key('search_button'))).size,
        WnButtonSize.medium,
      );
      expect(
        tester.widget<WnButton>(find.byKey(const Key('contact_button'))).size,
        WnButtonSize.medium,
      );
      expect(
        tester.widget<WnButton>(find.byKey(const Key('add_to_group_button'))).size,
        WnButtonSize.medium,
      );
    });

    testWidgets('does not render mute action', (tester) async {
      await pumpActions(tester, isOwnProfile: false);

      expect(find.byKey(const Key('mute_button')), findsNothing);
      expect(find.text('Mute'), findsNothing);
    });

    testWidgets('calls add to group callback', (tester) async {
      var tapped = false;
      await pumpActions(
        tester,
        isOwnProfile: false,
        onAddToGroupTap: () => tapped = true,
      );

      await tester.tap(find.byKey(const Key('add_to_group_button')));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('does not render archive or delete actions', (tester) async {
      await pumpActions(tester, isOwnProfile: false);

      final context = tester.element(find.byType(WnChatInfoActions));
      expect(find.text(context.l10n.archive), findsNothing);
      expect(find.text(context.l10n.delete), findsNothing);
    });
  });
}
