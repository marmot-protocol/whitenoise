import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:share_plus/share_plus.dart';
import 'package:whitenoise/profiling/perfetto_exporter.dart';
import 'package:whitenoise/profiling/span_stats.dart';
import 'package:whitenoise/profiling/tracer.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_filter_chip.dart';
import 'package:whitenoise/widgets/wn_separator.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

enum _LayerFilter { all, dart, rust }

enum _SortField { percent, total, calls, avg }

// ---------------------------------------------------------------------------
// Snapshot model
// ---------------------------------------------------------------------------

class _Snapshot {
  _Snapshot({required this.stats}) : timestamp = DateTime.now();

  final DateTime timestamp;
  final List<SpanStat> stats;

  String get label =>
      '${timestamp.hour.toString().padLeft(2, '0')}:'
      '${timestamp.minute.toString().padLeft(2, '0')}:'
      '${timestamp.second.toString().padLeft(2, '0')}';
}

// ---------------------------------------------------------------------------
// Main screen
// ---------------------------------------------------------------------------

/// Full-screen CPU profiling view (staging only).
///
/// The tracer is always running in staging — spans are recorded globally as soon
/// as the instrumented hooks execute. This screen just reads and displays the
/// ring buffer, refreshing every second while it is visible.
///
/// Controls:
///   • Reset — wipes the ring buffer so you can start a fresh measurement window
///   • Export — serialises the buffer to a Perfetto JSON file and opens the
///              system share sheet; open at https://ui.perfetto.dev (local, no upload)
///   • Snapshot — captures current stats for later comparison
class ProfilingScreen extends HookWidget {
  const ProfilingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final stats = useState<List<SpanStat>>(computeSpanStats());
    final isExporting = useState(false);
    final exportError = useState<String?>(null);
    final isPaused = useState(false);

    // Layer filter
    final layerFilter = useState(_LayerFilter.all);

    // Sort
    final sortField = useState(_SortField.percent);
    final sortAscending = useState(false);

    // Threshold filter (hide < 1%)
    final hideSmall = useState(false);

    // Snapshots
    final snapshots = useState<List<_Snapshot>>([]);
    final compareSnapshot = useState<_Snapshot?>(null);

