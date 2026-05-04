import 'package:flutter/material.dart' show Key, SizedBox;
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_key_package_card.dart';
import 'package:whitenoise/widgets/wn_pill.dart';
import '../test_helpers.dart' show mountWidget;

void main() {
  group('WnKeyPackageCard tests', () {
    group('basic rendering', () {
      testWidgets('renders title correctly', (WidgetTester tester) async {
        final widget = WnKeyPackageCard(
          title: 'Key Package #1',
          packageId: 'abc123',
          createdAt: '2026-01-28T21:00:42.000Z',
          onDelete: () {},
          deleteLabel: 'Delete',
        );
        await mountWidget(widget, tester);
        expect(find.text('Key Package #1'), findsOneWidget);
      });

      testWidgets('renders package ID with label', (WidgetTester tester) async {
        final widget = WnKeyPackageCard(
          title: 'Key Package #1',
          packageId: '7fbc6a4207913cf327b00bc66718886b00920',
          createdAt: '2026-01-28T21:00:42.000Z',
          onDelete: () {},
          deleteLabel: 'Delete',
        );
        await mountWidget(widget, tester);
        expect(find.byKey(const Key('package_id_text')), findsOneWidget);
        expect(find.textContaining('ID:'), findsOneWidget);
        expect(
          find.textContaining('7fbc6a4207913cf327b00bc66718886b00920'),
          findsOneWidget,
        );
      });

      testWidgets('renders created at with label', (WidgetTester tester) async {
        final widget = WnKeyPackageCard(
          title: 'Key Package #1',
          packageId: 'abc123',
          createdAt: '2026-01-28T21:00:42.000Z',
          onDelete: () {},
          deleteLabel: 'Delete',
        );
        await mountWidget(widget, tester);
        expect(find.byKey(const Key('created_at_text')), findsOneWidget);
        expect(find.textContaining('Created at:'), findsOneWidget);
        expect(find.textContaining('2026-01-28T21:00:42.000Z'), findsOneWidget);
      });

      testWidgets('renders key icon', (WidgetTester tester) async {
        final widget = WnKeyPackageCard(
          title: 'Key Package #1',
          packageId: 'abc123',
          createdAt: '2026-01-28T21:00:42.000Z',
          onDelete: () {},
          deleteLabel: 'Delete',
        );
        await mountWidget(widget, tester);
        expect(find.byKey(const Key('key_package_icon')), findsOneWidget);
      });

      testWidgets('renders delete button', (WidgetTester tester) async {
        final widget = WnKeyPackageCard(
          title: 'Key Package #1',
          packageId: 'abc123',
          createdAt: '2026-01-28T21:00:42.000Z',
          onDelete: () {},
          deleteLabel: 'Delete',
        );
        await mountWidget(widget, tester);
        expect(find.byKey(const Key('delete_button')), findsOneWidget);
        expect(find.text('Delete'), findsOneWidget);
      });
    });

    group('delete button functionality', () {
      testWidgets('calls onDelete when delete button is tapped', (WidgetTester tester) async {
        var deleteCalled = false;
        final widget = WnKeyPackageCard(
          title: 'Key Package #1',
          packageId: 'abc123',
          createdAt: '2026-01-28T21:00:42.000Z',
          onDelete: () {
            deleteCalled = true;
          },
          deleteLabel: 'Delete',
        );
        await mountWidget(widget, tester);
        await tester.tap(find.byKey(const Key('delete_button')));
        expect(deleteCalled, isTrue);
      });

      testWidgets('does not call onDelete when disabled', (WidgetTester tester) async {
        var deleteCalled = false;
        final widget = WnKeyPackageCard(
          title: 'Key Package #1',
          packageId: 'abc123',
          createdAt: '2026-01-28T21:00:42.000Z',
          onDelete: () {
            deleteCalled = true;
          },
          deleteLabel: 'Delete',
          disabled: true,
        );
        await mountWidget(widget, tester);
        await tester.tap(find.byKey(const Key('delete_button')));
        expect(deleteCalled, isFalse);
      });
    });

    group('disabled state', () {
      testWidgets('renders correctly when disabled', (WidgetTester tester) async {
        final widget = WnKeyPackageCard(
          title: 'Key Package #1',
          packageId: 'abc123',
          createdAt: '2026-01-28T21:00:42.000Z',
          onDelete: () {},
          deleteLabel: 'Delete',
          disabled: true,
        );
        await mountWidget(widget, tester);
        expect(find.text('Key Package #1'), findsOneWidget);
        expect(find.text('Delete'), findsOneWidget);
      });

      testWidgets('delete button shows disabled state', (WidgetTester tester) async {
        final widget = WnKeyPackageCard(
          title: 'Key Package #1',
          packageId: 'abc123',
          createdAt: '2026-01-28T21:00:42.000Z',
          onDelete: () {},
          deleteLabel: 'Delete',
          disabled: true,
        );
        await mountWidget(widget, tester);
        final button = tester.widget<WnButton>(find.byType(WnButton));
        expect(button.disabled, isTrue);
      });

      testWidgets('renders correctly when not disabled', (WidgetTester tester) async {
        final widget = WnKeyPackageCard(
          title: 'Key Package #1',
          packageId: 'abc123',
          createdAt: '2026-01-28T21:00:42.000Z',
          onDelete: () {},
          deleteLabel: 'Delete',
        );
        await mountWidget(widget, tester);
        final button = tester.widget<WnButton>(find.byType(WnButton));
        expect(button.disabled, isFalse);
      });
    });

    group('content variations', () {
      testWidgets('handles long package ID', (WidgetTester tester) async {
        final widget = SizedBox(
          width: 368,
          child: WnKeyPackageCard(
            title: 'Key Package #1',
            packageId: '7fbc6a4207913cf327b00bc66718886b009206a4c56c677bf5f2f08a6ff4e3ed',
            createdAt: '2026-01-28T21:00:42.000Z',
            onDelete: () {},
            deleteLabel: 'Delete',
          ),
        );
        await mountWidget(widget, tester);
        expect(
          find.textContaining('7fbc6a4207913cf327b00bc66718886b00920'),
          findsOneWidget,
        );
      });

      testWidgets('handles long title with ellipsis', (WidgetTester tester) async {
        final widget = SizedBox(
          width: 368,
          child: WnKeyPackageCard(
            title: 'Key Package #1234567890 with a very long title',
            packageId: 'abc123',
            createdAt: '2026-01-28T21:00:42.000Z',
            onDelete: () {},
            deleteLabel: 'Delete',
          ),
        );
        await mountWidget(widget, tester);
        expect(
          find.textContaining('Key Package #1234567890'),
          findsOneWidget,
        );
      });

      testWidgets('renders with different package numbers', (WidgetTester tester) async {
        final widget = WnKeyPackageCard(
          title: 'Key Package #42',
          packageId: 'xyz789',
          createdAt: '2025-12-25T12:00:00.000Z',
          onDelete: () {},
          deleteLabel: 'Delete',
        );
        await mountWidget(widget, tester);
        expect(find.text('Key Package #42'), findsOneWidget);
        expect(find.textContaining('xyz789'), findsOneWidget);
        expect(find.textContaining('2025-12-25T12:00:00.000Z'), findsOneWidget);
      });
    });

    group('legacy pill', () {
      testWidgets('shows legacy pill when legacyLabel is provided', (WidgetTester tester) async {
        final widget = WnKeyPackageCard(
          title: 'Key Package #1',
          packageId: 'abc123',
          createdAt: '2026-01-28T21:00:42.000Z',
          onDelete: () {},
          deleteLabel: 'Delete',
          legacyLabel: 'Legacy',
        );
        await mountWidget(widget, tester);
        expect(find.byType(WnPill), findsOneWidget);
        expect(find.text('Legacy'), findsOneWidget);
      });

      testWidgets('does not show legacy pill when legacyLabel is null', (
        WidgetTester tester,
      ) async {
        final widget = WnKeyPackageCard(
          title: 'Key Package #1',
          packageId: 'abc123',
          createdAt: '2026-01-28T21:00:42.000Z',
          onDelete: () {},
          deleteLabel: 'Delete',
        );
        await mountWidget(widget, tester);
        expect(find.byKey(const Key('legacy_pill')), findsNothing);
      });
    });

    group('deleteButtonKey', () {
      testWidgets('uses custom deleteButtonKey when provided', (WidgetTester tester) async {
        final widget = WnKeyPackageCard(
          title: 'Key Package #1',
          packageId: 'abc123',
          createdAt: '2026-01-28T21:00:42.000Z',
          onDelete: () {},
          deleteLabel: 'Delete',
          deleteButtonKey: const Key('custom_delete_key'),
        );
        await mountWidget(widget, tester);
        expect(find.byKey(const Key('custom_delete_key')), findsOneWidget);
        expect(find.byKey(const Key('delete_button')), findsNothing);
      });

      testWidgets('uses default key when deleteButtonKey is null', (WidgetTester tester) async {
        final widget = WnKeyPackageCard(
          title: 'Key Package #1',
          packageId: 'abc123',
          createdAt: '2026-01-28T21:00:42.000Z',
          onDelete: () {},
          deleteLabel: 'Delete',
        );
        await mountWidget(widget, tester);
        expect(find.byKey(const Key('delete_button')), findsOneWidget);
      });

      testWidgets('custom deleteButtonKey responds to tap', (WidgetTester tester) async {
        var deleteCalled = false;
        final widget = WnKeyPackageCard(
          title: 'Key Package #1',
          packageId: 'abc123',
          createdAt: '2026-01-28T21:00:42.000Z',
          onDelete: () {
            deleteCalled = true;
          },
          deleteLabel: 'Delete',
          deleteButtonKey: const Key('custom_delete_key'),
        );
        await mountWidget(widget, tester);
        await tester.tap(find.byKey(const Key('custom_delete_key')));
        expect(deleteCalled, isTrue);
      });
    });

    group('layout', () {
      testWidgets('renders within constrained width', (WidgetTester tester) async {
        final widget = SizedBox(
          width: 368,
          child: WnKeyPackageCard(
            title: 'Key Package #1',
            packageId: 'abc123',
            createdAt: '2026-01-28T21:00:42.000Z',
            onDelete: () {},
            deleteLabel: 'Delete',
          ),
        );
        await mountWidget(widget, tester);
        expect(find.byType(WnKeyPackageCard), findsOneWidget);
      });

      testWidgets('renders in narrow container', (WidgetTester tester) async {
        final widget = SizedBox(
          width: 200,
          child: WnKeyPackageCard(
            title: 'Key Package #1',
            packageId: 'abc123',
            createdAt: '2026-01-28T21:00:42.000Z',
            onDelete: () {},
            deleteLabel: 'Delete',
          ),
        );
        await mountWidget(widget, tester);
        expect(find.byType(WnKeyPackageCard), findsOneWidget);
      });

      testWidgets('renders wrapped in container', (WidgetTester tester) async {
        final widget = SizedBox(
          width: 368,
          child: WnKeyPackageCard(
            title: 'Key Package #1',
            packageId: 'abc123',
            createdAt: '2026-01-28T21:00:42.000Z',
            onDelete: () {},
            deleteLabel: 'Delete',
          ),
        );
        await mountWidget(widget, tester);
        expect(find.byType(WnKeyPackageCard), findsOneWidget);
      });
    });
  });
}
