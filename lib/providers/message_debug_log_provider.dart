import 'package:flutter_riverpod/flutter_riverpod.dart';

const _maxEntries = 100;

enum MessageSendStatus { started, ok, failed }

enum MessageStreamEventType {
  connected,
  snapshot,
  update,
  lagged,
  streamError,
  disconnected,
}

class MessageSendLogEntry {
  const MessageSendLogEntry({
    required this.timestamp,
    required this.groupId,
    required this.status,
    this.contentLen,
    this.mediaCount,
    this.replyToId,
    this.resultId,
    this.error,
    this.stackTrace,
  });

  final DateTime timestamp;
  final String groupId;
  final MessageSendStatus status;
  final int? contentLen;
  final int? mediaCount;
  final String? replyToId;
  final String? resultId;
  final Object? error;
  final StackTrace? stackTrace;
}

class MessageStreamEventEntry {
  const MessageStreamEventEntry({
    required this.timestamp,
    required this.groupId,
    required this.eventType,
    this.messageCount,
    this.trigger,
    this.messageId,
    this.error,
    this.stackTrace,
    this.laggedCount,
  });

  final DateTime timestamp;
  final String groupId;
  final MessageStreamEventType eventType;

  /// For snapshot: number of messages in initial snapshot
  final int? messageCount;

  /// For update: trigger name (newMessage, reactionAdded, etc.)
  final String? trigger;

  /// For update: the message ID affected
  final String? messageId;

  /// For streamError: the error
  final Object? error;
  final StackTrace? stackTrace;

  /// For lagged: how many messages were skipped
  final int? laggedCount;
}

class MessageDebugLogState {
  const MessageDebugLogState({
    required this.sendLog,
    required this.streamLog,
  });

  final List<MessageSendLogEntry> sendLog;
  final List<MessageStreamEventEntry> streamLog;
}

class MessageDebugLogNotifier extends Notifier<MessageDebugLogState> {
  @override
  MessageDebugLogState build() => const MessageDebugLogState(sendLog: [], streamLog: []);

  // ── Send log ──────────────────────────────────────────────────────────────

  void logStarted({
    required String groupId,
    required int contentLen,
    int mediaCount = 0,
    String? replyToId,
  }) {
    state = MessageDebugLogState(
      sendLog: [
        MessageSendLogEntry(
          timestamp: DateTime.now(),
          groupId: groupId,
          status: MessageSendStatus.started,
          contentLen: contentLen,
          mediaCount: mediaCount,
          replyToId: replyToId,
        ),
        ...state.sendLog,
      ].take(_maxEntries).toList(),
      streamLog: state.streamLog,
    );
  }

  void logOk({required String groupId, required String resultId}) {
    state = MessageDebugLogState(
      sendLog: [
        MessageSendLogEntry(
          timestamp: DateTime.now(),
          groupId: groupId,
          status: MessageSendStatus.ok,
          resultId: resultId,
        ),
        ...state.sendLog,
      ].take(_maxEntries).toList(),
      streamLog: state.streamLog,
    );
  }

  void logFailed({
    required String groupId,
    required Object error,
    StackTrace? stackTrace,
  }) {
    state = MessageDebugLogState(
      sendLog: [
        MessageSendLogEntry(
          timestamp: DateTime.now(),
          groupId: groupId,
          status: MessageSendStatus.failed,
          error: error,
          stackTrace: stackTrace,
        ),
        ...state.sendLog,
      ].take(_maxEntries).toList(),
      streamLog: state.streamLog,
    );
  }

  // ── Stream event log ─────────────────────────────────────────────────────

  void _addStreamEvent(MessageStreamEventEntry entry) {
    state = MessageDebugLogState(
      sendLog: state.sendLog,
      streamLog: [entry, ...state.streamLog].take(_maxEntries).toList(),
    );
  }

  void logStreamConnected({required String groupId}) {
    _addStreamEvent(
      MessageStreamEventEntry(
        timestamp: DateTime.now(),
        groupId: groupId,
        eventType: MessageStreamEventType.connected,
      ),
    );
  }

  void logStreamSnapshot({required String groupId, required int messageCount}) {
    _addStreamEvent(
      MessageStreamEventEntry(
        timestamp: DateTime.now(),
        groupId: groupId,
        eventType: MessageStreamEventType.snapshot,
        messageCount: messageCount,
      ),
    );
  }

  void logStreamUpdate({
    required String groupId,
    required String trigger,
    required String messageId,
  }) {
    _addStreamEvent(
      MessageStreamEventEntry(
        timestamp: DateTime.now(),
        groupId: groupId,
        eventType: MessageStreamEventType.update,
        trigger: trigger,
        messageId: messageId,
      ),
    );
  }

  void logStreamLagged({required String groupId, required int laggedCount}) {
    _addStreamEvent(
      MessageStreamEventEntry(
        timestamp: DateTime.now(),
        groupId: groupId,
        eventType: MessageStreamEventType.lagged,
        laggedCount: laggedCount,
      ),
    );
  }

  void logStreamError({
    required String groupId,
    required Object error,
    StackTrace? stackTrace,
  }) {
    _addStreamEvent(
      MessageStreamEventEntry(
        timestamp: DateTime.now(),
        groupId: groupId,
        eventType: MessageStreamEventType.streamError,
        error: error,
        stackTrace: stackTrace,
      ),
    );
  }

  void logStreamDisconnected({required String groupId}) {
    _addStreamEvent(
      MessageStreamEventEntry(
        timestamp: DateTime.now(),
        groupId: groupId,
        eventType: MessageStreamEventType.disconnected,
      ),
    );
  }
}

final messageDebugLogProvider = NotifierProvider<MessageDebugLogNotifier, MessageDebugLogState>(
  MessageDebugLogNotifier.new,
);
