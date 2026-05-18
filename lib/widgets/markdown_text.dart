import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/src/rust/api/markdown.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/utils/avatar_color.dart';
import 'package:whitenoise/utils/encoding.dart' show hexFromNpub;

const Set<String> _safeUrlSchemes = {
  'http',
  'https',
  'mailto',
  'nostr',
  'tel',
  'whitenoise',
  'whitenoise-staging',
};

bool isSafeMarkdownUrl(String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null || !uri.hasScheme) {
    return false;
  }
  return _safeUrlSchemes.contains(uri.scheme.toLowerCase());
}

bool isPlainTextDocument(MarkdownDocument document) {
  if (document.blocks.length != 1) return false;
  final block = document.blocks.first;
  if (block is! MarkdownBlock_Paragraph) return false;
  return block.inlines.every(
    (inline) =>
        inline is MarkdownInline_Text ||
        inline is MarkdownInline_SoftBreak ||
        inline is MarkdownInline_HardBreak,
  );
}

class MarkdownText extends HookWidget {
  const MarkdownText({
    super.key,
    required this.document,
    required this.baseStyle,
    this.onLinkTap,
    this.onNostrTap,
    this.mentionDisplayName,
    this.highlightQueries = const [],
    this.highlightColor,
    this.maxLines,
    this.softWrap = true,
  });

  final MarkdownDocument document;
  final TextStyle baseStyle;
  final void Function(String url)? onLinkTap;
  final void Function(MarkdownNostrHrp hrp, String bech32)? onNostrTap;

  /// Resolves a hex pubkey to a display name. Called for npub mentions/URIs.
  /// Return `null` if unknown — renderer falls back to truncated npub.
  final String? Function(String hexPubkey)? mentionDisplayName;
  final List<String> highlightQueries;
  final Color? highlightColor;
  final int? maxLines;
  final bool softWrap;

  @override
  Widget build(BuildContext context) {
    final recognizers = useRef<List<TapGestureRecognizer>>([]);
    useEffect(() {
      return () {
        for (final r in recognizers.value) {
          r.dispose();
        }
      };
    }, const []);

    for (final r in recognizers.value) {
      r.dispose();
    }
    recognizers.value = [];

    final renderer = _MarkdownRenderer(
      context: context,
      baseStyle: baseStyle,
      onLinkTap: onLinkTap,
      onNostrTap: onNostrTap,
      mentionDisplayName: mentionDisplayName,
      highlightQueries: highlightQueries,
      highlightColor: highlightColor ?? Colors.yellow,
      registerRecognizer: (r) => recognizers.value.add(r),
    );

    final blocks = document.blocks;
    if (blocks.isEmpty) {
      return const SizedBox.shrink();
    }
    if (blocks.length == 1 && blocks.first is MarkdownBlock_Paragraph) {
      final paragraph = blocks.first as MarkdownBlock_Paragraph;
      return Text.rich(
        renderer.buildInlineSpan(paragraph.inlines, baseStyle),
        style: baseStyle,
        maxLines: maxLines,
        overflow: maxLines != null ? TextOverflow.ellipsis : TextOverflow.clip,
        softWrap: softWrap,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: _withBlockGaps(blocks.map(renderer.buildBlock).toList()),
    );
  }

  static List<Widget> _withBlockGaps(List<Widget> blocks) {
    if (blocks.length <= 1) return blocks;
    final result = <Widget>[];
    for (var i = 0; i < blocks.length; i++) {
      if (i > 0) result.add(SizedBox(height: 8.h));
      result.add(blocks[i]);
    }
    return result;
  }
}

class _MarkdownRenderer {
  _MarkdownRenderer({
    required this.context,
    required this.baseStyle,
    required this.onLinkTap,
    required this.onNostrTap,
    required this.mentionDisplayName,
    required this.highlightQueries,
    required this.highlightColor,
    required this.registerRecognizer,
  });

  final BuildContext context;
  final TextStyle baseStyle;
  final void Function(String url)? onLinkTap;
  final void Function(MarkdownNostrHrp hrp, String bech32)? onNostrTap;
  final String? Function(String hexPubkey)? mentionDisplayName;
  final List<String> highlightQueries;
  final Color highlightColor;
  final void Function(TapGestureRecognizer) registerRecognizer;

  TextStyle get _codeStyleNoBackground => baseStyle.copyWith(
    fontFamily: 'monospace',
    fontFamilyFallback: const ['Courier'],
  );

  TextStyle get _codeStyle => _codeStyleNoBackground.copyWith(
    backgroundColor: context.colors.backgroundContentSecondary,
  );

