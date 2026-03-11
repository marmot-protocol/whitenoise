import 'dart:math' as math;

import 'package:whitenoise/profiling/tracer.dart';

/// A single row in the profiling table.
final class SpanStat {
  const SpanStat({
    required this.name,
    required this.totalUs,
    required this.callCount,
    required this.percent,
    required this.durationsUs,
  });

  /// Span name (e.g. `chat_list.stream_update`).
  final String name;

  /// Cumulative CPU-time for this span name (microseconds).
  final int totalUs;

  /// How many times this span was recorded.
  final int callCount;

  /// Share of total recorded CPU time (0–100).
  final double percent;

  /// Individual call durations in microseconds (sorted ascending for percentile queries).
  final List<int> durationsUs;

  /// Average duration per call (microseconds).
  int get avgUs => callCount == 0 ? 0 : totalUs ~/ callCount;

  /// Minimum single-call duration.
  int get minUs => durationsUs.isEmpty ? 0 : durationsUs.first;

  /// Maximum single-call duration.
  int get maxUs => durationsUs.isEmpty ? 0 : durationsUs.last;

  /// Percentile query (0–100). Requires [durationsUs] to be sorted.
  int percentileUs(int p) {
    if (durationsUs.isEmpty) return 0;
    final idx = ((p / 100) * (durationsUs.length - 1)).round();
    return durationsUs[idx];
  }

  int get p50Us => percentileUs(50);
  int get p95Us => percentileUs(95);
  int get p99Us => percentileUs(99);

  String get totalMs => (totalUs / 1000).toStringAsFixed(1);
  String get avgMs => (avgUs / 1000).toStringAsFixed(2);
  String get percentDisplay => percent.toStringAsFixed(1);

  /// Histogram of durations split into [buckets] bins. Each value is 0.0–1.0
  /// (normalised to peak). Useful for rendering a small bar chart.
  List<double> histogram({int buckets = 20}) {
    if (durationsUs.isEmpty) return List.filled(buckets, 0);
    final minD = durationsUs.first;
    final maxD = durationsUs.last;
    if (minD == maxD) {
      // All calls identical — single full-height bar in the middle.
      final result = List.filled(buckets, 0.0);
      result[buckets ~/ 2] = 1.0;
      return result;
    }
    final width = (maxD - minD) / buckets;
    final counts = List.filled(buckets, 0);
    for (final d in durationsUs) {
      final idx = ((d - minD) / width).floor().clamp(0, buckets - 1);
      counts[idx]++;
    }
    final peak = counts.reduce(math.max);
    if (peak == 0) return List.filled(buckets, 0);
    return counts.map((c) => c / peak).toList();
  }
}

/// Aggregates the tracer ring buffer into a ranked list of [SpanStat]s.
///
/// Uses [Tracer.snapshot] to iterate [SpanEvent] objects directly — O(n)
/// single pass, no Perfetto B/E map allocation.
///
/// Spans are grouped by [SpanEvent.name]. The list is sorted by [SpanStat.totalUs]
/// descending so the hottest path is always first.
List<SpanStat> computeSpanStats() {
  final events = Tracer.snapshot();
  if (events.isEmpty) return const [];

  final durations = <String, List<int>>{};

  for (final e in events) {
    (durations[e.name] ??= []).add(e.durationUs);
  }

  final grandTotal = events.fold(0, (sum, e) => sum + e.durationUs);
  if (grandTotal == 0) return const [];

  final stats = durations.entries.map((entry) {
    final name = entry.key;
    final durs = entry.value..sort();
    final total = durs.fold(0, (a, b) => a + b);
    return SpanStat(
      name: name,
      totalUs: total,
      callCount: durs.length,
      percent: total / grandTotal * 100,
      durationsUs: durs,
    );
  }).toList()
    ..sort((a, b) => b.totalUs.compareTo(a.totalUs));

  return stats;
}

/// Computes stats from a pre-captured list of [SpanEvent]s (for snapshots).
List<SpanStat> computeSpanStatsFromEvents(List<SpanEvent> events) {
  if (events.isEmpty) return const [];

  final durations = <String, List<int>>{};

  for (final e in events) {
    (durations[e.name] ??= []).add(e.durationUs);
  }

  final grandTotal = events.fold(0, (sum, e) => sum + e.durationUs);
  if (grandTotal == 0) return const [];

  final stats = durations.entries.map((entry) {
    final name = entry.key;
    final durs = entry.value..sort();
    final total = durs.fold(0, (a, b) => a + b);
    return SpanStat(
      name: name,
      totalUs: total,
      callCount: durs.length,
      percent: total / grandTotal * 100,
      durationsUs: durs,
    );
  }).toList()
    ..sort((a, b) => b.totalUs.compareTo(a.totalUs));

  return stats;
}