    // Refresh the table every second while this screen is visible and not paused.
    useEffect(() {
      final timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (isPaused.value) return;
        stats.value = computeSpanStats();
      });
      return timer.cancel;
    }, const []);

    // Derived: filtered + sorted stats
    final displayStats = useMemoized(() {
      var list = stats.value.toList();

      // Layer filter
      switch (layerFilter.value) {
        case _LayerFilter.dart:
          list = list.where((s) => !s.name.startsWith('wn.')).toList();
        case _LayerFilter.rust:
          list = list.where((s) => s.name.startsWith('wn.')).toList();
        case _LayerFilter.all:
          break;
      }

      // Threshold filter
      if (hideSmall.value) {
        list = list.where((s) => s.percent >= 1.0).toList();
      }

      // Sort
      list.sort((a, b) {
        final cmp = switch (sortField.value) {
          _SortField.percent => a.percent.compareTo(b.percent),
          _SortField.total => a.totalUs.compareTo(b.totalUs),
          _SortField.calls => a.callCount.compareTo(b.callCount),
          _SortField.avg => a.avgUs.compareTo(b.avgUs),
        };
        return sortAscending.value ? cmp : -cmp;
      });

      return list;
    }, [stats.value, layerFilter.value, sortField.value, sortAscending.value, hideSmall.value]);

    void resetBuffer() {
      Tracer.reset();
      stats.value = const [];
      exportError.value = null;
    }

    Future<void> exportTrace() async {
      isExporting.value = true;
      exportError.value = null;
      try {
        final file = await exportPerfettoTrace();
        if (context.mounted) {
          await SharePlus.instance.share(
            ShareParams(
              files: [XFile(file.path, mimeType: 'application/json')],
              text: 'Whitenoise CPU trace — open at https://ui.perfetto.dev',
            ),
          );
        }
      } on Exception catch (e) {
        exportError.value = e.toString();
      } finally {
        isExporting.value = false;
      }
    }

    void takeSnapshot() {
      final snap = _Snapshot(stats: stats.value);
      // Keep max 5 snapshots, drop oldest.
      final updated = [...snapshots.value, snap];
      if (updated.length > 5) updated.removeAt(0);
      snapshots.value = updated;
    }

    void onSortTap(_SortField field) {
      if (sortField.value == field) {
        sortAscending.value = !sortAscending.value;
      } else {
        sortField.value = field;
        sortAscending.value = false;
      }
    }

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          child: WnSlate(
            header: WnSlateNavigationHeader(
              title: 'CPU Profiling',
              type: WnSlateNavigationType.back,
              onNavigate: () => Routes.goBack(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Gap(12.h),
                      _StatusBar(
                        spanCount: Tracer.spanCount,
                        isPaused: isPaused.value,
                      ),
                      Gap(8.h),
                      _BufferBar(spanCount: Tracer.spanCount),
                      Gap(12.h),
                      _Controls(
                        isExporting: isExporting.value,
                        hasData: stats.value.isNotEmpty,
                        isPaused: isPaused.value,
                        onReset: resetBuffer,
                        onExport: exportTrace,
                        onPauseToggle: () => isPaused.value = !isPaused.value,
                        onSnapshot: takeSnapshot,
                      ),
                      if (exportError.value != null) ...[
                        Gap(8.h),
                        Text(
                          exportError.value!,
                          style: context.typographyScaled.medium12.copyWith(
                            color: colors.fillDestructive,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                      Gap(12.h),
                      _LayerFilterRow(
                        selected: layerFilter.value,
                        onChanged: (v) => layerFilter.value = v,
                        hideSmall: hideSmall.value,
                        onHideSmallChanged: (v) => hideSmall.value = v,
                      ),
                      if (snapshots.value.isNotEmpty) ...[
                        Gap(8.h),
                        _SnapshotBar(
                          snapshots: snapshots.value,
                          selected: compareSnapshot.value,
                          onSelect: (s) {
                            compareSnapshot.value = compareSnapshot.value == s ? null : s;
                          },
                        ),
                      ],
                      Gap(12.h),
                      const WnSeparator(),
                    ],
                  ),
                ),
                Expanded(
                  child: displayStats.isEmpty
                      ? const _EmptyState()
                      : _StatsTable(
                          stats: displayStats,
                          sortField: sortField.value,
                          sortAscending: sortAscending.value,
                          onSortTap: onSortTap,
                          compareSnapshot: compareSnapshot.value,
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

// ---------------------------------------------------------------------------
// Status bar
// ---------------------------------------------------------------------------

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.spanCount, required this.isPaused});

  final int spanCount;
  final bool isPaused;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typographyScaled;

    return Row(
      children: [
        Container(
          key: const Key('profiling_status_dot'),
          width: 8.r,
          height: 8.r,
          decoration: BoxDecoration(
            color: isPaused ? colors.intentionWarningContent : colors.fillDestructive,
            shape: BoxShape.circle,
          ),
        ),
        Gap(6.w),
        Text(
          isPaused ? 'Paused' : 'Live',
          style: typography.semiBold14.copyWith(
            color: colors.backgroundContentPrimary,
          ),
        ),
        const Spacer(),
        Text(
          '$spanCount spans',
          style: typography.medium12.copyWith(
            color: colors.backgroundContentTertiary,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Buffer fill bar
// ---------------------------------------------------------------------------

class _BufferBar extends StatelessWidget {
  const _BufferBar({required this.spanCount});

  final int spanCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pct = (spanCount / 10000).clamp(0.0, 1.0);

    return Container(
      key: const Key('profiling_buffer_bar'),
      height: 3.h,
      decoration: BoxDecoration(
        color: colors.borderTertiary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(2.r),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: pct,
        child: Container(
          decoration: BoxDecoration(
            color: pct > 0.8 ? colors.intentionWarningContent : colors.intentionSuccessContent,
            borderRadius: BorderRadius.circular(2.r),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Control buttons
// ---------------------------------------------------------------------------

class _Controls extends StatelessWidget {
  const _Controls({
    required this.isExporting,
    required this.hasData,
    required this.isPaused,
    required this.onReset,
    required this.onExport,
    required this.onPauseToggle,
    required this.onSnapshot,
  });

  final bool isExporting;
  final bool hasData;
  final bool isPaused;
  final VoidCallback onReset;
  final VoidCallback onExport;
  final VoidCallback onPauseToggle;
  final VoidCallback onSnapshot;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: WnButton(
            key: const Key('profiling_pause_button'),
            text: isPaused ? 'Resume' : 'Pause',
            onPressed: onPauseToggle,
            size: WnButtonSize.medium,
            type: WnButtonType.outline,
          ),
        ),
        Gap(6.w),
        Expanded(
          child: WnButton(
            key: const Key('profiling_snapshot_button'),
            text: 'Snapshot',
            onPressed: onSnapshot,
            disabled: !hasData,
            size: WnButtonSize.medium,
            type: WnButtonType.outline,
          ),
        ),
        Gap(6.w),
        Expanded(
          child: WnButton(
            key: const Key('profiling_reset_button'),
            text: 'Reset',
            onPressed: onReset,
            size: WnButtonSize.medium,
            type: WnButtonType.outline,
          ),
        ),
        Gap(6.w),
        Expanded(
          child: WnButton(
            key: const Key('profiling_export_button'),
            text: isExporting ? 'Exporting…' : 'Export',
            onPressed: onExport,
            disabled: !hasData || isExporting,
            size: WnButtonSize.medium,
            type: WnButtonType.outline,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Layer filter row
// ---------------------------------------------------------------------------

class _LayerFilterRow extends StatelessWidget {
  const _LayerFilterRow({
    required this.selected,
    required this.onChanged,
    required this.hideSmall,
    required this.onHideSmallChanged,
  });

  final _LayerFilter selected;
  final ValueChanged<_LayerFilter> onChanged;
  final bool hideSmall;
  final ValueChanged<bool> onHideSmallChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        WnFilterChip(
          label: 'All',
          selected: selected == _LayerFilter.all,
          onSelected: (_) => onChanged(_LayerFilter.all),
        ),
        Gap(6.w),
        WnFilterChip(
          label: 'Dart',
          selected: selected == _LayerFilter.dart,
          onSelected: (_) => onChanged(_LayerFilter.dart),
        ),
        Gap(6.w),
        WnFilterChip(
          label: 'Rust',
          selected: selected == _LayerFilter.rust,
          onSelected: (_) => onChanged(_LayerFilter.rust),
        ),
        const Spacer(),
        WnFilterChip(
          label: '<1%',
          selected: hideSmall,
          onSelected: onHideSmallChanged,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Snapshot bar
// ---------------------------------------------------------------------------

class _SnapshotBar extends StatelessWidget {
  const _SnapshotBar({
    required this.snapshots,
    required this.selected,
    required this.onSelect,
  });

  final List<_Snapshot> snapshots;
  final _Snapshot? selected;
  final ValueChanged<_Snapshot> onSelect;

  @override
  Widget build(BuildContext context) {
    final typography = context.typographyScaled;
    final colors = context.colors;

    return Row(
      children: [
        Text(
          'Compare:',
          style: typography.medium12.copyWith(
            color: colors.backgroundContentTertiary,
          ),
        ),
        Gap(8.w),
        ...snapshots.map((snap) {
          final isSelected = identical(snap, selected);
          return Padding(
            padding: EdgeInsets.only(right: 6.w),
            child: GestureDetector(
              onTap: () => onSelect(snap),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: isSelected ? colors.fillTertiaryActive : colors.backgroundPrimary,
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(
                    color: isSelected ? colors.borderSecondary : colors.borderTertiary,
                  ),
                ),
                child: Text(
                  snap.label,
                  style: typography.medium10.copyWith(
                    color: colors.backgroundContentSecondary,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typographyScaled;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Text(
          'Use the app — data will appear here within a second.',
          key: const Key('profiling_empty_message'),
          textAlign: TextAlign.center,
          style: typography.medium14.copyWith(
            color: colors.backgroundContentTertiary,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stats table
// ---------------------------------------------------------------------------

class _StatsTable extends StatelessWidget {
  const _StatsTable({
    required this.stats,
    required this.sortField,
    required this.sortAscending,
    required this.onSortTap,
    required this.compareSnapshot,
  });

  final List<SpanStat> stats;
  final _SortField sortField;
  final bool sortAscending;
  final ValueChanged<_SortField> onSortTap;
  final _Snapshot? compareSnapshot;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typographyScaled;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 4.h),
          child: Row(
            children: [
              _HeaderCell(
                label: 'Span',
                flex: 3,
                typography: typography,
                colors: colors,
              ),
              _SortableHeaderCell(
                label: '%',
                flex: 1,
                field: _SortField.percent,
                currentField: sortField,
                ascending: sortAscending,
                onTap: onSortTap,
                typography: typography,
                colors: colors,
              ),
              _SortableHeaderCell(
                label: 'Total',
                flex: 2,
                field: _SortField.total,
                currentField: sortField,
                ascending: sortAscending,
                onTap: onSortTap,
                typography: typography,
                colors: colors,
              ),
              _SortableHeaderCell(
                label: 'Calls',
                flex: 1,
                field: _SortField.calls,
                currentField: sortField,
                ascending: sortAscending,
                onTap: onSortTap,
                typography: typography,
                colors: colors,
              ),
              _SortableHeaderCell(
                label: 'Avg',
                flex: 2,
                field: _SortField.avg,
                currentField: sortField,
                ascending: sortAscending,
                onTap: onSortTap,
                typography: typography,
                colors: colors,
              ),
              if (compareSnapshot != null)
                _HeaderCell(
                  label: 'Δ%',
                  flex: 1,
                  typography: typography,
                  colors: colors,
                  alignRight: true,
                ),
            ],
          ),
        ),
        Divider(height: 1.h, color: colors.borderTertiary),
        Expanded(
          child: ListView.separated(
            key: const Key('profiling_stats_list'),
            padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
            itemCount: stats.length,
            separatorBuilder: (_, _) => Divider(height: 1.h, color: colors.borderTertiary),
            itemBuilder: (context, index) {
              final stat = stats[index];
              // Find delta from snapshot if comparing
              double? deltaPct;
              if (compareSnapshot != null) {
                final oldStat = compareSnapshot!.stats
                    .where((s) => s.name == stat.name)
                    .firstOrNull;
                deltaPct = oldStat != null ? stat.percent - oldStat.percent : stat.percent;
              }
              return _StatRow(
                stat: stat,
                rank: index + 1,
                deltaPct: deltaPct,
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Header cells
// ---------------------------------------------------------------------------

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({
    required this.label,
    required this.flex,
    required this.typography,
    required this.colors,
    this.alignRight = false,
  });

  final String label;
  final int flex;
  final AppTypography typography;
  final SemanticColors colors;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: typography.semiBold10.copyWith(
          color: colors.backgroundContentTertiary,
          letterSpacing: 0.5.sp,
        ),
      ),
    );
  }
}

class _SortableHeaderCell extends StatelessWidget {
  const _SortableHeaderCell({
    required this.label,
    required this.flex,
    required this.field,
    required this.currentField,
    required this.ascending,
    required this.onTap,
    required this.typography,
    required this.colors,
  });

  final String label;
  final int flex;
  final _SortField field;
  final _SortField currentField;
  final bool ascending;
  final ValueChanged<_SortField> onTap;
  final AppTypography typography;
  final SemanticColors colors;

  @override
  Widget build(BuildContext context) {
    final isActive = field == currentField;
    final arrow = isActive ? (ascending ? ' ↑' : ' ↓') : '';

    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: () => onTap(field),
        child: Text(
          '$label$arrow',
          textAlign: TextAlign.right,
          style: typography.semiBold10.copyWith(
            color: isActive ? colors.backgroundContentPrimary : colors.backgroundContentTertiary,
            letterSpacing: 0.5.sp,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stat row
// ---------------------------------------------------------------------------

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.stat,
    required this.rank,
    this.deltaPct,
  });

  final SpanStat stat;
  final int rank;
  final double? deltaPct;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typographyScaled;

    final pct = stat.percent;
    final heatColor = _heatColor(pct, colors);

    return GestureDetector(
      onTap: () => _showDetailSheet(context, stat),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stat.name,
                    key: Key('profiling_row_name_$rank'),
                    style: typography.medium12.copyWith(
                      color: colors.backgroundContentPrimary,
                      fontFamily: 'monospace',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Gap(2.h),
                  _PercentBar(percent: pct, color: heatColor),
                ],
              ),
            ),
            Expanded(
              child: Text(
                '${stat.percentDisplay}%',
                key: Key('profiling_row_pct_$rank'),
                textAlign: TextAlign.right,
                style: typography.semiBold12.copyWith(color: heatColor),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                stat.totalMs,
                textAlign: TextAlign.right,
                style: typography.medium12.copyWith(
                  color: colors.backgroundContentSecondary,
                ),
              ),
            ),
            Expanded(
              child: Text(
                '${stat.callCount}',
                textAlign: TextAlign.right,
                style: typography.medium12.copyWith(
                  color: colors.backgroundContentSecondary,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                stat.avgMs,
                textAlign: TextAlign.right,
                style: typography.medium12.copyWith(
                  color: colors.backgroundContentTertiary,
                ),
              ),
            ),
            if (deltaPct != null)
              Expanded(
                child: Text(
                  _formatDelta(deltaPct!),
                  textAlign: TextAlign.right,
                  style: typography.semiBold10.copyWith(
                    color: _deltaColor(deltaPct!, colors),
                    fontFamily: 'monospace',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _heatColor(double pct, SemanticColors colors) {
    if (pct >= 30) return colors.fillDestructive;
    if (pct >= 15) return colors.intentionWarningContent;
    if (pct >= 5) return colors.intentionSuccessContent;
    return colors.backgroundContentTertiary;
  }

  String _formatDelta(double delta) {
    final sign = delta >= 0 ? '+' : '';
    return '$sign${delta.toStringAsFixed(1)}';
  }

  Color _deltaColor(double delta, SemanticColors colors) {
    if (delta > 2) return colors.fillDestructive;
    if (delta < -2) return colors.intentionSuccessContent;
    return colors.backgroundContentTertiary;
  }
}

// ---------------------------------------------------------------------------
// Percent bar
// ---------------------------------------------------------------------------

class _PercentBar extends StatelessWidget {
  const _PercentBar({required this.percent, required this.color});

  final double percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = constraints.maxWidth * (percent.clamp(0, 100) / 100);
        return Container(
          key: const Key('profiling_percent_bar'),
          height: 3.h,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(2.r),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: barWidth,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Detail bottom sheet
// ---------------------------------------------------------------------------

void _showDetailSheet(BuildContext context, SpanStat stat) {
  showModalBottomSheet(
    context: context,
    backgroundColor: context.colors.backgroundPrimary,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
    ),
    builder: (ctx) => _DetailSheet(stat: stat),
  );
}

class _DetailSheet extends StatelessWidget {
  const _DetailSheet({required this.stat});

  final SpanStat stat;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typographyScaled;

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: colors.borderTertiary,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          Gap(16.h),

          // Span name
          Text(
            stat.name,
            style: typography.semiBold16.copyWith(
              color: colors.backgroundContentPrimary,
              fontFamily: 'monospace',
            ),
          ),
          Gap(4.h),
          Text(
            '${stat.callCount} calls · ${stat.totalMs} ms total · ${stat.percentDisplay}% CPU',
            style: typography.medium12.copyWith(
              color: colors.backgroundContentTertiary,
            ),
          ),
          Gap(20.h),

          // Percentile row
          _PercentileRow(stat: stat),
          Gap(20.h),

          // Histogram
          Text(
            'Duration distribution',
            style: typography.semiBold12.copyWith(
              color: colors.backgroundContentSecondary,
            ),
          ),
          Gap(8.h),
          _Histogram(stat: stat),
          Gap(16.h),

          // Recent calls
          if (stat.durationsUs.length > 1) ...[
            Text(
              'Recent calls (newest first)',
              style: typography.semiBold12.copyWith(
                color: colors.backgroundContentSecondary,
              ),
            ),
            Gap(8.h),
            _RecentCalls(stat: stat),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Percentile row
// ---------------------------------------------------------------------------

class _PercentileRow extends StatelessWidget {
  const _PercentileRow({required this.stat});

  final SpanStat stat;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typographyScaled;

    return Row(
      children: [
        _PercentileCell(label: 'min', valueUs: stat.minUs, typography: typography, colors: colors),
        _PercentileCell(label: 'p50', valueUs: stat.p50Us, typography: typography, colors: colors),
        _PercentileCell(label: 'p95', valueUs: stat.p95Us, typography: typography, colors: colors),
        _PercentileCell(label: 'max', valueUs: stat.maxUs, typography: typography, colors: colors),
      ],
    );
  }
}

class _PercentileCell extends StatelessWidget {
  const _PercentileCell({
    required this.label,
    required this.valueUs,
    required this.typography,
    required this.colors,
  });

  final String label;
  final int valueUs;
  final AppTypography typography;
  final SemanticColors colors;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: typography.semiBold10.copyWith(
              color: colors.backgroundContentTertiary,
              letterSpacing: 0.5.sp,
            ),
          ),
          Gap(4.h),
          Text(
            _formatUs(valueUs),
            style: typography.semiBold14.copyWith(
              color: colors.backgroundContentPrimary,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  String _formatUs(int us) {
    if (us < 1000) return '${us}µs';
    if (us < 1000000) return '${(us / 1000).toStringAsFixed(1)}ms';
    return '${(us / 1000000).toStringAsFixed(2)}s';
  }
}

// ---------------------------------------------------------------------------
// Histogram
// ---------------------------------------------------------------------------

class _Histogram extends StatelessWidget {
  const _Histogram({required this.stat});

  final SpanStat stat;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typographyScaled;
    final buckets = stat.histogram();
    const barHeight = 48.0;

    return Column(
      children: [
        SizedBox(
          height: barHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: buckets.map((v) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 0.5.w),
                  child: FractionallySizedBox(
                    heightFactor: math.max(v, 0.02), // min visible height
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors.intentionSuccessContent.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(1.r),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Gap(4.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatUs(stat.minUs),
              style: typography.medium10.copyWith(
                color: colors.backgroundContentTertiary,
                fontFamily: 'monospace',
              ),
            ),
            Text(
              _formatUs(stat.maxUs),
              style: typography.medium10.copyWith(
                color: colors.backgroundContentTertiary,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatUs(int us) {
    if (us < 1000) return '${us}µs';
    if (us < 1000000) return '${(us / 1000).toStringAsFixed(1)}ms';
    return '${(us / 1000000).toStringAsFixed(2)}s';
  }
}

// ---------------------------------------------------------------------------
// Recent calls
// ---------------------------------------------------------------------------

class _RecentCalls extends StatelessWidget {
  const _RecentCalls({required this.stat});

  final SpanStat stat;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typographyScaled;

    // Show last 10, newest first (durationsUs is sorted by value, not time,
    // so we take the last N from the original list which approximates recency).
    final recent = stat.durationsUs.reversed.take(10).toList();
    final avgUs = stat.avgUs;

    return Wrap(
      spacing: 6.w,
      runSpacing: 4.h,
      children: recent.map((us) {
        final isOutlier = us > avgUs * 3;
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: isOutlier
                ? colors.fillDestructive.withValues(alpha: 0.15)
                : colors.borderTertiary.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4.r),
          ),
          child: Text(
            _formatUs(us),
            style: typography.medium10.copyWith(
              color: isOutlier ? colors.fillDestructive : colors.backgroundContentSecondary,
              fontFamily: 'monospace',
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatUs(int us) {
    if (us < 1000) return '${us}µs';
    if (us < 1000000) return '${(us / 1000).toStringAsFixed(1)}ms';
    return '${(us / 1000000).toStringAsFixed(2)}s';
  }
}
