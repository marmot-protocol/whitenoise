import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/providers/app_log_provider.dart';
import 'package:whitenoise/providers/rust_log_listener_provider.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/utils/app_flavor.dart';

import '../mocks/mock_wn_api.dart';

class _MockApi extends MockWnApi {
  StreamController<String>? logsController;
  String? lastLogsBaseDir;

  @override
  Stream<String> crateApiLogsSubscribeToRustLogs({required String logsBaseDir}) {
    lastLogsBaseDir = logsBaseDir;
    logsController?.close();
    logsController = StreamController<String>.broadcast();
    return logsController!.stream;
  }

  @override
  void reset() {
    super.reset();
    logsController?.close();
    logsController = null;
    lastLogsBaseDir = null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  final api = _MockApi();

  setUpAll(() async {
    RustLib.initMock(api: api);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      pathProviderChannel,
      (call) async => '/tmp/wn_test_docs',
    );
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      pathProviderChannel,
      null,
    );
  });

  setUp(() {
    api.reset();
    appLogStore.clear();
  });

  group('parseRustLogLevel', () {
    test('parses TRACE level', () {
      final line = '2026-02-28T09:30:15.123456Z TRACE whitenoise::module: trace message';
      expect(parseRustLogLevel(line), Level.FINEST);
    });

    test('parses DEBUG level', () {
      final line = '2026-02-28T09:30:15.123456Z DEBUG whitenoise::module: debug message';
      expect(parseRustLogLevel(line), Level.FINE);
    });

    test('parses INFO level', () {
      final line = '2026-02-28T09:30:15.123456Z  INFO whitenoise::module: info message';
      expect(parseRustLogLevel(line), Level.INFO);
    });

    test('parses WARN level', () {
      final line = '2026-02-28T09:30:15.234567Z  WARN nostr_manager::connection: relay lost';
      expect(parseRustLogLevel(line), Level.WARNING);
    });

    test('parses ERROR level', () {
      final line = '2026-02-28T09:30:15.345678Z ERROR whitenoise::accounts: login failed';
      expect(parseRustLogLevel(line), Level.SEVERE);
    });

    test('falls back to INFO for unstructured lines', () {
      expect(parseRustLogLevel('some random log line'), Level.INFO);
    });

    test('falls back to INFO for empty string', () {
      expect(parseRustLogLevel(''), Level.INFO);
    });

    test('falls back to INFO for status messages without level prefix', () {
      final line = 'subscribe_to_rust_logs: waiting for log file path="/data/logs" err=NotFound';
      expect(parseRustLogLevel(line), Level.INFO);
    });
  });

  group('rustLogListenerProvider', () {
    if (!isStaging) {
      test('requires staging flavor', () {}, skip: 'Set --dart-define=APP_FLAVOR=staging');
      return;
    }

    test('subscribes using application logs directory', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final sub = container.listen(rustLogListenerProvider, (_, _) {}, fireImmediately: true);
      addTearDown(sub.close);

      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(api.lastLogsBaseDir, '/tmp/wn_test_docs/whitenoise/logs');
      expect(api.logsController?.hasListener, isTrue);
    });

    test('forwards rust log lines into app log store', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final sub = container.listen(rustLogListenerProvider, (_, _) {}, fireImmediately: true);
      addTearDown(sub.close);

      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      api.logsController?.add('2026-03-01T12:00:00.000000Z WARN rust::network: connection lost');
      await Future<void>.delayed(Duration.zero);

      expect(appLogStore.entries, hasLength(1));
      final entry = appLogStore.entries.single;
      expect(entry.loggerName, 'rust');
      expect(entry.level, Level.WARNING);
      expect(entry.message, contains('connection lost'));
    });

    test('forwards stream errors into app log store', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final sub = container.listen(rustLogListenerProvider, (_, _) {}, fireImmediately: true);
      addTearDown(sub.close);

      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      api.logsController?.addError(Exception('boom'));
      await Future<void>.delayed(Duration.zero);

      expect(appLogStore.entries, hasLength(1));
      final entry = appLogStore.entries.single;
      expect(entry.level, Level.SEVERE);
      expect(entry.loggerName, 'rust');
      expect(entry.message, contains('rust log stream error'));
      expect(entry.message, contains('boom'));
    });

    test('cancels subscription when disposed before listening starts', () async {
      final container = ProviderContainer();
      final sub = container.listen(rustLogListenerProvider, (_, _) {}, fireImmediately: true);
      sub.close();
      container.dispose();

      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      if (api.logsController != null) {
        expect(api.logsController?.hasListener, isFalse);
      }
    });

    test('handles _startListening failure gracefully', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        pathProviderChannel,
        (call) async => throw PlatformException(code: 'ERROR', message: 'No directory'),
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);
      final sub = container.listen(rustLogListenerProvider, (_, _) {}, fireImmediately: true);
      addTearDown(sub.close);

      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(api.logsController, isNull);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        pathProviderChannel,
        (call) async => '/tmp/wn_test_docs',
      );
    });

    test('handles stream done event', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final sub = container.listen(rustLogListenerProvider, (_, _) {}, fireImmediately: true);
      addTearDown(sub.close);

      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(api.logsController, isNotNull);
      await api.logsController!.close();
      await Future<void>.delayed(Duration.zero);
    });

    test('cancels subscription when provider is disposed', () async {
      final container = ProviderContainer();
      final sub = container.listen(rustLogListenerProvider, (_, _) {}, fireImmediately: true);
      addTearDown(sub.close);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(api.logsController?.hasListener, isTrue);
      container.dispose();
      await Future<void>.delayed(Duration.zero);

      expect(api.logsController?.hasListener, isFalse);
    });
  });
}
