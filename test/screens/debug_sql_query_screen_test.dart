import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/screens/debug_sql_query_screen.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';

import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

class _MockApi extends MockWnApi {}

void main() {
  final api = _MockApi();

  setUpAll(() => RustLib.initMock(api: api));
  setUp(api.reset);

  testWidgets('runs debug query and renders pretty JSON result', (tester) async {
    api.debugQueryResult = '[{"table":"accounts","count":2}]';

    await mountWidget(const DebugSqlQueryScreen(), tester);
    await tester.enterText(
      find.byKey(const Key('developer_debug_query_input')),
      'SELECT * FROM accounts;',
    );
    await tester.tap(find.byKey(const Key('developer_debug_query_run_button')));
    await tester.pumpAndSettle();

    expect(api.lastDebugQuerySql, 'SELECT * FROM accounts;');
    expect(find.byKey(const Key('developer_debug_query_table')), findsOneWidget);
    expect(find.byKey(const Key('developer_debug_query_result')), findsOneWidget);
    expect(find.textContaining('"table": "accounts"'), findsOneWidget);
  });

  testWidgets('shows errors from debug query', (tester) async {
    api.shouldFailDebugQuery = true;

    await mountWidget(const DebugSqlQueryScreen(), tester);
    await tester.tap(find.byKey(const Key('developer_debug_query_run_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('developer_debug_query_error')), findsOneWidget);
    expect(find.textContaining('debug query failed'), findsOneWidget);
  });

  testWidgets('shows validation error when SQL is empty', (tester) async {
    await mountWidget(const DebugSqlQueryScreen(), tester);
    await tester.enterText(find.byKey(const Key('developer_debug_query_input')), '   ');
    await tester.tap(find.byKey(const Key('developer_debug_query_run_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('developer_debug_query_error')), findsOneWidget);
    expect(find.text('debug_query: SQL is empty'), findsOneWidget);
    expect(api.lastDebugQuerySql, isNull);
  });

  testWidgets('copy button is disabled when no result exists', (tester) async {
    await mountWidget(const DebugSqlQueryScreen(), tester);

    final copyButton = tester.widget<TextButton>(
      find.byKey(const Key('developer_debug_query_copy_button')),
    );
    expect(copyButton.onPressed, isNull);
  });

  testWidgets('copy button is enabled after running a query', (tester) async {
    api.debugQueryResult = '[{"table":"accounts","count":2}]';

    await mountWidget(const DebugSqlQueryScreen(), tester);
    await tester.tap(find.byKey(const Key('developer_debug_query_run_button')));
    await tester.pumpAndSettle();

    final copyButton = tester.widget<TextButton>(
      find.byKey(const Key('developer_debug_query_copy_button')),
    );
    expect(copyButton.onPressed, isNotNull);
  });

  testWidgets('copy button returns early when result is empty string', (tester) async {
    api.debugQueryResult = '';

    await mountWidget(const DebugSqlQueryScreen(), tester);
    await tester.tap(find.byKey(const Key('developer_debug_query_run_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('developer_debug_query_copy_button')));
    await tester.pump();

    expect(find.text('Copied to clipboard'), findsNothing);
  });

  testWidgets('back button is rendered', (tester) async {
    await mountWidget(const DebugSqlQueryScreen(), tester);

    expect(find.byKey(const Key('slate_back_button')), findsOneWidget);
  });
}
