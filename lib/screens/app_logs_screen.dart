import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/providers/app_log_filter_provider.dart';
import 'package:whitenoise/providers/app_log_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_search_field.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';

class AppLogsScreen extends HookConsumerWidget {
  const AppLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final typography = context.typographyScaled;
    final entries = ref.watch(filteredAppLogProvider);
    final totalEntries = ref.watch(appLogProvider).length;
    final filter = ref.watch(appLogFilterProvider);
    final patternController = useTextEditingController();
    final patternFocus = useFocusNode();
    final searchController = useTextEditingController(text: filter.searchQuery);

    useEffect(() {
      if (searchController.text != filter.searchQuery) {
        searchController.text = filter.searchQuery;
      }
      return null;
    }, [filter.searchQuery]);

    final hasFilters =
        filter.searchQuery.isNotEmpty ||
        filter.includePatterns.isNotEmpty ||
        filter.excludePatterns.isNotEmpty;

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          child: WnSlate(
            header: WnSlateNavigationHeader(
              title: context.l10n.appLogsTitle,
              type: WnSlateNavigationType.back,
              onNavigate: () => Routes.goBack(context),
            ),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 8.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      WnSearchField(
                        key: const Key('app_logs_search'),
                        placeholder: context.l10n.appLogsSearchPlaceholder,
                        controller: searchController,
                        onChanged: (v) => ref.read(appLogFilterProvider.notifier).setSearch(v),
                      ),
                      Gap(8.h),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              key: const Key('app_logs_pattern_input'),
                              controller: patternController,
                              focusNode: patternFocus,
                              style: typography.medium14.copyWith(
                                color: colors.backgroundContentPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: context.l10n.appLogsAddPatternPlaceholder,
                                hintStyle: typography.medium14.copyWith(
                                  color: colors.backgroundContentTertiary,
                                ),
                                filled: true,
                                fillColor: colors.backgroundPrimary,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 10.h,
                                  horizontal: 12.w,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                  borderSide: BorderSide(color: colors.borderTertiary),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                  borderSide: BorderSide(color: colors.borderPrimary),
                                ),
                              ),
                              onSubmitted: (_) {
                                final text = patternController.text;
                                if (text.trim().isNotEmpty) {
                                  ref.read(appLogFilterProvider.notifier).addExclude(text);
                                  patternController.clear();
                                }
                              },
                            ),
                          ),
                          Gap(8.w),
                          TextButton(
                            key: const Key('app_logs_add_ignore'),
                            onPressed: () {
                              final text = patternController.text;
                              if (text.trim().isNotEmpty) {
                                ref.read(appLogFilterProvider.notifier).addExclude(text);
                                patternController.clear();
                                patternFocus.unfocus();
                              }
                            },
                            child: Text(context.l10n.appLogsIgnore),
                          ),
                          TextButton(
                            key: const Key('app_logs_add_show'),
                            onPressed: () {
                              final text = patternController.text;
                              if (text.trim().isNotEmpty) {
                                ref.read(appLogFilterProvider.notifier).addInclude(text);
                                patternController.clear();
                                patternFocus.unfocus();
                              }
                            },
                            child: Text(context.l10n.appLogsShow),
                          ),
                        ],
                      ),
                      if (filter.excludePatterns.isNotEmpty ||
                          filter.includePatterns.isNotEmpty) ...[
                        Gap(8.h),
                        Wrap(
                          spacing: 6.w,
                          runSpacing: 6.h,
                          children: [
                            ...filter.excludePatterns.map(
                              (p) => _FilterChip(
                                key: Key('exclude_$p'),
                                label: p,
                                isExclude: true,
                                onRemove: () =>
                                    ref.read(appLogFilterProvider.notifier).removeExclude(p),
                              ),
                            ),
                            ...filter.includePatterns.map(
                              (p) => _FilterChip(
                                key: Key('include_$p'),
                                label: p,
                                isExclude: false,
                                onRemove: () =>
                                    ref.read(appLogFilterProvider.notifier).removeInclude(p),
                              ),
                            ),
                          ],
                        ),
                      ],
                      Gap(8.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (hasFilters)
                            TextButton(
                              key: const Key('app_logs_clear_filters'),
                              onPressed: () => ref.read(appLogFilterProvider.notifier).clearAll(),
                              child: Text(context.l10n.appLogsClearFilters),
                            )
                          else
                            const SizedBox.shrink(),
                          Row(
                            children: [
                              if (hasFilters && totalEntries > 0)
                                Padding(
                                  padding: EdgeInsets.only(right: 8.w),
                                  child: Text(
                                    context.l10n.appLogsFilteredCount(
                                      entries.length,
                                      totalEntries,
                                    ),
                                    style: typography.medium12.copyWith(
                                      color: colors.backgroundContentTertiary,
                                    ),
                                  ),
                                ),
                              if (totalEntries > 0)
                                TextButton(
                                  onPressed: () => ref.read(appLogProvider.notifier).clear(),
                                  child: Text(context.l10n.appLogsClear),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: entries.isEmpty
                      ? Center(
                          child: Text(
                            totalEntries == 0
                                ? context.l10n.appLogsEmpty
                                : context.l10n.appLogsFilteredCount(
                                    entries.length,
                                    totalEntries,
                                  ),
                            style: typography.medium14.copyWith(
                              color: colors.backgroundContentTertiary,
                            ),
                          ),
                        )
                      : ListView.builder(
                          reverse: true,
                          padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
                          itemCount: entries.length,
                          itemBuilder: (context, index) {
                            final entry = entries[index];
                            return _LogEntryTile(
                              entry: entry,
                              onTap: () => _copyEntry(context, entry),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _copyEntry(BuildContext context, AppLogEntry entry) async {
    final text = _formatEntry(entry);
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.rawDebugViewCopied),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _formatEntry(AppLogEntry entry) {
    final buf = StringBuffer();
    buf.writeln('${entry.timestamp.toIso8601String()} ${entry.level.name} ${entry.loggerName}');
    buf.writeln(entry.message);
    if (entry.error != null) buf.writeln('  error: ${entry.error}');
    if (entry.stackTrace != null) buf.writeln('  stackTrace: ${entry.stackTrace}');
    return buf.toString();
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    super.key,
    required this.label,
    required this.isExclude,
    required this.onRemove,
  });

  final String label;
  final bool isExclude;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typographyScaled;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: isExclude
            ? colors.fillDestructive.withValues(alpha: 0.15)
            : colors.intentionSuccessContent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(
          color: isExclude
              ? colors.fillDestructive.withValues(alpha: 0.4)
              : colors.intentionSuccessContent.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isExclude ? '− $label' : '+ $label',
            style: typography.medium12.copyWith(
              color: colors.backgroundContentPrimary,
              fontFamily: 'monospace',
            ),
          ),
          Gap(4.w),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close,
              size: 14.sp,
              color: colors.backgroundContentSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LogEntryTile extends StatelessWidget {
  const _LogEntryTile({required this.entry, required this.onTap});

  final AppLogEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typographyScaled;
    final levelColor = _levelColor(colors, entry.level);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 6.h),
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: colors.backgroundSecondary,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: levelColor.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  entry.level.name,
                  style: typography.semiBold10.copyWith(
                    color: levelColor,
                    fontFamily: 'monospace',
                  ),
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    entry.loggerName,
                    style: typography.medium10.copyWith(
                      color: colors.backgroundContentSecondary,
                      fontFamily: 'monospace',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  _formatTime(entry.timestamp),
                  style: typography.medium10.copyWith(
                    color: colors.backgroundContentTertiary,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            SelectableText(
              entry.message,
              style: typography.medium12.copyWith(
                color: colors.backgroundContentPrimary,
                fontFamily: 'monospace',
                height: 1.4,
              ),
            ),
            if (entry.error != null) ...[
              SizedBox(height: 4.h),
              SelectableText(
                'error: ${entry.error}',
                style: typography.medium10.copyWith(
                  color: colors.fillDestructive,
                  fontFamily: 'monospace',
                  height: 1.3,
                ),
              ),
            ],
            if (entry.stackTrace != null) ...[
              SizedBox(height: 4.h),
              SelectableText(
                entry.stackTrace.toString().split('\n').take(5).join('\n'),
                style: typography.medium10.copyWith(
                  color: colors.backgroundContentTertiary,
                  fontFamily: 'monospace',
                  height: 1.3,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _levelColor(SemanticColors colors, Level level) {
    if (level == Level.SEVERE || level == Level.SHOUT) {
      return colors.fillDestructive;
    }
    if (level == Level.WARNING) {
      return colors.intentionWarningContent;
    }
    return colors.backgroundContentSecondary;
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')}:'
        '${dt.millisecond.toString().padLeft(3, '0')}';
  }
}
