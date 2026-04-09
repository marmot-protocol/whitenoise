import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/utils/formatting.dart';
import 'package:whitenoise/widgets/wn_copyable_field.dart';
import 'package:whitenoise/widgets/wn_icon.dart';
import '../mocks/mock_clipboard.dart';
import '../test_helpers.dart';

void main() {
  group('WnCopyableField', () {
    testWidgets('displays label', (tester) async {
      await mountWidget(
        const WnCopyableField(
          label: 'My Label',
          value: 'my-value',
        ),
        tester,
      );
      expect(find.text('My Label'), findsOneWidget);
    });

    testWidgets('displays displayValue when provided', (tester) async {
      await mountWidget(
        WnCopyableField(
          label: 'Label',
          value: 'abcd1234efgh5678',
          displayValue: formatPublicKey('abcd1234efgh5678'),
        ),
        tester,
      );
      expect(find.text(formatPublicKey('abcd1234efgh5678')), findsOneWidget);
      expect(find.text('abcd1234efgh5678'), findsNothing);
    });

    testWidgets('displays value when displayValue is not provided', (tester) async {
      await mountWidget(
        const WnCopyableField(
          label: 'Label',
          value: 'my-value',
        ),
        tester,
      );
      expect(find.text('my-value'), findsOneWidget);
    });

    testWidgets('copies original value to clipboard even when displayValue is set', (
      tester,
    ) async {
      late String? Function() getClipboard;
      getClipboard = mockClipboard();
      await mountWidget(
        WnCopyableField(
          label: 'Label',
          value: 'abcd1234efgh5678',
          displayValue: formatPublicKey('abcd1234efgh5678'),
        ),
        tester,
      );
      await tester.tap(find.byKey(const Key('copy_button')));
      expect(getClipboard(), 'abcd1234efgh5678');
    });

    testWidgets('displays 16 large circles when obscurable and obscured', (tester) async {
      await mountWidget(
        const WnCopyableField(
          label: 'Label',
          value: 'my-value',
          obscurable: true,
        ),
        tester,
      );
      expect(find.text('my-value'), findsNothing);
      expect(find.text('⬤' * 16), findsOneWidget);
    });

    testWidgets('displays custom dot count when obscureDotCount is provided', (tester) async {
      await mountWidget(
        const WnCopyableField(
          label: 'Label',
          value: 'my-value',
          obscurable: true,
          obscureDotCount: 14,
        ),
        tester,
      );
      expect(find.text('⬤' * 14), findsOneWidget);
      expect(find.text('⬤' * 16), findsNothing);
    });

    testWidgets('displays actual value when obscurable but not obscured', (tester) async {
      await mountWidget(
        const WnCopyableField(
          label: 'Label',
          value: 'abcd1234efgh5678',
          obscurable: true,
          obscured: false,
        ),
        tester,
      );
      expect(find.text('abcd1234efgh5678'), findsOneWidget);
      expect(find.text(formatPublicKey('abcd1234efgh5678')), findsNothing);
    });

    testWidgets('displays copy button', (tester) async {
      await mountWidget(
        const WnCopyableField(
          label: 'Label',
          value: 'value',
        ),
        tester,
      );
      expect(find.byKey(const Key('copy_button')), findsOneWidget);
    });

    testWidgets('does not show visibility toggle when not obscurable', (tester) async {
      await mountWidget(
        const WnCopyableField(
          label: 'Label',
          value: 'value',
        ),
        tester,
      );
      expect(find.byKey(const Key('visibility_toggle')), findsNothing);
    });

    testWidgets('shows visibility toggle when obscurable', (tester) async {
      await mountWidget(
        const WnCopyableField(
          label: 'Label',
          value: 'value',
          obscurable: true,
        ),
        tester,
      );
      expect(find.byKey(const Key('visibility_toggle')), findsOneWidget);
    });

    testWidgets('shows view icon when obscured', (tester) async {
      await mountWidget(
        const WnCopyableField(
          label: 'Label',
          value: 'value',
          obscurable: true,
        ),
        tester,
      );
      final icons = find.byType(WnIcon);
      final viewIcon = icons.evaluate().where((e) {
        final widget = e.widget as WnIcon;
        return widget.icon == WnIcons.view;
      });
      expect(viewIcon.length, 1);
    });

    testWidgets('shows view_off icon when not obscured', (tester) async {
      await mountWidget(
        const WnCopyableField(
          label: 'Label',
          value: 'value',
          obscurable: true,
          obscured: false,
        ),
        tester,
      );
      final icons = find.byType(WnIcon);
      final viewOffIcon = icons.evaluate().where((e) {
        final widget = e.widget as WnIcon;
        return widget.icon == WnIcons.viewOff;
      });
      expect(viewOffIcon.length, 1);
    });

    group('copy functionality', () {
      late String? Function() getClipboard;

      setUp(() {
        getClipboard = mockClipboard();
      });

      testWidgets('copies value to clipboard on tap', (tester) async {
        await mountWidget(
          const WnCopyableField(
            label: 'Label',
            value: 'secret-value',
          ),
          tester,
        );
        await tester.tap(find.byKey(const Key('copy_button')));
        expect(getClipboard(), 'secret-value');
      });

      testWidgets('copies updated value when value prop changes', (tester) async {
        await mountWidget(
          const WnCopyableField(
            label: 'Label',
            value: 'initial-value',
          ),
          tester,
        );

        await mountWidget(
          const WnCopyableField(
            label: 'Label',
            value: 'updated-value',
          ),
          tester,
        );

        await tester.tap(find.byKey(const Key('copy_button')));
        expect(getClipboard(), 'updated-value');
      });

      testWidgets('calls onCopied callback when copy button is tapped', (tester) async {
        var onCopiedCalled = false;
        await mountWidget(
          WnCopyableField(
            label: 'Label',
            value: 'value',
            onCopied: () => onCopiedCalled = true,
          ),
          tester,
        );
        await tester.tap(find.byKey(const Key('copy_button')));
        await tester.pump();
        expect(onCopiedCalled, isTrue);
      });

      testWidgets('does not throw when onCopied is null', (tester) async {
        await mountWidget(
          const WnCopyableField(
            label: 'Label',
            value: 'value',
          ),
          tester,
        );
        await tester.tap(find.byKey(const Key('copy_button')));
        await tester.pump();
      });
    });

    group('visibility toggle', () {
      testWidgets('calls onToggleVisibility when tapped', (tester) async {
        var toggleCalled = false;
        await mountWidget(
          WnCopyableField(
            label: 'Label',
            value: 'value',
            obscurable: true,
            onToggleVisibility: () => toggleCalled = true,
          ),
          tester,
        );
        await tester.tap(find.byKey(const Key('visibility_toggle')));
        expect(toggleCalled, isTrue);
      });
    });
  });
}
