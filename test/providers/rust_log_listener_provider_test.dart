import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/providers/rust_log_listener_provider.dart';

void main() {
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
}
