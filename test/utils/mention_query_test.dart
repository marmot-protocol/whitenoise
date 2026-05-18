import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/utils/mention_query.dart';

TextEditingValue _value(String text, int caret) {
  return TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: caret),
  );
}

void main() {
  group('activeMentionQuery', () {
    test('returns null when text is empty', () {
      expect(activeMentionQuery(_value('', 0)), isNull);
    });

    test('returns null when there is no @ before the caret', () {
      expect(activeMentionQuery(_value('hello world', 11)), isNull);
    });

    test('returns null when the @ is preceded by a non-boundary char', () {
      expect(activeMentionQuery(_value('email@example.com', 17)), isNull);
    });

    test('detects @ at the start of the text with empty query', () {
      final result = activeMentionQuery(_value('@', 1))!;
      expect(result.start, 0);
      expect(result.end, 1);
      expect(result.query, '');
    });

    test('captures the typed query after @', () {
      final result = activeMentionQuery(_value('hi @ali', 7))!;
      expect(result.start, 3);
      expect(result.end, 7);
      expect(result.query, 'ali');
    });

    test('closes when a space is typed after the query', () {
      expect(activeMentionQuery(_value('hi @ali ', 8)), isNull);
    });

    test('returns null when selection is not collapsed', () {
      const v = TextEditingValue(
        text: 'hi @ali',
        selection: TextSelection(baseOffset: 3, extentOffset: 7),
      );
      expect(activeMentionQuery(v), isNull);
    });
  });
}
