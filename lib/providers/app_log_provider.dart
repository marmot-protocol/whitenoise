import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

const _maxEntries = 1000;

class AppLogEntry {
  const AppLogEntry({
    required this.timestamp,
    required this.level,
    required this.loggerName,
    required this.message,
    this.error,
    this.stackTrace,
  });

  final DateTime timestamp;
  final Level level;
  final String loggerName;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;
}

/// Global sink that main.dart can call before a ProviderContainer exists.
/// Once the Riverpod tree is up, the provider also uses this instance.
class AppLogSink {
  final List<AppLogEntry> _entries = [];
  void Function()? _notify;
  Object? _notifyToken;

  List<AppLogEntry> get entries => List.unmodifiable(_entries);

  void add(LogRecord record) {
    _entries.insert(
      0,
      AppLogEntry(
        timestamp: record.time,
        level: record.level,
        loggerName: record.loggerName,
        message: record.message,
        error: record.error,
        stackTrace: record.stackTrace,
      ),
    );
    while (_entries.length > _maxEntries) {
      _entries.removeLast();
    }
    _notify?.call();
  }

  void clear() {
    _entries.clear();
    _notify?.call();
  }
}

final appLogStore = AppLogSink();

class AppLogNotifier extends Notifier<List<AppLogEntry>> {
  @override
  List<AppLogEntry> build() {
    final cleanupToken = Object();

    void notify() {
      Future(() {
        if (ref.mounted) {
          state = List.unmodifiable(appLogStore._entries);
        }
      });
    }

    appLogStore._notify = notify;
    appLogStore._notifyToken = cleanupToken;
    ref.onDispose(() {
      if (identical(appLogStore._notifyToken, cleanupToken)) {
        appLogStore._notify = null;
        appLogStore._notifyToken = null;
      }
    });

    return List.unmodifiable(appLogStore._entries);
  }

  void clear() => appLogStore.clear();
}

final appLogProvider = NotifierProvider<AppLogNotifier, List<AppLogEntry>>(
  AppLogNotifier.new,
);
