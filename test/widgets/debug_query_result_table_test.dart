import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/widgets/debug_query_result_table.dart';

import '../test_helpers.dart' show mountWidget;

void main() {
  group('parseDebugQueryResultTable', () {
    test('parses valid JSON array of objects', () {
      final json = jsonEncode([
        {'id': 1, 'name': 'Alice'},
        {'id': 2, 'name': 'Bob'},
      ]);

      final result = parseDebugQueryResultTable(json);

      expect(result, isNotNull);
      expect(result!.columns, ['id', 'name']);
      expect(result.rows.length, 2);
      expect(result.rows[0], ['1', 'Alice']);
      expect(result.rows[1], ['2', 'Bob']);
      expect(result.isTruncated, false);
    });

    test('returns null for invalid JSON', () {
      final result = parseDebugQueryResultTable('not json at all');

      expect(result, isNull);
    });

    test('returns null for empty array', () {
      final result = parseDebugQueryResultTable('[]');

      expect(result, isNull);
    });

    test('returns null for non-array JSON', () {
      final result = parseDebugQueryResultTable('{"key": "value"}');

      expect(result, isNull);
    });

    test('returns null for array of non-maps', () {
      final result = parseDebugQueryResultTable('[1, 2, 3]');

      expect(result, isNull);
    });

    test('returns null for array with empty maps', () {
      final result = parseDebugQueryResultTable('[{}]');

      expect(result, isNull);
    });

    test('handles null cell values as "null" string', () {
      final json = jsonEncode([
        {'id': 1, 'name': null},
      ]);

      final result = parseDebugQueryResultTable(json);

      expect(result, isNotNull);
      expect(result!.rows[0], ['1', 'null']);
    });

    test('handles boolean cell values', () {
      final json = jsonEncode([
        {'active': true, 'deleted': false},
      ]);

      final result = parseDebugQueryResultTable(json);

      expect(result, isNotNull);
      expect(result!.rows[0], ['true', 'false']);
    });

    test('handles numeric cell values', () {
      final json = jsonEncode([
        {'int_val': 42, 'double_val': 3.14},
      ]);

      final result = parseDebugQueryResultTable(json);

      expect(result, isNotNull);
      expect(result!.rows[0], ['42', '3.14']);
    });

    test('stringifies nested object values via jsonEncode', () {
      final json = jsonEncode([
        {
          'id': 1,
          'metadata': {'role': 'admin', 'level': 5},
        },
      ]);

      final result = parseDebugQueryResultTable(json);

      expect(result, isNotNull);
      expect(result!.rows[0][0], '1');
      expect(result.rows[0][1], '{"role":"admin","level":5}');
    });

    test('stringifies nested array values via jsonEncode', () {
      final json = jsonEncode([
        {
          'id': 1,
          'tags': ['a', 'b', 'c'],
        },
      ]);

      final result = parseDebugQueryResultTable(json);

      expect(result, isNotNull);
      expect(result!.rows[0][1], '["a","b","c"]');
    });

    test('truncates rows when exceeding maxRows', () {
      final rows = List.generate(5, (i) => {'id': i, 'name': 'row_$i'});
      final json = jsonEncode(rows);

      final result = parseDebugQueryResultTable(json, maxRows: 3);

      expect(result, isNotNull);
      expect(result!.rows.length, 3);
      expect(result.isTruncated, true);
      expect(result.rows[0], ['0', 'row_0']);
      expect(result.rows[2], ['2', 'row_2']);
    });

    test('does not truncate when rows equal maxRows', () {
      final rows = List.generate(3, (i) => {'id': i});
      final json = jsonEncode(rows);

      final result = parseDebugQueryResultTable(json, maxRows: 3);

      expect(result, isNotNull);
      expect(result!.rows.length, 3);
      expect(result.isTruncated, false);
    });

    test('collects columns from all rows', () {
      final json = jsonEncode([
        {'a': 1},
        {'b': 2},
        {'a': 3, 'c': 4},
      ]);

      final result = parseDebugQueryResultTable(json);

      expect(result, isNotNull);
      expect(result!.columns, ['a', 'b', 'c']);
      expect(result.rows[0], ['1', 'null', 'null']);
      expect(result.rows[1], ['null', '2', 'null']);
      expect(result.rows[2], ['3', 'null', '4']);
    });
  });

  group('formatDebugQueryResult', () {
    test('pretty-prints valid JSON', () {
      final input = '{"name":"Alice","age":30}';

      final result = formatDebugQueryResult(input);

      expect(result, contains('  "name": "Alice"'));
      expect(result, contains('  "age": 30'));
    });

    test('pretty-prints JSON array', () {
      final input = '[{"id":1},{"id":2}]';

      final result = formatDebugQueryResult(input);

      expect(result, contains('  {\n    "id": 1\n  }'));
    });

    test('returns raw string for invalid JSON', () {
      const input = 'this is not json';

      final result = formatDebugQueryResult(input);

      expect(result, input);
    });

    test('returns raw string for malformed JSON', () {
      const input = '{"unclosed": ';

      final result = formatDebugQueryResult(input);

      expect(result, input);
    });
  });

  group('DebugQueryResultTable widget', () {
    testWidgets('renders title and table columns', (tester) async {
      final data = const DebugQueryResultTableData(
        columns: ['id', 'name'],
        rows: [
          ['1', 'Alice'],
          ['2', 'Bob'],
        ],
        isTruncated: false,
      );

      await mountWidget(
        DebugQueryResultTable(data: data, title: 'Test Table'),
        tester,
      );

      expect(find.text('Test Table'), findsOneWidget);
      expect(find.text('id'), findsOneWidget);
      expect(find.text('name'), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
    });

    testWidgets('does not show truncation message when not truncated', (tester) async {
      final data = const DebugQueryResultTableData(
        columns: ['id'],
        rows: [
          ['1'],
        ],
        isTruncated: false,
      );

      await mountWidget(
        DebugQueryResultTable(data: data, title: 'Not Truncated'),
        tester,
      );

      expect(find.textContaining('showing first'), findsNothing);
    });

    testWidgets('shows truncation message when isTruncated is true', (tester) async {
      final data = const DebugQueryResultTableData(
        columns: ['id', 'value'],
        rows: [
          ['1', 'a'],
          ['2', 'b'],
          ['3', 'c'],
        ],
        isTruncated: true,
      );

      await mountWidget(
        DebugQueryResultTable(data: data, title: 'Truncated Table'),
        tester,
      );

      expect(find.text('Truncated Table'), findsOneWidget);
      expect(find.text('showing first 3 rows'), findsOneWidget);
    });

    testWidgets('applies custom tableKey to DataTable', (tester) async {
      const tableKey = Key('custom_table_key');
      final data = const DebugQueryResultTableData(
        columns: ['col'],
        rows: [
          ['val'],
        ],
        isTruncated: false,
      );

      await mountWidget(
        DebugQueryResultTable(data: data, title: 'Keyed', tableKey: tableKey),
        tester,
      );

      expect(find.byKey(tableKey), findsOneWidget);
    });

    testWidgets('renders DataTable with correct number of rows', (tester) async {
      final data = const DebugQueryResultTableData(
        columns: ['x'],
        rows: [
          ['1'],
          ['2'],
          ['3'],
          ['4'],
        ],
        isTruncated: false,
      );

      await mountWidget(
        DebugQueryResultTable(data: data, title: 'Row Count'),
        tester,
      );

      final dataTable = tester.widget<DataTable>(find.byType(DataTable));
      expect(dataTable.rows.length, 4);
      expect(dataTable.columns.length, 1);
    });
  });

  group('end-to-end: parse then render truncated', () {
    testWidgets('parse with maxRows then render shows truncation', (tester) async {
      final rows = List.generate(10, (i) => {'id': i, 'val': 'item_$i'});
      final json = jsonEncode(rows);

      final data = parseDebugQueryResultTable(json, maxRows: 5);
      expect(data, isNotNull);
      expect(data!.isTruncated, true);
      expect(data.rows.length, 5);

      await mountWidget(
        DebugQueryResultTable(data: data, title: 'Query Results'),
        tester,
      );

      expect(find.text('Query Results'), findsOneWidget);
      expect(find.text('showing first 5 rows'), findsOneWidget);
      expect(find.text('item_0'), findsOneWidget);
      expect(find.text('item_4'), findsOneWidget);
    });
  });
}
