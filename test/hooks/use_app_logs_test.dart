import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/hooks/use_app_logs.dart';
import 'package:whitenoise/providers/app_log_provider.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';

import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

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

  group('useAppLogs', () {
    testWidgets('subscribes using application logs directory', (tester) async {
      await mountHook(tester, useAppLogs);
      await tester.pump();
      await tester.pump();

      expect(api.lastLogsBaseDir, '/tmp/wn_test_docs/whitenoise/logs');
      expect(api.logsController?.hasListener, isTrue);
    });

    testWidgets('forwards rust log lines into app log store', (tester) async {
      await mountHook(tester, useAppLogs);
      await tester.pump();
      await tester.pump();

      api.logsController?.add('2026-03-01T12:00:00.000000Z WARN rust::network: connection lost');
      await tester.pump();

      expect(appLogStore.entries, hasLength(1));
      final entry = appLogStore.entries.single;
      expect(entry.loggerName, 'rust');
      expect(entry.level, Level.WARNING);
      expect(entry.message, contains('connection lost'));
    });

    testWidgets('forwards stream errors into app log store', (tester) async {
      await mountHook(tester, useAppLogs);
      await tester.pump();
      await tester.pump();

      api.logsController?.addError(Exception('boom'));
      await tester.pump();

      expect(appLogStore.entries, hasLength(1));
      final entry = appLogStore.entries.single;
      expect(entry.level, Level.SEVERE);
      expect(entry.loggerName, 'rust');
      expect(entry.message, contains('rust log stream error'));
      expect(entry.message, contains('boom'));
    });

    testWidgets('cancels subscription when widget is unmounted before listening starts', (
      tester,
    ) async {
      await mountHook(tester, useAppLogs);
      await tester.pumpWidget(const SizedBox());

      await tester.pump();
      await tester.pump();
      await tester.pump();

      if (api.logsController != null) {
        expect(api.logsController?.hasListener, isFalse);
      }
    });

    testWidgets('handles _startListening failure gracefully', (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        pathProviderChannel,
        (call) async => throw PlatformException(code: 'ERROR', message: 'No directory'),
      );
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          pathProviderChannel,
          (call) async => '/tmp/wn_test_docs',
        );
      });

      await mountHook(tester, useAppLogs);
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(api.logsController, isNull);
    });

    testWidgets('handles stream done event', (tester) async {
      await mountHook(tester, useAppLogs);
      await tester.pump();
      await tester.pump();

      expect(api.logsController, isNotNull);
      await api.logsController!.close();
      await tester.pump();
    });

    testWidgets('cancels subscription when widget is unmounted', (tester) async {
      await mountHook(tester, useAppLogs);
      await tester.pump();
      await tester.pump();

      expect(api.logsController?.hasListener, isTrue);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();

      expect(api.logsController?.hasListener, isFalse);
    });
  });
}
