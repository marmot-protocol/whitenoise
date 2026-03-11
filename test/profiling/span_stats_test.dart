import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/profiling/span_stats.dart';
import 'package:whitenoise/profiling/tracer.dart';

void main() {
  setUp(Tracer.reset);
  tearDown(Tracer.reset);

  group('computeSpanStats', () {
    test('returns empty list when buffer is empty', () {
      expect(computeSpanStats(), isEmpty);
    });

    test('returns one stat per unique span name', () {
      Tracer.begin('alpha').end();
      Tracer.begin('beta').end();
      Tracer.begin('alpha').end();

      final stats = computeSpanStats();
      final names = stats.map((s) => s.name).toList();
      expect(names, containsAll(['alpha', 'beta']));
      expect(stats, hasLength(2));
    });

    test('call count is correct per name', () {
      Tracer.begin('x').end();
      Tracer.begin('x').end();
      Tracer.begin('x').end();

      final stats = computeSpanStats();
      expect(stats.single.callCount, 3);
    });

    test('percentages sum to 100', () {
      Tracer.begin('a').end();
      Tracer.begin('b').end();

      final stats = computeSpanStats();
      final total = stats.fold(0.0, (sum, s) => sum + s.percent);
      expect(total, closeTo(100.0, 0.001));
    });

    test('stats are sorted by totalUs descending (hottest first)', () {
      // Record spans in a way that guarantees one is longer than the other.
      for (var i = 0; i < 100; i++) {
        Tracer.begin('cheap').end();
      }
      // A single long-ish span created via trace so it wraps multiple iterations.
      Tracer.trace('expensive', () {
        var sum = 0;
        for (var i = 0; i < 1000000; i++) {
          sum += i;
        }
        return sum;
      });

      final stats = computeSpanStats();
      for (var i = 0; i < stats.length - 1; i++) {
        expect(stats[i].totalUs, greaterThanOrEqualTo(stats[i + 1].totalUs));
      }
    });

    test('percent is between 0 and 100 for each stat', () {
      Tracer.begin('p').end();
      Tracer.begin('q').end();

      for (final stat in computeSpanStats()) {
        expect(stat.percent, inInclusiveRange(0.0, 100.0));
      }
    });

    test('totalMs and avgMs are non-negative strings', () {
      Tracer.begin('ms').end();

      final stat = computeSpanStats().single;
      expect(double.tryParse(stat.totalMs), isNotNull);
      expect(double.tryParse(stat.avgMs), isNotNull);
      expect(double.parse(stat.totalMs), greaterThanOrEqualTo(0));
      expect(double.parse(stat.avgMs), greaterThanOrEqualTo(0));
    });

    test('percentDisplay contains one decimal place', () {
      Tracer.begin('one').end();

      final stat = computeSpanStats().single;
      expect(stat.percentDisplay, matches(RegExp(r'^\d+\.\d$')));
    });
  });

  group('SpanStat.durationsUs', () {
    test('contains individual call durations sorted ascending', () {
      Tracer.begin('d').end();
      Tracer.begin('d').end();
      Tracer.begin('d').end();

      final stat = computeSpanStats().single;
      expect(stat.durationsUs, hasLength(3));
      for (var i = 0; i < stat.durationsUs.length - 1; i++) {
        expect(stat.durationsUs[i], lessThanOrEqualTo(stat.durationsUs[i + 1]));
      }
    });

    test('minUs and maxUs reflect extremes', () {
      // Create spans with varying cost.
      Tracer.begin('fast').end();
      Tracer.trace('fast', () {
        var sum = 0;
        for (var i = 0; i < 100000; i++) sum += i;
        return sum;
      });

      final stat = computeSpanStats().where((s) => s.name == 'fast').single;
      expect(stat.minUs, lessThanOrEqualTo(stat.maxUs));
      expect(stat.minUs, stat.durationsUs.first);
      expect(stat.maxUs, stat.durationsUs.last);
    });
  });

  group('SpanStat.percentileUs', () {
    test('p50 is the median value', () {
      // Record many spans to get a meaningful distribution.
      for (var i = 0; i < 100; i++) {
        Tracer.begin('pct').end();
      }

      final stat = computeSpanStats().single;
      expect(stat.p50Us, greaterThanOrEqualTo(stat.minUs));
      expect(stat.p50Us, lessThanOrEqualTo(stat.maxUs));
    });

    test('p95 >= p50', () {
      for (var i = 0; i < 100; i++) {
        Tracer.begin('pct2').end();
      }

      final stat = computeSpanStats().single;
      expect(stat.p95Us, greaterThanOrEqualTo(stat.p50Us));
    });

    test('percentileUs(0) returns min, percentileUs(100) returns max', () {
      for (var i = 0; i < 50; i++) {
        Tracer.begin('bounds').end();
      }

      final stat = computeSpanStats().single;
      expect(stat.percentileUs(0), stat.minUs);
      expect(stat.percentileUs(100), stat.maxUs);
    });

    test('returns 0 for empty durationsUs', () {
      // Construct directly to test edge case.
      const empty = SpanStat(
        name: 'empty',
        totalUs: 0,
        callCount: 0,
        percent: 0,
        durationsUs: [],
      );
      expect(empty.percentileUs(50), 0);
      expect(empty.minUs, 0);
      expect(empty.maxUs, 0);
    });
  });

  group('SpanStat.histogram', () {
    test('returns list of specified bucket count', () {
      Tracer.begin('h').end();
      Tracer.begin('h').end();

      final stat = computeSpanStats().single;
      expect(stat.histogram(buckets: 10), hasLength(10));
      expect(stat.histogram(buckets: 20), hasLength(20));
    });

    test('all values are between 0.0 and 1.0', () {
      for (var i = 0; i < 50; i++) {
        Tracer.begin('hist').end();
      }

      final stat = computeSpanStats().single;
      for (final v in stat.histogram()) {
        expect(v, inInclusiveRange(0.0, 1.0));
      }
    });

    test('at least one bucket is 1.0 (the peak)', () {
      for (var i = 0; i < 50; i++) {
        Tracer.begin('peak').end();
      }

      final stat = computeSpanStats().single;
      final hist = stat.histogram();
      expect(hist.any((v) => v == 1.0), isTrue);
    });

    test('empty durationsUs returns all zeros', () {
      const empty = SpanStat(
        name: 'empty',
        totalUs: 0,
        callCount: 0,
        percent: 0,
        durationsUs: [],
      );
      expect(empty.histogram(), everyElement(0.0));
    });
  });

  group('computeSpanStatsFromEvents', () {
    test('produces same results as computeSpanStats', () {
      Tracer.begin('a').end();
      Tracer.begin('b').end();
      Tracer.begin('a').end();

      final fromBuffer = computeSpanStats();
      final fromEvents = computeSpanStatsFromEvents(Tracer.snapshot());

      expect(fromEvents.length, fromBuffer.length);
      for (var i = 0; i < fromBuffer.length; i++) {
        expect(fromEvents[i].name, fromBuffer[i].name);
        expect(fromEvents[i].totalUs, fromBuffer[i].totalUs);
        expect(fromEvents[i].callCount, fromBuffer[i].callCount);
      }
    });

    test('returns empty list for empty input', () {
      expect(computeSpanStatsFromEvents([]), isEmpty);
    });
  });
}
