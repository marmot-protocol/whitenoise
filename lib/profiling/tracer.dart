import 'dart:developer' as developer;

// Ring buffer capacity — oldest entries are evicted when full.
const int _kCapacity = 10000;

/// A single completed timing span.
final class SpanEvent {
  const SpanEvent({
    required this.name,
    required this.startUs,
    required this.endUs,
    this.tid = 1,
  });

  final String name;
  final int startUs;
  final int endUs;

  /// Thread/lane ID for Perfetto visualisation. Rust spans use their span_id
  /// so concurrent async operations get separate lanes in the flamegraph.
  /// Dart spans default to tid 1.
  final int tid;

  int get durationUs => endUs - startUs;
}

/// An in-flight span. Call [end] to complete it.
final class Span {
  Span._(this._name, this._startUs);

  final String _name;
  final int _startUs;
  bool _ended = false;

  void end() {
    if (_ended) return;
    _ended = true;
    final endUs = _nowUs();
    developer.Timeline.finishSync();
    _RingBuffer._instance.add(
      SpanEvent(name: _name, startUs: _startUs, endUs: endUs),
    );
  }
}

/// Global tracer. All methods are zero-cost no-ops when [end] is not called,
/// but the ring buffer itself is always available for export.
abstract final class Tracer {
  /// Begin a named span. Call [Span.end] when the work is done.
  static Span begin(String name) {
    final startUs = _nowUs();
    developer.Timeline.startSync(name);
    return Span._(name, startUs);
  }

  /// Wrap synchronous work in a span.
  static T trace<T>(String name, T Function() fn) {
    final span = begin(name);
    try {
      return fn();
    } finally {
      span.end();
    }
  }

  /// Wrap async work in a span.
  static Future<T> traceAsync<T>(String name, Future<T> Function() fn) async {
    final span = begin(name);
    try {
      return await fn();
    } finally {
      span.end();
    }
  }

  /// Inject a pre-built span event directly into the ring buffer.
  /// Used to merge Rust spans (received via FFI flush) into the same timeline.
  static void injectSpan(SpanEvent event) => _RingBuffer._instance.add(event);

  /// Clear the ring buffer (used between recording sessions).
  static void reset() => _RingBuffer._instance.reset();

  /// Export all buffered span events as Perfetto/Chrome-trace event objects.
  /// Each span produces two events: a 'B' (begin) and 'E' (end) event.
  static List<Map<String, dynamic>> exportEvents() {
    return _RingBuffer._instance.exportEvents();
  }

  static int get spanCount => _RingBuffer._instance.count;

  /// Returns a snapshot of all buffered [SpanEvent]s in insertion order.
  /// This is the preferred API for computing stats — avoids the overhead of
  /// converting to Perfetto B/E map pairs.
  static List<SpanEvent> snapshot() => _RingBuffer._instance.snapshot();
}

// ---------------------------------------------------------------------------
// Internal ring buffer
// ---------------------------------------------------------------------------

final class _RingBuffer {
  _RingBuffer._();

  static final _RingBuffer _instance = _RingBuffer._();

  final _buf = List<SpanEvent?>.filled(_kCapacity, null);
  int _head = 0;
  int _count = 0;

  void add(SpanEvent event) {
    _buf[_head % _kCapacity] = event;
    _head++;
    if (_count < _kCapacity) _count++;
  }

  void reset() {
    _head = 0;
    _count = 0;
    _buf.fillRange(0, _kCapacity, null);
  }

  int get count => _count;

  /// Returns all buffered events in insertion order (oldest first).
  List<SpanEvent> snapshot() {
    final result = <SpanEvent>[];
    final start = _count < _kCapacity ? 0 : _head % _kCapacity;
    for (var i = 0; i < _count; i++) {
      final event = _buf[(start + i) % _kCapacity];
      if (event != null) result.add(event);
    }
    return result;
  }

  List<Map<String, dynamic>> exportEvents() {
    final events = <Map<String, dynamic>>[];
    final total = _count;
    final start = total < _kCapacity ? 0 : _head % _kCapacity;
    for (var i = 0; i < total; i++) {
      final event = _buf[(start + i) % _kCapacity];
      if (event == null) continue;
      events.add({
        'name': event.name,
        'ph': 'B',
        'ts': event.startUs,
        'pid': 1,
        'tid': event.tid,
      });
      events.add({
        'name': event.name,
        'ph': 'E',
        'ts': event.endUs,
        'pid': 1,
        'tid': event.tid,
      });
    }
    return events;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

int _nowUs() => DateTime.now().microsecondsSinceEpoch;
