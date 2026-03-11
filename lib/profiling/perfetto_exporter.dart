import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:whitenoise/profiling/tracer.dart';

/// Exports the current tracer ring buffer to a Perfetto-compatible JSON file
/// and returns the [File] path for sharing.
///
/// The output format is the Chrome Trace Event Format (a subset of Perfetto
/// JSON). Drop the file at https://ui.perfetto.dev (runs fully in-browser,
/// no data is uploaded).
Future<File> exportPerfettoTrace() async {
  final events = Tracer.exportEvents();
  final payload = jsonEncode({'traceEvents': events});

  final dir = await getTemporaryDirectory();
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final file = File('${dir.path}/whitenoise-trace-$timestamp.json');
  await file.writeAsString(payload);
  return file;
}

/// Returns a human-readable summary of the current buffer state.
String tracerStatus() {
  final count = Tracer.spanCount;
  final pct = (count / 10000 * 100).round();
  return '$count spans recorded · buffer $pct% full';
}
