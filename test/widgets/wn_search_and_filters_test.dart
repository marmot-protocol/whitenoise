import 'package:flutter/material.dart' show Key, TextField;
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/widgets/wn_search_and_filters.dart';
import 'package:whitenoise/widgets/wn_search_field.dart';
import '../test_helpers.dart' show mountWidget;

void main() {
  group('WnSearchAndFilters', () {
    group('structure', () {
      testWidgets('renders search field', (tester) async {
        await mountWidget(const WnSearchAndFilters(), tester);
        expect(find.byType(WnSearchField), findsOneWidget);
      });

      testWidgets('renders search field with Search placeholder', (tester) async {
        await mountWidget(const WnSearchAndFilters(), tester);
        expect(find.text('Search'), findsOneWidget);
      });

      testWidgets('renders search and filters container', (tester) async {
        await mountWidget(const WnSearchAndFilters(), tester);
        expect(find.byKey(const Key('search_and_filters')), findsOneWidget);
      });
    });

    group('isLoading', () {
      testWidgets('forwards isLoading=true to WnSearchField', (tester) async {
        await mountWidget(const WnSearchAndFilters(isLoading: true), tester);
        final field = tester.widget<WnSearchField>(find.byType(WnSearchField));
        expect(field.isLoading, isTrue);
        expect(find.byKey(const Key('search_loading_indicator')), findsOneWidget);
      });

      testWidgets('forwards isLoading=false to WnSearchField by default', (tester) async {
        await mountWidget(const WnSearchAndFilters(), tester);
        final field = tester.widget<WnSearchField>(find.byType(WnSearchField));
        expect(field.isLoading, isFalse);
        expect(find.byKey(const Key('search_loading_indicator')), findsNothing);
      });
    });

    group('search callback', () {
      testWidgets('calls onSearchChanged when text is entered', (tester) async {
        String? searchValue;
        await mountWidget(
          WnSearchAndFilters(onSearchChanged: (value) => searchValue = value),
          tester,
        );

        await tester.enterText(find.byType(TextField), 'hello');
        expect(searchValue, 'hello');
      });

      testWidgets('does not crash when onSearchChanged is null', (tester) async {
        await mountWidget(const WnSearchAndFilters(), tester);

        await tester.enterText(find.byType(TextField), 'hello');
        await tester.pump();
        expect(find.text('hello'), findsOneWidget);
      });
    });
  });
}
