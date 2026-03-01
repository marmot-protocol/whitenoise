import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/src/rust/api/utils.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/debug_query_result_table.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';

class DebugSqlQueryScreen extends HookWidget {
  const DebugSqlQueryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typographyScaled;
    final sqlController = useTextEditingController(
      text: "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name;",
    );
    final isRunning = useState(false);
    final result = useState<String?>(null);
    final error = useState<String?>(null);

    Future<void> runQuery() async {
      final sql = sqlController.text.trim();
      if (sql.isEmpty) {
        error.value = 'debug_query: SQL is empty';
        result.value = null;
        return;
      }

      isRunning.value = true;
      error.value = null;
      try {
        final rawResult = await debugQuery(sql: sql);
        if (!context.mounted) {
          return;
        }
        result.value = formatDebugQueryResult(rawResult);
      } catch (e) {
        if (!context.mounted) {
          return;
        }
        error.value = 'debug_query: $e';
        result.value = null;
      } finally {
        if (context.mounted) {
          isRunning.value = false;
        }
      }
    }

    Future<void> copyResult() async {
      if (result.value == null || result.value!.isEmpty) {
        return;
      }
      await Clipboard.setData(ClipboardData(text: result.value!));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.rawDebugViewCopied),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          child: WnSlate(
            header: WnSlateNavigationHeader(
              title: 'Debug SQL Query',
              type: WnSlateNavigationType.back,
              onNavigate: () => Routes.goBack(context),
            ),
            child: ListView(
              padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 14.h),
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: colors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'debug_query:',
                        style: typography.semiBold10.copyWith(
                          color: colors.backgroundContentSecondary,
                          fontFamily: 'monospace',
                        ),
                      ),
                      SizedBox(height: 8.h),
                      TextField(
                        key: const Key('developer_debug_query_input'),
                        controller: sqlController,
                        minLines: 5,
                        maxLines: 12,
                        style: typography.medium10.copyWith(
                          color: colors.backgroundContentPrimary,
                          fontFamily: 'monospace',
                          height: 1.4,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: 'SELECT * FROM accounts LIMIT 10;',
                          hintStyle: typography.medium10.copyWith(
                            color: colors.backgroundContentTertiary,
                            fontFamily: 'monospace',
                          ),
                          filled: true,
                          fillColor: colors.backgroundPrimary,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6.r),
                            borderSide: BorderSide(
                              color: colors.backgroundContentTertiary.withValues(alpha: 0.4),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6.r),
                            borderSide: BorderSide(
                              color: colors.backgroundContentTertiary.withValues(alpha: 0.4),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6.r),
                            borderSide: BorderSide(color: colors.backgroundContentSecondary),
                          ),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          TextButton(
                            key: const Key('developer_debug_query_run_button'),
                            onPressed: isRunning.value ? null : runQuery,
                            child: Text(isRunning.value ? 'Running...' : 'Run SQL'),
                          ),
                          SizedBox(width: 8.w),
                          TextButton(
                            key: const Key('developer_debug_query_copy_button'),
                            onPressed: result.value == null ? null : copyResult,
                            child: const Text('Copy Result'),
                          ),
                        ],
                      ),
                      if (error.value != null) ...[
                        SizedBox(height: 6.h),
                        SelectableText(
                          key: const Key('developer_debug_query_error'),
                          error.value!,
                          style: typography.medium10.copyWith(
                            color: colors.fillDestructive,
                            fontFamily: 'monospace',
                            height: 1.4,
                          ),
                        ),
                      ],
                      if (result.value != null) ...[
                        SizedBox(height: 6.h),
                        Builder(
                          builder: (context) {
                            final tableData = parseDebugQueryResultTable(result.value!);
                            if (tableData == null) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: EdgeInsets.only(bottom: 8.h),
                              child: DebugQueryResultTable(
                                data: tableData,
                                title:
                                    'table (${tableData.rows.length} rows, ${tableData.columns.length} columns):',
                                tableKey: const Key('developer_debug_query_table'),
                              ),
                            );
                          },
                        ),
                        Text(
                          'result:',
                          style: typography.semiBold10.copyWith(
                            color: colors.backgroundContentSecondary,
                            fontFamily: 'monospace',
                          ),
                        ),
                        SizedBox(height: 4.h),
                        SelectableText(
                          key: const Key('developer_debug_query_result'),
                          result.value!,
                          style: typography.medium10.copyWith(
                            color: colors.backgroundContentPrimary,
                            fontFamily: 'monospace',
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
