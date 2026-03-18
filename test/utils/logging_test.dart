import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/utils/logging.dart';

void main() {
  late Logger logger;
  late StreamSubscription<LogRecord> subscription;
  late List<LogRecord> records;
  late Level? previousRootLevel;

  setUp(() {
    previousRootLevel = Logger.root.level;
    Logger.root.level = Level.ALL;

    logger = Logger('logDuration_test');
    records = [];
    subscription = logger.onRecord.listen(records.add);
  });

  tearDown(() async {
    await subscription.cancel();
    Logger.root.level = previousRootLevel ?? Level.INFO;
  });

  group('logDuration', () {
    test('logs warning for durations >= 50ms', () {
      logDuration(logger, 'op', 50);

      expect(
        records.single,
        isA<LogRecord>()
            .having(
              (r) => r.level,
              'level',
              Level.WARNING,
            )
            .having(
              (r) => r.message,
              'message',
              'op 50ms',
            ),
      );
    });

    test('logs info for durations < 50ms', () {
      logDuration(logger, 'op', 49);

      expect(
        records.single,
        isA<LogRecord>()
            .having(
              (r) => r.level,
              'level',
              Level.INFO,
            )
            .having(
              (r) => r.message,
              'message',
              'op 49ms',
            ),
      );
    });
  });
}
