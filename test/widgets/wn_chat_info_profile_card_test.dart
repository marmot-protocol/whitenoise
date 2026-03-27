import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/widgets/wn_avatar.dart';
import 'package:whitenoise/widgets/wn_chat_info_profile_card.dart';
import 'package:whitenoise/widgets/wn_copy_card.dart';

import '../mocks/mock_clipboard.dart' show clearClipboardMock, mockClipboard, mockClipboardFailing;
import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

final _api = MockWnApi();

void main() {
  setUpAll(() => RustLib.initMock(api: _api));
  setUp(() => _api.reset());

  Future<void> pumpCard(
    WidgetTester tester, {
    String userPubkey = testPubkeyA,
    String? displayName,
    String? pictureUrl,
    AvatarColor? avatarColor,
    VoidCallback? onCopied,
    VoidCallback? onCopyError,
  }) async {
    await mountWidget(
      SingleChildScrollView(
        child: WnChatInfoProfileCard(
          userPubkey: userPubkey,
          displayName: displayName,
          pictureUrl: pictureUrl,
          avatarColor: avatarColor ?? AvatarColor.fromPubkey(userPubkey),
          onPublicKeyCopied: onCopied,
          onPublicKeyCopyError: onCopyError,
        ),
      ),
      tester,
    );
  }

  group('WnChatInfoProfileCard', () {
    testWidgets('shows avatar and copy card', (tester) async {
      await pumpCard(
        tester,
        displayName: 'Alice',
      );

      expect(find.byType(WnAvatar), findsOneWidget);
      expect(find.byType(WnCopyCard), findsOneWidget);
    });

    testWidgets('shows display name', (tester) async {
      await pumpCard(
        tester,
        displayName: 'Alice',
      );

      expect(find.byKey(const Key('chat_info_display_name')), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets('hides name when display name is null', (tester) async {
      await pumpCard(tester);

      expect(find.byKey(const Key('chat_info_display_name')), findsNothing);
    });

    testWidgets('hides name when display name is empty string', (tester) async {
      await pumpCard(
        tester,
        displayName: '',
      );

      expect(find.byKey(const Key('chat_info_display_name')), findsNothing);
    });

    testWidgets('passes picture URL to avatar', (tester) async {
      await pumpCard(
        tester,
        displayName: 'Alice',
        pictureUrl: 'https://example.com/p.png',
      );

      final avatar = tester.widget<WnAvatar>(find.byType(WnAvatar));
      expect(avatar.pictureUrl, 'https://example.com/p.png');
    });

    testWidgets('passes avatar color to WnAvatar', (tester) async {
      const color = AvatarColor.blue;
      await pumpCard(
        tester,
        displayName: 'Alice',
        avatarColor: color,
      );

      final avatar = tester.widget<WnAvatar>(find.byType(WnAvatar));
      expect(avatar.color, color);
    });

    testWidgets('copy card uses npub values', (tester) async {
      await pumpCard(tester);

      final copyCard = tester.widget<WnCopyCard>(find.byType(WnCopyCard));
      expect(copyCard.textToDisplay, testNpubAFormatted);
      expect(copyCard.textToCopy, testNpubA);
    });

    testWidgets('uses snapToWords for ellipsis', (tester) async {
      await pumpCard(tester);
      final copyCard = tester.widget<WnCopyCard>(find.byType(WnCopyCard));
      expect(copyCard.snapToWords, isTrue);
    });

    testWidgets('copy action triggers success callback', (tester) async {
      mockClipboard();
      var copied = false;
      await pumpCard(
        tester,
        displayName: 'Alice',
        onCopied: () => copied = true,
      );

      await tester.tap(find.byKey(const Key('copy_button')));
      await tester.pumpAndSettle();

      expect(copied, isTrue);
    });

    testWidgets('copy action triggers error callback', (tester) async {
      mockClipboardFailing();
      addTearDown(clearClipboardMock);
      var failed = false;
      await pumpCard(
        tester,
        displayName: 'Alice',
        onCopyError: () => failed = true,
      );

      await tester.tap(find.byKey(const Key('copy_button')));
      await tester.pumpAndSettle();

      expect(failed, isTrue);
    });
  });
}
