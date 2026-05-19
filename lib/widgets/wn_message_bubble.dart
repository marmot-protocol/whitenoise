import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/src/rust/api/messages.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_chat_status.dart';
import 'package:whitenoise/widgets/wn_reaction.dart';
export 'package:whitenoise/src/rust/api/messages.dart' show EmojiReaction;

final _unorderedMarkdownListPattern = RegExp(r'^(\s*)[-+*]\s+(.+)$');
final _orderedMarkdownListPattern = RegExp(r'^(\s*)(\d+)[.)]\s+(.+)$');

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

List<TextSpan> _buildHighlightedSpans(
  String text,
  TextStyle baseStyle,
  List<HighlightSpan> spans,
  Color highlightColor,
) {
  if (spans.isEmpty) return [TextSpan(text: text, style: baseStyle)];

  final highlightStyle = baseStyle.copyWith(backgroundColor: highlightColor);

  final result = <TextSpan>[];
  var cursor = 0;
  for (final span in spans) {
    final start = _codePointToCodeUnit(text, span.start).clamp(0, text.length);
    final end = _codePointToCodeUnit(text, span.end).clamp(start, text.length);
    if (start > cursor) {
      result.add(TextSpan(text: text.substring(cursor, start), style: baseStyle));
    }
    if (end > start) {
      result.add(TextSpan(text: text.substring(start, end), style: highlightStyle));
    }
    cursor = end;
  }
  if (cursor < text.length) {
    result.add(TextSpan(text: text.substring(cursor), style: baseStyle));
  }
  return result;
}

List<TextSpan> _buildMessageTextSpans(
  String text,
  TextStyle baseStyle,
  List<HighlightSpan>? highlightSpans,
  Color? highlightColor,
) {
  if (highlightSpans != null && highlightSpans.isNotEmpty) {
    return _buildHighlightedSpans(text, baseStyle, highlightSpans, highlightColor!);
  }
  return _buildMarkdownSpans(text, baseStyle) ?? [TextSpan(text: text, style: baseStyle)];
}

List<TextSpan>? _buildMarkdownSpans(String text, TextStyle baseStyle) {
  final spans = <TextSpan>[];
  var didFormat = false;

  final lines = text.split('\n');
  for (var index = 0; index < lines.length; index++) {
    if (index > 0) {
      spans.add(TextSpan(text: '\n', style: baseStyle));
    }

    final line = lines[index];
    final listItem = _parseMarkdownListItem(line);
    if (listItem != null) {
      didFormat = true;
      spans.add(TextSpan(text: '${listItem.indent}${listItem.marker}', style: baseStyle));
      final itemSpans = _buildInlineMarkdownSpans(listItem.content, baseStyle);
      if (itemSpans == null) {
        spans.add(TextSpan(text: listItem.content, style: baseStyle));
      } else {
        spans.addAll(itemSpans);
      }
      continue;
    }

    final inlineSpans = _buildInlineMarkdownSpans(line, baseStyle);
    if (inlineSpans == null) {
      spans.add(TextSpan(text: line, style: baseStyle));
    } else {
      didFormat = true;
      spans.addAll(inlineSpans);
    }
  }

  return didFormat ? spans : null;
}

List<TextSpan>? _buildInlineMarkdownSpans(String text, TextStyle baseStyle) {
  final spans = <TextSpan>[];
  var cursor = 0;
  var didFormat = false;

  void appendPlain(int end) {
    if (end > cursor) {
      spans.add(TextSpan(text: text.substring(cursor, end), style: baseStyle));
    }
  }

  while (cursor < text.length) {
    final token = _nextMarkdownToken(text, cursor, baseStyle);
    if (token == null) {
      break;
    }

    appendPlain(token.start);
    spans.add(token.span);
    cursor = token.end;
    didFormat = true;
  }

  appendPlain(text.length);
  return didFormat ? spans : null;
}

_MarkdownListItem? _parseMarkdownListItem(String line) {
  final unordered = _unorderedMarkdownListPattern.firstMatch(line);
  if (unordered != null) {
    return _MarkdownListItem(
      indent: unordered.group(1)!,
      marker: '• ',
      content: unordered.group(2)!,
    );
  }

  final ordered = _orderedMarkdownListPattern.firstMatch(line);
  if (ordered != null) {
    return _MarkdownListItem(
      indent: ordered.group(1)!,
      marker: '${ordered.group(2)!}. ',
      content: ordered.group(3)!,
    );
  }

  return null;
}

