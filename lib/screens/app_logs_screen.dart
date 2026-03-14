import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/hooks/use_app_logs.dart';
import 'package:whitenoise/hooks/use_system_notice.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/providers/app_log_filter_provider.dart';
import 'package:whitenoise/providers/app_log_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_icon.dart';
import 'package:whitenoise/widgets/wn_input.dart' show WnInput, WnInputTrailingButton;
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart';

const _pauseThreshold = 80.0;

class AppLogsScreen extends HookConsumerWidget {
  const AppLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useAppLogs();
    final colors = context.colors;
    final typography = context.typographyScaled;
    final liveRawEntries = ref.watch(appLogProvider);
    final totalEntries = liveRawEntries.length;
    final filter = ref.watch(appLogFilterProvider);
    final patternController = useTextEditingController();
    final patternFocus = useFocusNode();
    final searchController = useTextEditingController(text: filter.searchQuery);

    final paused = useState(false);
    final frozenRawEntries = useState<List<AppLogEntry>>(const []);
    final scrollController = useScrollController();
    final isAnimating = useRef(false);
    final mountedRef = useRef(true);
    final systemNotice = useSystemNotice();
    useEffect(
      () =>
          () => mountedRef.value = false,
      const [],
    );

    List<AppLogEntry> applyFilter(List<AppLogEntry> source) {
      if (filter.searchQuery.isEmpty &&
          filter.includePatterns.isEmpty &&
          filter.excludePatterns.isEmpty) {
        return source;
      }
      return source.where((e) {
        final buf = StringBuffer('${e.level.name} ${e.loggerName} ${e.message}');
        if (e.error != null) buf.write(' ${e.error}');
        if (e.stackTrace != null) buf.write(' ${e.stackTrace}');
        final text = buf.toString().toLowerCase();
        if (filter.excludePatterns.any((p) => text.contains(p.toLowerCase()))) {
          return false;
        }
        if (filter.includePatterns.isNotEmpty &&
            !filter.includePatterns.any((p) => text.contains(p.toLowerCase()))) {
          return false;
        }
        if (filter.searchQuery.isNotEmpty && !text.contains(filter.searchQuery.toLowerCase())) {
          return false;
        }
        return true;
      }).toList();
    }

    final entries = applyFilter(paused.value ? frozenRawEntries.value : liveRawEntries);

    final liveRawEntriesRef = useRef(liveRawEntries);
    liveRawEntriesRef.value = liveRawEntries;

    useEffect(() {
      void onScroll() {
        if (!scrollController.hasClients) return;
        if (isAnimating.value) return;
        final offset = scrollController.offset;
        if (!paused.value && offset > _pauseThreshold) {
          paused.value = true;
          frozenRawEntries.value = List.of(liveRawEntriesRef.value);
        } else if (paused.value && offset <= _pauseThreshold) {
          paused.value = false;
        }
      }

      scrollController.addListener(onScroll);
      return () => scrollController.removeListener(onScroll);
    }, [scrollController, paused]);

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

