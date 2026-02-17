import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
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
    FlutterMetadata? metadata,
    VoidCallback? onCopied,
    VoidCallback? onCopyError,
  }) async {
    await mountWidget(
      SingleChildScrollView(
        child: WnChatInfoProfileCard(
          userPubkey: userPubkey,
          metadata: metadata,
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
        metadata: const FlutterMetadata(displayName: 'Alice', custom: {}),
      );

      expect(find.byType(WnAvatar), findsOneWidget);
      expect(find.byType(WnCopyCard), findsOneWidget);
    });

    testWidgets('shows display name', (tester) async {
      await pumpCard(
        tester,
        metadata: const FlutterMetadata(displayName: 'Alice', custom: {}),
      );

      expect(find.byKey(const Key('chat_info_display_name')), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets('falls back to name when display name is missing', (tester) async {
      await pumpCard(
        tester,
        metadata: const FlutterMetadata(name: 'bob', custom: {}),
      );

      expect(find.text('bob'), findsOneWidget);
    });

    testWidgets('hides name when metadata has no name', (tester) async {
      await pumpCard(
        tester,
        metadata: const FlutterMetadata(custom: {}),
      );

      expect(find.byKey(const Key('chat_info_display_name')), findsNothing);
    });

    testWidgets('copy card uses npub values', (tester) async {
      await pumpCard(
        tester,
        metadata: const FlutterMetadata(custom: {}),
      );

      final copyCard = tester.widget<WnCopyCard>(find.byType(WnCopyCard));
      expect(copyCard.textToDisplay, testNpubAFormatted);
      expect(copyCard.textToCopy, testNpubA);
    });

    testWidgets('does not render nip05 and about text', (tester) async {
      await pumpCard(
        tester,
        metadata: const FlutterMetadata(
          displayName: 'Alice',
          nip05: 'alice@example.com',
          about: 'About text',
          custom: {},
        ),
      );

      expect(find.text('alice@example.com'), findsNothing);
      expect(find.text('About text'), findsNothing);
    });

    testWidgets('copy action triggers success callback', (tester) async {
      mockClipboard();
      var copied = false;
      await pumpCard(
        tester,
        metadata: const FlutterMetadata(displayName: 'Alice', custom: {}),
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
        metadata: const FlutterMetadata(displayName: 'Alice', custom: {}),
        onCopyError: () => failed = true,
      );

      await tester.tap(find.byKey(const Key('copy_button')));
      await tester.pumpAndSettle();

      expect(failed, isTrue);
    });
  });
}
