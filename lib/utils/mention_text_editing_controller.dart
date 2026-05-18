import 'package:flutter/material.dart';

class MentionTextTarget {
  const MentionTextTarget({
    required this.uri,
    required this.displayText,
  });

  /// Serialized form that appears in the outgoing message body
  /// (for npub mentions, this is the bare `@npub1...` string).
  final String uri;

  /// What the user sees in the input (e.g. `@DisplayName`).
  final String displayText;
}

class MentionTextEditingController extends TextEditingController {
  MentionTextEditingController({super.text});

  final List<_TrackedMention> _mentions = [];
  List<MentionTextTarget> _targets = const [];
  var _targetsKey = '';
  var _isApplyingInternalChange = false;
  String? Function(String npub)? _displayNameForNpub;

  /// Optional resolver consulted for bare `@npub1...` strings that aren't part
  /// of an explicit picker target. When the resolver returns a non-empty name,
  /// the mention is shown as `@Name` instead of being truncated.
  ///
  /// Setting a new resolver re-processes the existing text so previously
  /// truncated mentions can pick up newly known names.
  set displayNameForNpub(String? Function(String npub)? resolver) {
    if (identical(_displayNameForNpub, resolver)) return;
    _displayNameForNpub = resolver;
    if (text.isEmpty) return;
    _restoreAutoNpubMentions();
    if (_targets.isNotEmpty) _replaceKnownUris();
    _replaceBareNpubs();
  }

  /// Expands tracked auto-detected `@npub1...` mentions back to their URI
  /// form in the text so they can be re-processed with a fresh resolver.
  /// Auto-detected = URI starts with `@npub1` AND the URI isn't registered
  /// as an explicit picker target.
  void _restoreAutoNpubMentions() {
    final targetUris = _targets.map((t) => t.uri).toSet();
    bool isAuto(_TrackedMention m) => m.uri.startsWith('@npub1') && !targetUris.contains(m.uri);
    final autoMentions = _validMentions(text, _mentions).where(isAuto).toList();
    if (autoMentions.isEmpty) return;
    final expanded = _expandMentions(text, autoMentions);
    _mentions.removeWhere(isAuto);
    _isApplyingInternalChange = true;
    super.value = TextEditingValue(
      text: expanded,
      selection: TextSelection.collapsed(
        offset: selection.baseOffset.clamp(0, expanded.length),
      ),
    );
    _isApplyingInternalChange = false;
  }

  /// Returns the text with each display mention substring expanded back to its
  /// underlying URI form. This is what should be sent on the wire / saved as
  /// the draft body.
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
    final delta = replacement.length - (end - start);
    final updatedMentions = [
      for (final mention in _mentions)
        if (!_rangesOverlap(mention.start, mention.end, start, end))
          mention.start >= end ? mention.shift(delta) : mention,
      _TrackedMention(
        start: start,
        end: start + displayText.length,
        displayText: displayText,
        uri: uri,
      ),
    ]..sort((a, b) => a.start.compareTo(b.start));

