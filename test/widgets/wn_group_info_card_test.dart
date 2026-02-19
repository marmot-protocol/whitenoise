import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/widgets/wn_avatar.dart';
import 'package:whitenoise/widgets/wn_group_info_card.dart';
import '../test_helpers.dart';

void main() {
  group('WnGroupInfoCard', () {
    testWidgets('displays avatar with color derived from groupId', (tester) async {
      await mountWidget(
        const WnGroupInfoCard(groupId: testPubkeyA),
        tester,
      );

      expect(find.byKey(const Key('group_info_avatar')), findsOneWidget);
      expect(find.byType(WnAvatar), findsOneWidget);
    });

    testWidgets('displays name when provided', (tester) async {
      await mountWidget(
        const WnGroupInfoCard(groupId: testPubkeyA, name: 'Test Group'),
        tester,
      );

      expect(find.byKey(const Key('group_info_name')), findsOneWidget);
      expect(find.text('Test Group'), findsOneWidget);
    });

    testWidgets('does not display name when null', (tester) async {
      await mountWidget(
        const WnGroupInfoCard(groupId: testPubkeyA),
        tester,
      );

      expect(find.byKey(const Key('group_info_name')), findsNothing);
    });

    testWidgets('does not display name when empty', (tester) async {
      await mountWidget(
        const WnGroupInfoCard(groupId: testPubkeyA, name: ''),
        tester,
      );

      expect(find.byKey(const Key('group_info_name')), findsNothing);
    });

    testWidgets('displays description when provided', (tester) async {
      await mountWidget(
        const WnGroupInfoCard(
          groupId: testPubkeyA,
          name: 'Test Group',
          description: 'A test group description',
        ),
        tester,
      );

      expect(find.byKey(const Key('group_info_description')), findsOneWidget);
      expect(find.text('A test group description'), findsOneWidget);
    });

    testWidgets('does not display description when null', (tester) async {
      await mountWidget(
        const WnGroupInfoCard(groupId: testPubkeyA, name: 'Test Group'),
        tester,
      );

      expect(find.byKey(const Key('group_info_description')), findsNothing);
    });

    testWidgets('does not display description when empty', (tester) async {
      await mountWidget(
        const WnGroupInfoCard(
          groupId: testPubkeyA,
          name: 'Test Group',
          description: '',
        ),
        tester,
      );

      expect(find.byKey(const Key('group_info_description')), findsNothing);
    });

    testWidgets('passes imagePath to avatar', (tester) async {
      await mountWidget(
        const WnGroupInfoCard(
          groupId: testPubkeyA,
          name: 'Test Group',
          imagePath: '/path/to/image.jpg',
        ),
        tester,
      );

      final avatar = tester.widget<WnAvatar>(find.byType(WnAvatar));
      expect(avatar.pictureUrl, '/path/to/image.jpg');
    });

    testWidgets('passes name as displayName to avatar', (tester) async {
      await mountWidget(
        const WnGroupInfoCard(groupId: testPubkeyA, name: 'My Group'),
        tester,
      );

      final avatar = tester.widget<WnAvatar>(find.byType(WnAvatar));
      expect(avatar.displayName, 'My Group');
    });

    testWidgets('passes empty string as displayName when name is null', (tester) async {
      await mountWidget(
        const WnGroupInfoCard(groupId: testPubkeyA),
        tester,
      );

      final avatar = tester.widget<WnAvatar>(find.byType(WnAvatar));
      expect(avatar.displayName, '');
    });

    testWidgets('uses large avatar size', (tester) async {
      await mountWidget(
        const WnGroupInfoCard(groupId: testPubkeyA),
        tester,
      );

      final avatar = tester.widget<WnAvatar>(find.byType(WnAvatar));
      expect(avatar.size, WnAvatarSize.large);
    });
  });
}
