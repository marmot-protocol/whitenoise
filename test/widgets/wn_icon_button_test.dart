import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_icon.dart';
import 'package:whitenoise/widgets/wn_icon_button.dart';

import '../test_helpers.dart' show mountWidget;

Color? _resolveBgColor(WidgetTester tester, Set<WidgetState> states) {
  final button = tester.widget<FilledButton>(find.byType(FilledButton));
  return button.style!.backgroundColor!.resolve(states);
}

void main() {
  group('WnIconButton', () {
    group('basic functionality', () {
      testWidgets('renders icon', (WidgetTester tester) async {
        final widget = WnIconButton(
          icon: WnIcons.addCircle,
          onPressed: () {},
        );
        await mountWidget(widget, tester);
        expect(find.byType(WnIcon), findsOneWidget);
      });

      testWidgets('calls onPressed when tapped', (WidgetTester tester) async {
        var onPressedCalled = false;
        final widget = WnIconButton(
          icon: WnIcons.addCircle,
          onPressed: () {
            onPressedCalled = true;
          },
        );
        await mountWidget(widget, tester);
        await tester.tap(find.byType(WnIconButton));
        expect(onPressedCalled, isTrue);
      });
    });

    group('disabled state', () {
      testWidgets('does not call onPressed when disabled', (WidgetTester tester) async {
        var onPressedCalled = false;
        final widget = WnIconButton(
          icon: WnIcons.addCircle,
          onPressed: () {
            onPressedCalled = true;
          },
          disabled: true,
        );
        await mountWidget(widget, tester);
        await tester.tap(find.byType(WnIconButton));
        expect(onPressedCalled, isFalse);
      });
    });

    group('sizing', () {
      testWidgets('size56 renders larger than size44', (WidgetTester tester) async {
        await mountWidget(
          WnIconButton(icon: WnIcons.addCircle, onPressed: () {}),
          tester,
        );
        final size44 = tester.getSize(find.byType(WnIconButton));

        await mountWidget(
          WnIconButton(icon: WnIcons.addCircle, onPressed: () {}, size: WnIconButtonSize.size56),
          tester,
        );
        final size56 = tester.getSize(find.byType(WnIconButton));

        expect(size56.width, greaterThan(size44.width));
      });
    });

    group('null onPressed', () {
      testWidgets('does not crash when tapped', (WidgetTester tester) async {
        const widget = WnIconButton(icon: WnIcons.addCircle, onPressed: null);
        await mountWidget(widget, tester);
        await tester.tap(find.byType(WnIconButton));
        expect(find.byType(WnIconButton), findsOneWidget);
      });
    });

    group('backgroundColor', () {
      const colors = SemanticColors.light;

      group('primary', () {
        Future<void> mount(WidgetTester tester) async {
          await mountWidget(
            WnIconButton(
              icon: WnIcons.addCircle,
              onPressed: () {},
              type: WnIconButtonType.primary,
            ),
            tester,
          );
        }

        testWidgets('uses fillPrimary by default', (tester) async {
          await mount(tester);
          expect(_resolveBgColor(tester, {}), equals(colors.fillPrimary));
        });

        testWidgets('uses fillPrimaryActive when pressed', (tester) async {
          await mount(tester);
          expect(
            _resolveBgColor(tester, {WidgetState.pressed}),
            equals(colors.fillPrimaryActive),
          );
        });

        testWidgets('uses fillPrimaryHover when hovered', (tester) async {
          await mount(tester);
          expect(
            _resolveBgColor(tester, {WidgetState.hovered}),
            equals(colors.fillPrimaryHover),
          );
        });

        testWidgets('uses fillSecondary when disabled', (tester) async {
          await mountWidget(
            const WnIconButton(
              icon: WnIcons.addCircle,
              onPressed: null,
              type: WnIconButtonType.primary,
              disabled: true,
            ),
            tester,
          );
          expect(
            _resolveBgColor(tester, {WidgetState.disabled}),
            equals(colors.fillSecondary),
          );
        });
      });

      group('outline', () {
        Future<void> mount(WidgetTester tester) async {
          await mountWidget(
            WnIconButton(
              icon: WnIcons.addCircle,
              onPressed: () {},
              type: WnIconButtonType.outline,
            ),
            tester,
          );
        }

        testWidgets('uses fillSecondary by default', (tester) async {
          await mount(tester);
          expect(_resolveBgColor(tester, {}), equals(colors.fillSecondary));
        });

        testWidgets('uses fillSecondaryActive when pressed', (tester) async {
          await mount(tester);
          expect(
            _resolveBgColor(tester, {WidgetState.pressed}),
            equals(colors.fillSecondaryActive),
          );
        });

        testWidgets('uses fillSecondaryHover when hovered', (tester) async {
          await mount(tester);
          expect(
            _resolveBgColor(tester, {WidgetState.hovered}),
            equals(colors.fillSecondaryHover),
          );
        });

        testWidgets('uses transparent when disabled', (tester) async {
          await mountWidget(
            const WnIconButton(
              icon: WnIcons.addCircle,
              onPressed: null,
              type: WnIconButtonType.outline,
              disabled: true,
            ),
            tester,
          );
          expect(
            _resolveBgColor(tester, {WidgetState.disabled}),
            equals(Colors.transparent),
          );
        });
      });

      group('ghost', () {
        Future<void> mount(WidgetTester tester) async {
          await mountWidget(
            WnIconButton(icon: WnIcons.addCircle, onPressed: () {}),
            tester,
          );
        }

        testWidgets('uses fillTertiary by default', (tester) async {
          await mount(tester);
          expect(_resolveBgColor(tester, {}), equals(colors.fillTertiary));
        });

        testWidgets('uses fillTertiaryActive when pressed', (tester) async {
          await mount(tester);
          expect(
            _resolveBgColor(tester, {WidgetState.pressed}),
            equals(colors.fillTertiaryActive),
          );
        });

        testWidgets('uses fillTertiaryHover when hovered', (tester) async {
          await mount(tester);
          expect(
            _resolveBgColor(tester, {WidgetState.hovered}),
            equals(colors.fillTertiaryHover),
          );
        });

        testWidgets('uses transparent when disabled', (tester) async {
          await mountWidget(
            const WnIconButton(
              icon: WnIcons.addCircle,
              onPressed: null,
              disabled: true,
            ),
            tester,
          );
          expect(
            _resolveBgColor(tester, {WidgetState.disabled}),
            equals(Colors.transparent),
          );
        });
      });
    });
  });
}
