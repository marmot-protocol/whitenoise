import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:whitenoise/providers/app_log_provider.dart' show appLogStore;
import 'package:whitenoise/src/rust/api/logs.dart' as logs_api;
import 'package:whitenoise/utils/app_flavor.dart';

final _logger = Logger('rustLogListener');

final _levelPattern = RegExp(r'\d{4}-\d{2}-\d{2}T[\d:.]+Z\s+(TRACE|DEBUG|INFO|WARN|ERROR)\s');

const _levelMap = {
  'TRACE': Level.FINEST,
  'DEBUG': Level.FINE,
  'INFO': Level.INFO,
  'WARN': Level.WARNING,
  'ERROR': Level.SEVERE,
};

@visibleForTesting
Level parseRustLogLevel(String line) {
  final match = _levelPattern.firstMatch(line);
  if (match == null) return Level.INFO;
  return _levelMap[match.group(1)] ?? Level.INFO;
}

/// Subscribes to Rust log file and forwards each line to appLogStore.
/// Only active in staging builds.
final rustLogListenerProvider = Provider.autoDispose<void>((ref) {
  if (!isStaging) return;

  StreamSubscription<String>? subscription;
  final disposed = Completer<void>();

  ref.onDispose(() {
    disposed.complete();
    subscription?.cancel();
  });

  unawaited(
    _startListening()
        .then((sub) {
          if (disposed.isCompleted) {
            sub.cancel();
          } else {
            subscription = sub;
          }
        })
        .catchError((Object e, StackTrace st) {
          _logger.severe('failed to start rust log listener', e, st);
        }),
  );
});

Future<StreamSubscription<String>> _startListening() async {
  final dir = await getApplicationDocumentsDirectory();
  final logsBaseDir = '${dir.path}/whitenoise/logs';

  final stream = logs_api.subscribeToRustLogs(logsBaseDir: logsBaseDir);

  return stream.listen(
    (line) {
      final record = LogRecord(
        parseRustLogLevel(line),
        line,
        'rust',
      );
      appLogStore.add(record);
    },
    onError: (e, st) {
      final record = LogRecord(
        Level.SEVERE,
        'rust log stream error: $e',
        'rust',
        e,
        st,
      );
      appLogStore.add(record);
    },
    onDone: () {},
    cancelOnError: false,
  );
}
