import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncData;
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/providers/deep_link_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/screens/chat_list_screen.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/utils/deep_links.dart';
import 'package:whitenoise/widgets/wn_avatar.dart';
import 'package:whitenoise/widgets/wn_copy_card.dart';

import '../mocks/mock_clipboard.dart' show clearClipboardMock, mockClipboard, mockClipboardFailing;
import '../mocks/mock_secure_storage.dart';
import '../mocks/mock_share_plus.dart';
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
    picture: null,
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

  Future<void> pumpShareProfileScreen(
    WidgetTester tester, {
    List overrides = const [],
    Future<String> Function()? deepLinkScheme,
  }) async {
    await mountTestApp(
      tester,
      overrides: [
        authProvider.overrideWith(() => _MockAuthNotifier()),
        secureStorageProvider.overrideWithValue(MockSecureStorage()),
        deepLinkSchemeProvider.overrideWith(
          (ref) => deepLinkScheme?.call() ?? Future.value(DeepLinks.productionScheme),
        ),
        ...overrides,
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
      expect(find.text('Share & connect'), findsOneWidget);
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

    testWidgets('QR code encodes user deep link', (tester) async {
      await pumpShareProfileScreen(tester);

      expect(find.byKey(ValueKey(DeepLinks.userUri(testNpubA))), findsOneWidget);
    });

    testWidgets('defers QR code until deep link scheme is available', (tester) async {
      final schemeCompleter = Completer<String>();

      await pumpShareProfileScreen(
        tester,
        deepLinkScheme: () => schemeCompleter.future,
      );

      expect(find.byType(WnCopyCard), findsOneWidget);
      expect(find.byType(QrImageView), findsNothing);

      schemeCompleter.complete(DeepLinks.stagingScheme);
      await tester.pumpAndSettle();

      expect(
        find.byKey(ValueKey(DeepLinks.userUri(testNpubA, scheme: DeepLinks.stagingScheme))),
        findsOneWidget,
      );
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

    testWidgets('shows holding label when long pressing QR code', (tester) async {
      mockSharePlus();
      addTearDown(clearSharePlusMock);
      await pumpShareProfileScreen(tester);

      final gesture = await tester.startGesture(tester.getCenter(find.byType(QrImageView)));
      // Long press fires at 500ms; pump 600ms to clear threshold
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.textContaining('Hold to share QR code'), findsOneWidget);

      await gesture.up();
      // Drain the first 500ms delay (started at t=500ms, still pending at t=600ms)
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
    });

    testWidgets('resets label to scan to connect on long press end', (tester) async {
      mockSharePlus();
      addTearDown(clearSharePlusMock);
      await pumpShareProfileScreen(tester);

      final gesture = await tester.startGesture(tester.getCenter(find.byType(QrImageView)));
      await tester.pump(const Duration(milliseconds: 600));
      await gesture.up();
      // Drain first delay before asserting
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Scan to connect'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('resets state on long press cancel', (tester) async {
      await pumpShareProfileScreen(tester);

      final gesture = await tester.startGesture(tester.getCenter(find.byType(QrImageView)));
      await gesture.cancel();
      await tester.pumpAndSettle();

      expect(find.text('Scan to connect'), findsOneWidget);
    });

    testWidgets('progresses dots during hold', (tester) async {
      mockSharePlus();
      addTearDown(clearSharePlusMock);
      await pumpShareProfileScreen(tester);

      final gesture = await tester.startGesture(tester.getCenter(find.byType(QrImageView)));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Hold to share QR code.'), findsOneWidget);

      // First delay (t=500ms start) completes at t=1000ms; 400ms more needed
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Hold to share QR code..'), findsOneWidget);

      await gesture.up();
      // Drain second delay (started at t=1000ms) to prevent pending-timer failure
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
    });

    testWidgets('shares QR image after full hold', (tester) async {
      final calls = mockSharePlus();
      addTearDown(clearSharePlusMock);
      await pumpShareProfileScreen(tester);

      // Start the gesture OUTSIDE runAsync so the long-press timer and
      // captureAndShareQr's Future.delayed timers stay on the fake clock.
      final gesture = await tester.startGesture(tester.getCenter(find.byType(QrImageView)));
      await tester.pump(
        const Duration(milliseconds: 600),
      ); // onLongPressStart fires at fake t=500ms

      await tester.runAsync(() async {
        // Advance fake timers for captureAndShareQr's two 500ms delays.
        await tester.pump(const Duration(milliseconds: 400)); // first delay (fake t=1000ms)
        await tester.pump(const Duration(milliseconds: 500)); // second delay (fake t=1500ms)
        // Poll until share() is called — toByteData(png) takes variable real time on CI.
        for (var i = 0; i < 30; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          await tester.pump();
          if (calls.isNotEmpty) break;
        }

        expect(calls, isNotEmpty);

        await gesture.up();
        await tester.pumpAndSettle();
      });
    });

    testWidgets('shows error notice when share fails', (tester) async {
      mockSharePlusFailing();
      addTearDown(clearSharePlusMock);
      await pumpShareProfileScreen(tester);

      final gesture = await tester.startGesture(tester.getCenter(find.byType(QrImageView)));
      await tester.pump(const Duration(milliseconds: 600));

      await tester.runAsync(() async {
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 500)); // second delay; dotCount=3
        // Poll until error notice appears — toByteData(png) takes variable real time on CI.
        for (var i = 0; i < 30; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          await tester.pump();
          if (find.text('Unable to share QR code. Please try again.').evaluate().isNotEmpty) break;
        }

        expect(find.text('Unable to share QR code. Please try again.'), findsOneWidget);

        await gesture.up();
        await tester.pumpAndSettle();
      });
    });
  });
}
