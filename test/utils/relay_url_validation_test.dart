import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/utils/relay_url_validation.dart';

void main() {
  group('validateRelayUrl', () {
    test('returns null for valid wss:// URL', () {
      expect(validateRelayUrl('wss://relay.example.com'), isNull);
    });

    test('returns null for valid ws:// URL', () {
      expect(validateRelayUrl('ws://local.relay.com'), isNull);
    });

    test('returns null for URL with path', () {
      expect(validateRelayUrl('wss://relay.example.com/path'), isNull);
    });

    test('returns null for URL with whitespace', () {
      expect(validateRelayUrl('  wss://relay.example.com  '), isNull);
    });

    test('returns error for https:// URL', () {
      expect(validateRelayUrl('https://relay.example.com'), RelayValidationError.invalidScheme);
    });

    test('returns error for plain domain', () {
      expect(validateRelayUrl('relay.example.com'), RelayValidationError.invalidScheme);
    });

    test('returns error for double wss:// URL', () {
      expect(validateRelayUrl('wss://wss://relay.example.com'), RelayValidationError.invalidUrl);
    });

    test('returns error for single-part host', () {
      expect(validateRelayUrl('wss://localhost'), RelayValidationError.invalidUrl);
    });

    test('returns error for empty host', () {
      expect(validateRelayUrl('wss://'), RelayValidationError.invalidUrl);
    });

    test('returns error for host with empty part', () {
      expect(validateRelayUrl('wss://.example.com'), RelayValidationError.invalidUrl);
    });
  });

  group('isRelayUrlEmpty', () {
    test('returns true for empty string', () {
      expect(isRelayUrlEmpty(''), isTrue);
    });

    test('returns true for whitespace', () {
      expect(isRelayUrlEmpty('   '), isTrue);
    });

    test('returns true for bare wss://', () {
      expect(isRelayUrlEmpty('wss://'), isTrue);
    });

    test('returns true for bare ws://', () {
      expect(isRelayUrlEmpty('ws://'), isTrue);
    });

    test('returns true for wss:// with whitespace', () {
      expect(isRelayUrlEmpty('  wss://  '), isTrue);
    });

    test('returns false for wss:// with content', () {
      expect(isRelayUrlEmpty('wss://relay.example.com'), isFalse);
    });
  });
}