_MarkdownToken? _nextMarkdownToken(String text, int start, TextStyle baseStyle) {
  for (var index = start; index < text.length; index++) {
    final codeToken = _markdownTokenAt(text, index, '`', baseStyle);
    if (codeToken != null) return codeToken;

    final boldAsteriskToken = _markdownTokenAt(text, index, '**', baseStyle);
    if (boldAsteriskToken != null) return boldAsteriskToken;

    final boldUnderscoreToken = _markdownTokenAt(text, index, '__', baseStyle);
    if (boldUnderscoreToken != null) return boldUnderscoreToken;

    final italicAsteriskToken = _markdownTokenAt(text, index, '*', baseStyle);
    if (italicAsteriskToken != null) return italicAsteriskToken;

    final italicUnderscoreToken = _markdownTokenAt(text, index, '_', baseStyle);
    if (italicUnderscoreToken != null) return italicUnderscoreToken;
  }
  return null;
}

_MarkdownToken? _markdownTokenAt(
  String text,
  int index,
  String delimiter,
  TextStyle baseStyle,
) {
  if (!text.startsWith(delimiter, index)) return null;
  if (!_canOpenMarkdown(text, index, delimiter)) return null;

  final contentStart = index + delimiter.length;
  final closingIndex = _findClosingDelimiter(text, delimiter, contentStart);
  if (closingIndex <= contentStart) return null;
  if (!_canCloseMarkdown(text, closingIndex, delimiter)) return null;

  final rawContent = text.substring(contentStart, closingIndex);
  if (rawContent.trim().isEmpty) return null;

  return _MarkdownToken(
    start: index,
    end: closingIndex + delimiter.length,
    span: TextSpan(text: rawContent, style: _markdownStyle(baseStyle, delimiter)),
  );
}

int _findClosingDelimiter(String text, String delimiter, int start) {
  var index = start;
  while (index < text.length) {
    final found = text.indexOf(delimiter, index);
    if (found == -1) return -1;
    if (_canCloseMarkdown(text, found, delimiter)) return found;
    index = found + delimiter.length;
  }
  return -1;
}

bool _canOpenMarkdown(String text, int index, String delimiter) {
  if (delimiter == '`') return true;

  final before = index == 0 ? null : text[index - 1];
  final afterIndex = index + delimiter.length;
  final after = afterIndex >= text.length ? null : text[afterIndex];
  if (after == null || after.trim().isEmpty) return false;

  if (delimiter.contains('_')) {
    return before == null || !_isWordChar(before);
  }
  return true;
}

bool _canCloseMarkdown(String text, int index, String delimiter) {
  if (delimiter == '`') return true;

  final before = index == 0 ? null : text[index - 1];
  final afterIndex = index + delimiter.length;
  final after = afterIndex >= text.length ? null : text[afterIndex];
  if (before == null || before.trim().isEmpty) return false;

  if (delimiter.contains('_')) {
    return after == null || !_isWordChar(after);
  }
  return true;
}

bool _isWordChar(String value) {
  final codeUnit = value.codeUnitAt(0);
  return (codeUnit >= 48 && codeUnit <= 57) ||
      (codeUnit >= 65 && codeUnit <= 90) ||
      (codeUnit >= 97 && codeUnit <= 122);
}

TextStyle _markdownStyle(TextStyle baseStyle, String delimiter) {
  return switch (delimiter) {
    '`' => baseStyle.copyWith(fontFamily: 'monospace'),
    '**' || '__' => baseStyle.copyWith(fontWeight: FontWeight.w700),
    '*' || '_' => baseStyle.copyWith(fontStyle: FontStyle.italic),
    _ => baseStyle,
  };
}

class _MarkdownToken {
  const _MarkdownToken({
    required this.start,
    required this.end,
    required this.span,
  });

  final int start;
  final int end;
  final TextSpan span;
}

class _MarkdownListItem {
  const _MarkdownListItem({
    required this.indent,
    required this.marker,
    required this.content,
  });

