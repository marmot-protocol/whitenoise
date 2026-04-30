import 'package:flutter/material.dart' show Key, TextField;
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/widgets/chat_list_search_and_filters.dart';
import 'package:whitenoise/widgets/wn_filter_chip.dart';
import 'package:whitenoise/widgets/wn_search_field.dart';
import '../test_helpers.dart' show mountWidget;

void main() {
  group('ChatListSearchAndFilters', () {
    group('structure', () {
      testWidgets('renders search field', (tester) async {
        await mountWidget(const ChatListSearchAndFilters(), tester);
        expect(find.byType(WnSearchField), findsOneWidget);
      });

      testWidgets('renders search field with Search placeholder', (tester) async {
        await mountWidget(const ChatListSearchAndFilters(), tester);
        expect(find.text('Search'), findsOneWidget);
      });

      testWidgets('renders search and filters container', (tester) async {
        await mountWidget(const ChatListSearchAndFilters(), tester);
        expect(find.byKey(const Key('search_and_filters')), findsOneWidget);
      });
    });

    group('isLoading', () {
      testWidgets('forwards isLoading=true to WnSearchField', (tester) async {
        await mountWidget(const ChatListSearchAndFilters(isLoading: true), tester);
        final field = tester.widget<WnSearchField>(find.byType(WnSearchField));
        expect(field.isLoading, isTrue);
        expect(find.byKey(const Key('search_loading_indicator')), findsOneWidget);
      });

      testWidgets('forwards isLoading=false to WnSearchField by default', (tester) async {
        await mountWidget(const ChatListSearchAndFilters(), tester);
        final field = tester.widget<WnSearchField>(find.byType(WnSearchField));
        expect(field.isLoading, isFalse);
        expect(find.byKey(const Key('search_loading_indicator')), findsNothing);
      });
    });

    group('search callback', () {
      testWidgets('calls onSearchChanged when text is entered', (tester) async {
        String? searchValue;
        await mountWidget(
          ChatListSearchAndFilters(onSearchChanged: (value) => searchValue = value),
          tester,
        );

        await tester.enterText(find.byType(TextField), 'hello');
        expect(searchValue, 'hello');
      });

      testWidgets('does not crash when onSearchChanged is null', (tester) async {
        await mountWidget(const ChatListSearchAndFilters(), tester);

        await tester.enterText(find.byType(TextField), 'hello');
        await tester.pump();
        expect(find.text('hello'), findsOneWidget);
      });
    });

    group('filter chips', () {
      testWidgets('hides chips by default', (tester) async {
        await mountWidget(const ChatListSearchAndFilters(), tester);
        expect(find.byKey(const Key('filter_chip_chats')), findsNothing);
        expect(find.byKey(const Key('filter_chip_archive')), findsNothing);
        expect(find.byKey(const Key('filter_chips_row')), findsNothing);
      });

      testWidgets('renders both chips when showFilterChips is true', (tester) async {
        await mountWidget(const ChatListSearchAndFilters(showFilterChips: true), tester);
        expect(find.byKey(const Key('filter_chip_chats')), findsOneWidget);
        expect(find.byKey(const Key('filter_chip_archive')), findsOneWidget);
      });

      testWidgets('renders chips in a row', (tester) async {
        await mountWidget(const ChatListSearchAndFilters(showFilterChips: true), tester);
        expect(find.byKey(const Key('filter_chips_row')), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const Key('filter_chips_row')),
            matching: find.byType(WnFilterChip),
          ),
          findsNWidgets(2),
        );
      });

      testWidgets('chats chip not selected by default', (tester) async {
        await mountWidget(const ChatListSearchAndFilters(showFilterChips: true), tester);
        final chip = tester.widget<WnFilterChip>(find.byKey(const Key('filter_chip_chats')));
        expect(chip.selected, isFalse);
      });

      testWidgets('reflects isChatsSelected on chats chip', (tester) async {
        await mountWidget(
          const ChatListSearchAndFilters(showFilterChips: true, isChatsSelected: true),
          tester,
        );
        final chip = tester.widget<WnFilterChip>(find.byKey(const Key('filter_chip_chats')));
        expect(chip.selected, isTrue);
      });

      testWidgets('archive chip not selected by default', (tester) async {
        await mountWidget(const ChatListSearchAndFilters(showFilterChips: true), tester);
        final chip = tester.widget<WnFilterChip>(find.byKey(const Key('filter_chip_archive')));
        expect(chip.selected, isFalse);
      });

      testWidgets('reflects isArchiveSelected on archive chip', (tester) async {
        await mountWidget(
          const ChatListSearchAndFilters(showFilterChips: true, isArchiveSelected: true),
          tester,
        );
        final chip = tester.widget<WnFilterChip>(find.byKey(const Key('filter_chip_archive')));
        expect(chip.selected, isTrue);
      });

      testWidgets('calls onChatsSelected when chats chip is tapped', (tester) async {
        bool? tappedValue;
        await mountWidget(
          ChatListSearchAndFilters(
            showFilterChips: true,
            onChatsSelected: (value) => tappedValue = value,
          ),
          tester,
        );
        await tester.tap(find.byKey(const Key('filter_chip_chats')));
        await tester.pump();
        expect(tappedValue, isTrue);
      });

      testWidgets('calls onChatsSelected with false when selected chats chip is tapped', (
        tester,
      ) async {
        bool? tappedValue;
        await mountWidget(
          ChatListSearchAndFilters(
            showFilterChips: true,
            isChatsSelected: true,
            onChatsSelected: (value) => tappedValue = value,
          ),
          tester,
        );
        await tester.tap(find.byKey(const Key('filter_chip_chats')));
        await tester.pump();
        expect(tappedValue, isFalse);
      });

      testWidgets('calls onArchiveSelected when archive chip is tapped', (tester) async {
        bool? tappedValue;
        await mountWidget(
          ChatListSearchAndFilters(
            showFilterChips: true,
            onArchiveSelected: (value) => tappedValue = value,
          ),
          tester,
        );
        await tester.tap(find.byKey(const Key('filter_chip_archive')));
        await tester.pump();
        expect(tappedValue, isTrue);
      });

      testWidgets('calls onArchiveSelected with false when selected archive chip is tapped', (
        tester,
      ) async {
        bool? tappedValue;
        await mountWidget(
          ChatListSearchAndFilters(
            showFilterChips: true,
            isArchiveSelected: true,
            onArchiveSelected: (value) => tappedValue = value,
          ),
          tester,
        );
        await tester.tap(find.byKey(const Key('filter_chip_archive')));
        await tester.pump();
        expect(tappedValue, isFalse);
      });

      testWidgets('does not crash when onChatsSelected is null and chip tapped', (tester) async {
        await mountWidget(const ChatListSearchAndFilters(showFilterChips: true), tester);
        await tester.tap(find.byKey(const Key('filter_chip_chats')));
        await tester.pump();
      });

      testWidgets('does not crash when onArchiveSelected is null and chip tapped', (tester) async {
        await mountWidget(const ChatListSearchAndFilters(showFilterChips: true), tester);
        await tester.tap(find.byKey(const Key('filter_chip_archive')));
        await tester.pump();
      });
    });
  });
}
