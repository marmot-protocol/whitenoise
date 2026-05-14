import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/src/rust/api/messages.dart' show HighlightSpan, SerializableToken;
import 'package:whitenoise/widgets/wn_icon.dart';

typedef MessageUrlTap = FutureOr<void> Function(String url);
typedef MessageNostrTap = FutureOr<void> Function(String uri);

class MessageContentText extends HookWidget {
  const MessageContentText({
    super.key,
    required this.content,
    required this.style,
    this.contentTokens = const [],
    this.linkStyle,
    this.highlightSpans,
    this.highlightColor,
    this.nostrDisplayNamesByUri = const {},
    this.trailingSpans = const [],
    this.maxLines,
    this.overflow,
    this.onUrlTap,
    this.onNostrTap,
  });

  final String content;
  final TextStyle style;
  final List<SerializableToken> contentTokens;
  final TextStyle? linkStyle;
  final List<HighlightSpan>? highlightSpans;
  final Color? highlightColor;
  final Map<String, String> nostrDisplayNamesByUri;
  final List<InlineSpan> trailingSpans;
  final int? maxLines;
  final TextOverflow? overflow;
  final MessageUrlTap? onUrlTap;
  final MessageNostrTap? onNostrTap;

  Future<void> _handleUrlTap(String url) async {
    if (onUrlTap != null) {
      await onUrlTap!(url);
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _handleNostrTap(String nostrUri) async {
    if (onNostrTap != null) {
      await onNostrTap!(nostrUri);
      return;
    }

    final uri = Uri.tryParse(nostrUri);
    if (uri == null || !uri.hasScheme) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final codeColor = style.color ?? Theme.of(context).colorScheme.onSurface;
    final effectiveLinkStyle =
        linkStyle ??
        style.copyWith(
          color: Theme.of(context).colorScheme.primary,
          decoration: TextDecoration.underline,
        );
    final codeTextStyle = _monospaceTextStyle(style);
    final inlineCodeStyle = codeTextStyle.copyWith(
      backgroundColor: codeColor.withValues(alpha: 0.12),
    );

    final spanState = useMemoized(
      () => _buildSpanState(
        content: content,
        contentTokens: contentTokens,
        style: style,
        linkStyle: effectiveLinkStyle,
        codeStyle: inlineCodeStyle,
        highlightSpans: highlightSpans,
        highlightColor: highlightColor,
        nostrDisplayNamesByUri: nostrDisplayNamesByUri,
        onUrlTap: (url) => unawaited(_handleUrlTap(url)),
        onNostrTap: (uri) => unawaited(_handleNostrTap(uri)),
      ),
      [
        content,
        contentTokens,
        style,
        effectiveLinkStyle,
        inlineCodeStyle,
        highlightSpans,
        highlightColor,
        nostrDisplayNamesByUri,
        onUrlTap,
        onNostrTap,
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

    if (spanState.hasCodeBlocks) {
      return _MessageContentColumn(
        pieces: spanState.pieces,
        trailingSpans: trailingSpans,
        maxLines: maxLines,
        overflow: overflow,
        codeStyle: codeTextStyle,
        codeBlockBackground: codeColor.withValues(alpha: 0.10),
        codeBlockHeaderBackground: codeColor.withValues(alpha: 0.16),
        codeBlockBorderColor: codeColor.withValues(alpha: 0.08),
        codeBlockIconColor: codeColor.withValues(alpha: 0.72),
      );
    }

    return Text.rich(
      TextSpan(children: [...spanState.spans, ...trailingSpans]),
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

class _MessageContentColumn extends StatelessWidget {
  const _MessageContentColumn({
    required this.pieces,
    required this.trailingSpans,
    required this.maxLines,
    required this.overflow,
    required this.codeStyle,
    required this.codeBlockBackground,
    required this.codeBlockHeaderBackground,
    required this.codeBlockBorderColor,
    required this.codeBlockIconColor,
  });

  final List<_MessageContentPiece> pieces;
  final List<InlineSpan> trailingSpans;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextStyle codeStyle;
  final Color codeBlockBackground;
  final Color codeBlockHeaderBackground;
  final Color codeBlockBorderColor;
  final Color codeBlockIconColor;

  @override
  Widget build(BuildContext context) {
    final lastTextPieceIndex = pieces.lastIndexWhere((piece) => piece.isText);
    final children = <Widget>[];

    for (var index = 0; index < pieces.length; index++) {
      final piece = pieces[index];
      if (piece.isCodeBlock) {
        children.add(
          Padding(
            padding: EdgeInsets.symmetric(vertical: 4.h),
            child: _MessageCodeBlock(
              code: piece.code!,
              style: codeStyle,
              backgroundColor: codeBlockBackground,
              headerBackgroundColor: codeBlockHeaderBackground,
              borderColor: codeBlockBorderColor,
              iconColor: codeBlockIconColor,
            ),
          ),
        );
        continue;
      }

      final spans = index == lastTextPieceIndex
          ? [...piece.spans!, ...trailingSpans]
          : piece.spans!;
      if (spans.isEmpty) continue;

      children.add(
        Text.rich(
          TextSpan(children: spans),
          maxLines: maxLines,
          overflow: overflow,
        ),
      );
    }

    if (lastTextPieceIndex < 0 && trailingSpans.isNotEmpty) {
      children.add(Text.rich(TextSpan(children: trailingSpans)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}

class _MessageCodeBlock extends HookWidget {
  const _MessageCodeBlock({
    required this.code,
    required this.style,
    required this.backgroundColor,
    required this.headerBackgroundColor,
    required this.borderColor,
    required this.iconColor,
  });

  final String code;
  final TextStyle style;
  final Color backgroundColor;
  final Color headerBackgroundColor;
  final Color borderColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final copied = useState(false);
    final copiedTimer = useRef<Timer?>(null);

    useEffect(() {
      return () => copiedTimer.value?.cancel();
    }, const []);

    Future<void> copyCode() async {
      try {
        await Clipboard.setData(ClipboardData(text: code));
        copiedTimer.value?.cancel();
        copied.value = true;
        copiedTimer.value = Timer(const Duration(milliseconds: 1400), () {
          copied.value = false;
        });
      } catch (_) {}
    }

    final copiedStyle =
        Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ) ??
        const TextStyle(color: Colors.white, fontWeight: FontWeight.w700);

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          key: const Key('message_code_block'),
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(6.r),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              ColoredBox(
                key: const Key('message_code_block_header'),
                color: headerBackgroundColor,
                child: SizedBox(
                  height: 28.h,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Semantics(
                      button: true,
                      label: context.l10n.copyCode,
                      child: GestureDetector(
                        key: const Key('message_code_block_copy_button'),
                        behavior: HitTestBehavior.opaque,
                        onTap: () => unawaited(copyCode()),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                          child: WnIcon(
                            WnIcons.copy,
                            size: 16.w,
                            color: iconColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 12.h),
                  child: Text(
                    code,
                    key: const Key('message_code_block_text'),
                    style: style,
                    softWrap: false,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (copied.value)
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: DecoratedBox(
                  key: const Key('message_code_block_copied_pill'),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(999.r),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    child: Text(context.l10n.copied, style: copiedStyle),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SpanState {
  _SpanState({
    required this.spans,
    required this.pieces,
    required this.recognizers,
    required this.needsRichText,
  });

  final List<InlineSpan> spans;
  final List<_MessageContentPiece> pieces;
  final List<TapGestureRecognizer> recognizers;
  final bool needsRichText;

  bool get hasCodeBlocks => pieces.any((piece) => piece.isCodeBlock);

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
  bool get isNostr => tokenType == 'Nostr';
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

enum _ContentRunType { text, inlineCode, codeBlock }

class _ContentRun {
  const _ContentRun({
    required this.text,
    required this.type,
    required this.start,
    required this.end,
  });

  final String text;
  final _ContentRunType type;
  final int start;
  final int end;
}

class _MessageContentPiece {
  const _MessageContentPiece.text(this.spans) : code = null;
  const _MessageContentPiece.codeBlock(this.code) : spans = null;

  final List<InlineSpan>? spans;
  final String? code;

  bool get isText => spans != null;
  bool get isCodeBlock => code != null;
}

class _FencedCodeMatch {
  const _FencedCodeMatch({required this.text, required this.end});

  final String text;
  final int end;
}

_SpanState _buildSpanState({
  required String content,
  required List<SerializableToken> contentTokens,
  required TextStyle style,
  required TextStyle linkStyle,
  required TextStyle codeStyle,
  required List<HighlightSpan>? highlightSpans,
  required Color? highlightColor,
  required Map<String, String> nostrDisplayNamesByUri,
  required void Function(String url) onUrlTap,
  required void Function(String uri) onNostrTap,
}) {
  final recognizers = <TapGestureRecognizer>[];
  final segments = _buildSegments(content, contentTokens);
  final runs = _parseContentRuns(content);
  final highlightRanges = _buildHighlightRanges(content, highlightSpans);
  final spans = <InlineSpan>[];
  final pieces = <_MessageContentPiece>[];
  final textPieceSpans = <InlineSpan>[];
  var hasCodeRuns = false;

  void flushTextPiece() {
    if (textPieceSpans.isEmpty) return;
    pieces.add(_MessageContentPiece.text(List<InlineSpan>.of(textPieceSpans)));
    textPieceSpans.clear();
  }

  for (final run in runs) {
    if (run.type == _ContentRunType.codeBlock) {
      hasCodeRuns = true;
      flushTextPiece();
      pieces.add(_MessageContentPiece.codeBlock(run.text));
      continue;
    }

    if (run.type == _ContentRunType.inlineCode) {
      hasCodeRuns = true;
      final span = TextSpan(text: run.text, style: codeStyle);
      spans.add(span);
      textPieceSpans.add(span);
      continue;
    }

    for (final segment in _segmentsInRange(segments, run.start, run.end)) {
      final segmentSpans = _buildSegmentSpans(
        segment: segment,
        style: style,
        linkStyle: linkStyle,
        highlightRanges: highlightRanges,
        highlightColor: highlightColor,
        nostrDisplayNamesByUri: nostrDisplayNamesByUri,
        recognizers: recognizers,
        onUrlTap: onUrlTap,
        onNostrTap: onNostrTap,
      );
      spans.addAll(segmentSpans);
      textPieceSpans.addAll(segmentSpans);
    }
  }
  flushTextPiece();

  return _SpanState(
    spans: spans,
    pieces: pieces,
    recognizers: recognizers,
    needsRichText:
        hasCodeRuns ||
        recognizers.isNotEmpty ||
        highlightRanges.isNotEmpty ||
        contentTokens.isNotEmpty,
  );
}

List<_ContentRun> _parseContentRuns(String content) {
  final runs = <_ContentRun>[];
  var cursor = 0;

  while (cursor < content.length) {
    final markerStart = content.indexOf('`', cursor);
    if (markerStart < 0) break;

    if (markerStart > cursor) {
      runs.add(
        _ContentRun(
          text: content.substring(cursor, markerStart),
          type: _ContentRunType.text,
          start: cursor,
          end: markerStart,
        ),
      );
    }

    if (_startsWithAt(content, markerStart, '```')) {
      final match = _parseFencedCode(content, markerStart);
      if (match == null) {
        runs.add(
          _ContentRun(
            text: content.substring(markerStart),
            type: _ContentRunType.text,
            start: markerStart,
            end: content.length,
          ),
        );
        cursor = content.length;
      } else {
        runs.add(
          _ContentRun(
            text: match.text,
            type: _ContentRunType.codeBlock,
            start: markerStart,
            end: match.end,
          ),
        );
        cursor = match.end;
      }
      continue;
    }

    final markerEnd = content.indexOf('`', markerStart + 1);
    if (markerEnd < 0) {
      runs.add(
        _ContentRun(
          text: content.substring(markerStart),
          type: _ContentRunType.text,
          start: markerStart,
          end: content.length,
        ),
      );
      cursor = content.length;
      continue;
    }

    final inlineText = content.substring(markerStart + 1, markerEnd);
    if (inlineText.contains('\n')) {
      runs.add(
        _ContentRun(
          text: content.substring(markerStart, markerStart + 1),
          type: _ContentRunType.text,
          start: markerStart,
          end: markerStart + 1,
        ),
      );
      cursor = markerStart + 1;
      continue;
    }

    runs.add(
      _ContentRun(
        text: inlineText,
        type: _ContentRunType.inlineCode,
        start: markerStart,
        end: markerEnd + 1,
      ),
    );
    cursor = markerEnd + 1;
  }

  if (cursor < content.length) {
    runs.add(
      _ContentRun(
        text: content.substring(cursor),
        type: _ContentRunType.text,
        start: cursor,
        end: content.length,
      ),
    );
  }

  return runs.isEmpty
      ? [_ContentRun(text: content, type: _ContentRunType.text, start: 0, end: content.length)]
      : runs;
}

bool _startsWithAt(String text, int index, String pattern) =>
    index + pattern.length <= text.length &&
    text.substring(index, index + pattern.length) == pattern;

_FencedCodeMatch? _parseFencedCode(String content, int markerStart) {
  final markerEnd = markerStart + 3;
  final closingMarkerStart = content.indexOf('```', markerEnd);
  if (closingMarkerStart < 0) return null;

  var codeStart = markerEnd;
  if (_startsWithAt(content, codeStart, '\r\n')) {
    codeStart += 2;
  } else if (_startsWithAt(content, codeStart, '\n')) {
    codeStart += 1;
  } else {
    final languageEnd = content.indexOf('\n', codeStart);
    if (languageEnd >= 0 && languageEnd < closingMarkerStart) {
      codeStart = languageEnd + 1;
    }
  }

  var codeEnd = closingMarkerStart;
  if (codeEnd > codeStart && content.codeUnitAt(codeEnd - 1) == 0x0A) {
    codeEnd -= 1;
    if (codeEnd > codeStart && content.codeUnitAt(codeEnd - 1) == 0x0D) {
      codeEnd -= 1;
    }
  }

  var afterMarker = closingMarkerStart + 3;
  if (_startsWithAt(content, afterMarker, '\r\n')) {
    afterMarker += 2;
  } else if (_startsWithAt(content, afterMarker, '\n')) {
    afterMarker += 1;
  }

  return _FencedCodeMatch(
    text: content.substring(codeStart, codeEnd),
    end: afterMarker,
  );
}

TextStyle _monospaceTextStyle(TextStyle style) {
  return style.copyWith(
    fontFamily: 'SF Mono',
    fontFamilyFallback: const ['Menlo', 'Monaco', 'Consolas', 'Courier New', 'monospace'],
    letterSpacing: 0,
  );
}

List<_ContentSegment> _segmentsInRange(List<_ContentSegment> segments, int start, int end) {
  final result = <_ContentSegment>[];

  for (final segment in segments) {
    if (segment.end <= start) continue;
    if (segment.start >= end) break;

    final sliceStart = _max(segment.start, start);
    final sliceEnd = _min(segment.end, end);
    if (sliceEnd <= sliceStart) continue;

    result.add(
      _ContentSegment(
        text: segment.text.substring(sliceStart - segment.start, sliceEnd - segment.start),
        tokenType: segment.tokenType,
        start: sliceStart,
        end: sliceEnd,
        target: segment.target,
      ),
    );
  }

  return result;
}

int _min(int a, int b) => a < b ? a : b;

int _max(int a, int b) => a > b ? a : b;

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
  required Map<String, String> nostrDisplayNamesByUri,
  required List<TapGestureRecognizer> recognizers,
  required void Function(String url) onUrlTap,
  required void Function(String uri) onNostrTap,
}) {
  if (segment.text.isEmpty) return const [];

  final nostrDisplayText = _nostrDisplayText(segment, nostrDisplayNamesByUri);
  if (nostrDisplayText != null) {
    final effectiveHighlightColor = _segmentOverlapsHighlight(segment, highlightRanges)
        ? highlightColor
        : null;
    return [
      _spanForSegmentText(
        segment: segment,
        text: nostrDisplayText,
        style: style,
        linkStyle: linkStyle,
        highlightColor: effectiveHighlightColor,
        recognizers: recognizers,
        onUrlTap: onUrlTap,
        onNostrTap: onNostrTap,
      ),
    ];
  }

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
          onNostrTap: onNostrTap,
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
          onNostrTap: onNostrTap,
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
        onNostrTap: onNostrTap,
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
  required void Function(String uri) onNostrTap,
}) {
  return _spanForSegmentText(
    segment: segment,
    text: segment.text.substring(start - segment.start, end - segment.start),
    style: style,
    linkStyle: linkStyle,
    highlightColor: highlightColor,
    recognizers: recognizers,
    onUrlTap: onUrlTap,
    onNostrTap: onNostrTap,
  );
}

InlineSpan _spanForSegmentText({
  required _ContentSegment segment,
  required String text,
  required TextStyle style,
  required TextStyle linkStyle,
  required Color? highlightColor,
  required List<TapGestureRecognizer> recognizers,
  required void Function(String url) onUrlTap,
  required void Function(String uri) onNostrTap,
}) {
  final baseStyle = segment.isUrl || segment.isNostr ? linkStyle : style;
  final effectiveStyle = highlightColor == null
      ? baseStyle
      : baseStyle.copyWith(backgroundColor: highlightColor);

  if ((!segment.isUrl && !segment.isNostr) || segment.target == null) {
    return TextSpan(text: text, style: effectiveStyle);
  }

  final recognizer = TapGestureRecognizer()
    ..onTap = () {
      if (segment.isNostr) {
        onNostrTap(segment.target!);
      } else {
        onUrlTap(segment.target!);
      }
    };
  recognizers.add(recognizer);
  return TextSpan(text: text, style: effectiveStyle, recognizer: recognizer);
}

String? _nostrDisplayText(_ContentSegment segment, Map<String, String> displayNamesByUri) {
  if (!segment.isNostr || segment.target == null || displayNamesByUri.isEmpty) return null;

  return displayNamesByUri[_nostrUri(segment.target!)] ??
      displayNamesByUri[_nostrUri(segment.text)];
}

String _nostrUri(String value) => value.startsWith('nostr:') ? value : 'nostr:$value';

bool _segmentOverlapsHighlight(_ContentSegment segment, List<_HighlightRange> ranges) {
  for (final range in ranges) {
    if (range.end <= segment.start) continue;
    if (range.start >= segment.end) return false;
    return true;
  }
  return false;
}