  final String indent;
  final String marker;
  final String content;
}

const _timestampMinPadding = 16.0;
const _chatStatusW = 18.0;
const _chatStatusGap = 4.0;
const _truncatedStatusTopGap = 2.0;
const _truncatedStatusBottomReserve = 6.0;

enum MessageDirection { incoming, outgoing }

enum BubbleLeadingVariant { none, tail, avatar }

const _tailW = 16.0;
const _tailH = 10.0;
const _tailOverhang = 8.0;

class _TextWithTimestamp extends StatelessWidget {
  const _TextWithTimestamp({
    required this.content,
    required this.timestamp,
    required this.textStyle,
    required this.tsStyle,
    required this.isOutgoing,
    required this.showDeliveryStatus,
    this.highlightSpans,
    this.highlightColor,
    this.deliveryStatus,
    this.onStatusTap,
    this.maxLines,
  });

  final String content;
  final String timestamp;
  final TextStyle textStyle;
  final TextStyle tsStyle;
  final bool isOutgoing;
  final bool showDeliveryStatus;
  final List<HighlightSpan>? highlightSpans;
  final Color? highlightColor;
  final ChatStatusType? deliveryStatus;
  final VoidCallback? onStatusTap;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final reservedWidth = _timestampReservedWidth(
      timestamp,
      tsStyle,
      isOutgoing,
      showDeliveryStatus,
    );

    Widget statusRow = Row(
      key: const Key('message_status_row'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(timestamp, style: tsStyle),
        if (showDeliveryStatus && isOutgoing) ...[
          SizedBox(width: _chatStatusGap.w),
          WnChatStatus(status: deliveryStatus ?? ChatStatusType.sending),
        ],
      ],
    );

    if (onStatusTap != null) {
      statusRow = GestureDetector(
        key: const Key('status_tap_area'),
        behavior: HitTestBehavior.opaque,
        onTap: onStatusTap,
        child: statusRow,
      );
    }

    final textChildren = _buildMessageTextSpans(
      content,
      textStyle,
      highlightSpans,
      highlightColor,
    );

    if (maxLines != null) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final textMaxWidth = (constraints.maxWidth - reservedWidth).clamp(0.0, double.infinity);
          final painter = TextPainter(
            text: TextSpan(text: content, style: textStyle),
            textDirection: Directionality.of(context),
            maxLines: maxLines,
            ellipsis: '\u2026',
            textScaler: MediaQuery.textScalerOf(context),
          );
          try {
            painter.layout(maxWidth: textMaxWidth);
            final isTruncated = painter.didExceedMaxLines;
            if (isTruncated) {
              final textLinePainter = TextPainter(
                text: TextSpan(text: ' ', style: textStyle),
                textDirection: Directionality.of(context),
                textScaler: MediaQuery.textScalerOf(context),
              );
              final statusLinePainter = TextPainter(
                text: TextSpan(text: timestamp, style: tsStyle),
                textDirection: Directionality.of(context),
                textScaler: MediaQuery.textScalerOf(context),
              );
              final (:lineHeight, :statusHeight, :effectiveMaxLines) = (() {
                try {
                  textLinePainter.layout();
                  statusLinePainter.layout();
                  final lineHeight = math.max(textLinePainter.preferredLineHeight, 1.0);
                  final statusHeight = math.max(
                    statusLinePainter.preferredLineHeight,
                    (showDeliveryStatus && isOutgoing) ? _chatStatusW.h : 0.0,
                  );
                  final availableTextHeight = constraints.maxHeight.isFinite
                      ? math.max(
                          0.0,
                          constraints.maxHeight -
                              statusHeight -
                              _truncatedStatusTopGap.h -
                              _truncatedStatusBottomReserve.h,
                        )
                      : double.infinity;
                  final linesByHeight = availableTextHeight.isFinite
                      ? (availableTextHeight / lineHeight).floor()
                      : maxLines!;
                  final effectiveMaxLines = math.max(1, math.min(maxLines!, linesByHeight) - 1);
                  return (
                    lineHeight: lineHeight,
                    statusHeight: statusHeight,
                    effectiveMaxLines: effectiveMaxLines,
                  );
                } finally {
                  textLinePainter.dispose();
                  statusLinePainter.dispose();
                }
              })();
              if (constraints.maxHeight.isFinite) {
                return SizedBox(
                  height: constraints.maxHeight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Text(
                          content,
                          style: textStyle,
                          maxLines: effectiveMaxLines,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(height: _truncatedStatusTopGap.h),
                      Align(alignment: Alignment.centerRight, child: statusRow),
                    ],
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    content,
                    style: textStyle,
                    maxLines: effectiveMaxLines,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: _truncatedStatusTopGap.h),
                  Align(alignment: Alignment.centerRight, child: statusRow),
                ],
              );
            }
            final isSingleLine = painter.computeLineMetrics().length <= 1;
            return Stack(
              alignment: isOutgoing && isSingleLine ? Alignment.topRight : Alignment.topLeft,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      ...textChildren,
                      WidgetSpan(child: SizedBox(width: reservedWidth)),
                    ],
                  ),
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                ),
                Positioned(bottom: 0, right: 0, child: statusRow),
              ],
            );
          } finally {
            painter.dispose();
          }
        },
      );
    }

    return Stack(
      children: [
        Text.rich(
          TextSpan(
            children: [
              ...textChildren,
              WidgetSpan(child: SizedBox(width: reservedWidth)),
            ],
          ),
        ),
        Positioned(bottom: 0, right: 0, child: statusRow),
      ],
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  const _BubbleTailPainter({required this.color, required this.incoming});

  final Color color;
  final bool incoming;

  @override
  void paint(Canvas canvas, Size size) {
    if (!incoming) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }
    canvas.drawPath(
      Path()
        ..moveTo(size.width, 0)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close(),
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_BubbleTailPainter old) => old.color != color || old.incoming != incoming;
}

