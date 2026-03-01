import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/providers/message_debug_log_provider.dart';

void main() {
  late ProviderContainer container;
  late MessageDebugLogNotifier notifier;

  setUp(() {
    container = ProviderContainer();
    notifier = container.read(messageDebugLogProvider.notifier);
  });

  tearDown(() {
    container.dispose();
  });

  group('MessageDebugLogNotifier send log', () {
    test('starts with empty logs', () {
      final state = container.read(messageDebugLogProvider);
      expect(state.sendLog, isEmpty);
      expect(state.streamLog, isEmpty);
    });

    test('logStarted adds entry with payload details', () {
      notifier.logStarted(groupId: 'g1', contentLen: 42, mediaCount: 2, replyToId: 'r1');

      final entry = container.read(messageDebugLogProvider).sendLog.single;
      expect(entry.groupId, 'g1');
      expect(entry.status, MessageSendStatus.started);
      expect(entry.contentLen, 42);
      expect(entry.mediaCount, 2);
      expect(entry.replyToId, 'r1');
      expect(entry.resultId, isNull);
    });

    test('logOk adds ok entry with result id', () {
      notifier.logOk(groupId: 'g2', resultId: 'msg_123');

      final entry = container.read(messageDebugLogProvider).sendLog.single;
      expect(entry.groupId, 'g2');
      expect(entry.status, MessageSendStatus.ok);
      expect(entry.resultId, 'msg_123');
    });

    test('logFailed adds failed entry with error and stack', () {
      final stack = StackTrace.fromString('trace line');
      notifier.logFailed(groupId: 'g3', error: 'boom', stackTrace: stack);

      final entry = container.read(messageDebugLogProvider).sendLog.single;
      expect(entry.groupId, 'g3');
      expect(entry.status, MessageSendStatus.failed);
      expect(entry.error, 'boom');
      expect(entry.stackTrace, stack);
    });

    test('newest send entries are first', () {
      notifier.logStarted(groupId: 'g', contentLen: 1);
      notifier.logOk(groupId: 'g', resultId: 'id_1');
      notifier.logFailed(groupId: 'g', error: 'err');

      final statuses = container
          .read(messageDebugLogProvider)
          .sendLog
          .map((e) => e.status)
          .toList();
      expect(statuses, [MessageSendStatus.failed, MessageSendStatus.ok, MessageSendStatus.started]);
    });

    test('send log is capped at 100 entries', () {
      for (var i = 0; i < 110; i++) {
        notifier.logOk(groupId: 'g', resultId: 'id_$i');
      }

      final sendLog = container.read(messageDebugLogProvider).sendLog;
      expect(sendLog, hasLength(100));
      expect(sendLog.first.resultId, 'id_109');
      expect(sendLog.last.resultId, 'id_10');
    });
  });

  group('MessageDebugLogNotifier stream log', () {
    test('logStreamConnected records connected event', () {
      notifier.logStreamConnected(groupId: 'g1');
      final entry = container.read(messageDebugLogProvider).streamLog.single;

      expect(entry.groupId, 'g1');
      expect(entry.eventType, MessageStreamEventType.connected);
    });

    test('logStreamSnapshot stores count', () {
      notifier.logStreamSnapshot(groupId: 'g2', messageCount: 12);
      final entry = container.read(messageDebugLogProvider).streamLog.single;

      expect(entry.eventType, MessageStreamEventType.snapshot);
      expect(entry.messageCount, 12);
    });

    test('logStreamUpdate stores trigger and message id', () {
      notifier.logStreamUpdate(groupId: 'g3', trigger: 'newMessage', messageId: 'm_1');
      final entry = container.read(messageDebugLogProvider).streamLog.single;

      expect(entry.eventType, MessageStreamEventType.update);
      expect(entry.trigger, 'newMessage');
      expect(entry.messageId, 'm_1');
    });

    test('logStreamLagged stores lagged count', () {
      notifier.logStreamLagged(groupId: 'g4', laggedCount: 5);
      final entry = container.read(messageDebugLogProvider).streamLog.single;

      expect(entry.eventType, MessageStreamEventType.lagged);
      expect(entry.laggedCount, 5);
    });

    test('logStreamError stores error and stack trace', () {
      final stack = StackTrace.fromString('stream stack');
      notifier.logStreamError(groupId: 'g5', error: 'stream failed', stackTrace: stack);
      final entry = container.read(messageDebugLogProvider).streamLog.single;

      expect(entry.eventType, MessageStreamEventType.streamError);
      expect(entry.error, 'stream failed');
      expect(entry.stackTrace, stack);
    });

    test('logStreamDisconnected records disconnected event', () {
      notifier.logStreamDisconnected(groupId: 'g6');
      final entry = container.read(messageDebugLogProvider).streamLog.single;

      expect(entry.eventType, MessageStreamEventType.disconnected);
    });

    test('newest stream entries are first', () {
      notifier.logStreamConnected(groupId: 'g');
      notifier.logStreamSnapshot(groupId: 'g', messageCount: 1);
      notifier.logStreamDisconnected(groupId: 'g');

      final types = container
          .read(messageDebugLogProvider)
          .streamLog
          .map((e) => e.eventType)
          .toList();
      expect(
        types,
        [
          MessageStreamEventType.disconnected,
          MessageStreamEventType.snapshot,
          MessageStreamEventType.connected,
        ],
      );
    });

    test('stream log is capped at 100 entries', () {
      for (var i = 0; i < 110; i++) {
        notifier.logStreamUpdate(groupId: 'g', trigger: 't', messageId: 'm$i');
      }

      final streamLog = container.read(messageDebugLogProvider).streamLog;
      expect(streamLog, hasLength(100));
      expect(streamLog.first.messageId, 'm109');
      expect(streamLog.last.messageId, 'm10');
    });
  });
}
