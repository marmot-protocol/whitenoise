import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:whitenoise/providers/app_log_provider.dart' show appLogStore;
import 'package:whitenoise/src/rust/api/logs.dart' as logs_api;
import 'package:whitenoise/utils/app_flavor.dart';

final _logger = Logger('rustLogListener');

/// Subscribes to Rust log file and forwards each line to appLogStore.
/// Only active in staging builds.
final rustLogListenerProvider = Provider.autoDispose<void>((ref) {
  if (!isStaging) return;

  StreamSubscription<String>? subscription;
  var disposed = false;

  ref.onDispose(() {
    disposed = true;
    subscription?.cancel();
  });

  unawaited(
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
        Level.INFO,
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