class _MessageText extends StatelessWidget {
  const _MessageText({
    required this.content,
    required this.textStyle,
    this.highlightSpans,
    this.highlightColor,
    this.maxLines,
  });

  final String content;
  final TextStyle textStyle;
  final List<HighlightSpan>? highlightSpans;
  final Color? highlightColor;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final spans = _buildMessageTextSpans(
      content,
      textStyle,
      highlightSpans,
      highlightColor,
    );
    final hasHighlights = highlightSpans != null && highlightSpans!.isNotEmpty;
    if (!hasHighlights && spans.length == 1 && spans.single.text == content) {
      return Text(
        content,
        style: textStyle,
        maxLines: maxLines,
        overflow: maxLines != null ? TextOverflow.ellipsis : TextOverflow.clip,
      );
    }

    return Text.rich(
      TextSpan(children: spans),
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : TextOverflow.clip,
    );
  }
}

BorderRadius _bubbleBorderRadius({
  required bool isOutgoing,
  required bool showTail,
  required double r,
}) {
  if (!showTail) return BorderRadius.circular(r);
  return BorderRadius.only(
    topLeft: Radius.circular(r),
    topRight: Radius.circular(r),
    bottomLeft: isOutgoing ? Radius.circular(r) : Radius.zero,
    bottomRight: isOutgoing ? Radius.zero : Radius.circular(r),
  );
}

double _timestampReservedWidth(
  String timestamp,
  TextStyle tsStyle,
  bool isOutgoing,
  bool showDeliveryStatus,
) {
  final painter = TextPainter(
    text: TextSpan(text: timestamp, style: tsStyle),
    textDirection: TextDirection.ltr,
  );
  try {
    painter.layout();
    final tsWidth = painter.width;
    final statusWidth = (showDeliveryStatus && isOutgoing)
        ? (_chatStatusGap.w + _chatStatusW.w)
        : 0.0;
    return _timestampMinPadding.w + tsWidth + statusWidth;
  } finally {
    painter.dispose();
  }
}

const _swipeReplyThreshold = 50.0;

class _SwipeableBubble extends HookWidget {
  const _SwipeableBubble({
    required this.child,
    required this.onSwipeReply,
  });

  final Widget child;
  final VoidCallback onSwipeReply;

