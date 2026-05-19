import 'package:flutter/widgets.dart';

class ActiveMentionQuery {
  const ActiveMentionQuery({
    required this.start,
    required this.end,
    required this.query,
  });

  final int start;
  final int end;
  final String query;
}

ActiveMentionQuery? activeMentionQuery(TextEditingValue value) {
  final selection = value.selection;
  final caret = selection.baseOffset;
  if (!selection.isCollapsed || caret < 0 || caret > value.text.length) {
    return null;
  }

  var start = caret;
  while (start > 0 && !_isMentionBoundary(value.text.codeUnitAt(start - 1))) {
    start--;
  }

  if (start >= caret || value.text[start] != '@') return null;
  return ActiveMentionQuery(
    start: start,
    end: caret,
    query: value.text.substring(start + 1, caret),
  );
}

bool _isMentionBoundary(int codeUnit) =>
    codeUnit == 0x20 || codeUnit == 0x09 || codeUnit == 0x0A || codeUnit == 0x0D;
