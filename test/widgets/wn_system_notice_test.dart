import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_icon.dart' show WnIcon, WnIcons;
import 'package:whitenoise/widgets/wn_system_notice.dart';

import '../test_helpers.dart';

const _animationDuration = Duration(milliseconds: 200);

void main() {
  testWidgets(
    'WnSystemNotice renders correctly with default properties',
    (tester) async {
      await mountWidget(
        const WnSystemNotice(title: 'Test Notice'),
        tester,
      );

      expect(find.text('Test Notice'), findsOneWidget);
      expect(find.byType(WnSystemNotice), findsOneWidget);
      expect(
        find.byKey(const ValueKey('systemNotice_leadingIcon')),
        findsOneWidget,
      );
    },
  );

  group('WnSystemNotice Types', () {
    testWidgets('renders success type correctly', (tester) async {
      await mountWidget(
        const WnSystemNotice(
          title: 'Success',
        ),
        tester,
      );

      final iconFinder = find.byKey(const ValueKey('systemNotice_leadingIcon'));
      expect(iconFinder, findsOneWidget);
      final icon = tester.widget<WnIcon>(iconFinder);
      expect(icon.icon, equals(WnIcons.checkmarkFilled));
    });

    testWidgets('renders info type correctly', (tester) async {
      await mountWidget(
        const WnSystemNotice(
          title: 'Info',
          type: WnSystemNoticeType.info,
        ),
        tester,
      );

      final iconFinder = find.byKey(const ValueKey('systemNotice_leadingIcon'));
      expect(iconFinder, findsOneWidget);
      final icon = tester.widget<WnIcon>(iconFinder);
      expect(icon.icon, equals(WnIcons.informationFilled));
    });

    testWidgets('renders warning type correctly', (tester) async {
      await mountWidget(
        const WnSystemNotice(
          title: 'Warning',
          type: WnSystemNoticeType.warning,
        ),
        tester,
      );

      final iconFinder = find.byKey(const ValueKey('systemNotice_leadingIcon'));
      expect(iconFinder, findsOneWidget);
      final icon = tester.widget<WnIcon>(iconFinder);
      expect(icon.icon, equals(WnIcons.warningFilled));
    });

    testWidgets('renders error type correctly', (tester) async {
      await mountWidget(
        const WnSystemNotice(
          title: 'Error',
          type: WnSystemNoticeType.error,
        ),
        tester,
      );

      final iconFinder = find.byKey(const ValueKey('systemNotice_leadingIcon'));
      expect(iconFinder, findsOneWidget);
      final icon = tester.widget<WnIcon>(iconFinder);
      expect(icon.icon, equals(WnIcons.errorFilled));
    });

    testWidgets('renders neutral type correctly', (tester) async {
      await mountWidget(
        const WnSystemNotice(
          title: 'Neutral',
          type: WnSystemNoticeType.neutral,
        ),
        tester,
      );
      expect(find.byType(WnIcon), findsNothing);
    });
  });

  group('WnSystemNotice Variants', () {
    testWidgets('Temporary variant renders title only', (tester) async {
      await mountWidget(
        const WnSystemNotice(
          title: 'Temporary',
          description: Text('Should not show'),
        ),
        tester,
      );

      expect(find.text('Temporary'), findsOneWidget);
      expect(find.text('Should not show'), findsNothing);
      expect(
        find.byKey(const ValueKey('systemNotice_actionIcon')),
        findsNothing,
      );
    });

    testWidgets('Dismissible variant renders dismiss icon', (tester) async {
      await mountWidget(
        WnSystemNotice(
          title: 'Dismissible',
          variant: WnSystemNoticeVariant.dismissible,
          onDismiss: () {},
        ),
        tester,
      );

      expect(
        find.byKey(const ValueKey('systemNotice_actionIcon')),
        findsOneWidget,
      );
    });

    testWidgets(
      'Collapsed variant renders chevron down and hides content',
      (tester) async {
        await mountWidget(
          WnSystemNotice(
            title: 'Collapsed',
            variant: WnSystemNoticeVariant.collapsed,
            description: const Text('Hidden Content'),
            onToggle: () {},
          ),
          tester,
        );

        expect(
          find.byKey(const ValueKey('systemNotice_actionIcon')),
          findsOneWidget,
        );
        expect(find.text('Hidden Content'), findsNothing);
      },
    );

    testWidgets(
      'Expanded variant renders chevron up and shows content',
      (tester) async {
        await mountWidget(
          WnSystemNotice(
            title: 'Expanded',
            variant: WnSystemNoticeVariant.expanded,
            description: const Text('Visible Content'),
            onToggle: () {},
          ),
          tester,
        );

        expect(
          find.byKey(const ValueKey('systemNotice_actionIcon')),
          findsOneWidget,
        );
        expect(find.text('Visible Content'), findsOneWidget);
      },
    );
  });

  group('Content and Actions', () {
    testWidgets('renders description when appropriate', (tester) async {
      await mountWidget(
        WnSystemNotice(
          title: 'Notice',
          description: const Text('Description text'),
          variant: WnSystemNoticeVariant.dismissible,
          onDismiss: () {},
        ),
        tester,
      );

      expect(find.text('Description text'), findsOneWidget);
    });

    testWidgets('renders actions when present', (tester) async {
      await mountWidget(
        WnSystemNotice(
          title: 'Notice',
          variant: WnSystemNoticeVariant.expanded,
          primaryAction: const WnButton(text: 'Primary', onPressed: null),
          secondaryAction: const WnButton(text: 'Secondary', onPressed: null),
          onToggle: () {},
        ),
        tester,
      );

      expect(find.text('Primary'), findsOneWidget);
      expect(find.text('Secondary'), findsOneWidget);
    });
  });

  group('Interactions', () {
    testWidgets('onDismiss callback is called', (tester) async {
      var dismissed = false;
      await mountWidget(
        WnSystemNotice(
          title: 'Dismiss me',
          variant: WnSystemNoticeVariant.dismissible,
          onDismiss: () => dismissed = true,
        ),
        tester,
      );

      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('systemNotice_actionIcon')));
      await tester.pumpAndSettle();
      expect(dismissed, isTrue);
    });

    testWidgets('onToggle callback is called', (tester) async {
      var toggled = false;
      await mountWidget(
        WnSystemNotice(
          title: 'Toggle me',
          variant: WnSystemNoticeVariant.collapsed,
          onToggle: () => toggled = true,
        ),
        tester,
      );

      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('systemNotice_actionIcon')));
      expect(toggled, isTrue);
    });
  });

  group('Action icon only renders when callback exists', () {
    testWidgets(
      'dismissible without onDismiss does not show action icon',
      (tester) async {
        await mountWidget(
          const WnSystemNotice(
            title: 'No callback',
            variant: WnSystemNoticeVariant.dismissible,
          ),
          tester,
        );

        expect(
          find.byKey(const ValueKey('systemNotice_actionIcon')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'collapsed without onToggle does not show action icon',
      (tester) async {
        await mountWidget(
          const WnSystemNotice(
            title: 'No callback',
            variant: WnSystemNoticeVariant.collapsed,
          ),
          tester,
        );

        expect(
          find.byKey(const ValueKey('systemNotice_actionIcon')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'expanded without onToggle does not show action icon',
      (tester) async {
        await mountWidget(
          const WnSystemNotice(
            title: 'No callback',
            variant: WnSystemNoticeVariant.expanded,
          ),
          tester,
        );

        expect(
          find.byKey(const ValueKey('systemNotice_actionIcon')),
          findsNothing,
        );
      },
    );
  });

  group('Entrance Animation', () {
    testWidgets('slides down from top on mount', (tester) async {
      await mountWidget(
        const WnSystemNotice(title: 'Animated Notice'),
        tester,
      );

      final slideTransition = tester.widget<SlideTransition>(
        find.byKey(const Key('systemNotice_slideTransition')),
      );
      expect(slideTransition.position.value, const Offset(0, -1));

      await tester.pumpAndSettle();

      expect(slideTransition.position.value, Offset.zero);
    });

    testWidgets('uses ClipRect to prevent overflow during animation', (tester) async {
      await mountWidget(
        const WnSystemNotice(title: 'Clipped Notice'),
        tester,
      );

      expect(find.byKey(const Key('systemNotice_clipRect')), findsOneWidget);
    });
  });

  group('Exit Animation', () {
    testWidgets('slides up when dismissed', (tester) async {
      var dismissed = false;
      await mountWidget(
        WnSystemNotice(
          title: 'Dismiss me',
          variant: WnSystemNoticeVariant.dismissible,
          onDismiss: () => dismissed = true,
        ),
        tester,
      );

      await tester.pumpAndSettle();

      final slideTransitionBefore = tester.widget<SlideTransition>(
        find.byKey(const Key('systemNotice_slideTransition')),
      );
      expect(slideTransitionBefore.position.value, Offset.zero);

      await tester.tap(find.byKey(const ValueKey('systemNotice_actionIcon')));
      await tester.pump();
      await tester.pump(_animationDuration ~/ 2);

      final slideTransitionMid = tester.widget<SlideTransition>(
        find.byKey(const Key('systemNotice_slideTransition')),
      );
      expect(slideTransitionMid.position.value.dy, lessThan(0));

      await tester.pumpAndSettle();

      expect(dismissed, isTrue);
    });

    testWidgets('onDismiss called after animation completes', (tester) async {
      var dismissed = false;
      await mountWidget(
        WnSystemNotice(
          title: 'Dismiss me',
          variant: WnSystemNoticeVariant.dismissible,
          onDismiss: () => dismissed = true,
        ),
        tester,
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('systemNotice_actionIcon')));
      await tester.pump();

      expect(dismissed, isFalse);

      await tester.pumpAndSettle();

      expect(dismissed, isTrue);
    });
  });

  group('Auto-hide', () {
    testWidgets(
      'temporary variant auto-hides after default duration (3s)',
      (tester) async {
        var dismissed = false;
        await mountWidget(
          WnSystemNotice(
            title: 'Auto-hide',
            onDismiss: () => dismissed = true,
          ),
          tester,
        );

        await tester.pumpAndSettle();

        expect(dismissed, isFalse);

        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();

        expect(dismissed, isTrue);
      },
    );

    testWidgets('custom autoHideDuration is respected', (tester) async {
      var dismissed = false;
      await mountWidget(
        WnSystemNotice(
          title: 'Custom duration',
          autoHideDuration: const Duration(seconds: 1),
          onDismiss: () => dismissed = true,
        ),
        tester,
      );

      await tester.pumpAndSettle();

      await tester.pump(const Duration(milliseconds: 500));
      expect(dismissed, isFalse);

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(dismissed, isTrue);
    });

    testWidgets('non-temporary variants do not auto-hide', (tester) async {
      var dismissed = false;
      await mountWidget(
        WnSystemNotice(
          title: 'No auto-hide',
          variant: WnSystemNoticeVariant.dismissible,
          onDismiss: () => dismissed = true,
        ),
        tester,
      );

      await tester.pumpAndSettle();

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      expect(dismissed, isFalse);
    });

    testWidgets('auto-hide timer cancelled on manual dismiss', (tester) async {
      var dismissCount = 0;
      await mountWidget(
        WnSystemNotice(
          title: 'Manual dismiss',
          variant: WnSystemNoticeVariant.dismissible,
          autoHideDuration: const Duration(seconds: 3),
          onDismiss: () => dismissCount++,
        ),
        tester,
      );

      await tester.pumpAndSettle();

      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.byKey(const ValueKey('systemNotice_actionIcon')));
      await tester.pumpAndSettle();

      expect(dismissCount, 1);

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(dismissCount, 1);
    });

    testWidgets('ignores queued dismiss callback after unmount', (tester) async {
      var dismissed = false;
      await mountWidget(
        WnSystemNotice(
          title: 'Auto-hide while navigating',
          variant: WnSystemNoticeVariant.dismissible,
          onDismiss: () => dismissed = true,
        ),
        tester,
      );

      await tester.pumpAndSettle();
      final dismissGesture = tester.widget<GestureDetector>(
        find.ancestor(
          of: find.byKey(const ValueKey('systemNotice_actionIcon')),
          matching: find.byType(GestureDetector),
        ),
      );
      final queuedDismiss = dismissGesture.onTap;
      expect(queuedDismiss, isNotNull);

      await tester.pumpWidget(const SizedBox.shrink());
      queuedDismiss!();
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(dismissed, isFalse);
    });

    testWidgets('cancels pending auto-hide timer on unmount', (tester) async {
      var dismissed = false;
      await mountWidget(
        WnSystemNotice(
          title: 'Auto-hide timer while navigating',
          autoHideDuration: const Duration(milliseconds: 50),
          onDismiss: () => dismissed = true,
        ),
        tester,
      );

      await tester.pump(const Duration(milliseconds: 30));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(dismissed, isFalse);
    });
  });

  group('Expand/Collapse Animation', () {
    testWidgets('expand animates height and fades in content', (tester) async {
      var isExpanded = false;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: WnSystemNotice(
                  title: 'Toggle me',
                  description: const Text('Content'),
                  variant: isExpanded
                      ? WnSystemNoticeVariant.expanded
                      : WnSystemNoticeVariant.collapsed,
                  onToggle: () {
                    setState(() => isExpanded = !isExpanded);
                  },
                ),
              ),
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Content'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('systemNotice_actionIcon')));
      await tester.pump();

      expect(find.byType(AnimatedSize), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('collapse animates height and fades out content', (tester) async {
      var isExpanded = true;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: WnSystemNotice(
                  title: 'Toggle me',
                  description: const Text('Content'),
                  variant: isExpanded
                      ? WnSystemNoticeVariant.expanded
                      : WnSystemNoticeVariant.collapsed,
                  onToggle: () {
                    setState(() => isExpanded = !isExpanded);
                  },
                ),
              ),
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Content'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('systemNotice_actionIcon')));
      await tester.pump();

      expect(find.byType(AnimatedSize), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.text('Content'), findsNothing);
    });
  });
}