  @override
  Widget build(BuildContext context) {
    final dragDistance = useRef(0.0);
    final hasTriggered = useRef(false);

    void handleDragStart(DragStartDetails details) {
      dragDistance.value = 0;
      hasTriggered.value = false;
    }

    void handleDragUpdate(DragUpdateDetails details) {
      if (hasTriggered.value) return;
      if (details.delta.dx > 0) {
        dragDistance.value += details.delta.dx;
      }
      if (dragDistance.value >= _swipeReplyThreshold) {
        hasTriggered.value = true;
        onSwipeReply();
      }
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: handleDragStart,
      onHorizontalDragUpdate: handleDragUpdate,
      child: child,
    );
  }
}

class _BubbleContent extends StatelessWidget {
  const _BubbleContent({
    required this.bubbleColor,
    required this.borderRadius,
    required this.hasSenderName,
    required this.senderName,
    required this.senderNameColor,
    required this.replyContent,
    required this.mediaContent,
    required this.hasText,
    required this.hasTimestamp,
    required this.content,
    this.highlightSpans,
    this.highlightColor,
    required this.timestamp,
    required this.textStyle,
    required this.tsStyle,
    required this.isOutgoing,
    required this.hasReactions,
    required this.reactions,
    required this.reactionType,
    required this.currentUserPubkey,
    required this.onReaction,
    required this.showDeliveryStatus,
    this.deliveryStatus,
    this.onStatusTap,
    this.contentMaxLines,
  });

  final Color bubbleColor;
  final BorderRadius borderRadius;
  final bool hasSenderName;
  final String? senderName;
  final Color? senderNameColor;
  final Widget? replyContent;
  final Widget? mediaContent;
  final bool hasText;
  final bool hasTimestamp;
  final String? content;
  final List<HighlightSpan>? highlightSpans;
  final Color? highlightColor;
  final String? timestamp;
  final TextStyle textStyle;
  final TextStyle tsStyle;
  final bool isOutgoing;
  final bool hasReactions;
  final List<EmojiReaction> reactions;
  final WnReactionType reactionType;
  final String? currentUserPubkey;
  final void Function(String emoji)? onReaction;
  final bool showDeliveryStatus;
  final ChatStatusType? deliveryStatus;
  final VoidCallback? onStatusTap;
  final int? contentMaxLines;

  Widget _buildTimestampRow() {
    Widget row = Row(
      key: const Key('message_status_row'),
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(timestamp!, style: tsStyle),
        if (showDeliveryStatus && isOutgoing) ...[
          SizedBox(width: _chatStatusGap.w),
          WnChatStatus(status: deliveryStatus ?? ChatStatusType.sending),
        ],
      ],
    );
    if (onStatusTap != null) {
      row = GestureDetector(
        key: const Key('status_tap_area'),
        behavior: HitTestBehavior.opaque,
        onTap: onStatusTap,
        child: row,
      );
    }
    return row;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final padding = EdgeInsets.only(
      left: 10.w,
      right: 10.w,
      top: 10.h,
      bottom: 12.h,
    );

