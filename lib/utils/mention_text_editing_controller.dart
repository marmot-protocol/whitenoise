import 'package:flutter/material.dart';

class MentionTextTarget {
  const MentionTextTarget({
    required this.uri,
    required this.displayText,
  });

  final String uri;
  final String displayText;
}

class MentionTextEditingController extends TextEditingController {
  MentionTextEditingController({super.text});

  final List<_TrackedMention> _mentions = [];
  List<MentionTextTarget> _targets = const [];
  var _targetsKey = '';
  var _isApplyingInternalChange = false;

  String get messageText => _expandMentions(text, _validMentions(text, _mentions));

  void insertMention({
    required int start,
    required int end,
    required String displayName,
    required String uri,
  }) {
    if (start < 0 || end < start || end > text.length) return;

    final displayText = _displayTextFor(displayName, uri);
    final replacement = '$displayText ';
    final updatedText = text.replaceRange(start, end, replacement);

    _isApplyingInternalChange = true;
    value = TextEditingValue(
      text: updatedText,
      selection: TextSelection.collapsed(offset: start + replacement.length),
    );
    _isApplyingInternalChange = false;

    _mentions
      ..removeWhere((mention) => _rangesOverlap(mention.start, mention.end, start, end))
      ..add(
        _TrackedMention(
          start: start,
          end: start + displayText.length,
          displayText: displayText,
          uri: uri,
        ),
      )
      ..sort((a, b) => a.start.compareTo(b.start));
    notifyListeners();
  }

  void setMentionTargets(List<MentionTextTarget> targets) {
    final nextKey = targets
        .map((target) => '${target.uri}\u001f${target.displayText}')
        .join('\u001e');
    if (_targetsKey == nextKey) return;

    _targets = targets;
    _targetsKey = nextKey;
    _replaceKnownUris();
  }

  @override
  set value(TextEditingValue newValue) {
    if (!_isApplyingInternalChange) {
      final previousMentions = List<_TrackedMention>.of(_mentions);
      _mentions
        ..clear()
        ..addAll(_shiftMentions(value.text, newValue.text, previousMentions));
    }
    super.value = newValue;
    if (!_isApplyingInternalChange && _targets.isNotEmpty) {
      _replaceKnownUris();
    }
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final validMentions = _validMentions(text, _mentions);
    if (validMentions.isEmpty) {
      return super.buildTextSpan(context: context, style: style, withComposing: withComposing);
    }

    final mentionStyle = style?.copyWith(
      color: Theme.of(context).colorScheme.primary,
      fontWeight: FontWeight.w700,
    );
    final children = <InlineSpan>[];
    var cursor = 0;

    for (final mention in validMentions) {
      if (mention.start > cursor) {
        children.add(TextSpan(text: text.substring(cursor, mention.start), style: style));
      }
      children.add(TextSpan(text: mention.displayText, style: mentionStyle ?? style));
      cursor = mention.end;
    }

    if (cursor < text.length) {
      children.add(TextSpan(text: text.substring(cursor), style: style));
    }

    return TextSpan(style: style, children: children);
  }

  void _replaceKnownUris() {
    if (_targets.isEmpty || text.isEmpty) return;

    final matches = <_MentionUriMatch>[];
    for (final target in _targets) {
      var start = text.indexOf(target.uri);
      while (start >= 0) {
        matches.add(_MentionUriMatch(start: start, end: start + target.uri.length, target: target));
        start = text.indexOf(target.uri, start + target.uri.length);
      }
    }

    if (matches.isEmpty) return;

    matches.sort((a, b) => a.start.compareTo(b.start));
    final selectedMatches = <_MentionUriMatch>[];
    var previousEnd = -1;
    for (final match in matches) {
      if (match.start < previousEnd) continue;
      selectedMatches.add(match);
      previousEnd = match.end;
    }

    final buffer = StringBuffer();
    final restoredMentions = <_TrackedMention>[];
    var cursor = 0;
    var selectionOffset = selection.baseOffset;

    for (final match in selectedMatches) {
      final displayText = match.target.displayText;
      buffer.write(text.substring(cursor, match.start));
      final newStart = buffer.length;
      buffer.write(displayText);
      restoredMentions.add(
        _TrackedMention(
          start: newStart,
          end: newStart + displayText.length,
          displayText: displayText,
          uri: match.target.uri,
        ),
      );

      final delta = displayText.length - (match.end - match.start);
      if (selectionOffset >= match.end) {
        selectionOffset += delta;
      } else if (selectionOffset > match.start) {
        selectionOffset = newStart + displayText.length;
      }

      cursor = match.end;
    }
    buffer.write(text.substring(cursor));

    _isApplyingInternalChange = true;
    value = TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: selectionOffset.clamp(0, buffer.length)),
    );
    _isApplyingInternalChange = false;

    _mentions
      ..clear()
      ..addAll(restoredMentions);
    notifyListeners();
  }
}