    void resumeLive() {
      if (scrollController.hasClients) {
        isAnimating.value = true;
        scrollController
            .animateTo(
              0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
            )
            .then((_) {
              if (!mountedRef.value) return;
              isAnimating.value = false;
              paused.value = false;
            });
      } else {
        paused.value = false;
      }
    }

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          child: WnSlate(
            systemNotice: systemNotice.noticeMessage != null
                ? WnSystemNotice(
                    title: systemNotice.noticeMessage!,
                    type: systemNotice.noticeType,
                    onDismiss: systemNotice.dismissNotice,
                    autoHideDuration: const Duration(seconds: 2),
                  )
                : null,
            header: WnSlateNavigationHeader(
              title: context.l10n.appLogsTitle,
              onNavigate: () => Routes.goBack(context),
            ),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 8.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      WnInput(
                        key: const Key('app_logs_search'),
                        placeholder: context.l10n.appLogsSearchPlaceholder,
                        controller: searchController,
                        onChanged: (v) => ref.read(appLogFilterProvider.notifier).setSearch(v),
                        trailingAction: filter.searchQuery.isNotEmpty
                            ? WnInputTrailingButton(
                                icon: WnIcons.closeSmall,
                                onPressed: () =>
                                    ref.read(appLogFilterProvider.notifier).setSearch(''),
                                filled: false,
                              )
                            : null,
                      ),
                      Gap(8.h),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: WnInput(
                                  key: const Key('app_logs_pattern_input'),
                                  placeholder: context.l10n.appLogsAddPatternPlaceholder,
                                  controller: patternController,
                                  focusNode: patternFocus,
                                  leadingIcon: Icon(
                                    Icons.filter_list,
                                    size: 20.sp,
                                    color: colors.backgroundContentTertiary,
                                  ),
                                  onSubmitted: (_) {
                                    final text = patternController.text;
                                    if (text.trim().isNotEmpty) {
                                      ref.read(appLogFilterProvider.notifier).addExclude(text);
                                      patternController.clear();
                                    }
                                  },
                                  trailingAction: hasFilters
                                      ? WnInputTrailingButton(
                                          key: const Key('app_logs_clear_filters'),
                                          icon: WnIcons.closeSmall,
                                          onPressed: () =>
                                              ref.read(appLogFilterProvider.notifier).clearAll(),
                                          filled: false,
                                        )
                                      : null,
                                ),
                              ),
                              Gap(8.w),
                              WnButton(
                                key: const Key('app_logs_add_ignore'),
                                text: context.l10n.appLogsIgnore,
                                onPressed: () {
                                  final text = patternController.text;
                                  if (text.trim().isNotEmpty) {
                                    ref.read(appLogFilterProvider.notifier).addExclude(text);
                                    patternController.clear();
                                    patternFocus.unfocus();
                                  }
                                },
                                type: WnButtonType.outline,
                                size: WnButtonSize.small,
                              ),
                              Gap(8.w),
                              WnButton(
                                key: const Key('app_logs_add_show'),
                                text: context.l10n.appLogsShow,
                                onPressed: () {
                                  final text = patternController.text;
                                  if (text.trim().isNotEmpty) {
                                    ref.read(appLogFilterProvider.notifier).addInclude(text);
                                    patternController.clear();
                                    patternFocus.unfocus();
                                  }
                                },
                                size: WnButtonSize.small,
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
                        ],
                      ),
                      Gap(8.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: hasFilters && totalEntries > 0
                                ? Padding(
                                    padding: EdgeInsets.only(right: 8.w),
                                    child: Text(
                                      context.l10n.appLogsFilteredCount(
                                        entries.length,
                                        totalEntries,
                                      ),
                                      style: typography.medium12.copyWith(
                                        color: colors.backgroundContentTertiary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                          Row(
                            children: [
                              if (totalEntries > 0)
                                WnButton(
                                  key: const Key('app_logs_clear'),
                                  text: context.l10n.appLogsEraseAll,
                                  leadingIcon: WnIcons.trashCan,
                                  onPressed: () {
                                    ref.read(appLogProvider.notifier).clear();
                                    paused.value = false;
                                    frozenRawEntries.value = const [];
                                  },
                                  type: WnButtonType.outline,
                                  size: WnButtonSize.small,
                                ),
                              if (totalEntries > 0 && entries.isNotEmpty) Gap(8.w),
                              if (entries.isNotEmpty)
                                WnButton(
                                  key: const Key('app_logs_copy_all'),
                                  text: context.l10n.appLogsCopyAll,
                                  leadingIcon: WnIcons.copy,
                                  onPressed: () => _copyAllEntries(
                                    context,
                                    entries,
                                    showSuccessNotice: systemNotice.showSuccessNotice,
                                  ),
                                  type: WnButtonType.outline,
                                  size: WnButtonSize.small,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      entries.isEmpty
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
                              key: const Key('app_logs_list'),
                              controller: scrollController,
                              reverse: true,
                              padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
                              itemCount: entries.length,
                              itemBuilder: (context, index) {
                                final entry = entries[index];
                                return _LogEntryTile(
                                  entry: entry,
                                  onTap: () => _copyEntry(
                                    context,
                                    entry,
                                    showSuccessNotice: systemNotice.showSuccessNotice,
                                  ),
                                );
                              },
                            ),
                      if (paused.value)
                        Positioned(
                          bottom: 16.h,
                          right: 16.w,
                          child: _AppLogsResumeLiveButton(onTap: resumeLive),
                        ),
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

  Future<void> _copyEntry(
    BuildContext context,
    AppLogEntry entry, {
    required void Function(String) showSuccessNotice,
  }) async {
    final text = _formatEntry(entry);
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      showSuccessNotice(context.l10n.rawDebugViewCopied);
    }
  }

  Future<void> _copyAllEntries(
    BuildContext context,
    List<AppLogEntry> entries, {
    required void Function(String) showSuccessNotice,
  }) async {
    final buffer = StringBuffer();
    for (final entry in entries) {
      buffer.write(_formatEntry(entry));
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (context.mounted) {
      showSuccessNotice(context.l10n.rawDebugViewCopied);
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

class _AppLogsResumeLiveButton extends StatelessWidget {
  const _AppLogsResumeLiveButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typographyScaled;

    return GestureDetector(
      key: const Key('app_logs_resume_live'),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: colors.fillPrimary,
          borderRadius: BorderRadius.circular(999.r),
          boxShadow: [
            BoxShadow(
              color: colors.backgroundContentPrimary.withValues(alpha: 0.15),
              blurRadius: 8.r,
              offset: Offset(0.w, 2.h),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            WnIcon(
              WnIcons.arrowDown,
              key: const Key('app_logs_resume_live_icon'),
              size: 14.sp,
              color: colors.fillContentPrimary,
            ),
            Gap(6.w),
            Text(
              context.l10n.appLogsLive,
              style: typography.semiBold12.copyWith(
                color: colors.fillContentPrimary,
              ),
            ),
          ],
        ),
      ),
    );
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

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onRemove,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
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
              style: typography.medium10.copyWith(
                color: colors.backgroundContentPrimary,
                fontFamily: 'monospace',
              ),
            ),
            Gap(3.w),
            Icon(
              Icons.close,
              size: 12.sp,
              color: colors.backgroundContentSecondary,
            ),
          ],
        ),
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
      behavior: HitTestBehavior.opaque,
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
                Gap(6.w),
                WnIcon(
                  WnIcons.copy,
                  key: const Key('app_logs_entry_copy_icon'),
                  size: 14.sp,
                  color: colors.backgroundContentTertiary,
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Text(
              entry.message,
              style: typography.medium12.copyWith(
                color: colors.backgroundContentPrimary,
                fontFamily: 'monospace',
                height: 1.4,
              ),
            ),
            if (entry.error != null) ...[
              SizedBox(height: 4.h),
              Text(
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
              Text(
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
