import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/theme/semantic_colors.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_icon.dart';
import '../test_helpers.dart' show mountWidget;

void main() {
  group('WnButton tests', () {
    group('basic functionality', () {
      testWidgets('displays text', (WidgetTester tester) async {
        final widget = WnButton(
          text: 'Click me',
          onPressed: () {},
        );
        await mountWidget(widget, tester);
        expect(find.text('Click me'), findsOneWidget);
      });

      testWidgets('calls onPressed when tapped', (WidgetTester tester) async {
        var onPressedCalled = false;
        final widget = WnButton(
          text: 'Click me',
          onPressed: () {
            onPressedCalled = true;
          },
        );
        await mountWidget(widget, tester);
        await tester.tap(find.byType(WnButton));
        expect(onPressedCalled, isTrue);
      });
    });

    group('button types', () {
      testWidgets('renders primary type by default', (WidgetTester tester) async {
        final widget = WnButton(
          text: 'Primary',
          onPressed: () {},
        );
        await mountWidget(widget, tester);
        expect(find.text('Primary'), findsOneWidget);
      });

      testWidgets('renders outline type', (WidgetTester tester) async {
        final widget = WnButton(
          text: 'Outline',
          onPressed: () {},
          type: WnButtonType.outline,
        );
        await mountWidget(widget, tester);
        expect(find.text('Outline'), findsOneWidget);
      });

      testWidgets('renders ghost type', (WidgetTester tester) async {
        final widget = WnButton(
          text: 'Ghost',
          onPressed: () {},
          type: WnButtonType.ghost,
        );
        await mountWidget(widget, tester);
        expect(find.text('Ghost'), findsOneWidget);
      });

      testWidgets('renders overlay type', (WidgetTester tester) async {
        final widget = WnButton(
          text: 'Overlay',
          onPressed: () {},
          type: WnButtonType.overlay,
        );
        await mountWidget(widget, tester);
        expect(find.text('Overlay'), findsOneWidget);
      });

      testWidgets('renders destructive type', (WidgetTester tester) async {
        final widget = WnButton(
          text: 'Destructive',
          onPressed: () {},
          type: WnButtonType.destructive,
        );
        await mountWidget(widget, tester);
        expect(find.text('Destructive'), findsOneWidget);
      });
    });

    group('button sizes', () {
      testWidgets('renders large size by default', (WidgetTester tester) async {
        final widget = WnButton(
          text: 'Large',
          onPressed: () {},
        );
        await mountWidget(widget, tester);
        expect(find.text('Large'), findsOneWidget);
      });

      testWidgets('renders medium size', (WidgetTester tester) async {
        final widget = WnButton(
          text: 'Medium',
          onPressed: () {},
          size: WnButtonSize.medium,
        );
        await mountWidget(widget, tester);
        expect(find.text('Medium'), findsOneWidget);
      });

      testWidgets('renders small size', (WidgetTester tester) async {
        final widget = WnButton(
          text: 'Small',
          onPressed: () {},
          size: WnButtonSize.small,
        );
        await mountWidget(widget, tester);
        expect(find.text('Small'), findsOneWidget);
      });

      testWidgets('renders xsmall size', (WidgetTester tester) async {
        final widget = WnButton(
          text: 'XSmall',
          onPressed: () {},
          size: WnButtonSize.xsmall,
        );
        await mountWidget(widget, tester);
        expect(find.text('XSmall'), findsOneWidget);
      });
    });

    group('icons', () {
      testWidgets('renders leading icon when provided', (WidgetTester tester) async {
        final widget = WnButton(
          text: 'With Icon',
          onPressed: () {},
          leadingIcon: WnIcons.addLarge,
        );
        await mountWidget(widget, tester);
        expect(find.byKey(const Key('leading_icon')), findsOneWidget);
      });

      testWidgets('renders trailing icon when provided', (WidgetTester tester) async {
        final widget = WnButton(
          text: 'With Icon',
          onPressed: () {},
          trailingIcon: WnIcons.arrowRight,
        );
        await mountWidget(widget, tester);
        expect(find.byKey(const Key('trailing_icon')), findsOneWidget);
      });

      testWidgets('renders both leading and trailing icons', (WidgetTester tester) async {
        final widget = WnButton(
          text: 'With Icons',
          onPressed: () {},
          leadingIcon: WnIcons.addLarge,
          trailingIcon: WnIcons.arrowRight,
        );
        await mountWidget(widget, tester);
        expect(find.byKey(const Key('leading_icon')), findsOneWidget);
        expect(find.byKey(const Key('trailing_icon')), findsOneWidget);
      });

      testWidgets('does not render icons when not provided', (WidgetTester tester) async {
        final widget = WnButton(
          text: 'No Icons',
          onPressed: () {},
        );
        await mountWidget(widget, tester);
        expect(find.byKey(const Key('leading_icon')), findsNothing);
        expect(find.byKey(const Key('trailing_icon')), findsNothing);
      });
    });

    group('loading state', () {
      testWidgets('displays loading indicator when loading', (WidgetTester tester) async {
        final widget = WnButton(
          text: 'Loading',
          onPressed: () {},
          loading: true,
        );
        await mountWidget(widget, tester);
        expect(find.byKey(const Key('loading_indicator')), findsOneWidget);
      });

      testWidgets('hides text when loading', (WidgetTester tester) async {
        final widget = WnButton(
          text: 'Loading',
          onPressed: () {},
          loading: true,
        );
        await mountWidget(widget, tester);
        expect(find.text('Loading'), findsNothing);
      });

      testWidgets('does not call onPressed when loading', (WidgetTester tester) async {
        var onPressedCalled = false;
        final widget = WnButton(
          text: 'Loading',
          onPressed: () {
            onPressedCalled = true;
          },
          loading: true,
        );
        await mountWidget(widget, tester);
        await tester.tap(find.byType(WnButton));
        expect(onPressedCalled, isFalse);
      });

      testWidgets('hides icons when loading', (WidgetTester tester) async {
        final widget = WnButton(
          text: 'Loading',
          onPressed: () {},
          loading: true,
          leadingIcon: WnIcons.addLarge,
          trailingIcon: WnIcons.arrowRight,
        );
        await mountWidget(widget, tester);
        expect(find.byKey(const Key('leading_icon')), findsNothing);
        expect(find.byKey(const Key('trailing_icon')), findsNothing);
      });
    });

    group('disabled state', () {
      testWidgets('displays text when disabled', (WidgetTester tester) async {
        final widget = WnButton(
          text: 'Disabled',
          onPressed: () {},
          disabled: true,
        );
        await mountWidget(widget, tester);
        expect(find.text('Disabled'), findsOneWidget);
      });

      testWidgets('does not display loading indicator when disabled', (WidgetTester tester) async {
        final widget = WnButton(
          text: 'Disabled',
          onPressed: () {},
          disabled: true,
        );
        await mountWidget(widget, tester);
        expect(find.byKey(const Key('loading_indicator')), findsNothing);
      });

      testWidgets('does not call onPressed when disabled', (WidgetTester tester) async {
        var onPressedCalled = false;
        final widget = WnButton(
          text: 'Disabled',
          onPressed: () {
            onPressedCalled = true;
          },
          disabled: true,
        );
        await mountWidget(widget, tester);
        await tester.tap(find.byType(WnButton));
        expect(onPressedCalled, isFalse);
      });

      testWidgets('displays icons when disabled', (WidgetTester tester) async {
        final widget = WnButton(
          text: 'Disabled',
          onPressed: () {},
          disabled: true,
          leadingIcon: WnIcons.addLarge,
          trailingIcon: WnIcons.arrowRight,
        );
        await mountWidget(widget, tester);
        expect(find.byKey(const Key('leading_icon')), findsOneWidget);
        expect(find.byKey(const Key('trailing_icon')), findsOneWidget);
      });
    });

    group('disabled state for each button type', () {
      testWidgets('primary button respects disabled state', (WidgetTester tester) async {
        var onPressedCalled = false;
        final widget = WnButton(
          text: 'Primary',
          onPressed: () {
            onPressedCalled = true;
          },
          disabled: true,
        );
        await mountWidget(widget, tester);
        await tester.tap(find.byType(WnButton));
        expect(onPressedCalled, isFalse);
      });

      testWidgets('outline button respects disabled state', (WidgetTester tester) async {
        var onPressedCalled = false;
        final widget = WnButton(
          text: 'Outline',
          onPressed: () {
            onPressedCalled = true;
          },
          type: WnButtonType.outline,
          disabled: true,
        );
        await mountWidget(widget, tester);
        await tester.tap(find.byType(WnButton));
        expect(onPressedCalled, isFalse);
      });

      testWidgets('ghost button respects disabled state', (WidgetTester tester) async {
        var onPressedCalled = false;
        final widget = WnButton(
          text: 'Ghost',
          onPressed: () {
            onPressedCalled = true;
          },
          type: WnButtonType.ghost,
          disabled: true,
        );
        await mountWidget(widget, tester);
        await tester.tap(find.byType(WnButton));
        expect(onPressedCalled, isFalse);
      });

      testWidgets('overlay button respects disabled state', (WidgetTester tester) async {
        var onPressedCalled = false;
        final widget = WnButton(
          text: 'Overlay',
          onPressed: () {
            onPressedCalled = true;
          },
          type: WnButtonType.overlay,
          disabled: true,
        );
        await mountWidget(widget, tester);
        await tester.tap(find.byType(WnButton));
        expect(onPressedCalled, isFalse);
      });

      testWidgets('destructive button respects disabled state', (WidgetTester tester) async {
        var onPressedCalled = false;
        final widget = WnButton(
          text: 'Destructive',
          onPressed: () {
            onPressedCalled = true;
          },
          type: WnButtonType.destructive,
          disabled: true,
        );
        await mountWidget(widget, tester);
        await tester.tap(find.byType(WnButton));
        expect(onPressedCalled, isFalse);
      });
    });

    group('loading state for each button type', () {
      testWidgets('primary button shows loading indicator', (WidgetTester tester) async {
        final widget = WnButton(
          text: 'Primary',
          onPressed: () {},
          loading: true,
        );
        await mountWidget(widget, tester);
        expect(find.byKey(const Key('loading_indicator')), findsOneWidget);
      });

      testWidgets('outline button shows loading indicator', (WidgetTester tester) async {
        final widget = WnButton(
          text: 'Outline',
          onPressed: () {},
          type: WnButtonType.outline,
          loading: true,
        );
        await mountWidget(widget, tester);
        expect(find.byKey(const Key('loading_indicator')), findsOneWidget);
      });

      testWidgets('ghost button shows loading indicator', (WidgetTester tester) async {
        final widget = WnButton(
          text: 'Ghost',
          onPressed: () {},
          type: WnButtonType.ghost,
          loading: true,
        );
        await mountWidget(widget, tester);
        expect(find.byKey(const Key('loading_indicator')), findsOneWidget);
      });

      testWidgets('overlay button shows loading indicator', (WidgetTester tester) async {
        final widget = WnButton(
          text: 'Overlay',
          onPressed: () {},
          type: WnButtonType.overlay,
          loading: true,
        );
        await mountWidget(widget, tester);
        expect(find.byKey(const Key('loading_indicator')), findsOneWidget);
      });

      testWidgets('destructive button shows loading indicator', (WidgetTester tester) async {
        final widget = WnButton(
          text: 'Destructive',
          onPressed: () {},
          type: WnButtonType.destructive,
          loading: true,
        );
        await mountWidget(widget, tester);
        expect(find.byKey(const Key('loading_indicator')), findsOneWidget);
      });
    });

    group('text overflow', () {
      testWidgets('handles long text with ellipsis', (WidgetTester tester) async {
        final widget = SizedBox(
          width: 100,
          child: WnButton(
            text: 'This is a very long button text that should overflow',
            onPressed: () {},
          ),
        );
        await mountWidget(widget, tester);
        expect(find.text('This is a very long button text that should overflow'), findsOneWidget);
      });

      testWidgets('text uses ellipsis overflow', (WidgetTester tester) async {
        final widget = WnButton(
          text: 'Test',
          onPressed: () {},
        );
        await mountWidget(widget, tester);
        final textWidget = tester.widget<Text>(find.text('Test'));
        expect(textWidget.overflow, TextOverflow.ellipsis);
      });

      testWidgets('renders without crash in unbounded width parent', (WidgetTester tester) async {
        final widget = UnconstrainedBox(
          child: Row(
            children: [
              WnButton(
                text: 'Unbounded',
                onPressed: () {},
              ),
            ],
          ),
        );
        await mountWidget(widget, tester);
        expect(find.text('Unbounded'), findsOneWidget);
      });

      testWidgets('renders with icons in unbounded width parent', (WidgetTester tester) async {
        final widget = UnconstrainedBox(
          child: Row(
            children: [
              WnButton(
                text: 'Unbounded',
                onPressed: () {},
                leadingIcon: WnIcons.addLarge,
                trailingIcon: WnIcons.arrowRight,
              ),
            ],
          ),
        );
        await mountWidget(widget, tester);
        expect(find.text('Unbounded'), findsOneWidget);
        expect(find.byKey(const Key('leading_icon')), findsOneWidget);
        expect(find.byKey(const Key('trailing_icon')), findsOneWidget);
      });
    });

    group('null onPressed', () {
      testWidgets('renders correctly with null onPressed', (WidgetTester tester) async {
        final widget = const WnButton(
          text: 'Null Handler',
          onPressed: null,
        );
        await mountWidget(widget, tester);
        expect(find.text('Null Handler'), findsOneWidget);
      });

      testWidgets('does not crash when tapped with null onPressed', (WidgetTester tester) async {
        final widget = const WnButton(
          text: 'Null Handler',
          onPressed: null,
        );
        await mountWidget(widget, tester);
        await tester.tap(find.byType(WnButton));
        expect(find.text('Null Handler'), findsOneWidget);
      });
    });

    group('combined states', () {
      testWidgets('loading takes precedence over disabled', (WidgetTester tester) async {
        final widget = WnButton(
          text: 'Both States',
          onPressed: () {},
          loading: true,
          disabled: true,
        );
        await mountWidget(widget, tester);
        expect(find.byKey(const Key('loading_indicator')), findsOneWidget);
        expect(find.text('Both States'), findsNothing);
      });

      testWidgets('does not call onPressed when both loading and disabled', (
        WidgetTester tester,
      ) async {
        var onPressedCalled = false;
        final widget = WnButton(
          text: 'Both States',
          onPressed: () {
            onPressedCalled = true;
          },
          loading: true,
          disabled: true,
        );
        await mountWidget(widget, tester);
        await tester.tap(find.byType(WnButton));
        expect(onPressedCalled, isFalse);
      });
    });

    group('icons with different sizes', () {
      testWidgets('renders icons correctly with small size', (WidgetTester tester) async {
        final widget = WnButton(
          text: 'Small',
          onPressed: () {},
          size: WnButtonSize.small,
          leadingIcon: WnIcons.addLarge,
          trailingIcon: WnIcons.arrowRight,
        );
        await mountWidget(widget, tester);
        expect(find.byKey(const Key('leading_icon')), findsOneWidget);
        expect(find.byKey(const Key('trailing_icon')), findsOneWidget);
      });

      testWidgets('renders icons correctly with medium size', (WidgetTester tester) async {
        final widget = WnButton(
          text: 'Medium',
          onPressed: () {},
          size: WnButtonSize.medium,
          leadingIcon: WnIcons.addLarge,
          trailingIcon: WnIcons.arrowRight,
        );
        await mountWidget(widget, tester);
        expect(find.byKey(const Key('leading_icon')), findsOneWidget);
        expect(find.byKey(const Key('trailing_icon')), findsOneWidget);
      });

      testWidgets('renders icons correctly with xsmall size', (WidgetTester tester) async {
        final widget = WnButton(
          text: 'XSmall',
          onPressed: () {},
          size: WnButtonSize.xsmall,
          leadingIcon: WnIcons.addLarge,
          trailingIcon: WnIcons.arrowRight,
        );
        await mountWidget(widget, tester);
        expect(find.byKey(const Key('leading_icon')), findsOneWidget);
        expect(find.byKey(const Key('trailing_icon')), findsOneWidget);
      });
    });

    group('xsmall button specifics', () {
      testWidgets('xsmall button shows loading indicator', (WidgetTester tester) async {
        final widget = WnButton(
          text: 'XSmall',
          onPressed: () {},
          size: WnButtonSize.xsmall,
          loading: true,
        );
        await mountWidget(widget, tester);
        expect(find.byKey(const Key('loading_indicator')), findsOneWidget);
      });

      testWidgets('xsmall button respects disabled state', (WidgetTester tester) async {
        var onPressedCalled = false;
        final widget = WnButton(
          text: 'XSmall',
          onPressed: () {
            onPressedCalled = true;
          },
          size: WnButtonSize.xsmall,
          disabled: true,
        );
        await mountWidget(widget, tester);
        await tester.tap(find.byType(WnButton));
        expect(onPressedCalled, isFalse);
      });
    });

    group('button colors', () {
      final colors = SemanticColors.light;

      Color resolveBackground(ButtonStyle style, {bool disabled = false}) {
        return style.backgroundColor!.resolve(disabled ? {WidgetState.disabled} : {})!;
      }

      Color resolveForeground(ButtonStyle style, {bool disabled = false}) {
        return style.foregroundColor!.resolve(disabled ? {WidgetState.disabled} : {})!;
      }

      group('primary', () {
        testWidgets('enabled background uses fillPrimary', (WidgetTester tester) async {
          await mountWidget(WnButton(text: 'Test', onPressed: () {}), tester);
          final button = tester.widget<FilledButton>(find.byType(FilledButton));
          expect(resolveBackground(button.style!), equals(colors.fillPrimary));
        });

        testWidgets('enabled foreground uses fillContentPrimary', (WidgetTester tester) async {
          await mountWidget(WnButton(text: 'Test', onPressed: () {}), tester);
          final button = tester.widget<FilledButton>(find.byType(FilledButton));
          expect(resolveForeground(button.style!), equals(colors.fillContentPrimary));
        });

        testWidgets('disabled background uses fillDisabled', (WidgetTester tester) async {
          await mountWidget(
            WnButton(text: 'Test', onPressed: () {}, disabled: true),
            tester,
          );
          final button = tester.widget<FilledButton>(find.byType(FilledButton));
          expect(resolveBackground(button.style!, disabled: true), equals(colors.fillDisabled));
        });

        testWidgets('disabled foreground uses fillContentDisabled', (WidgetTester tester) async {
          await mountWidget(
            WnButton(text: 'Test', onPressed: () {}, disabled: true),
            tester,
          );
          final button = tester.widget<FilledButton>(find.byType(FilledButton));
          expect(
            resolveForeground(button.style!, disabled: true),
            equals(colors.fillContentDisabled),
          );
        });
      });

      group('outline', () {
        testWidgets('enabled background uses fillSecondary', (WidgetTester tester) async {
          await mountWidget(
            WnButton(text: 'Test', onPressed: () {}, type: WnButtonType.outline),
            tester,
          );
          final button = tester.widget<FilledButton>(find.byType(FilledButton));
          expect(resolveBackground(button.style!), equals(colors.fillSecondary));
        });

        testWidgets('enabled foreground uses fillContentSecondary', (WidgetTester tester) async {
          await mountWidget(
            WnButton(text: 'Test', onPressed: () {}, type: WnButtonType.outline),
            tester,
          );
          final button = tester.widget<FilledButton>(find.byType(FilledButton));
          expect(resolveForeground(button.style!), equals(colors.fillContentSecondary));
        });

        testWidgets('disabled background uses fillSecondary with alpha', (
          WidgetTester tester,
        ) async {
          await mountWidget(
            WnButton(text: 'Test', onPressed: () {}, type: WnButtonType.outline, disabled: true),
            tester,
          );
          final button = tester.widget<FilledButton>(find.byType(FilledButton));
          expect(
            resolveBackground(button.style!, disabled: true),
            equals(colors.fillSecondary.withValues(alpha: 0.25)),
          );
        });

        testWidgets('disabled foreground uses fillContentSecondary with alpha', (
          WidgetTester tester,
        ) async {
          await mountWidget(
            WnButton(text: 'Test', onPressed: () {}, type: WnButtonType.outline, disabled: true),
            tester,
          );
          final button = tester.widget<FilledButton>(find.byType(FilledButton));
          expect(
            resolveForeground(button.style!, disabled: true),
            equals(colors.fillContentSecondary.withValues(alpha: 0.25)),
          );
        });
      });

      group('ghost', () {
        testWidgets('enabled background uses fillTertiary', (WidgetTester tester) async {
          await mountWidget(
            WnButton(text: 'Test', onPressed: () {}, type: WnButtonType.ghost),
            tester,
          );
          final button = tester.widget<FilledButton>(find.byType(FilledButton));
          expect(resolveBackground(button.style!), equals(colors.fillTertiary));
        });

        testWidgets('enabled foreground uses fillContentTertiary', (WidgetTester tester) async {
          await mountWidget(
            WnButton(text: 'Test', onPressed: () {}, type: WnButtonType.ghost),
            tester,
          );
          final button = tester.widget<FilledButton>(find.byType(FilledButton));
          expect(resolveForeground(button.style!), equals(colors.fillContentTertiary));
        });

        testWidgets('disabled background uses fillTertiary with alpha', (
          WidgetTester tester,
        ) async {
          await mountWidget(
            WnButton(text: 'Test', onPressed: () {}, type: WnButtonType.ghost, disabled: true),
            tester,
          );
          final button = tester.widget<FilledButton>(find.byType(FilledButton));
          expect(
            resolveBackground(button.style!, disabled: true),
            equals(colors.fillTertiary.withValues(alpha: 0.25)),
          );
        });

        testWidgets('disabled foreground uses fillContentTertiary with alpha', (
          WidgetTester tester,
        ) async {
          await mountWidget(
            WnButton(text: 'Test', onPressed: () {}, type: WnButtonType.ghost, disabled: true),
            tester,
          );
          final button = tester.widget<FilledButton>(find.byType(FilledButton));
          expect(
            resolveForeground(button.style!, disabled: true),
            equals(colors.fillContentTertiary.withValues(alpha: 0.25)),
          );
        });
      });

      group('overlay', () {
        testWidgets('enabled background uses fillQuaternary', (WidgetTester tester) async {
          await mountWidget(
            WnButton(text: 'Test', onPressed: () {}, type: WnButtonType.overlay),
            tester,
          );
          final button = tester.widget<FilledButton>(find.byType(FilledButton));
          expect(resolveBackground(button.style!), equals(colors.fillQuaternary));
        });

        testWidgets('enabled foreground uses fillContentQuaternary', (
          WidgetTester tester,
        ) async {
          await mountWidget(
            WnButton(text: 'Test', onPressed: () {}, type: WnButtonType.overlay),
            tester,
          );
          final button = tester.widget<FilledButton>(find.byType(FilledButton));
          expect(resolveForeground(button.style!), equals(colors.fillContentQuaternary));
        });

        testWidgets('disabled background uses fillQuaternary with alpha', (
          WidgetTester tester,
        ) async {
          await mountWidget(
            WnButton(text: 'Test', onPressed: () {}, type: WnButtonType.overlay, disabled: true),
            tester,
          );
          final button = tester.widget<FilledButton>(find.byType(FilledButton));
          expect(
            resolveBackground(button.style!, disabled: true),
            equals(colors.fillQuaternary.withValues(alpha: 0.25)),
          );
        });

        testWidgets('disabled foreground uses fillContentQuaternary with alpha', (
          WidgetTester tester,
        ) async {
          await mountWidget(
            WnButton(text: 'Test', onPressed: () {}, type: WnButtonType.overlay, disabled: true),
            tester,
          );
          final button = tester.widget<FilledButton>(find.byType(FilledButton));
          expect(
            resolveForeground(button.style!, disabled: true),
            equals(colors.fillContentQuaternary.withValues(alpha: 0.25)),
          );
        });
      });

      group('destructive', () {
        testWidgets('enabled background uses fillDestructive', (WidgetTester tester) async {
          await mountWidget(
            WnButton(text: 'Test', onPressed: () {}, type: WnButtonType.destructive),
            tester,
          );
          final button = tester.widget<FilledButton>(find.byType(FilledButton));
          expect(resolveBackground(button.style!), equals(colors.fillDestructive));
        });

        testWidgets('enabled foreground uses fillContentQuaternary', (
          WidgetTester tester,
        ) async {
          await mountWidget(
            WnButton(text: 'Test', onPressed: () {}, type: WnButtonType.destructive),
            tester,
          );
          final button = tester.widget<FilledButton>(find.byType(FilledButton));
          expect(resolveForeground(button.style!), equals(colors.fillContentQuaternary));
        });

        testWidgets('disabled background uses fillDisabled', (WidgetTester tester) async {
          await mountWidget(
            WnButton(
              text: 'Test',
              onPressed: () {},
              type: WnButtonType.destructive,
              disabled: true,
            ),
            tester,
          );
          final button = tester.widget<FilledButton>(find.byType(FilledButton));
          expect(resolveBackground(button.style!, disabled: true), equals(colors.fillDisabled));
        });

        testWidgets('disabled foreground uses fillContentDisabled', (WidgetTester tester) async {
          await mountWidget(
            WnButton(
              text: 'Test',
              onPressed: () {},
              type: WnButtonType.destructive,
              disabled: true,
            ),
            tester,
          );
          final button = tester.widget<FilledButton>(find.byType(FilledButton));
          expect(
            resolveForeground(button.style!, disabled: true),
            equals(colors.fillContentDisabled),
          );
        });
      });
    });
  });
}