  TextStyle get _linkStyle => baseStyle.copyWith(
    color: context.colors.intentionInfoContent,
    decoration: TextDecoration.underline,
    decorationColor: context.colors.intentionInfoContent,
  );

  Widget buildBlock(MarkdownBlock block) {
    switch (block) {
      case MarkdownBlock_Paragraph(:final inlines):
        return Text.rich(buildInlineSpan(inlines, baseStyle), style: baseStyle);
      case MarkdownBlock_Heading(:final level, :final inlines):
        final headingStyle = _headingStyleFor(level);
        return Padding(
          padding: EdgeInsets.only(top: level == 1 ? 4.h : 2.h, bottom: 2.h),
          child: Text.rich(buildInlineSpan(inlines, headingStyle), style: headingStyle),
        );
      case MarkdownBlock_ThematicBreak():
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 4.h),
          child: Divider(
            color: context.colors.borderTertiary,
            thickness: 1,
            height: 1,
          ),
        );
      case MarkdownBlock_CodeBlock(:final content):
        return _buildCodeBlock(content);
      case MarkdownBlock_BlockQuote(:final blocks):
        return _buildBlockQuote(blocks);
      case MarkdownBlock_List(:final kind, :final items, :final tight):
        return _buildList(kind, items, tight: tight);
      case MarkdownBlock_Table(:final alignments, :final header, :final rows):
        return _buildTable(alignments, header, rows);
      case MarkdownBlock_MathBlock(:final content):
        return _buildMathBlock(content);
    }
  }

  TextStyle _headingStyleFor(int level) {
    final base = baseStyle.fontSize ?? 14.sp;
    final size = switch (level) {
      1 => base + 8.sp,
      2 => base + 6.sp,
      3 => base + 4.sp,
      4 => base + 2.sp,
      _ => base,
    };
    return baseStyle.copyWith(fontSize: size, fontWeight: FontWeight.w700);
  }

  Widget _buildCodeBlock(String content) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: context.colors.backgroundContentSecondary,
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Text(content, style: _codeStyleNoBackground),
      ),
    );
  }

  Widget _buildMathBlock(String content) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: context.colors.backgroundContentSecondary,
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        content,
        style: _codeStyleNoBackground.copyWith(fontStyle: FontStyle.italic),
      ),
    );
  }

  Widget _buildBlockQuote(List<MarkdownBlock> blocks) {
    return Container(
      padding: EdgeInsets.only(left: 8.w),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: context.colors.borderTertiary, width: 3.w),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: MarkdownText._withBlockGaps(blocks.map(buildBlock).toList()),
      ),
    );
  }

  Widget _buildList(
    MarkdownListKind kind,
    List<MarkdownListItem> items, {
    required bool tight,
  }) {
    final rows = <Widget>[];
    final itemGap = tight ? 2.h : 8.h;
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final markerWidget = _listMarker(kind, i, item.checked);
      final itemBlocks = item.blocks.isEmpty
          ? <Widget>[Text('', style: baseStyle)]
          : item.blocks.map(buildBlock).toList();
      rows.add(
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : itemGap),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 20.w, child: markerWidget),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: MarkdownText._withBlockGaps(itemBlocks),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: rows,
    );
  }

  Widget _listMarker(MarkdownListKind kind, int index, bool? checked) {
    if (checked != null) {
      return Padding(
        padding: EdgeInsets.only(top: 2.h),
        child: Icon(
          checked ? Icons.check_box : Icons.check_box_outline_blank,
          key: Key(checked ? 'check_box' : 'check_box_outline_blank'),
          size: (baseStyle.fontSize ?? 14.sp) + 2.sp,
          color: baseStyle.color,
        ),
      );
    }
    switch (kind) {
      case MarkdownListKind_Bullet():
        return Text('•', style: baseStyle);
      case MarkdownListKind_Ordered(:final start, :final delimiter):
        return Text('${start + index}$delimiter', style: baseStyle);
    }
  }

  Widget _buildTable(
    List<MarkdownAlignment> alignments,
    List<MarkdownTableCell> header,
    List<List<MarkdownTableCell>> rows,
  ) {
    Alignment alignmentFor(int col) {
      if (col >= alignments.length) return Alignment.centerLeft;
      return switch (alignments[col]) {
        MarkdownAlignment.right => Alignment.centerRight,
        MarkdownAlignment.center => Alignment.center,
        MarkdownAlignment.left || MarkdownAlignment.none => Alignment.centerLeft,
      };
    }

    Widget cellFor(MarkdownTableCell cell, int col, {required bool isHeader}) {
      final style = isHeader ? baseStyle.copyWith(fontWeight: FontWeight.w700) : baseStyle;
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
        alignment: alignmentFor(col),
        child: Text.rich(buildInlineSpan(cell.inlines, style), style: style),
      );
    }

    final colCount = [
      header.length,
      ...rows.map((r) => r.length),
    ].fold<int>(0, (a, b) => a > b ? a : b);
    if (colCount == 0) return const SizedBox.shrink();

    final tableRows = <TableRow>[
      TableRow(
        decoration: BoxDecoration(color: context.colors.backgroundContentSecondary),
        children: [
          for (var c = 0; c < colCount; c++)
            cellFor(
              c < header.length ? header[c] : const MarkdownTableCell(inlines: []),
              c,
              isHeader: true,
            ),
        ],
      ),
      for (final row in rows)
        TableRow(
          children: [
            for (var c = 0; c < colCount; c++)
              cellFor(
                c < row.length ? row[c] : const MarkdownTableCell(inlines: []),
                c,
                isHeader: false,
              ),
          ],
        ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        defaultColumnWidth: const IntrinsicColumnWidth(),
        border: TableBorder.all(color: context.colors.borderTertiary),
        children: tableRows,
      ),
    );
  }

  TextSpan buildInlineSpan(List<MarkdownInline> inlines, TextStyle style) {
    return TextSpan(
      children: [for (final inline in inlines) _buildInline(inline, style)],
    );
  }

  InlineSpan _buildInline(MarkdownInline inline, TextStyle style) {
    switch (inline) {
      case MarkdownInline_Text(:final content):
        return _highlightedTextSpan(content, style);
      case MarkdownInline_SoftBreak():
      case MarkdownInline_HardBreak():
        return TextSpan(text: '\n', style: style);
      case MarkdownInline_Code(:final content):
        return TextSpan(text: content, style: _codeStyle.merge(style));
      case MarkdownInline_Emph(:final children):
        return buildInlineSpan(
          children,
          style.copyWith(fontStyle: FontStyle.italic),
        );
      case MarkdownInline_Strong(:final children):
        return buildInlineSpan(
          children,
          style.copyWith(fontWeight: FontWeight.w700),
        );
      case MarkdownInline_Strikethrough(:final children):
        return buildInlineSpan(
          children,
          style.copyWith(
            decoration: TextDecoration.lineThrough,
            decorationColor: style.color,
            decorationThickness: 2.0,
          ),
        );
      case MarkdownInline_Link(:final dest, :final children):
        return TextSpan(
          children: [buildInlineSpan(children, _linkStyle)],
          recognizer: _linkRecognizer(dest),
        );
      case MarkdownInline_Image(:final dest, :final alt):
        final altText = _flattenInlines(alt);
        final label = altText.isEmpty ? 'image' : altText;
        return TextSpan(
          text: '[image: $label]',
          style: _linkStyle.copyWith(fontStyle: FontStyle.italic),
          recognizer: _linkRecognizer(dest),
        );
      case MarkdownInline_Autolink(:final url, :final kind):
        final dest = kind == MarkdownAutolinkKind.email ? 'mailto:$url' : url;
        return TextSpan(
          text: url,
          style: _linkStyle,
          recognizer: _linkRecognizer(dest),
        );
      case MarkdownInline_Math(:final content):
        return TextSpan(
          text: content,
          style: _codeStyle.merge(style.copyWith(fontStyle: FontStyle.italic)),
        );
      case MarkdownInline_NostrMention(:final entity):
      case MarkdownInline_NostrUri(:final entity):
        if (entity.hrp == MarkdownNostrHrp.npub) {
          final hex = hexFromNpub(entity.bech32);
          return TextSpan(
            text: _resolveMentionLabel(entity.bech32, hex),
            style: _mentionStyle(style, hex),
            recognizer: _nostrRecognizer(entity.hrp, entity.bech32),
          );
        }
        return TextSpan(
          text: _formatNostrLabel(entity),
          style: _linkStyle,
          recognizer: _nostrRecognizer(entity.hrp, entity.bech32),
        );
    }
  }

  TextSpan _highlightedTextSpan(String text, TextStyle style) {
    if (highlightQueries.isEmpty || text.isEmpty) {
      return TextSpan(text: text, style: style);
    }
    final matches = <_HighlightMatch>[];
    final lowerText = text.toLowerCase();
    for (final query in highlightQueries) {
      if (query.isEmpty) continue;
      final lowerQuery = query.toLowerCase();
      var from = 0;
      while (true) {
        final idx = lowerText.indexOf(lowerQuery, from);
        if (idx < 0) break;
        matches.add(_HighlightMatch(idx, idx + lowerQuery.length));
        from = idx + lowerQuery.length;
      }
    }
    if (matches.isEmpty) {
      return TextSpan(text: text, style: style);
    }
    matches.sort((a, b) => a.start.compareTo(b.start));
    final merged = <_HighlightMatch>[];
    for (final m in matches) {
      if (merged.isNotEmpty && m.start <= merged.last.end) {
        if (m.end > merged.last.end) {
          merged[merged.length - 1] = _HighlightMatch(merged.last.start, m.end);
        }
      } else {
        merged.add(m);
      }
    }
    final highlightStyle = style.copyWith(backgroundColor: highlightColor);
    final children = <TextSpan>[];
    var cursor = 0;
    for (final m in merged) {
      if (m.start > cursor) {
        children.add(TextSpan(text: text.substring(cursor, m.start), style: style));
      }
      children.add(TextSpan(text: text.substring(m.start, m.end), style: highlightStyle));
      cursor = m.end;
    }
    if (cursor < text.length) {
      children.add(TextSpan(text: text.substring(cursor), style: style));
    }
    return TextSpan(children: children);
  }

  String _formatNostrLabel(MarkdownNostrEntity entity) {
    final b32 = entity.bech32;
    if (b32.length > 16) {
      return '${b32.substring(0, 12)}…${b32.substring(b32.length - 4)}';
    }
    return b32;
  }

  /// Renders the display name for an npub mention.
  /// Looks up via [mentionDisplayName]; if unresolved, falls back to a
  /// truncated bech32 ('npub1abcdefgh…wxyz'). No '@' prefix per design.
  String _resolveMentionLabel(String bech32, String? hex) {
    final lookup = mentionDisplayName;
    if (lookup != null && hex != null) {
      final name = lookup(hex);
      if (name != null && name.isNotEmpty) {
        return name;
      }
    }
    if (bech32.length > 16) {
      return '${bech32.substring(0, 12)}…${bech32.substring(bech32.length - 4)}';
    }
    return bech32;
  }

  /// Style for an npub mention: bold, in the user's per-pubkey color.
  /// Same palette as the bubble's sender-name color. When the hex pubkey
  /// can't be derived, falls back to the surrounding text color so the
  /// mention is still bold but doesn't pretend to identify someone.
  TextStyle _mentionStyle(TextStyle style, String? hex) {
    final color = hex != null
        ? AvatarColor.fromPubkey(hex).toColorSet(context.colors).content
        : style.color;
    return style.copyWith(color: color, fontWeight: FontWeight.w700);
  }

  String _flattenInlines(List<MarkdownInline> inlines) {
    final buffer = StringBuffer();
    for (final inline in inlines) {
      switch (inline) {
        case MarkdownInline_Text(:final content):
          buffer.write(content);
        case MarkdownInline_Code(:final content):
          buffer.write(content);
        case MarkdownInline_Math(:final content):
          buffer.write(content);
        case MarkdownInline_SoftBreak():
        case MarkdownInline_HardBreak():
          buffer.write(' ');
        case MarkdownInline_Emph(:final children):
        case MarkdownInline_Strong(:final children):
        case MarkdownInline_Strikethrough(:final children):
          buffer.write(_flattenInlines(children));
        case MarkdownInline_Link(:final children):
          buffer.write(_flattenInlines(children));
        case MarkdownInline_Image(:final alt):
          buffer.write(_flattenInlines(alt));
        case MarkdownInline_Autolink(:final url):
          buffer.write(url);
        case MarkdownInline_NostrMention(:final entity):
        case MarkdownInline_NostrUri(:final entity):
          buffer.write(entity.bech32);
      }
    }
    return buffer.toString();
  }

  TapGestureRecognizer? _linkRecognizer(String dest) {
    if (!isSafeMarkdownUrl(dest)) return null;
    final handler = onLinkTap;
    if (handler == null) return null;
    final recognizer = TapGestureRecognizer()..onTap = () => handler(dest);
    registerRecognizer(recognizer);
    return recognizer;
  }

  TapGestureRecognizer? _nostrRecognizer(MarkdownNostrHrp hrp, String bech32) {
    final handler = onNostrTap;
    if (handler == null) return null;
    final recognizer = TapGestureRecognizer()..onTap = () => handler(hrp, bech32);
    registerRecognizer(recognizer);
    return recognizer;
  }
}

class _HighlightMatch {
  const _HighlightMatch(this.start, this.end);
  final int start;
  final int end;
}
