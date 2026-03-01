import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/theme.dart';

class DebugQueryResultTableData {
  final List<String> columns;
  final List<List<String>> rows;
  final bool isTruncated;

  const DebugQueryResultTableData({
    required this.columns,
    required this.rows,
    required this.isTruncated,
  });
}

DebugQueryResultTableData? parseDebugQueryResultTable(String rawResult, {int maxRows = 200}) {
  dynamic decoded;
  try {
    decoded = jsonDecode(rawResult);
  } catch (_) {
    return null;
  }

  if (decoded is! List || decoded.isEmpty) {
    return null;
  }
  if (decoded.any((row) => row is! Map)) {
    return null;
  }

  final columns = <String>[];
  for (final row in decoded.cast<Map<dynamic, dynamic>>()) {
    for (final key in row.keys) {
      final column = key.toString();
      if (!columns.contains(column)) {
        columns.add(column);
      }
    }
  }
  if (columns.isEmpty) {
    return null;
  }

  final visibleRows = decoded.take(maxRows).cast<Map<dynamic, dynamic>>();
  final rows = <List<String>>[];
  for (final row in visibleRows) {
    rows.add(columns.map((column) => _stringifyCell(row[column])).toList());
  }

  return DebugQueryResultTableData(
    columns: columns,
    rows: rows,
    isTruncated: decoded.length > maxRows,
  );
}

String formatDebugQueryResult(String rawResult) {
  try {
    final decoded = jsonDecode(rawResult);
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(decoded);
  } catch (_) {
    return rawResult;
  }
}

class DebugQueryResultTable extends StatelessWidget {
  const DebugQueryResultTable({
    super.key,
    required this.data,
    required this.title,
    this.tableKey,
  });

  final DebugQueryResultTableData data;
  final String title;
  final Key? tableKey;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typographyScaled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: typography.semiBold10.copyWith(
            color: colors.backgroundContentSecondary,
            fontFamily: 'monospace',
          ),
        ),
        if (data.isTruncated) ...[
          SizedBox(height: 4.h),
          Text(
            'showing first ${data.rows.length} rows',
            style: typography.medium10.copyWith(
              color: colors.backgroundContentTertiary,
              fontFamily: 'monospace',
            ),
          ),
        ],
        SizedBox(height: 6.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(6.r),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Theme(
              data: Theme.of(context).copyWith(
                dividerColor: colors.borderTertiary,
              ),
              child: DataTable(
                key: tableKey,
                headingRowColor: WidgetStatePropertyAll(colors.backgroundPrimary),
                dataRowColor: WidgetStatePropertyAll(colors.backgroundSecondary),
                columnSpacing: 18.w,
                horizontalMargin: 10.w,
                headingTextStyle: typography.semiBold10.copyWith(
                  color: colors.backgroundContentSecondary,
                  fontFamily: 'monospace',
                ),
                dataTextStyle: typography.medium10.copyWith(
                  color: colors.backgroundContentPrimary,
                  fontFamily: 'monospace',
                ),
                columns: data.columns.map((column) => DataColumn(label: Text(column))).toList(),
                rows: data.rows
                    .map(
                      (row) => DataRow(
                        cells: row
                            .map(
                              (cell) => DataCell(
                                ConstrainedBox(
                                  constraints: BoxConstraints(maxWidth: 220.w),
                                  child: Text(
                                    cell,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 3,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

String _stringifyCell(Object? value) {
  if (value == null) {
    return 'null';
  }
  if (value is num || value is bool || value is String) {
    return value.toString();
  }
  return jsonEncode(value);
}
