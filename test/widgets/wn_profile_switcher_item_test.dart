import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/widgets/wn_middle_ellipsis_text.dart';
import 'package:whitenoise/widgets/wn_profile_switcher_item.dart';

import '../test_helpers.dart';

void main() {
  group('WnProfileSwitcherItem', () {
    testWidgets('displays name and public key', (tester) async {
      await mountWidget(
        WnProfileSwitcherItem(
          pubkey: testPubkeyA,
          displayName: 'Alice',
          onTap: () {},
        ),
        tester,
      );

      expect(find.text('Alice'), findsOneWidget);
      expect(find.byType(Text), findsAtLeast(2));
    });

    testWidgets('displays avatar', (tester) async {
      await mountWidget(
        WnProfileSwitcherItem(
          pubkey: testPubkeyA,
          displayName: 'Alice',
          onTap: () {},
        ),
        tester,
      );

      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('displays checkmark when selected', (tester) async {
      await mountWidget(
        WnProfileSwitcherItem(
          pubkey: testPubkeyA,
          displayName: 'Alice',
          isSelected: true,
          onTap: () {},
        ),
        tester,
      );

      expect(find.byKey(const Key('profile_switcher_item_checkmark')), findsOneWidget);
    });

    testWidgets('does not display checkmark when not selected', (tester) async {
      await mountWidget(
        WnProfileSwitcherItem(
          pubkey: testPubkeyA,
          displayName: 'Alice',
          onTap: () {},
        ),
        tester,
      );

      expect(find.byKey(const Key('profile_switcher_item_checkmark')), findsNothing);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;

      await mountWidget(
        WnProfileSwitcherItem(
          pubkey: testPubkeyA,
          displayName: 'Alice',
          onTap: () => tapped = true,
        ),
        tester,
      );

      await tester.tap(find.text('Alice'));
      await tester.pumpAndSettle();

      expect(tapped, true);
    });

    testWidgets('displays formatted pubkey when no displayName', (tester) async {
      await mountWidget(
        WnProfileSwitcherItem(
          pubkey: testPubkeyA,
          onTap: () {},
        ),
        tester,
      );

      expect(find.byType(Text), findsAtLeast(2));
    });

    testWidgets('handles pictureUrl parameter', (tester) async {
      await mountWidget(
        WnProfileSwitcherItem(
          pubkey: testPubkeyA,
          displayName: 'Alice',
          pictureUrl: 'https://example.com/avatar.png',
          onTap: () {},
        ),
        tester,
      );

      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets('applies background color when selected', (tester) async {
      await mountWidget(
        WnProfileSwitcherItem(
          pubkey: testPubkeyA,
          displayName: 'Alice',
          isSelected: true,
          onTap: () {},
        ),
        tester,
      );

      final container = tester.widget<Container>(
        find
            .ancestor(
              of: find.text('Alice'),
              matching: find.byType(Container),
            )
            .first,
      );

      expect(container.decoration, isNotNull);
    });

    testWidgets('renders with different pubkeys', (tester) async {
      await mountWidget(
        Column(
          children: [
            WnProfileSwitcherItem(
              pubkey: testPubkeyA,
              displayName: 'Alice',
              onTap: () {},
            ),
            WnProfileSwitcherItem(
              pubkey: testPubkeyB,
              displayName: 'Bob',
              onTap: () {},
            ),
          ],
        ),
        tester,
      );

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
    });

    testWidgets('handles long display names with ellipsis', (tester) async {
      await mountWidget(
        SizedBox(
          width: 200,
          child: WnProfileSwitcherItem(
            pubkey: testPubkeyA,
            displayName: 'This is a very long display name that should be truncated',
            onTap: () {},
          ),
        ),
        tester,
      );

      final textWidget = tester.widget<Text>(
        find.text(
          'This is a very long display name that should be truncated',
        ),
      );
      expect(textWidget.overflow, TextOverflow.ellipsis);
    });

    group('snapToWords', () {
      testWidgets('pubkey fallback name uses snapToWords', (tester) async {
        await mountWidget(
          WnProfileSwitcherItem(pubkey: testPubkeyA, onTap: () {}),
          tester,
        );

        final allEllipsis = tester.widgetList<WnMiddleEllipsisText>(
          find.byType(WnMiddleEllipsisText),
        );
        expect(allEllipsis.every((w) => w.snapToWords), isTrue);
      });

      testWidgets('secondary pubkey uses snapToWords', (tester) async {
        await mountWidget(
          WnProfileSwitcherItem(
            pubkey: testPubkeyA,
            displayName: 'Alice',
            onTap: () {},
          ),
          tester,
        );

        final ellipsis = tester.widget<WnMiddleEllipsisText>(
          find.byType(WnMiddleEllipsisText),
        );
        expect(ellipsis.snapToWords, isTrue);
      });
    });
  });
}
