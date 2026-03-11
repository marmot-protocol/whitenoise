// No-op stubs compiled into production builds.
// All methods are inlined empty bodies — the compiler eliminates them entirely.

// Mirror of the real SpanEvent so injectSpan compiles against the stub.
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
  final int tid;
}

class Span {
  const Span._();

  void end() {}
}

abstract final class Tracer {
  static Span begin(String name) => const Span._();

  static T trace<T>(String name, T Function() fn) => fn();

  static Future<T> traceAsync<T>(String name, Future<T> Function() fn) => fn();

  // ignore: avoid_unused_parameters
  static void injectSpan(SpanEvent event) {}

  static void reset() {}

  static List<Map<String, dynamic>> exportEvents() => const [];
}
