import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:whitenoise/src/rust/api/messages.dart' show HighlightSpan, SerializableToken;

typedef MessageUrlTap = FutureOr<void> Function(String url);

class MessageContentText extends HookWidget {
  const MessageContentText({
    super.key,
    required this.content,
    required this.style,
    this.contentTokens = const [],
    this.linkStyle,
    this.highlightSpans,
    this.highlightColor,
    this.trailingSpans = const [],
    this.maxLines,
    this.overflow,
    this.onUrlTap,
  });

  final String content;
  final TextStyle style;
  final List<SerializableToken> contentTokens;
  final TextStyle? linkStyle;
  final List<HighlightSpan>? highlightSpans;
  final Color? highlightColor;
  final List<InlineSpan> trailingSpans;
  final int? maxLines;
  final TextOverflow? overflow;
  final MessageUrlTap? onUrlTap;

  Future<void> _handleUrlTap(String url) async {
    if (onUrlTap != null) {
      await onUrlTap!(url);
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveLinkStyle =
        linkStyle ??
        style.copyWith(
          color: Theme.of(context).colorScheme.primary,
          decoration: TextDecoration.underline,
        );

    final spanState = useMemoized(
      () => _buildSpanState(
        content: content,
        contentTokens: contentTokens,
        style: style,
        linkStyle: effectiveLinkStyle,
        highlightSpans: highlightSpans,
        highlightColor: highlightColor,
        onUrlTap: (url) => unawaited(_handleUrlTap(url)),
      ),
      [
        content,
        contentTokens,
        style,
        effectiveLinkStyle,
        highlightSpans,
        highlightColor,
        onUrlTap,
      ],
    );
    useEffect(() => spanState.dispose, [spanState]);

    if (!spanState.needsRichText && trailingSpans.isEmpty) {
      return Text(
        content,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    return Text.rich(
      TextSpan(children: [...spanState.spans, ...trailingSpans]),
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

class _SpanState {
  _SpanState({
    required this.spans,
    required this.recognizers,
    required this.needsRichText,
  });

  final List<InlineSpan> spans;
  final List<TapGestureRecognizer> recognizers;
  final bool needsRichText;

  void dispose() {
    for (final recognizer in recognizers) {
      recognizer.dispose();
    }
  }
}

class _ContentSegment {
  const _ContentSegment({
    required this.text,
    required this.tokenType,
    required this.start,
    required this.end,
    this.target,
  });

  final String text;
  final String tokenType;
  final int start;
  final int end;
  final String? target;

  bool get isUrl => tokenType == 'Url';
}

class _TokenMatch {
  const _TokenMatch({required this.start, required this.end});

  final int start;
  final int end;
}

class _HighlightRange {
  const _HighlightRange({required this.start, required this.end});

  final int start;
  final int end;
}

_SpanState _buildSpanState({
  required String content,
  required List<SerializableToken> contentTokens,
  required TextStyle style,
  required TextStyle linkStyle,
  required List<HighlightSpan>? highlightSpans,
  required Color? highlightColor,
  required void Function(String url) onUrlTap,
}) {
  final recognizers = <TapGestureRecognizer>[];
  final segments = _buildSegments(content, contentTokens);
  final highlightRanges = _buildHighlightRanges(content, highlightSpans);
  final spans = <InlineSpan>[];

  for (final segment in segments) {
    spans.addAll(
      _buildSegmentSpans(
        segment: segment,
        style: style,
        linkStyle: linkStyle,
        highlightRanges: highlightRanges,
        highlightColor: highlightColor,
        recognizers: recognizers,
        onUrlTap: onUrlTap,
      ),
    );
  }

  return _SpanState(
    spans: spans,
    recognizers: recognizers,
    needsRichText: recognizers.isNotEmpty || highlightRanges.isNotEmpty || contentTokens.isNotEmpty,
  );
}

List<_ContentSegment> _buildSegments(String content, List<SerializableToken> tokens) {
  if (tokens.isEmpty) return [_plainSegment(content)];

  final segments = <_ContentSegment>[];
  var cursor = 0;

  for (final token in tokens) {
    final match = _findTokenMatch(content, token, cursor);
    if (match == null) return [_plainSegment(content)];

    if (match.start > cursor) {
      segments.add(
        _ContentSegment(
          text: content.substring(cursor, match.start),
          tokenType: 'Text',
          start: cursor,
          end: match.start,
        ),
      );
    }

    if (match.end > match.start) {
      segments.add(
        _ContentSegment(
          text: content.substring(match.start, match.end),
          tokenType: token.tokenType,
          start: match.start,
          end: match.end,
          target: token.content,
        ),
      );
    }
    cursor = match.end;
  }

  if (cursor < content.length) {
    segments.add(
      _ContentSegment(
        text: content.substring(cursor),
        tokenType: 'Text',
        start: cursor,
        end: content.length,
      ),
    );
  }

  final rendered = segments.map((segment) => segment.text).join();
  return rendered == content ? segments : [_plainSegment(content)];
}

_ContentSegment _plainSegment(String content) =>
    _ContentSegment(text: content, tokenType: 'Text', start: 0, end: content.length);

_TokenMatch? _findTokenMatch(String content, SerializableToken token, int cursor) {
  final candidates = _displayCandidates(token);
  if (candidates.isEmpty) return _TokenMatch(start: cursor, end: cursor);

  for (final candidate in candidates) {
    final start = content.indexOf(candidate, cursor);
    if (start >= 0) {
      return _TokenMatch(start: start, end: start + candidate.length);
    }
  }

  return null;
}

List<String> _displayCandidates(SerializableToken token) {
  final content = token.content;
  final primary = switch (token.tokenType) {
    'Whitespace' => ' ',
    'LineBreak' => '\n',
    'Hashtag' => content == null ? '' : '#$content',
    _ => content ?? '',
  };

  if (primary.isEmpty) return const [];
  if (token.tokenType == 'Url' && primary.endsWith('/')) {
    return [primary, primary.substring(0, primary.length - 1)];
  }
  return [primary];
}

List<_HighlightRange> _buildHighlightRanges(
  String content,
  List<HighlightSpan>? highlightSpans,
) {
  if (highlightSpans == null || highlightSpans.isEmpty) return const [];

  final sorted =
      highlightSpans
          .map((span) {
            final start = _codePointToCodeUnit(content, span.start).clamp(0, content.length);
            final end = _codePointToCodeUnit(content, span.end).clamp(start, content.length);
            return _HighlightRange(start: start, end: end);
          })
          .where((range) => range.end > range.start)
          .toList()
        ..sort((a, b) => a.start.compareTo(b.start));

  final merged = <_HighlightRange>[];
  for (final range in sorted) {
    if (merged.isEmpty || range.start > merged.last.end) {
      merged.add(range);
    } else if (range.end > merged.last.end) {
      final last = merged.removeLast();
      merged.add(_HighlightRange(start: last.start, end: range.end));
    }
  }
  return merged;
}

int _codePointToCodeUnit(String text, int codePointIndex) {
  var codeUnits = 0;
  var codePoints = 0;
  for (final rune in text.runes) {
    if (codePoints >= codePointIndex) break;
    codeUnits += rune > 0xFFFF ? 2 : 1;
    codePoints++;
  }
  return codeUnits;
}

List<InlineSpan> _buildSegmentSpans({
  required _ContentSegment segment,
  required TextStyle style,
  required TextStyle linkStyle,
  required List<_HighlightRange> highlightRanges,
  required Color? highlightColor,
  required List<TapGestureRecognizer> recognizers,
  required void Function(String url) onUrlTap,
}) {
  if (segment.text.isEmpty) return const [];

  final spans = <InlineSpan>[];
  var cursor = segment.start;

  for (final range in highlightRanges) {
    if (range.end <= segment.start) continue;
    if (range.start >= segment.end) break;

    final start = range.start.clamp(segment.start, segment.end);
    final end = range.end.clamp(segment.start, segment.end);
    if (start > cursor) {
      spans.add(
        _spanForSegmentSlice(
          segment: segment,
          start: cursor,
          end: start,
          style: style,
          linkStyle: linkStyle,
          highlightColor: null,
          recognizers: recognizers,
          onUrlTap: onUrlTap,
        ),
      );
    }
    if (end > start) {
      spans.add(
        _spanForSegmentSlice(
          segment: segment,
          start: start,
          end: end,
          style: style,
          linkStyle: linkStyle,
          highlightColor: highlightColor,
          recognizers: recognizers,
          onUrlTap: onUrlTap,
        ),
      );
    }
    cursor = end;
  }

  if (cursor < segment.end) {
    spans.add(
      _spanForSegmentSlice(
        segment: segment,
        start: cursor,
        end: segment.end,
        style: style,
        linkStyle: linkStyle,
        highlightColor: null,
        recognizers: recognizers,
        onUrlTap: onUrlTap,
      ),
    );
  }

  return spans;
}

InlineSpan _spanForSegmentSlice({
  required _ContentSegment segment,
  required int start,
  required int end,
  required TextStyle style,
  required TextStyle linkStyle,
  required Color? highlightColor,
  required List<TapGestureRecognizer> recognizers,
  required void Function(String url) onUrlTap,
}) {
  final baseStyle = segment.isUrl ? linkStyle : style;
  final effectiveStyle = highlightColor == null
      ? baseStyle
      : baseStyle.copyWith(backgroundColor: highlightColor);
  final text = segment.text.substring(start - segment.start, end - segment.start);

  if (!segment.isUrl || segment.target == null) {
    return TextSpan(text: text, style: effectiveStyle);
  }

  final recognizer = TapGestureRecognizer()..onTap = () => onUrlTap(segment.target!);
  recognizers.add(recognizer);
  return TextSpan(text: text, style: effectiveStyle, recognizer: recognizer);
}