    _mentions
      ..clear()
      ..addAll(updatedMentions);
    _isApplyingInternalChange = true;
    value = TextEditingValue(
      text: updatedText,
      selection: TextSelection.collapsed(offset: start + replacement.length),
    );
    _isApplyingInternalChange = false;
  }

  /// Registers the (uri, displayText) pairs known for the current chat. The
  /// controller will swap any occurrences of `uri` in the text with
  /// `displayText` so drafts containing raw `@npub...` re-hydrate into the
  /// styled display form.
  void setMentionTargets(List<MentionTextTarget> targets) {
    final nextKey = targets.map((target) => '${target.uri}${target.displayText}').join('');
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
    if (!_isApplyingInternalChange) {
      if (_targets.isNotEmpty) _replaceKnownUris();
      _replaceBareNpubs();
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
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
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

  String? _resolveNpubName(String uri) {
    final resolver = _displayNameForNpub;
    if (resolver == null || !uri.startsWith('@')) return null;
    final name = resolver(uri.substring(1));
    if (name == null || name.trim().isEmpty) return null;
    return name.trim();
  }

  void _replaceBareNpubs() {
    if (text.isEmpty) return;
    final matches = _bareNpubRegex.allMatches(text).toList();
    if (matches.isEmpty) return;

    final existing = _validMentions(text, _mentions);
    final buffer = StringBuffer();
    final updatedMentions = <_TrackedMention>[];
    var cursor = 0;
    var selectionOffset = selection.baseOffset;
    var didReplace = false;

    for (final match in matches) {
      if (match.start < cursor) continue;
      final coveredByExisting = existing.any(
        (m) => _rangesOverlap(m.start, m.end, match.start, match.end),
      );
      if (coveredByExisting) continue;

      final uri = text.substring(match.start, match.end);
      final resolved = _resolveNpubName(uri);
      final displayText = resolved != null ? '@$resolved' : _truncateNpubMention(uri);
      if (displayText == uri) continue;

      buffer.write(text.substring(cursor, match.start));
      final newStart = buffer.length;
      buffer.write(displayText);
      updatedMentions.add(
        _TrackedMention(
          start: newStart,
          end: newStart + displayText.length,
          displayText: displayText,
          uri: uri,
        ),
      );

      final delta = displayText.length - (match.end - match.start);
      if (selectionOffset >= match.end) {
        selectionOffset += delta;
      } else if (selectionOffset > match.start) {
        selectionOffset = newStart + displayText.length;
      }
      cursor = match.end;
      didReplace = true;
    }

    if (!didReplace) return;
    buffer.write(text.substring(cursor));

    final shiftedExisting = <_TrackedMention>[];
    final newText = buffer.toString();
    for (final mention in existing) {
      final shifted = _shiftPastReplacements(mention, updatedMentions, text, newText);
      if (shifted != null) shiftedExisting.add(shifted);
    }

    _mentions
      ..clear()
      ..addAll(
        [...shiftedExisting, ...updatedMentions]..sort(
          (a, b) => a.start.compareTo(b.start),
        ),
      );
    _isApplyingInternalChange = true;
    value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selectionOffset.clamp(0, newText.length)),
    );
    _isApplyingInternalChange = false;
  }

  void _replaceKnownUris() {
    if (_targets.isEmpty || text.isEmpty) return;

    final matches = <_MentionUriMatch>[];
    for (final target in _targets) {
      var start = text.indexOf(target.uri);
      while (start >= 0) {
        matches.add(
          _MentionUriMatch(
            start: start,
            end: start + target.uri.length,
            target: target,
          ),
        );
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

    _mentions
      ..clear()
      ..addAll(restoredMentions);
    _isApplyingInternalChange = true;
    value = TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(
        offset: selectionOffset.clamp(0, buffer.length),
      ),
    );
    _isApplyingInternalChange = false;
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

final _bareNpubRegex = RegExp(r'@npub1[023456789acdefghjklmnpqrstuvwxyz]{58}');

String _truncateNpubMention(String uri) {
  if (!uri.startsWith('@')) return uri;
  final body = uri.substring(1);
  if (body.length <= 16) return uri;
  return '@${body.substring(0, 12)}…${body.substring(body.length - 4)}';
}

/// When `_replaceBareNpubs` rewrites the text, mentions that survived (those
/// added by `_replaceKnownUris` or shifted by `_shiftMentions`) need their
/// positions remapped into the new text. The new text is identical to the
/// old except that each replacement region was substituted in place, so we
/// can re-locate a surviving mention by searching for its display text in
/// the new buffer starting from where it used to live, adjusted for prior
/// deltas.
_TrackedMention? _shiftPastReplacements(
  _TrackedMention mention,
  List<_TrackedMention> replacements,
  String oldText,
  String newText,
) {
  var delta = 0;
  for (final r in replacements) {
    if (r.end <= mention.start) {
      // replacement is fully before; accumulate delta
      final oldRangeLen = r.uri.length;
      final newRangeLen = r.end - r.start;
      delta += newRangeLen - oldRangeLen;
    }
  }
  final candidateStart = mention.start + delta;
  final candidateEnd = candidateStart + (mention.end - mention.start);
  if (candidateEnd > newText.length) return null;
  if (newText.substring(candidateStart, candidateEnd) != mention.displayText) {
    return null;
  }
  return _TrackedMention(
    start: candidateStart,
    end: candidateEnd,
    displayText: mention.displayText,
    uri: mention.uri,
  );
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