    return Container(
      padding: padding,
      decoration: BoxDecoration(color: bubbleColor, borderRadius: borderRadius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasSenderName) ...[
            Text(
              senderName!,
              style: context.typographyScaled.semiBold12.copyWith(
                color: senderNameColor ?? colors.backgroundContentTertiary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 8.h),
          ],
          if (replyContent != null) ...[replyContent!, SizedBox(height: 8.h)],
          if (mediaContent != null) ...[
            mediaContent!,
            if (hasText || hasTimestamp) SizedBox(height: 8.h),
          ],
          if (hasText && hasTimestamp)
            _TextWithTimestamp(
              content: content!,
              timestamp: timestamp!,
              textStyle: textStyle,
              tsStyle: tsStyle,
              isOutgoing: isOutgoing,
              showDeliveryStatus: showDeliveryStatus,
              highlightSpans: highlightSpans,
              highlightColor: highlightColor,
              deliveryStatus: deliveryStatus,
              onStatusTap: onStatusTap,
              maxLines: contentMaxLines,
            )
          else if (hasText)
            _MessageText(
              content: content!,
              textStyle: textStyle,
              highlightSpans: highlightSpans,
              highlightColor: highlightColor,
              maxLines: contentMaxLines,
            )
          else if (hasTimestamp) ...[
            SizedBox(height: 2.h),
            _buildTimestampRow(),
          ],
          if (hasReactions) ...[
            SizedBox(height: 8.h),
            Wrap(
              spacing: 4.w,
              runSpacing: 4.h,
              children: [
                for (final reaction in reactions)
                  WnReaction(
                    key: ValueKey(reaction.emoji),
                    emoji: reaction.emoji,
                    count: reaction.count.toInt(),
                    type: reactionType,
                    isSelected: reaction.users.contains(currentUserPubkey),
                    onTap: onReaction != null ? () => onReaction!(reaction.emoji) : null,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _BubbleInner extends StatelessWidget {
  const _BubbleInner({
    required this.onHorizontalDragEnd,
    required this.onLongPress,
    required this.bubbleContent,
    required this.showTail,
    required this.isOutgoing,
    required this.tailOverhang,
    required this.tailW,
    required this.tailH,
    required this.bubbleColor,
  });

  final VoidCallback? onHorizontalDragEnd;
  final VoidCallback? onLongPress;
  final Widget bubbleContent;
  final bool showTail;
  final bool isOutgoing;
  final double tailOverhang;
  final double tailW;
  final double tailH;
  final Color bubbleColor;

  @override
  Widget build(BuildContext context) {
    Widget child = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: onLongPress,
      child: bubbleContent,
    );
    if (onHorizontalDragEnd != null) {
      child = _SwipeableBubble(onSwipeReply: onHorizontalDragEnd!, child: child);
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (showTail)
          Positioned(
            bottom: 0,
            left: isOutgoing ? null : -tailOverhang,
            right: isOutgoing ? -tailOverhang : null,
            child: CustomPaint(
              size: Size(tailW, tailH),
              painter: _BubbleTailPainter(color: bubbleColor, incoming: !isOutgoing),
            ),
          ),
      ],
    );
  }
}

class _DeletedBubbleBorder extends ShapeBorder {
  final bool isOutgoing;
  final bool showTail;
  final double radius;
  final double tailH;
  final double tailOverhang;
  final BorderSide side;

  const _DeletedBubbleBorder({
    required this.isOutgoing,
    required this.showTail,
    required this.radius,
    required this.tailH,
    required this.tailOverhang,
    this.side = BorderSide.none,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return _getPath(rect.deflate(side.width));
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return _getPath(rect);
  }

  Path _getPath(Rect rect) {
    final r = radius;
    final innerRect = EdgeInsets.only(
      left: showTail && !isOutgoing ? tailOverhang : 0,
      right: showTail && isOutgoing ? tailOverhang : 0,
    ).deflateRect(rect);

    final path = Path();
    if (showTail) {
      if (isOutgoing) {
        path.moveTo(innerRect.left + r, innerRect.top);
        path.lineTo(innerRect.right - r, innerRect.top);
        path.arcToPoint(Offset(innerRect.right, innerRect.top + r), radius: Radius.circular(r));
        path.lineTo(innerRect.right, innerRect.bottom - tailH);

        path.lineTo(innerRect.right + tailOverhang, innerRect.bottom);
        path.lineTo(innerRect.left + r, innerRect.bottom);

        path.arcToPoint(Offset(innerRect.left, innerRect.bottom - r), radius: Radius.circular(r));
        path.lineTo(innerRect.left, innerRect.top + r);
        path.arcToPoint(Offset(innerRect.left + r, innerRect.top), radius: Radius.circular(r));
      } else {
        path.moveTo(innerRect.right - r, innerRect.top);
        path.lineTo(innerRect.left + r, innerRect.top);
        path.arcToPoint(
          Offset(innerRect.left, innerRect.top + r),
          radius: Radius.circular(r),
          clockwise: false,
        );
        path.lineTo(innerRect.left, innerRect.bottom - tailH);

        path.lineTo(innerRect.left - tailOverhang, innerRect.bottom);
        path.lineTo(innerRect.right - r, innerRect.bottom);

        path.arcToPoint(
          Offset(innerRect.right, innerRect.bottom - r),
          radius: Radius.circular(r),
          clockwise: false,
        );
        path.lineTo(innerRect.right, innerRect.top + r);
        path.arcToPoint(
          Offset(innerRect.right - r, innerRect.top),
          radius: Radius.circular(r),
          clockwise: false,
        );
      }
      path.close();
      return path;
    } else {
      path.addRRect(RRect.fromRectAndRadius(innerRect, Radius.circular(r)));
      return path;
    }
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none) return;

    final paint = side.toPaint();
    final path = _getPath(rect.deflate(side.width / 2));
    canvas.drawPath(path, paint);
  }

  @override
  ShapeBorder scale(double t) {
    return _DeletedBubbleBorder(
      isOutgoing: isOutgoing,
      showTail: showTail,
      radius: radius * t,
      tailH: tailH * t,
      tailOverhang: tailOverhang * t,
      side: side.scale(t),
    );
  }
}

class WnMessageBubble extends StatelessWidget {
  final MessageDirection direction;
  final bool isDeleted;
  final String? deletedLabel;
  final bool showTail;
  final String? content;
  final List<HighlightSpan>? highlightSpans;
  final Widget? mediaContent;
  final Widget? replyContent;
  final String? timestamp;
  final List<EmojiReaction> reactions;
  final String? currentUserPubkey;
  final Widget? avatar;
  final String? senderName;
  final Color? senderNameColor;
  final BubbleLeadingVariant leadingVariant;
  final ChatStatusType? deliveryStatus;
  final VoidCallback? onLongPress;
  final void Function(String emoji)? onReaction;
  final VoidCallback? onHorizontalDragEnd;
  final VoidCallback? onStatusTap;
  final int? contentMaxLines;
  final double bubbleWidthFactor;
  final bool forceTightHeight;

  const WnMessageBubble({
    super.key,
    required this.direction,
    required this.isDeleted,
    this.deletedLabel,
    this.showTail = false,
    this.content,
    this.highlightSpans,
    this.mediaContent,
    this.replyContent,
    this.timestamp,
    this.reactions = const [],
    this.currentUserPubkey,
    this.avatar,
    this.senderName,
    this.senderNameColor,
    this.leadingVariant = BubbleLeadingVariant.none,
    this.deliveryStatus,
    this.onLongPress,
    this.onReaction,
    this.onHorizontalDragEnd,
    this.onStatusTap,
    this.contentMaxLines,
    this.bubbleWidthFactor = 0.8,
    this.forceTightHeight = false,
  });

  bool get _isOutgoing => direction == MessageDirection.outgoing;

  static Widget _wrapBubbleInner({required bool useIntrinsicWidth, required Widget child}) {
    if (!useIntrinsicWidth) return child;
    return IntrinsicWidth(child: child);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bubbleColor = isDeleted
        ? Colors.transparent
        : _isOutgoing
        ? colors.fillPrimary
        : colors.backgroundMessageIncoming;
    final textColor = isDeleted || !_isOutgoing
        ? colors.backgroundContentPrimary
        : colors.fillContentPrimary;
    final timestampColor = colors.backgroundContentTertiary;

    final hasAvatar = !_isOutgoing && avatar != null;
    final avatarColW = hasAvatar ? 44.w : 0.0;
    final leadingIndent = switch (leadingVariant) {
      BubbleLeadingVariant.none => 0.0,
      BubbleLeadingVariant.tail => _tailOverhang.w,
      BubbleLeadingVariant.avatar => 44.w + _tailOverhang.w,
    };

    final tailW = _tailW.w;
    final tailH = _tailH.h;
    final tailOverhang = _tailOverhang.w;
    final radius = 8.r;

    final actualContent = isDeleted ? deletedLabel : content;
    final hasText = actualContent != null && actualContent.isNotEmpty;
    final actualMediaContent = isDeleted ? null : mediaContent;
    final actualReplyContent = isDeleted ? null : replyContent;
    final actualReactions = isDeleted ? <EmojiReaction>[] : reactions;
    final actualTimestamp = isDeleted ? (showTail ? timestamp : null) : timestamp;
    final actualDeliveryStatus = isDeleted ? null : deliveryStatus;

    final hasTimestamp = actualTimestamp != null;
    final hasReactions = actualReactions.isNotEmpty;
    final hasSenderName = !_isOutgoing && senderName != null && senderName!.isNotEmpty;

    final reactionType = _isOutgoing ? WnReactionType.outgoing : WnReactionType.incoming;
    final textStyle = context.typographyScaled.medium16Compact.copyWith(color: textColor);
    final tsStyle = context.typographyScaled.medium12.copyWith(color: timestampColor);

    final highlightColor = highlightSpans != null ? colors.intentionInfoContent : null;

    final bubbleContent = _BubbleContent(
      bubbleColor: bubbleColor,
      borderRadius: _bubbleBorderRadius(
        isOutgoing: _isOutgoing,
        showTail: showTail,
        r: radius,
      ),
      hasSenderName: hasSenderName,
      senderName: senderName,
      senderNameColor: senderNameColor,
      replyContent: actualReplyContent,
      mediaContent: actualMediaContent,
      hasText: hasText,
      hasTimestamp: hasTimestamp,
      content: actualContent,
      highlightSpans: highlightSpans,
      highlightColor: highlightColor,
      timestamp: actualTimestamp,
      textStyle: textStyle,
      tsStyle: tsStyle,
      isOutgoing: _isOutgoing,
      hasReactions: hasReactions,
      reactions: actualReactions,
      reactionType: reactionType,
      currentUserPubkey: currentUserPubkey,
      onReaction: onReaction,
      showDeliveryStatus: !isDeleted,
      deliveryStatus: actualDeliveryStatus,
      onStatusTap: isDeleted ? null : onStatusTap,
      contentMaxLines: contentMaxLines,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final bottomMargin = showTail ? 12.h : 4.h;

        final baseMaxBubbleWidth =
            (constraints.maxWidth - avatarColW - leadingIndent) * bubbleWidthFactor;
        final maxBubbleWidth = _isOutgoing && !showTail
            ? baseMaxBubbleWidth - tailOverhang
            : baseMaxBubbleWidth;
        final bubble = Align(
          alignment: _isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
          heightFactor: (forceTightHeight || contentMaxLines != null) ? 1 : null,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxBubbleWidth),
            child: isDeleted
                ? Container(
                    key: const Key('deleted_bubble_border'),
                    padding: EdgeInsets.only(
                      left: showTail && !_isOutgoing ? tailOverhang : 0,
                      right: _isOutgoing && showTail ? tailOverhang : 0,
                    ),
                    decoration: ShapeDecoration(
                      shape: _DeletedBubbleBorder(
                        isOutgoing: _isOutgoing,
                        showTail: showTail,
                        radius: radius,
                        tailH: tailH,
                        tailOverhang: tailOverhang,
                        side: BorderSide(color: colors.borderPrimary),
                      ),
                    ),
                    child: _wrapBubbleInner(
                      useIntrinsicWidth: actualMediaContent == null && contentMaxLines == null,
                      child: bubbleContent,
                    ),
                  )
                : Padding(
                    key: const Key('bubble_tail_padding'),
                    padding: EdgeInsets.only(
                      left: showTail && !_isOutgoing ? tailOverhang : 0,
                      right: _isOutgoing && showTail ? tailOverhang : 0,
                    ),
                    child: _wrapBubbleInner(
                      useIntrinsicWidth: mediaContent == null && contentMaxLines == null,
                      child: _BubbleInner(
                        onHorizontalDragEnd: onHorizontalDragEnd,
                        onLongPress: onLongPress,
                        bubbleContent: bubbleContent,
                        showTail: showTail,
                        isOutgoing: _isOutgoing,
                        tailOverhang: tailOverhang,
                        tailW: tailW,
                        tailH: tailH,
                        bubbleColor: bubbleColor,
                      ),
                    ),
                  ),
          ),
        );

        if (!hasAvatar) {
          final trailingIndent = _isOutgoing && !showTail ? tailOverhang : 0.0;
          return Padding(
            key: const Key('bubble_outer_padding'),
            padding: EdgeInsets.only(
              left: leadingIndent,
              right: trailingIndent,
              bottom: bottomMargin,
            ),
            child: bubble,
          );
        }

        return Padding(
          padding: EdgeInsets.only(bottom: bottomMargin),
          child: Row(
            key: const Key('bubble_avatar_row'),
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 36.w, child: avatar),
              SizedBox(width: 8.w),
              Flexible(child: bubble),
            ],
          ),
        );
      },
    );
  }
}
