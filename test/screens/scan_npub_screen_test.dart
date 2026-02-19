import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncData;
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/screens/share_profile_screen.dart';
import 'package:whitenoise/screens/start_chat_screen.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/widgets/wn_scan_box.dart';

import '../mocks/mock_secure_storage.dart';
import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

class _MockApi extends MockWnApi {
  @override
  Future<FlutterMetadata> crateApiUsersUserMetadata({
    required bool blockingDataSync,
    required String pubkey,
  }) async {
    return const FlutterMetadata(
      name: 'Test User',
      displayName: 'Test Display Name',
      about: 'Test bio',
      custom: {},
    );
  }

  @override
  String crateApiUtilsHexPubkeyFromNpub({required String npub}) {
    if (npub == testNpubB) return testPubkeyB;
    throw Exception('Invalid npub');
  }
}

class _MockAuthNotifier extends AuthNotifier {
  @override
  Future<String?> build() async {
    state = const AsyncData(testPubkeyA);
    return testPubkeyA;
  }
}

late _MockApi _mockApi;

void main() {
  setUpAll(() {
    _mockApi = _MockApi();
    RustLib.initMock(api: _mockApi);
  });

  setUp(() {
    _mockApi.reset();
    setPermissionRequester(() async => PermissionStatus.granted);
  });

  tearDown(() {
    resetPermissionRequester();
  });

  Future<void> pumpScanNpubScreen(WidgetTester tester) async {
    await mountTestApp(
      tester,
      overrides: [
        authProvider.overrideWith(() => _MockAuthNotifier()),
        secureStorageProvider.overrideWithValue(MockSecureStorage()),
      ],
    );

    Routes.pushToShareProfile(tester.element(find.byType(Scaffold)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('scan_qr_button')));
    await tester.pumpAndSettle();
  }

  group('ScanNpubScreen', () {
    group('UI', () {
      testWidgets('displays scan box', (tester) async {
        await pumpScanNpubScreen(tester);
        expect(find.byType(WnScanBox), findsOneWidget);
      });

      testWidgets('displays mobile scanner', (tester) async {
        await pumpScanNpubScreen(tester);
        expect(find.byType(MobileScanner), findsOneWidget);
      });

      testWidgets('displays hint text', (tester) async {
        await pumpScanNpubScreen(tester);
        expect(find.text('Scan a contact\'s QR code.'), findsOneWidget);
      });

      testWidgets('displays title', (tester) async {
        await pumpScanNpubScreen(tester);
        expect(find.text('Scan QR code'), findsOneWidget);
      });
    });

    group('navigation', () {
      testWidgets('tapping back button returns to share profile screen', (tester) async {
        await pumpScanNpubScreen(tester);
        await tester.tap(find.byKey(const Key('slate_back_button')));
        await tester.pumpAndSettle();
        expect(find.byType(ShareProfileScreen), findsOneWidget);
      });
    });

    group('barcode detection', () {
      testWidgets('calling onBarcodeDetected with valid npub navigates to start chat', (
        tester,
      ) async {
        await pumpScanNpubScreen(tester);

        final scanBox = tester.widget<WnScanBox>(find.byType(WnScanBox));
        scanBox.onBarcodeDetected(testNpubB);
        await tester.pumpAndSettle();

        expect(find.byType(StartChatScreen), findsOneWidget);
      });

      testWidgets('calling onBarcodeDetected with non-npub value does nothing', (tester) async {
        await pumpScanNpubScreen(tester);

        final scanBox = tester.widget<WnScanBox>(find.byType(WnScanBox));
        scanBox.onBarcodeDetected('https://example.com');
        await tester.pumpAndSettle();

        expect(find.byType(WnScanBox), findsOneWidget);
        expect(find.text('Scan a contact\'s QR code.'), findsOneWidget);
      });

      testWidgets('calling onBarcodeDetected with invalid npub shows error', (tester) async {
        await pumpScanNpubScreen(tester);

        final scanBox = tester.widget<WnScanBox>(find.byType(WnScanBox));
        scanBox.onBarcodeDetected('npub1invalidkey');
        await tester.pumpAndSettle();

        expect(find.byType(WnScanBox), findsOneWidget);
        expect(find.text('Invalid public key. Please try again.'), findsOneWidget);
      });
    });
  });

  group('ShareProfileScreen scan button', () {
    testWidgets('navigates to scan screen when tapped', (tester) async {
      await mountTestApp(
        tester,
        overrides: [
          authProvider.overrideWith(() => _MockAuthNotifier()),
          secureStorageProvider.overrideWithValue(MockSecureStorage()),
        ],
      );
      Routes.pushToShareProfile(tester.element(find.byType(Scaffold)));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('scan_qr_button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('scan_qr_button')));
      await tester.pumpAndSettle();

      expect(find.byType(WnScanBox), findsOneWidget);
    });
  });
}
