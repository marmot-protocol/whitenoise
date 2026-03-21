import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:whitenoise/providers/app_log_provider.dart' show appLogStore;
import 'package:whitenoise/src/rust/api/logs.dart' as logs_api;

final _logger = Logger('appLogs');

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

void useAppLogs() {
  useEffect(() {
    StreamSubscription<String>? subscription;
    var disposed = false;

    _startListening()
        .then((sub) {
          if (disposed) {
            sub.cancel();
          } else {
            subscription = sub;
          }
        })
        .catchError((Object e, StackTrace st) {
          _logger.severe('failed to start rust log listener', e, st);
        });

    return () {
      disposed = true;
      subscription?.cancel();
    };
  }, const []);
}

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
