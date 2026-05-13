import 'package:flutter_test/flutter_test.dart';
import 'package:rust_lib_whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/utils/metadata.dart';

void main() {
  group('presentName', () {
    test('returns null when metadata is null', () {
      expect(presentName(null), isNull);
    });

    test('returns displayName when non-empty', () {
      const metadata = FlutterMetadata(
        displayName: 'Alice',
        name: 'alice123',
        custom: {},
      );
      expect(presentName(metadata), equals('Alice'));
    });

    test('returns name when displayName is null', () {
      const metadata = FlutterMetadata(
        name: 'alice123',
        custom: {},
      );
      expect(presentName(metadata), equals('alice123'));
    });

    test('returns name when displayName is empty', () {
      const metadata = FlutterMetadata(
        displayName: '',
        name: 'alice123',
        custom: {},
      );
      expect(presentName(metadata), equals('alice123'));
    });

    test('returns null when both displayName and name are null', () {
      const metadata = FlutterMetadata(custom: {});
      expect(presentName(metadata), isNull);
    });

    test('returns null when both displayName and name are empty', () {
      const metadata = FlutterMetadata(
        displayName: '',
        name: '',
        custom: {},
      );
      expect(presentName(metadata), isNull);
    });

    test('sanitizes malformed UTF-16 in displayName', () {
      final metadata = FlutterMetadata(
        displayName: 'hello${String.fromCharCode(0xD800)}world',
        custom: const {},
      );
      expect(presentName(metadata), equals('hello\u{FFFD}world'));
    });

    test('sanitizes malformed UTF-16 in name fallback', () {
      final metadata = FlutterMetadata(
        name: 'test${String.fromCharCode(0xDC00)}name',
        custom: const {},
      );
      expect(presentName(metadata), equals('test\u{FFFD}name'));
    });
  });

  group('sanitizeForDisplay', () {
    test('returns normal string unchanged', () {
      expect(sanitizeForDisplay('hello world'), equals('hello world'));
    });

    test('preserves valid emoji', () {
      expect(sanitizeForDisplay('hello 🎉'), equals('hello 🎉'));
    });

    test('preserves valid surrogate pairs', () {
      const smiley = '😀';
      expect(sanitizeForDisplay(smiley), equals(smiley));
    });

    test('replaces lone high surrogate with replacement character', () {
      final input = 'a${String.fromCharCode(0xD800)}b';
      expect(sanitizeForDisplay(input), equals('a\u{FFFD}b'));
    });

    test('replaces lone low surrogate with replacement character', () {
      final input = 'a${String.fromCharCode(0xDC00)}b';
      expect(sanitizeForDisplay(input), equals('a\u{FFFD}b'));
    });

    test('replaces high surrogate at end of string', () {
      final input = 'hello${String.fromCharCode(0xDBFF)}';
      expect(sanitizeForDisplay(input), equals('hello\u{FFFD}'));
    });

    test('replaces consecutive lone surrogates', () {
      final input = '${String.fromCharCode(0xD800)}${String.fromCharCode(0xD801)}';
      expect(sanitizeForDisplay(input), equals('\u{FFFD}\u{FFFD}'));
    });

    test('handles empty string', () {
      expect(sanitizeForDisplay(''), equals(''));
    });

    test('handles string with only surrogates', () {
      final input = String.fromCharCode(0xD800);
      expect(sanitizeForDisplay(input), equals('\u{FFFD}'));
    });

    test('preserves Thai characters', () {
      expect(sanitizeForDisplay('ภ๏รtг๏ภคยt'), equals('ภ๏รtг๏ภคยt'));
    });

    test('preserves mixed scripts with emoji', () {
      const input = '▪️🔸️▪️';
      expect(sanitizeForDisplay(input), equals(input));
    });

    test('preserves complex Unicode names', () {
      const input = 'ρꪊꪀᛕ ꪀꪮᦓꪻ᥅ꪮꪀꪖꪊꪻ';
      expect(sanitizeForDisplay(input), equals(input));
    });
  });
}
