import 'package:flutter/material.dart' show Key;
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/widgets/chat_list_filters.dart';
import 'package:whitenoise/widgets/wn_filter_chip.dart';
import '../test_helpers.dart' show mountWidget;

void main() {
  group('ChatListFilters', () {
    ChatListFilters buildWidget({
      bool isChatsSelected = false,
      bool isArchiveSelected = false,
      void Function(bool)? onChatsSelected,
      void Function(bool)? onArchiveSelected,
    }) {
      return ChatListFilters(
        isChatsSelected: isChatsSelected,
        isArchiveSelected: isArchiveSelected,
        onChatsSelected: onChatsSelected ?? (_) {},
        onArchiveSelected: onArchiveSelected ?? (_) {},
      );
    }

    group('structure', () {
      testWidgets('renders filter_chips_row key', (tester) async {
        await mountWidget(buildWidget(), tester);
        expect(find.byKey(const Key('filter_chips_row')), findsOneWidget);
      });

      testWidgets('renders chats chip', (tester) async {
        await mountWidget(buildWidget(), tester);
        expect(find.byKey(const Key('filter_chip_chats')), findsOneWidget);
      });

      testWidgets('renders archive chip', (tester) async {
        await mountWidget(buildWidget(), tester);
        expect(find.byKey(const Key('filter_chip_archive')), findsOneWidget);
      });

      testWidgets('renders two WnFilterChip widgets', (tester) async {
        await mountWidget(buildWidget(), tester);
        expect(find.byType(WnFilterChip), findsNWidgets(2));
      });
    });

    group('selected state', () {
      testWidgets('chats chip reflects isChatsSelected=false', (tester) async {
        await mountWidget(buildWidget(), tester);
        final chip = tester.widget<WnFilterChip>(find.byKey(const Key('filter_chip_chats')));
        expect(chip.selected, isFalse);
      });

      testWidgets('chats chip reflects isChatsSelected=true', (tester) async {
        await mountWidget(buildWidget(isChatsSelected: true), tester);
        final chip = tester.widget<WnFilterChip>(find.byKey(const Key('filter_chip_chats')));
        expect(chip.selected, isTrue);
      });

      testWidgets('archive chip reflects isArchiveSelected=false', (tester) async {
        await mountWidget(buildWidget(), tester);
        final chip = tester.widget<WnFilterChip>(find.byKey(const Key('filter_chip_archive')));
        expect(chip.selected, isFalse);
      });

      testWidgets('archive chip reflects isArchiveSelected=true', (tester) async {
        await mountWidget(buildWidget(isArchiveSelected: true), tester);
        final chip = tester.widget<WnFilterChip>(find.byKey(const Key('filter_chip_archive')));
        expect(chip.selected, isTrue);
      });
    });

    group('callbacks', () {
      testWidgets('calls onChatsSelected when chats chip is tapped', (tester) async {
        bool? received;
        await mountWidget(buildWidget(onChatsSelected: (v) => received = v), tester);
        await tester.tap(find.byKey(const Key('filter_chip_chats')));
        await tester.pump();
        expect(received, isTrue);
      });

      testWidgets('calls onArchiveSelected when archive chip is tapped', (tester) async {
        bool? received;
        await mountWidget(buildWidget(onArchiveSelected: (v) => received = v), tester);
        await tester.tap(find.byKey(const Key('filter_chip_archive')));
        await tester.pump();
        expect(received, isTrue);
      });
    });
  });
}