class _TrackedMention {
  const _TrackedMention({
    required this.start,
    required this.end,
    required this.displayText,
    required this.uri,
  });

  final int start;
  final int end;
  final String displayText;
  final String uri;

  _TrackedMention shift(int delta) {
    return _TrackedMention(
      start: start + delta,
      end: end + delta,
      displayText: displayText,
      uri: uri,
    );
  }
}

class _MentionUriMatch {
  const _MentionUriMatch({
    required this.start,
    required this.end,
    required this.target,
  });

  final int start;
  final int end;
  final MentionTextTarget target;
}

String _displayTextFor(String displayName, String uri) {
  final name = displayName.trim().isEmpty ? uri : displayName.trim();
  return name.startsWith('@') ? name : '@$name';
}

String _expandMentions(String text, List<_TrackedMention> mentions) {
  if (mentions.isEmpty) return text;

  final buffer = StringBuffer();
  var cursor = 0;
  for (final mention in mentions) {
    if (mention.start < cursor) continue;
    buffer
      ..write(text.substring(cursor, mention.start))
      ..write(mention.uri);
    cursor = mention.end;
  }
  buffer.write(text.substring(cursor));
  return buffer.toString();
}

List<_TrackedMention> _shiftMentions(
  String oldText,
  String newText,
  List<_TrackedMention> mentions,
) {
  if (mentions.isEmpty) return const [];

  final prefix = _commonPrefixLength(oldText, newText);
  final suffix = _commonSuffixLength(oldText, newText, prefix);
  final oldChangeEnd = oldText.length - suffix;
  final newChangeEnd = newText.length - suffix;
  final delta = (newChangeEnd - prefix) - (oldChangeEnd - prefix);
  final shifted = <_TrackedMention>[];

  for (final mention in mentions) {
    final insertedInsideMentionBoundary =
        mention.end == prefix &&
        newChangeEnd > prefix &&
        (prefix >= newText.length || !_isMentionBoundary(newText.codeUnitAt(prefix)));
    if (insertedInsideMentionBoundary) continue;

    final nextMention = mention.end <= prefix
        ? mention
        : mention.start >= oldChangeEnd
        ? mention.shift(delta)
        : null;
    if (nextMention == null) continue;
    if (_isValidMention(newText, nextMention)) {
      shifted.add(nextMention);
    }
  }

  return shifted;
}

List<_TrackedMention> _validMentions(String text, List<_TrackedMention> mentions) {
  return mentions.where((mention) => _isValidMention(text, mention)).toList()
    ..sort((a, b) => a.start.compareTo(b.start));
}

bool _isValidMention(String text, _TrackedMention mention) {
  if (mention.start < 0 || mention.end > text.length || mention.start >= mention.end) {
    return false;
  }
  return text.substring(mention.start, mention.end) == mention.displayText;
}

bool _rangesOverlap(int startA, int endA, int startB, int endB) => startA < endB && startB < endA;

bool _isMentionBoundary(int codeUnit) =>
    codeUnit == 0x20 || codeUnit == 0x09 || codeUnit == 0x0A || codeUnit == 0x0D;

int _commonPrefixLength(String a, String b) {
  final max = a.length < b.length ? a.length : b.length;
  var index = 0;
  while (index < max && a.codeUnitAt(index) == b.codeUnitAt(index)) {
    index++;
  }
  return index;
}

int _commonSuffixLength(String a, String b, int prefixLength) {
  final max = (a.length < b.length ? a.length : b.length) - prefixLength;
  var count = 0;
  while (count < max && a.codeUnitAt(a.length - count - 1) == b.codeUnitAt(b.length - count - 1)) {
    count++;
  }
  return count;
}
