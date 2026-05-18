import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/src/rust/api/markdown.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/widgets/markdown_text.dart';

import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

const _baseStyle = TextStyle(fontSize: 14, color: Colors.black);

MarkdownDocument _doc(List<MarkdownBlock> blocks) => MarkdownDocument(blocks: blocks);

MarkdownBlock _paragraph(List<MarkdownInline> inlines) => MarkdownBlock.paragraph(inlines: inlines);

MarkdownInline _t(String s) => MarkdownInline.text(content: s);

Future<void> _pump(WidgetTester tester, Widget child) async {
  await mountWidget(child, tester);
  await tester.pump();
}

void main() {
  setUpAll(() => RustLib.initMock(api: MockWnApi()));

  group('isSafeMarkdownUrl', () {
    test('accepts http and https', () {
      expect(isSafeMarkdownUrl('http://example.com'), isTrue);
      expect(isSafeMarkdownUrl('https://example.com'), isTrue);
    });

    test('accepts mailto, nostr, tel', () {
      expect(isSafeMarkdownUrl('mailto:a@b.com'), isTrue);
      expect(isSafeMarkdownUrl('nostr:npub1abc'), isTrue);
      expect(isSafeMarkdownUrl('tel:+15555550100'), isTrue);
    });

    test('rejects javascript, data, file, vbscript', () {
      expect(isSafeMarkdownUrl('javascript:alert(1)'), isFalse);
      expect(isSafeMarkdownUrl('data:text/html,<script>'), isFalse);
      expect(isSafeMarkdownUrl('file:///etc/passwd'), isFalse);
      expect(isSafeMarkdownUrl('vbscript:msgbox'), isFalse);
    });

    test('rejects schemeless and empty', () {
      expect(isSafeMarkdownUrl(''), isFalse);
      expect(isSafeMarkdownUrl('example.com'), isFalse);
      expect(isSafeMarkdownUrl('  '), isFalse);
    });

    test('scheme matching is case-insensitive', () {
      expect(isSafeMarkdownUrl('HTTPS://example.com'), isTrue);
      expect(isSafeMarkdownUrl('NoStR:npub1abc'), isTrue);
    });
  });

  group('isPlainTextDocument', () {
    test('empty document is not plain text', () {
      expect(isPlainTextDocument(_doc([])), isFalse);
    });

    test('multi-block document is not plain text', () {
      expect(
        isPlainTextDocument(
          _doc([
            _paragraph([_t('a')]),
            _paragraph([_t('b')]),
          ]),
        ),
        isFalse,
      );
    });

    test('single paragraph of text + breaks is plain text', () {
      expect(
        isPlainTextDocument(
          _doc([
            _paragraph([
              _t('hello'),
              const MarkdownInline.softBreak(),
              _t('world'),
              const MarkdownInline.hardBreak(),
              _t('!'),
            ]),
          ]),
        ),
        isTrue,
      );
    });

    test('paragraph with strong is not plain text', () {
      expect(
        isPlainTextDocument(
          _doc([
            _paragraph([
              _t('hello '),
              MarkdownInline.strong(children: [_t('world')]),
            ]),
          ]),
        ),
        isFalse,
      );
    });

    test('single non-paragraph block is not plain text', () {
      expect(
        isPlainTextDocument(
          _doc([
            MarkdownBlock.heading(level: 1, inlines: [_t('h')]),
          ]),
        ),
        isFalse,
      );
    });
  });

  group('MarkdownText — empty/edge cases', () {
    testWidgets('empty document renders SizedBox.shrink', (tester) async {
      await _pump(
        tester,
        MarkdownText(document: _doc(const []), baseStyle: _baseStyle),
      );
      expect(find.byType(SizedBox), findsWidgets);
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('single-paragraph plain text uses Text.rich', (tester) async {
      await _pump(
        tester,
        MarkdownText(
          document: _doc([
            _paragraph([_t('hello')]),
          ]),
          baseStyle: _baseStyle,
        ),
      );
      expect(find.byType(Text), findsOneWidget);
      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('maxLines truncation in single-paragraph mode', (tester) async {
      await _pump(
        tester,
        MarkdownText(
          document: _doc([
            _paragraph([_t('line1\nline2\nline3\nline4')]),
          ]),
          baseStyle: _baseStyle,
          maxLines: 2,
        ),
      );
      final richText = tester.widget<Text>(find.byType(Text).first);
      expect(richText.maxLines, 2);
      expect(richText.overflow, TextOverflow.ellipsis);
    });
  });

  group('MarkdownText — inlines', () {
    testWidgets('soft break renders as newline (chat UX, not CommonMark default)', (tester) async {
      await _pump(
        tester,
        MarkdownText(
          document: _doc([
            _paragraph([_t('a'), const MarkdownInline.softBreak(), _t('b')]),
          ]),
          baseStyle: _baseStyle,
        ),
      );
      final spans = tester.widget<Text>(find.byType(Text).first).textSpan!;
      final flattened = spans.toPlainText();
      expect(flattened, 'a\nb');
    });

    testWidgets('hard break renders as newline', (tester) async {
      await _pump(
        tester,
        MarkdownText(
          document: _doc([
            _paragraph([_t('a'), const MarkdownInline.hardBreak(), _t('b')]),
          ]),
          baseStyle: _baseStyle,
        ),
      );
      final flattened = tester.widget<Text>(find.byType(Text).first).textSpan!.toPlainText();
      expect(flattened, 'a\nb');
    });

    testWidgets('strong applies bold', (tester) async {
      await _pump(
        tester,
        MarkdownText(
          document: _doc([
            _paragraph([
              MarkdownInline.strong(children: [_t('bold')]),
            ]),
          ]),
          baseStyle: _baseStyle,
        ),
      );
      final text = tester.widget<Text>(find.byType(Text).first);
      final span = text.textSpan! as TextSpan;
      final inner = (span.children!.first as TextSpan).children!.first as TextSpan;
      expect(inner.style?.fontWeight, FontWeight.w700);
    });

    testWidgets('emph applies italic', (tester) async {
      await _pump(
        tester,
        MarkdownText(
          document: _doc([
            _paragraph([
              MarkdownInline.emph(children: [_t('it')]),
            ]),
          ]),
          baseStyle: _baseStyle,
        ),
      );
      final span = tester.widget<Text>(find.byType(Text).first).textSpan! as TextSpan;
      final inner = (span.children!.first as TextSpan).children!.first as TextSpan;
      expect(inner.style?.fontStyle, FontStyle.italic);
    });

    testWidgets('strikethrough applies lineThrough', (tester) async {
      await _pump(
        tester,
        MarkdownText(
          document: _doc([
            _paragraph([
              MarkdownInline.strikethrough(children: [_t('s')]),
            ]),
          ]),
          baseStyle: _baseStyle,
        ),
      );
      final span = tester.widget<Text>(find.byType(Text).first).textSpan! as TextSpan;
      final inner = (span.children!.first as TextSpan).children!.first as TextSpan;
      expect(inner.style?.decoration, TextDecoration.lineThrough);
    });

    testWidgets('code inline uses monospace', (tester) async {
      await _pump(
        tester,
        MarkdownText(
          document: _doc([
            _paragraph([const MarkdownInline.code(content: 'x')]),
          ]),
          baseStyle: _baseStyle,
        ),
      );
      final span = tester.widget<Text>(find.byType(Text).first).textSpan! as TextSpan;
      final code = span.children!.first as TextSpan;
      expect(code.style?.fontFamily, 'monospace');
    });

    testWidgets('safe link gets a recognizer; calls onLinkTap', (tester) async {
      var tapped = '';
      await _pump(
        tester,
        MarkdownText(
          document: _doc([
            _paragraph([
              MarkdownInline.link(
                dest: 'https://example.com',
                children: [_t('link')],
              ),
            ]),
          ]),
          baseStyle: _baseStyle,
          onLinkTap: (url) => tapped = url,
        ),
      );
      final span = tester.widget<Text>(find.byType(Text).first).textSpan! as TextSpan;
      final link = span.children!.first as TextSpan;
      final recognizer = link.recognizer as TapGestureRecognizer;
      recognizer.onTap!();
      expect(tapped, 'https://example.com');
    });

    testWidgets('javascript: link gets no recognizer', (tester) async {
      var tapped = '';
      await _pump(
        tester,
        MarkdownText(
          document: _doc([
            _paragraph([
              MarkdownInline.link(
                dest: 'javascript:alert(1)',
                children: [_t('bad')],
              ),
            ]),
          ]),
          baseStyle: _baseStyle,
          onLinkTap: (url) => tapped = url,
        ),
      );
      final span = tester.widget<Text>(find.byType(Text).first).textSpan! as TextSpan;
      final link = span.children!.first as TextSpan;
      expect(link.recognizer, isNull);
      expect(tapped, '');
    });

    testWidgets('link without onLinkTap has no recognizer', (tester) async {
      await _pump(
        tester,
        MarkdownText(
          document: _doc([
            _paragraph([
              MarkdownInline.link(
                dest: 'https://example.com',
                children: [_t('link')],
              ),
            ]),
          ]),
          baseStyle: _baseStyle,
        ),
      );
      final span = tester.widget<Text>(find.byType(Text).first).textSpan! as TextSpan;
      final link = span.children!.first as TextSpan;
      expect(link.recognizer, isNull);
    });

    testWidgets('image renders as [image: alt] label', (tester) async {
      await _pump(
        tester,
        MarkdownText(
          document: _doc([
            _paragraph([
              MarkdownInline.image(
                dest: 'https://example.com/a.png',
                alt: [_t('cat')],
              ),
            ]),
          ]),
          baseStyle: _baseStyle,
          onLinkTap: (_) {},
        ),
      );
      final span = tester.widget<Text>(find.byType(Text).first).textSpan! as TextSpan;
      final imageSpan = span.children!.first as TextSpan;
      expect(imageSpan.text, '[image: cat]');
    });

    testWidgets('image with empty alt renders [image: image]', (tester) async {
      await _pump(
        tester,
        MarkdownText(
          document: _doc([
            _paragraph([
              const MarkdownInline.image(
                dest: 'https://example.com/a.png',
                alt: [],
              ),
            ]),
          ]),
          baseStyle: _baseStyle,
        ),
      );
      final span = tester.widget<Text>(find.byType(Text).first).textSpan! as TextSpan;
      final imageSpan = span.children!.first as TextSpan;
      expect(imageSpan.text, '[image: image]');
    });

    testWidgets('autolink URI uses url destination', (tester) async {
      var tapped = '';
      await _pump(
        tester,
        MarkdownText(
          document: _doc([
            _paragraph([
              const MarkdownInline.autolink(
                url: 'https://example.com',
                kind: MarkdownAutolinkKind.uri,
              ),
            ]),
          ]),
          baseStyle: _baseStyle,
          onLinkTap: (url) => tapped = url,
        ),
      );
      final span = tester.widget<Text>(find.byType(Text).first).textSpan! as TextSpan;
      final link = span.children!.first as TextSpan;
      (link.recognizer as TapGestureRecognizer).onTap!();
      expect(tapped, 'https://example.com');
    });

    testWidgets('autolink email prepends mailto:', (tester) async {
      var tapped = '';
      await _pump(
        tester,
        MarkdownText(
          document: _doc([
            _paragraph([
              const MarkdownInline.autolink(
                url: 'a@b.com',
                kind: MarkdownAutolinkKind.email,
              ),
            ]),
          ]),
          baseStyle: _baseStyle,
          onLinkTap: (url) => tapped = url,
        ),
      );
      final span = tester.widget<Text>(find.byType(Text).first).textSpan! as TextSpan;
      final link = span.children!.first as TextSpan;
      (link.recognizer as TapGestureRecognizer).onTap!();
      expect(tapped, 'mailto:a@b.com');
    });

    testWidgets('math inline renders content text', (tester) async {
      await _pump(
        tester,
        MarkdownText(
          document: _doc([
            _paragraph([const MarkdownInline.math(content: 'E=mc^2')]),
          ]),
          baseStyle: _baseStyle,
        ),
      );
      final span = tester.widget<Text>(find.byType(Text).first).textSpan!;
      expect(span.toPlainText(), 'E=mc^2');
    });

    testWidgets('npub mention resolves display name via callback', (tester) async {
      String? receivedHex;
      await _pump(
        tester,
        MarkdownText(
          document: _doc([
            _paragraph([
              const MarkdownInline.nostrMention(
                entity: MarkdownNostrEntity(
                  hrp: MarkdownNostrHrp.npub,
                  bech32: testNpubA,
                ),
              ),
            ]),
          ]),
          baseStyle: _baseStyle,
          mentionDisplayName: (hex) {
            receivedHex = hex;
            return 'Alice';
          },
        ),
      );
      final span = tester.widget<Text>(find.byType(Text).first).textSpan! as TextSpan;
      final mention = span.children!.first as TextSpan;
      expect(mention.text, 'Alice');
      expect(receivedHex, testPubkeyA);
      expect(mention.style?.fontWeight, FontWeight.w700);
      expect(mention.style?.decoration, isNot(TextDecoration.underline));
      // Color seeded from the pubkey; only assert it differs from the
      // base style colour so we know the user-color path fired.
      expect(mention.style?.color, isNotNull);
      expect(mention.style?.color, isNot(_baseStyle.color));
    });

    testWidgets('npub mention with empty resolved name falls back to truncation', (tester) async {
      await _pump(
        tester,
        MarkdownText(
          document: _doc([
            _paragraph([
              const MarkdownInline.nostrMention(
                entity: MarkdownNostrEntity(
                  hrp: MarkdownNostrHrp.npub,
                  bech32: testNpubA,
                ),
              ),
            ]),
          ]),
          baseStyle: _baseStyle,
          mentionDisplayName: (_) => '',
        ),
      );
      final span = tester.widget<Text>(find.byType(Text).first).textSpan! as TextSpan;
      final mention = span.children!.first as TextSpan;
      expect(mention.text!.startsWith('@'), isFalse);
      expect(mention.text!.contains('…'), isTrue);
      expect(mention.text!.startsWith('npub1'), isTrue);
    });

    testWidgets('npub mention without callback uses truncated fallback', (tester) async {
      await _pump(
        tester,
        MarkdownText(
          document: _doc([
            _paragraph([
              const MarkdownInline.nostrMention(
                entity: MarkdownNostrEntity(
                  hrp: MarkdownNostrHrp.npub,
                  bech32: testNpubA,
                ),
              ),
            ]),
          ]),
          baseStyle: _baseStyle,
        ),
      );
      final span = tester.widget<Text>(find.byType(Text).first).textSpan! as TextSpan;
      final mention = span.children!.first as TextSpan;
      expect(mention.text!.startsWith('@'), isFalse);
      expect(mention.text!.contains('…'), isTrue);
      expect(mention.style?.fontWeight, FontWeight.w700);
    });

    testWidgets('nostr mention is tappable and gets npub hrp', (tester) async {
      MarkdownNostrHrp? gotHrp;
      String? gotB32;
      await _pump(
        tester,
        MarkdownText(
          document: _doc([
            _paragraph([
              const MarkdownInline.nostrMention(
                entity: MarkdownNostrEntity(
                  hrp: MarkdownNostrHrp.npub,
                  bech32: 'npub1xyz1234567890abcdef',
                ),
              ),
            ]),
          ]),
          baseStyle: _baseStyle,
          onNostrTap: (hrp, b32) {
            gotHrp = hrp;
            gotB32 = b32;
          },
        ),
      );
      final span = tester.widget<Text>(find.byType(Text).first).textSpan! as TextSpan;
      final mention = span.children!.first as TextSpan;
      expect(mention.text!.startsWith('@'), isFalse);
      (mention.recognizer as TapGestureRecognizer).onTap!();
      expect(gotHrp, MarkdownNostrHrp.npub);
      expect(gotB32, 'npub1xyz1234567890abcdef');
    });

    testWidgets('nostr uri with non-npub hrp shows raw bech32 truncated', (tester) async {
      await _pump(
        tester,
        MarkdownText(
          document: _doc([
            _paragraph([
              const MarkdownInline.nostrUri(
                entity: MarkdownNostrEntity(
                  hrp: MarkdownNostrHrp.nevent,
                  bech32: 'nevent1xyz1234567890abcdefghij',
                ),
              ),
            ]),
          ]),
          baseStyle: _baseStyle,
          onNostrTap: (_, _) {},
        ),
      );
      final span = tester.widget<Text>(find.byType(Text).first).textSpan! as TextSpan;
      final uri = span.children!.first as TextSpan;
      expect(uri.text!.startsWith('@'), isFalse);
      expect(uri.text!.contains('…'), isTrue);
    });

    testWidgets('short nostr bech32 is not truncated', (tester) async {
      await _pump(
        tester,
        MarkdownText(
          document: _doc([
            _paragraph([
              const MarkdownInline.nostrUri(
                entity: MarkdownNostrEntity(
                  hrp: MarkdownNostrHrp.note,
                  bech32: 'note1short',
                ),
              ),
            ]),
          ]),
          baseStyle: _baseStyle,
          onNostrTap: (_, _) {},
        ),
      );
      final span = tester.widget<Text>(find.byType(Text).first).textSpan! as TextSpan;
      final uri = span.children!.first as TextSpan;
      expect(uri.text, 'note1short');
    });

    testWidgets('nostr without onNostrTap has no recognizer', (tester) async {
      await _pump(
        tester,
        MarkdownText(
          document: _doc([
            _paragraph([
              const MarkdownInline.nostrUri(
                entity: MarkdownNostrEntity(
                  hrp: MarkdownNostrHrp.npub,
                  bech32: 'npub1short',
                ),
              ),
            ]),
          ]),
          baseStyle: _baseStyle,
        ),
      );
      final span = tester.widget<Text>(find.byType(Text).first).textSpan! as TextSpan;
      final uri = span.children!.first as TextSpan;
      expect(uri.recognizer, isNull);
    });
  });

  group('MarkdownText — blocks', () {
    testWidgets('heading renders with larger font', (tester) async {
      await _pump(
        tester,
        MarkdownText(
          document: _doc([
            MarkdownBlock.heading(level: 1, inlines: [_t('H1')]),
          ]),
          baseStyle: _baseStyle,
        ),
      );
      expect(find.text('H1'), findsOneWidget);
      final text = tester.widget<Text>(find.text('H1'));
      expect(text.style!.fontWeight, FontWeight.w700);
      expect(text.style!.fontSize! > 14, isTrue);
    });

    testWidgets('heading level 5 falls back to base size', (tester) async {
      await _pump(
        tester,
        MarkdownText(
          document: _doc([
            MarkdownBlock.heading(level: 5, inlines: [_t('H5')]),
          ]),
          baseStyle: _baseStyle,
        ),
      );
      final text = tester.widget<Text>(find.text('H5'));
      expect(text.style!.fontSize, _baseStyle.fontSize);
    });

    testWidgets('thematic break renders a divider', (tester) async {
      await _pump(
        tester,
        MarkdownText(
          document: _doc([
            const MarkdownBlock.thematicBreak(),
            _paragraph([_t('after')]),
          ]),
          baseStyle: _baseStyle,
        ),
      );
      expect(find.byType(Divider), findsOneWidget);
      expect(find.text('after'), findsOneWidget);
    });

    testWidgets('code block renders content in monospace', (tester) async {
      await _pump(
        tester,
        MarkdownText(
          document: _doc([
            const MarkdownBlock.codeBlock(
              kind: MarkdownCodeBlockKind.fenced,
              info: 'rust',
              content: 'fn main() {}',
            ),
            _paragraph([_t('after')]),
          ]),
          baseStyle: _baseStyle,
        ),
      );
      expect(find.text('fn main() {}'), findsOneWidget);
      final text = tester.widget<Text>(find.text('fn main() {}'));
      expect(text.style!.fontFamily, 'monospace');
    });

    testWidgets('math block renders content italic monospace', (tester) async {
      await _pump(
        tester,
        MarkdownText(
          document: _doc([
            const MarkdownBlock.mathBlock(content: 'E=mc^2'),
            _paragraph([_t('after')]),
          ]),
          baseStyle: _baseStyle,
        ),
      );
      final text = tester.widget<Text>(find.text('E=mc^2'));
      expect(text.style!.fontStyle, FontStyle.italic);
      expect(text.style!.fontFamily, 'monospace');
    });

    testWidgets('blockquote draws a left border', (tester) async {
      await _pump(
        tester,
        MarkdownText(
          document: _doc([
            MarkdownBlock.blockQuote(
              blocks: [
                _paragraph([_t('quoted')]),
              ],
            ),
            _paragraph([_t('after')]),
          ]),
          baseStyle: _baseStyle,
        ),
      );
      expect(find.text('quoted'), findsOneWidget);
      expect(find.text('after'), findsOneWidget);
    });

    testWidgets('bullet list renders • markers', (tester) async {
      await _pump(
        tester,
        MarkdownText(
          document: _doc([
            MarkdownBlock.list(
              kind: const MarkdownListKind.bullet(marker: '-'),
              tight: true,
              items: [
                MarkdownListItem(
                  blocks: [
                    _paragraph([_t('one')]),
                  ],
                ),
                MarkdownListItem(
                  blocks: [
                    _paragraph([_t('two')]),
                  ],
                ),
              ],
            ),
            _paragraph([_t('after')]),
          ]),
          baseStyle: _baseStyle,
        ),
      );
      expect(find.text('•'), findsNWidgets(2));
      expect(find.text('one'), findsOneWidget);
      expect(find.text('two'), findsOneWidget);
    });

    testWidgets('ordered list renders numbers with delimiter', (tester) async {
      await _pump(
        tester,
        MarkdownText(
          document: _doc([
            MarkdownBlock.list(
              kind: const MarkdownListKind.ordered(start: 3, delimiter: ')'),
              tight: true,
              items: [
                MarkdownListItem(
                  blocks: [
                    _paragraph([_t('a')]),
                  ],
                ),
                MarkdownListItem(
                  blocks: [
                    _paragraph([_t('b')]),
                  ],
                ),
              ],
            ),
            _paragraph([_t('after')]),
          ]),
          baseStyle: _baseStyle,
        ),
      );
      expect(find.text('3)'), findsOneWidget);
      expect(find.text('4)'), findsOneWidget);
    });

    testWidgets('task list renders check boxes', (tester) async {
      await _pump(
        tester,
        MarkdownText(
          document: _doc([
            const MarkdownBlock.list(
              kind: MarkdownListKind.bullet(marker: '-'),
              tight: true,
              items: [
                MarkdownListItem(
                  blocks: [
                    MarkdownBlock.paragraph(inlines: [MarkdownInline.text(content: 't')]),
                  ],
                  checked: false,
                ),
                MarkdownListItem(
                  blocks: [
                    MarkdownBlock.paragraph(inlines: [MarkdownInline.text(content: 'd')]),
                  ],
                  checked: true,
                ),
              ],
            ),
            _paragraph([_t('after')]),
          ]),
          baseStyle: _baseStyle,
        ),
      );
      expect(find.byKey(const Key('check_box_outline_blank')), findsOneWidget);
      expect(find.byKey(const Key('check_box')), findsOneWidget);
    });

    testWidgets('list item with empty blocks renders without crash', (tester) async {
      await _pump(
        tester,
        MarkdownText(
          document: _doc([
            const MarkdownBlock.list(
              kind: MarkdownListKind.bullet(marker: '-'),
              tight: true,
              items: [MarkdownListItem(blocks: [])],
            ),
            _paragraph([_t('after')]),
          ]),
          baseStyle: _baseStyle,
        ),
      );
      expect(find.text('after'), findsOneWidget);
    });

    testWidgets('table renders header and rows with alignment', (tester) async {
      await _pump(
        tester,
        MarkdownText(
          document: _doc([
            MarkdownBlock.table(
              alignments: const [
                MarkdownAlignment.left,
                MarkdownAlignment.center,
                MarkdownAlignment.right,
                MarkdownAlignment.none,
              ],
              header: [
                MarkdownTableCell(inlines: [_t('h1')]),
                MarkdownTableCell(inlines: [_t('h2')]),
                MarkdownTableCell(inlines: [_t('h3')]),
                MarkdownTableCell(inlines: [_t('h4')]),
              ],
              rows: [
                [
                  MarkdownTableCell(inlines: [_t('r1c1')]),
                  MarkdownTableCell(inlines: [_t('r1c2')]),
                  MarkdownTableCell(inlines: [_t('r1c3')]),
                  MarkdownTableCell(inlines: [_t('r1c4')]),
                ],
              ],
            ),
            _paragraph([_t('after')]),
          ]),
          baseStyle: _baseStyle,
        ),
      );
      expect(find.byType(Table), findsOneWidget);
      expect(find.text('h1'), findsOneWidget);
      expect(find.text('r1c1'), findsOneWidget);
    });

    testWidgets('empty table renders SizedBox.shrink', (tester) async {
      await _pump(
        tester,
        MarkdownText(
          document: _doc([
            const MarkdownBlock.table(alignments: [], header: [], rows: []),
            _paragraph([_t('after')]),
          ]),
          baseStyle: _baseStyle,
        ),
      );
      expect(find.byType(Table), findsNothing);
      expect(find.text('after'), findsOneWidget);
    });

    testWidgets('table pads short rows with empty cells', (tester) async {
      await _pump(
        tester,
        MarkdownText(
          document: _doc([
            MarkdownBlock.table(
              alignments: const [MarkdownAlignment.left, MarkdownAlignment.left],
              header: [
                MarkdownTableCell(inlines: [_t('h1')]),
              ],
              rows: [
                [
                  MarkdownTableCell(inlines: [_t('r1')]),
                ],
              ],
            ),
            _paragraph([_t('after')]),
          ]),
          baseStyle: _baseStyle,
        ),
      );
      expect(find.byType(Table), findsOneWidget);
    });
  });

  group('MarkdownText — highlights', () {
    testWidgets('matched substring gets background color', (tester) async {
      await _pump(
        tester,
        MarkdownText(
          document: _doc([
            _paragraph([_t('hello world')]),
          ]),
          baseStyle: _baseStyle,
          highlightQueries: const ['world'],
          highlightColor: Colors.yellow,
        ),
      );
      final root = tester.widget<Text>(find.byType(Text).first).textSpan! as TextSpan;
      final textSpan = root.children!.first as TextSpan;
      final children = textSpan.children!;
      final highlighted =
          children.firstWhere(
                (s) => (s as TextSpan).style?.backgroundColor == Colors.yellow,
              )
              as TextSpan;
      expect(highlighted.text, 'world');
    });

    testWidgets('case-insensitive match', (tester) async {
      await _pump(
        tester,
        MarkdownText(
          document: _doc([
            _paragraph([_t('Hello World')]),
          ]),
          baseStyle: _baseStyle,
          highlightQueries: const ['hello'],
          highlightColor: Colors.yellow,
        ),
      );
      final root = tester.widget<Text>(find.byType(Text).first).textSpan! as TextSpan;
      final textSpan = root.children!.first as TextSpan;
      final highlighted =
          (textSpan.children!).firstWhere(
                (s) => (s as TextSpan).style?.backgroundColor == Colors.yellow,
              )
              as TextSpan;
      expect(highlighted.text, 'Hello');
    });

    testWidgets('multiple matches all highlighted', (tester) async {
      await _pump(
        tester,
        MarkdownText(
          document: _doc([
            _paragraph([_t('foo foo foo')]),
          ]),
          baseStyle: _baseStyle,
          highlightQueries: const ['foo'],
          highlightColor: Colors.yellow,
        ),
      );
      final root = tester.widget<Text>(find.byType(Text).first).textSpan! as TextSpan;
      final textSpan = root.children!.first as TextSpan;
      final highlighted = (textSpan.children!)
          .where((s) => (s as TextSpan).style?.backgroundColor == Colors.yellow)
          .toList();
      expect(highlighted.length, 3);
    });

    testWidgets('overlapping queries are merged', (tester) async {
      await _pump(
        tester,
        MarkdownText(
          document: _doc([
            _paragraph([_t('abcdef')]),
          ]),
          baseStyle: _baseStyle,
          highlightQueries: const ['abc', 'bcd'],
          highlightColor: Colors.yellow,
        ),
      );
      final root = tester.widget<Text>(find.byType(Text).first).textSpan! as TextSpan;
      final textSpan = root.children!.first as TextSpan;
      final highlighted = (textSpan.children!)
          .where((s) => (s as TextSpan).style?.backgroundColor == Colors.yellow)
          .map((s) => (s as TextSpan).text)
          .toList();
      expect(highlighted, ['abcd']);
    });

    testWidgets('empty query string is ignored', (tester) async {
      await _pump(
        tester,
        MarkdownText(
          document: _doc([
            _paragraph([_t('hello')]),
          ]),
          baseStyle: _baseStyle,
          highlightQueries: const [''],
          highlightColor: Colors.yellow,
        ),
      );
      final root = tester.widget<Text>(find.byType(Text).first).textSpan! as TextSpan;
      final textSpan = root.children!.first as TextSpan;
      expect(textSpan.text, 'hello');
    });

    testWidgets('no match leaves text plain', (tester) async {
      await _pump(
        tester,
        MarkdownText(
          document: _doc([
            _paragraph([_t('hello')]),
          ]),
          baseStyle: _baseStyle,
          highlightQueries: const ['zzz'],
          highlightColor: Colors.yellow,
        ),
      );
      final root = tester.widget<Text>(find.byType(Text).first).textSpan! as TextSpan;
      final textSpan = root.children!.first as TextSpan;
      expect(textSpan.text, 'hello');
    });

    testWidgets('empty text inline is not highlighted', (tester) async {
      await _pump(
        tester,
        MarkdownText(
          document: _doc([
            _paragraph([_t('')]),
          ]),
          baseStyle: _baseStyle,
          highlightQueries: const ['x'],
          highlightColor: Colors.yellow,
        ),
      );
      expect(find.byType(Text), findsOneWidget);
    });
  });

  group('MarkdownText — flatten helper via image alt', () {
    testWidgets('flatten covers every inline variant', (tester) async {
      await _pump(
        tester,
        MarkdownText(
          document: _doc([
            _paragraph([
              MarkdownInline.image(
                dest: 'https://x',
                alt: [
                  _t('A'),
                  const MarkdownInline.code(content: 'B'),
                  const MarkdownInline.math(content: 'C'),
                  const MarkdownInline.softBreak(),
                  const MarkdownInline.hardBreak(),
                  MarkdownInline.strong(children: [_t('D')]),
                  MarkdownInline.emph(children: [_t('E')]),
                  MarkdownInline.strikethrough(children: [_t('F')]),
                  MarkdownInline.link(dest: 'https://y', children: [_t('G')]),
                  const MarkdownInline.image(dest: 'https://z', alt: []),
                  const MarkdownInline.autolink(
                    url: 'https://h',
                    kind: MarkdownAutolinkKind.uri,
                  ),
                  const MarkdownInline.nostrMention(
                    entity: MarkdownNostrEntity(
                      hrp: MarkdownNostrHrp.npub,
                      bech32: 'npub1iii',
                    ),
                  ),
                  const MarkdownInline.nostrUri(
                    entity: MarkdownNostrEntity(
                      hrp: MarkdownNostrHrp.note,
                      bech32: 'note1jjj',
                    ),
                  ),
                ],
              ),
            ]),
          ]),
          baseStyle: _baseStyle,
          onLinkTap: (_) {},
          onNostrTap: (_, _) {},
        ),
      );
      final span = tester.widget<Text>(find.byType(Text).first).textSpan! as TextSpan;
      final imageSpan = span.children!.first as TextSpan;
      expect(imageSpan.text!.contains('A'), isTrue);
      expect(imageSpan.text!.contains('B'), isTrue);
      expect(imageSpan.text!.contains('C'), isTrue);
      expect(imageSpan.text!.contains('D'), isTrue);
      expect(imageSpan.text!.contains('E'), isTrue);
      expect(imageSpan.text!.contains('F'), isTrue);
      expect(imageSpan.text!.contains('G'), isTrue);
      expect(imageSpan.text!.contains('https://h'), isTrue);
      expect(imageSpan.text!.contains('npub1iii'), isTrue);
      expect(imageSpan.text!.contains('note1jjj'), isTrue);
    });
  });
}
