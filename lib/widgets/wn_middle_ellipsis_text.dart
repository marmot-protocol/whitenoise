import 'package:flutter/material.dart';

const _ellipsis = ' ... ';

class WnMiddleEllipsisText extends StatelessWidget {
  const WnMiddleEllipsisText({
    super.key,
    required this.text,
    this.style,
    this.maxLines = 1,
    this.suffixLength = 8,
    this.snapToWords = false,
  }) : assert(suffixLength >= 0);

  final String text;
  final TextStyle? style;
  final int maxLines;
  final int suffixLength;
  final bool snapToWords;

  bool _fitsInMaxLines(
    String candidate,
    double maxWidth,
    TextStyle effectiveStyle,
    TextScaler textScaler,
    TextDirection textDirection,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: candidate, style: effectiveStyle),
      maxLines: maxLines,
      textDirection: textDirection,
      textScaler: textScaler,
    );
    try {
      painter.layout(maxWidth: maxWidth);
      return !painter.didExceedMaxLines;
    } finally {
      painter.dispose();
    }
  }

  String _computeDisplayText(
    double maxWidth,
    TextStyle effectiveStyle,
    TextScaler textScaler,
    TextDirection textDirection,
  ) {
    if (_fitsInMaxLines(text, maxWidth, effectiveStyle, textScaler, textDirection)) return text;

    final effectiveSuffixLength = suffixLength.clamp(0, text.length);
    final suffix = text.length > effectiveSuffixLength
        ? text.substring(text.length - effectiveSuffixLength)
        : '';

    final maxPrefixLength = text.length - effectiveSuffixLength;
    if (maxPrefixLength <= 0) return '$_ellipsis$suffix';

    var low = 0;
    var high = maxPrefixLength;
    var bestPrefix = '';

    while (low <= high) {
      final mid = (low + high) ~/ 2;
      final prefix = mid > 0 ? text.substring(0, mid) : '';
      final candidate = '$prefix$_ellipsis$suffix';

      if (_fitsInMaxLines(candidate, maxWidth, effectiveStyle, textScaler, textDirection)) {
        bestPrefix = prefix;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    if (snapToWords && bestPrefix.isNotEmpty) {
      final nextCharIsSpace = bestPrefix.length < text.length && text[bestPrefix.length] == ' ';
      final endsWithSpace = bestPrefix.endsWith(' ');

      if (!endsWithSpace && !nextCharIsSpace) {
        final lastSpaceIndex = bestPrefix.lastIndexOf(' ');
        if (lastSpaceIndex != -1) {
          bestPrefix = bestPrefix.substring(0, lastSpaceIndex + 1);
        }
      }
    }

    return bestPrefix.isEmpty ? '$_ellipsis$suffix' : '$bestPrefix$_ellipsis$suffix';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final effectiveStyle = style != null
            ? DefaultTextStyle.of(context).style.merge(style)
            : DefaultTextStyle.of(context).style;
        final textScaler = MediaQuery.textScalerOf(context);
        final textDirection = Directionality.of(context);
        final displayText = _computeDisplayText(
          maxWidth,
          effectiveStyle,
          textScaler,
          textDirection,
        );
        return Text(
          displayText,
          style: style,
          maxLines: maxLines,
        );
      },
    );
  }
}
