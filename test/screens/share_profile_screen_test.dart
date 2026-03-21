import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncData;
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/screens/chat_list_screen.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/widgets/wn_avatar.dart';
import 'package:whitenoise/widgets/wn_copy_card.dart';

import '../mocks/mock_clipboard.dart' show clearClipboardMock, mockClipboard, mockClipboardFailing;
import '../mocks/mock_secure_storage.dart';
import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

class _MockApi extends MockWnApi {
  @override
  Future<FlutterMetadata> crateApiUsersUserMetadata({
    required bool blockingDataSync,
    required String pubkey,
  }) async => const FlutterMetadata(
    name: 'Test User',
    displayName: 'Test Display Name',
    picture: 'https://example.com/picture.jpg',
    custom: {},
  );
}

late _MockApi _mockApi;

class _MockAuthNotifier extends AuthNotifier {
  _MockAuthNotifier([this._pubkey = testPubkeyA]);

  final String _pubkey;

  @override
  Future<String?> build() async {
    state = AsyncData(_pubkey);
    return _pubkey;
  }
}

void main() {
  setUpAll(() {
    _mockApi = _MockApi();
    RustLib.initMock(api: _mockApi);
  });

  setUp(() {
    _mockApi.reset();
  });

  Future<void> pumpShareProfileScreen(WidgetTester tester) async {
    await mountTestApp(
      tester,
      overrides: [
        authProvider.overrideWith(() => _MockAuthNotifier()),
        secureStorageProvider.overrideWithValue(MockSecureStorage()),
      ],
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(Scaffold));
    Routes.pushToShareProfile(context);
    await tester.pumpAndSettle();
  }

  group('ShareProfileScreen', () {
    testWidgets('displays Share profile title', (tester) async {
      await pumpShareProfileScreen(tester);
      expect(find.text('Share profile'), findsOneWidget);
    });

    testWidgets('displays user display name', (tester) async {
      await pumpShareProfileScreen(tester);
      expect(find.text('Test Display Name'), findsOneWidget);
    });

    testWidgets('displays Scan to connect text', (tester) async {
      await pumpShareProfileScreen(tester);
      expect(find.text('Scan to connect'), findsOneWidget);
    });

    testWidgets('displays QR code', (tester) async {
      await pumpShareProfileScreen(tester);
      await tester.pumpAndSettle();
      expect(find.byType(QrImageView), findsOneWidget);
    });

    testWidgets('tapping back button returns to previous screen', (tester) async {
      await pumpShareProfileScreen(tester);
      await tester.tap(find.byKey(const Key('slate_back_button')));
      await tester.pumpAndSettle();
      expect(find.byType(ChatListScreen), findsOneWidget);
    });

    testWidgets('tapping copy button copies npub to clipboard', (tester) async {
      final getClipboard = mockClipboard();
      await pumpShareProfileScreen(tester);
      await tester.pumpAndSettle();
      final copyButton = find.byKey(const Key('copy_button'));
      expect(copyButton, findsOneWidget);
      await tester.tap(copyButton);
      await tester.pump();
      expect(getClipboard(), startsWith('npub1'));
    });

    testWidgets('shows success message when copying public key', (tester) async {
      await pumpShareProfileScreen(tester);
      await tester.pumpAndSettle();
      final copyButton = find.byKey(const Key('copy_button'));
      await tester.tap(copyButton);
      await tester.pump();
      expect(find.text('Public key copied to clipboard'), findsOneWidget);
    });

    testWidgets('shows error notice when public key copy fails', (tester) async {
      mockClipboardFailing();
      addTearDown(clearClipboardMock);
      await pumpShareProfileScreen(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('copy_button')));
      await tester.pumpAndSettle();

      expect(find.text('Failed to copy public key. Please try again.'), findsOneWidget);
    });

    testWidgets('dismisses notice after auto-hide duration', (tester) async {
      mockClipboard();
      await pumpShareProfileScreen(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('copy_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Public key copied to clipboard'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(find.text('Public key copied to clipboard'), findsNothing);
    });

    testWidgets('uses snapToWords for ellipsis', (tester) async {
      await pumpShareProfileScreen(tester);
      final copyCard = tester.widget<WnCopyCard>(find.byType(WnCopyCard));
      expect(copyCard.snapToWords, isTrue);
    });

    testWidgets('hides copy card when npub conversion fails', (tester) async {
      _mockApi.shouldFailNpubConversion = true;
      await pumpShareProfileScreen(tester);
      await tester.pumpAndSettle();

      expect(find.byType(WnCopyCard), findsNothing);
    });

    testWidgets('passes color derived from pubkey to avatar', (tester) async {
      await pumpShareProfileScreen(tester);

      final avatar = tester.widget<WnAvatar>(find.byType(WnAvatar));
      expect(avatar.color, AvatarColor.violet);
    });

    testWidgets('different pubkey passes different avatar color', (tester) async {
      await mountTestApp(
        tester,
        overrides: [
          authProvider.overrideWith(() => _MockAuthNotifier(testPubkeyD)),
          secureStorageProvider.overrideWithValue(MockSecureStorage()),
        ],
      );
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(Scaffold));
      Routes.pushToShareProfile(context);
      await tester.pumpAndSettle();

      final avatar = tester.widget<WnAvatar>(find.byType(WnAvatar));
      expect(avatar.color, AvatarColor.cyan);
    });

    testWidgets('displays npub formatted in copy card', (tester) async {
      await pumpShareProfileScreen(tester);
      final copyCard = tester.widget<WnCopyCard>(find.byType(WnCopyCard));
      expect(copyCard.textToDisplay, testNpubAFormatted);
      expect(copyCard.snapToWords, isTrue);
    });

    testWidgets('displays scan QR code button', (tester) async {
      await pumpShareProfileScreen(tester);
      expect(find.byKey(const Key('scan_qr_button')), findsOneWidget);
      expect(find.text('Scan QR code'), findsOneWidget);
    });

    testWidgets('tapping scan button navigates to scan npub screen', (tester) async {
      await pumpShareProfileScreen(tester);
      await tester.tap(find.byKey(const Key('scan_qr_button')));
      await tester.pumpAndSettle();

      expect(find.text("Scan a contact's QR code."), findsOneWidget);
    });
  });
}
