import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:whitenoise/src/rust/api/messages.dart' show HighlightSpan, SerializableToken;
import 'package:whitenoise/widgets/message_content_text.dart';

import '../mocks/mock_clipboard.dart';
import '../test_helpers.dart';

class _MockUrlLauncher extends UrlLauncherPlatform with MockPlatformInterfaceMixin {
  final List<({String url, LaunchOptions options})> calls = [];
  bool returnValue = true;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    calls.add((url: url, options: options));
    return returnValue;
  }
}

void main() {
  group('MessageContentText', () {
    testWidgets('renders URL tokens using the original message text', (tester) async {
      await mountWidget(
        const MessageContentText(
          content: 'Visit https://example.com.',
          contentTokens: [
            SerializableToken(tokenType: 'Text', content: 'Visit'),
            SerializableToken(tokenType: 'Whitespace'),
            SerializableToken(tokenType: 'Url', content: 'https://example.com/'),
            SerializableToken(tokenType: 'Text', content: '.'),
          ],
          style: TextStyle(),
        ),
        tester,
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      expect(richText.text.toPlainText(), 'Visit https://example.com.');
    });

    testWidgets('launches URL token taps externally', (tester) async {
      final originalUrlLauncher = UrlLauncherPlatform.instance;
      final mockLauncher = _MockUrlLauncher();
      UrlLauncherPlatform.instance = mockLauncher;
      addTearDown(() => UrlLauncherPlatform.instance = originalUrlLauncher);

      await mountWidget(
        const MessageContentText(
          content: 'https://example.com',
          contentTokens: [
            SerializableToken(tokenType: 'Url', content: 'https://example.com/'),
          ],
          style: TextStyle(),
        ),
        tester,
      );

      await tester.tap(find.textContaining('https://example.com', findRichText: true));
      await tester.pump();

      expect(mockLauncher.calls, hasLength(1));
      expect(mockLauncher.calls.single.url, 'https://example.com/');
      expect(mockLauncher.calls.single.options.mode, PreferredLaunchMode.externalApplication);
    });

    testWidgets('uses custom URL tap handler when provided', (tester) async {
      String? tappedUrl;

      await mountWidget(
        MessageContentText(
          content: 'https://example.com',
          contentTokens: const [
            SerializableToken(tokenType: 'Url', content: 'https://example.com/'),
          ],
          style: const TextStyle(),
          onUrlTap: (url) {
            tappedUrl = url;
          },
        ),
        tester,
      );

      await tester.tap(find.textContaining('https://example.com', findRichText: true));
      await tester.pump();

      expect(tappedUrl, 'https://example.com/');
    });

    testWidgets('handles Nostr token taps separately from URL taps', (tester) async {
      const nostrUri = 'nostr:npub1l2vyh47mk2p0qlsku7hg0vn29faehy9hy34ygaclpn66ukqp3afqutajft';
      String? tappedNostrUri;

      await mountWidget(
        MessageContentText(
          content: 'Mention $nostrUri',
          contentTokens: const [
            SerializableToken(tokenType: 'Text', content: 'Mention'),
            SerializableToken(tokenType: 'Whitespace'),
            SerializableToken(tokenType: 'Nostr', content: nostrUri),
          ],
          style: const TextStyle(),
          onNostrTap: (uri) {
            tappedNostrUri = uri;
          },
        ),
        tester,
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      expect(richText.text.toPlainText(), 'Mention $nostrUri');

      await tester.tap(find.textContaining(nostrUri, findRichText: true));
      await tester.pump();

      expect(tappedNostrUri, nostrUri);
    });

    testWidgets('launches Nostr token taps externally by default', (tester) async {
      const nostrUri = 'nostr:$testNpubB';
      final originalUrlLauncher = UrlLauncherPlatform.instance;
      final mockLauncher = _MockUrlLauncher();
      UrlLauncherPlatform.instance = mockLauncher;
      addTearDown(() => UrlLauncherPlatform.instance = originalUrlLauncher);

      await mountWidget(
        const MessageContentText(
          content: nostrUri,
          contentTokens: [
            SerializableToken(tokenType: 'Nostr', content: nostrUri),
          ],
          style: TextStyle(),
        ),
        tester,
      );

      await tester.tap(find.textContaining(nostrUri, findRichText: true));
      await tester.pump();

      expect(mockLauncher.calls, hasLength(1));
      expect(mockLauncher.calls.single.url, nostrUri);
      expect(mockLauncher.calls.single.options.mode, PreferredLaunchMode.externalApplication);
    });

    testWidgets('renders known Nostr tokens as friendly mention names', (tester) async {
      const nostrUri = 'nostr:$testNpubB';
      String? tappedNostrUri;

      await mountWidget(
        MessageContentText(
          content: nostrUri,
          contentTokens: const [
            SerializableToken(tokenType: 'Nostr', content: nostrUri),
          ],
          nostrDisplayNamesByUri: const {nostrUri: '@Bob'},
          style: const TextStyle(),
          onNostrTap: (uri) {
            tappedNostrUri = uri;
          },
        ),
        tester,
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      expect(richText.text.toPlainText(), '@Bob');
      expect(find.textContaining(nostrUri, findRichText: true), findsNothing);

      await tester.tap(find.textContaining('@Bob', findRichText: true));
      await tester.pump();

      expect(tappedNostrUri, nostrUri);
    });

    testWidgets('leaves unknown Nostr display names as token text', (tester) async {
      const nostrUri = 'nostr:$testNpubB';

      await mountWidget(
        const MessageContentText(
          content: nostrUri,
          contentTokens: [
            SerializableToken(tokenType: 'Nostr', content: nostrUri),
          ],
          nostrDisplayNamesByUri: {'nostr:$testNpubC': '@Alice'},
          style: TextStyle(),
        ),
        tester,
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      expect(richText.text.toPlainText(), nostrUri);
    });

    testWidgets('renders plain gaps and trailing text around sparse tokens', (tester) async {
      await mountWidget(
        const MessageContentText(
          content: 'Go https://example.com now',
          contentTokens: [
            SerializableToken(tokenType: 'Url', content: 'https://example.com/'),
          ],
          style: TextStyle(),
        ),
        tester,
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      expect(richText.text.toPlainText(), 'Go https://example.com now');
    });

    testWidgets('falls back to plain text when tokens do not match content', (tester) async {
      await mountWidget(
        const MessageContentText(
          content: 'Hello world',
          contentTokens: [
            SerializableToken(tokenType: 'Url', content: 'https://missing.example/'),
          ],
          style: TextStyle(),
        ),
        tester,
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      expect(richText.text.toPlainText(), 'Hello world');
    });

    testWidgets('renders inline code without linking URL tokens inside it', (tester) async {
      final originalUrlLauncher = UrlLauncherPlatform.instance;
      final mockLauncher = _MockUrlLauncher();
      UrlLauncherPlatform.instance = mockLauncher;
      addTearDown(() => UrlLauncherPlatform.instance = originalUrlLauncher);

      await mountWidget(
        const MessageContentText(
          content: 'Use `https://example.com` here',
          contentTokens: [
            SerializableToken(tokenType: 'Text', content: 'Use'),
            SerializableToken(tokenType: 'Whitespace'),
            SerializableToken(tokenType: 'Text', content: '`'),
            SerializableToken(tokenType: 'Url', content: 'https://example.com/'),
            SerializableToken(tokenType: 'Text', content: '`'),
            SerializableToken(tokenType: 'Whitespace'),
            SerializableToken(tokenType: 'Text', content: 'here'),
          ],
          style: TextStyle(),
        ),
        tester,
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      expect(richText.text.toPlainText(), 'Use https://example.com here');

      await tester.tap(find.textContaining('https://example.com', findRichText: true));
      await tester.pump();

      expect(mockLauncher.calls, isEmpty);
    });

    testWidgets('renders inline code in a monospace style', (tester) async {
      await mountWidget(
        const MessageContentText(
          content: 'Run `flutter test` before pushing',
          style: TextStyle(),
        ),
        tester,
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final codeSpan = _textSpans(richText.text).singleWhere(
        (span) => span.text == 'flutter test',
      );

      expect(_usesMonospaceFont(codeSpan.style), isTrue);
      expect(codeSpan.style?.backgroundColor, isNotNull);
    });

    testWidgets('renders empty content without rich text decoration', (tester) async {
      await mountWidget(
        const MessageContentText(
          content: '',
          style: TextStyle(),
        ),
        tester,
      );

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.data, '');
    });

    testWidgets('keeps malformed backtick runs as literal text', (tester) async {
      await mountWidget(
        const MessageContentText(
          content: 'Use `unterminated',
          style: TextStyle(),
        ),
        tester,
      );
      expect(
        tester.widget<RichText>(find.byType(RichText)).text.toPlainText(),
        'Use `unterminated',
      );

      await mountWidget(
        const MessageContentText(
          content: '`first\nsecond`',
          style: TextStyle(),
        ),
        tester,
      );
      expect(
        tester.widget<RichText>(find.byType(RichText)).text.toPlainText(),
        '`first\nsecond`',
      );
    });

    testWidgets('keeps unclosed fenced code as literal text', (tester) async {
      await mountWidget(
        const MessageContentText(
          content: 'Before ```unterminated',
          style: TextStyle(),
        ),
        tester,
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      expect(richText.text.toPlainText(), 'Before ```unterminated');
      expect(find.byKey(const Key('message_code_block')), findsNothing);
    });

    testWidgets('renders fenced code blocks without the fence or language label', (tester) async {
      await mountWidget(
        const SizedBox(
          width: 320,
          child: MessageContentText(
            content: 'Before\n```dart\nfinal x = 1;\n```\nAfter',
            style: TextStyle(),
          ),
        ),
        tester,
      );

      final codeBlock = find.byKey(const Key('message_code_block'));
      final codeText = tester.widget<Text>(find.byKey(const Key('message_code_block_text')));

      expect(find.textContaining('Before', findRichText: true), findsOneWidget);
      expect(find.text('After', findRichText: true), findsOneWidget);
      expect(codeBlock, findsOneWidget);
      expect(find.byKey(const Key('message_code_block_header')), findsOneWidget);
      expect(find.byKey(const Key('message_code_block_copy_button')), findsOneWidget);
      expect(codeText.data, 'final x = 1;');
      expect(_usesMonospaceFont(codeText.style), isTrue);
      expect(tester.getSize(codeBlock).width, 320);
    });

    testWidgets('strips CRLF wrappers from fenced code blocks without a language', (
      tester,
    ) async {
      await mountWidget(
        const MessageContentText(
          content: '```\r\necho "hello"\r\n```\r\nAfter',
          style: TextStyle(),
        ),
        tester,
      );

      final codeText = tester.widget<Text>(find.byKey(const Key('message_code_block_text')));
      expect(codeText.data, 'echo "hello"');
      expect(find.text('After', findRichText: true), findsOneWidget);
    });

    testWidgets('strips CRLF wrappers from fenced code blocks', (tester) async {
      await mountWidget(
        const MessageContentText(
          content: '```shell\r\necho "hello"\r\n```\r\nAfter',
          style: TextStyle(),
        ),
        tester,
      );

      final codeText = tester.widget<Text>(find.byKey(const Key('message_code_block_text')));
      expect(codeText.data, 'echo "hello"');
      expect(find.text('After', findRichText: true), findsOneWidget);
    });

    testWidgets('renders trailing spans after a code-only message', (tester) async {
      await mountWidget(
        const MessageContentText(
          content: '```\necho "hello"\n```',
          trailingSpans: [TextSpan(text: '12:00')],
          style: TextStyle(),
        ),
        tester,
      );

      expect(find.byKey(const Key('message_code_block')), findsOneWidget);
      expect(find.text('12:00', findRichText: true), findsOneWidget);
    });

    testWidgets('merges overlapping highlight spans', (tester) async {
      await mountWidget(
        const MessageContentText(
          content: 'hello world',
          highlightSpans: [
            HighlightSpan(start: 0, end: 5),
            HighlightSpan(start: 3, end: 8),
            HighlightSpan(start: 8, end: 11),
          ],
          highlightColor: Colors.yellow,
          style: TextStyle(),
        ),
        tester,
      );

      final spans = _textSpans(tester.widget<RichText>(find.byType(RichText)).text);
      expect(spans.map((span) => span.text).join(), 'hello world');
      expect(spans.every((span) => span.style?.backgroundColor == Colors.yellow), isTrue);
    });

    testWidgets('does not highlight friendly Nostr text when highlight is after the token', (
      tester,
    ) async {
      const nostrUri = 'nostr:$testNpubB';

      await mountWidget(
        const MessageContentText(
          content: '$nostrUri later',
          contentTokens: [
            SerializableToken(tokenType: 'Nostr', content: nostrUri),
          ],
          nostrDisplayNamesByUri: {nostrUri: '@Bob'},
          highlightSpans: [HighlightSpan(start: 70, end: 75)],
          highlightColor: Colors.yellow,
          style: TextStyle(),
        ),
        tester,
      );

      final bobSpan = _textSpans(
        tester.widget<RichText>(find.byType(RichText)).text,
      ).singleWhere((span) => span.text == '@Bob');
      expect(bobSpan.style?.backgroundColor, isNull);
    });

    testWidgets('copies fenced code block content from the header button', (tester) async {
      final clipboardContent = mockClipboard();
      addTearDown(clearClipboardMock);

      await mountWidget(
        const MessageContentText(
          content: '```shell\necho "hello"\n```',
          style: TextStyle(),
        ),
        tester,
      );

      await tester.tap(find.byKey(const Key('message_code_block_copy_button')));
      await tester.pump();

      expect(clipboardContent(), 'echo "hello"');
    });

    testWidgets('shows copied feedback after copying a fenced code block', (tester) async {
      mockClipboard();
      addTearDown(clearClipboardMock);

      await mountWidget(
        const MessageContentText(
          content: '```shell\necho "hello"\n```',
          style: TextStyle(),
        ),
        tester,
      );

      await tester.tap(find.byKey(const Key('message_code_block_copy_button')));
      await tester.pump();

      expect(find.byKey(const Key('message_code_block_copied_pill')), findsOneWidget);
      expect(find.text('Copied'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 1600));

      expect(find.byKey(const Key('message_code_block_copied_pill')), findsNothing);
    });
  });
}

List<TextSpan> _textSpans(InlineSpan root) {
  final result = <TextSpan>[];

  void visit(InlineSpan span) {
    if (span is TextSpan) {
      if (span.text != null) {
        result.add(span);
      }
      span.children?.forEach(visit);
    }
  }

  visit(root);
  return result;
}

bool _usesMonospaceFont(TextStyle? style) {
  final fallback = style?.fontFamilyFallback ?? const <String>[];
  return style?.fontFamily == 'SF Mono' || fallback.contains('monospace');
}
