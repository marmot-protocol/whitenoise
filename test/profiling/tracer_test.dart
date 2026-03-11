import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/profiling/tracer.dart';

void main() {
  setUp(Tracer.reset);
  tearDown(Tracer.reset);

  group('Tracer.begin / Span.end', () {
    test('records a completed span in the ring buffer', () {
      final span = Tracer.begin('test.span');
      span.end();

      final events = Tracer.exportEvents();
      expect(events, hasLength(2));
      expect(events[0]['ph'], 'B');
      expect(events[0]['name'], 'test.span');
      expect(events[1]['ph'], 'E');
      expect(events[1]['name'], 'test.span');
    });

    test('end() is idempotent — calling twice records only one span', () {
      final span = Tracer.begin('idempotent');
      span.end();
      span.end();

      final events = Tracer.exportEvents();
      expect(events.where((e) => e['ph'] == 'B'), hasLength(1));
    });

    test('timestamps are monotonically non-decreasing', () {
      final span = Tracer.begin('timing');
      span.end();

      final events = Tracer.exportEvents();
      final startTs = events[0]['ts'] as int;
      final endTs = events[1]['ts'] as int;
      expect(endTs, greaterThanOrEqualTo(startTs));
    });
  });

  group('Tracer.trace', () {
    test('returns the value from the callback', () {
      final result = Tracer.trace('sync', () => 42);
      expect(result, 42);
    });

    test('records a span even when callback throws', () {
      expect(
        () => Tracer.trace<void>('throwing', () => throw Exception('boom')),
        throwsException,
      );
      // Span was still closed.
      expect(Tracer.spanCount, 1);
    });
  });

  group('Tracer.traceAsync', () {
    test('returns the future value', () async {
      final result = await Tracer.traceAsync('async', () async => 'hello');
      expect(result, 'hello');
    });

    test('records a span even when future throws', () async {
      await expectLater(
        () => Tracer.traceAsync<void>('async_throw', () async => throw Exception('boom')),
        throwsException,
      );
      expect(Tracer.spanCount, 1);
    });
  });

  group('Tracer.reset', () {
    test('clears all recorded spans', () {
      Tracer.begin('a').end();
      Tracer.begin('b').end();
      expect(Tracer.spanCount, 2);

      Tracer.reset();
      expect(Tracer.spanCount, 0);
      expect(Tracer.exportEvents(), isEmpty);
    });
  });

  group('spanCount', () {
    test('increments per completed span', () {
      expect(Tracer.spanCount, 0);
      Tracer.begin('x').end();
      expect(Tracer.spanCount, 1);
      Tracer.begin('y').end();
      expect(Tracer.spanCount, 2);
    });

    test('an unclosed span is not counted', () {
      Tracer.begin('open'); // not ended
      expect(Tracer.spanCount, 0);
    });
  });

  group('ring buffer eviction', () {
    test('buffer count does not exceed capacity', () {
      for (var i = 0; i < 10005; i++) {
        Tracer.begin('fill').end();
      }
      // Cap is 10000; count is clamped.
      expect(Tracer.spanCount, 10000);
    });

    test('exportEvents returns at most 10000 spans (20000 events)', () {
      for (var i = 0; i < 10005; i++) {
        Tracer.begin('fill').end();
      }
      final events = Tracer.exportEvents();
      expect(events.length, 20000); // 10000 spans × 2 events
    });
  });

  group('multiple span names', () {
    test('records spans with different names independently', () {
      Tracer.begin('alpha').end();
      Tracer.begin('beta').end();
      Tracer.begin('alpha').end();

      final events = Tracer.exportEvents();
      final alphaBegins = events.where((e) => e['ph'] == 'B' && e['name'] == 'alpha');
      final betaBegins = events.where((e) => e['ph'] == 'B' && e['name'] == 'beta');
      expect(alphaBegins, hasLength(2));
      expect(betaBegins, hasLength(1));
    });
  });

  group('Tracer.snapshot', () {
    test('returns empty list when no spans recorded', () {
      expect(Tracer.snapshot(), isEmpty);
    });

    test('returns SpanEvent objects with correct names', () {
      Tracer.begin('alpha').end();
      Tracer.begin('beta').end();
      Tracer.begin('alpha').end();

      final snap = Tracer.snapshot();
      expect(snap, hasLength(3));
      expect(snap.where((e) => e.name == 'alpha'), hasLength(2));
      expect(snap.where((e) => e.name == 'beta'), hasLength(1));
    });

    test('each SpanEvent has non-negative durationUs', () {
      Tracer.begin('dur').end();
      final snap = Tracer.snapshot();
      expect(snap.single.durationUs, greaterThanOrEqualTo(0));
    });

    test('snapshot count matches spanCount', () {
      for (var i = 0; i < 50; i++) {
        Tracer.begin('n$i').end();
      }
      expect(Tracer.snapshot().length, Tracer.spanCount);
    });

    test('snapshot is cleared by reset', () {
      Tracer.begin('x').end();
      expect(Tracer.snapshot(), isNotEmpty);
      Tracer.reset();
      expect(Tracer.snapshot(), isEmpty);
    });

    test('snapshot respects ring buffer eviction', () {
      for (var i = 0; i < 10005; i++) {
        Tracer.begin('fill').end();
      }
      expect(Tracer.snapshot().length, 10000);
    });
  });
}
