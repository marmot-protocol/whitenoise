import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:whitenoise/src/rust/api/messages.dart' show SerializableToken;
import 'package:whitenoise/widgets/message_content_text.dart';

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
  });
}
