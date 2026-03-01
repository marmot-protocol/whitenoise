import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/providers/app_log_provider.dart';

LogRecord _record(
  String message, {
  Level level = Level.INFO,
  String logger = 'test',
  Object? error,
  StackTrace? stackTrace,
  DateTime? time,
}) {
  return LogRecord(level, message, logger, error, stackTrace, Zone.current, time ?? DateTime.now());
}

void main() {
  group('AppLogSink', () {
    setUp(() {
      appLogStore.clear();
    });

    test('add inserts newest entries first', () {
      appLogStore.add(_record('first'));
      appLogStore.add(_record('second'));

      final entries = appLogStore.entries;
      expect(entries, hasLength(2));
      expect(entries.first.message, 'second');
      expect(entries.last.message, 'first');
    });

    test('add keeps maximum of 1000 entries', () {
      for (var i = 0; i < 1005; i++) {
        appLogStore.add(_record('msg_$i'));
      }

      final entries = appLogStore.entries;
      expect(entries, hasLength(1000));
      expect(entries.first.message, 'msg_1004');
      expect(entries.last.message, 'msg_5');
    });

    test('add maps error and stackTrace', () {
      final stack = StackTrace.fromString('line_a\nline_b');
      appLogStore.add(_record('boom', error: 'err', stackTrace: stack));

      final entry = appLogStore.entries.single;
      expect(entry.message, 'boom');
      expect(entry.error, 'err');
      expect(entry.stackTrace, stack);
    });

    test('clear removes all entries', () {
      appLogStore.add(_record('one'));
      appLogStore.add(_record('two'));
      expect(appLogStore.entries, hasLength(2));

      appLogStore.clear();
      expect(appLogStore.entries, isEmpty);
    });
  });
}
