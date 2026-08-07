import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncData;
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/screens/chat_screen.dart';
import 'package:whitenoise/screens/share_profile_screen.dart';
import 'package:whitenoise/screens/user_profile_screen.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/widgets/qr_scanner.dart';

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
        expect(find.byType(QrScanner), findsOneWidget);
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
      testWidgets('tapping back button returns to share profile screen', (
        tester,
      ) async {
        await pumpScanNpubScreen(tester);
        await tester.tap(find.byKey(const Key('slate_back_button')));
        await tester.pumpAndSettle();
        expect(find.byType(ShareProfileScreen), findsOneWidget);
      });
    });

    group('QrCode detection', () {
      testWidgets(
        'calling onQrCodeDetected with valid npub navigates to start chat',
        (tester) async {
          await pumpScanNpubScreen(tester);

          final qrScanner = tester.widget<QrScanner>(find.byType(QrScanner));
          qrScanner.onQrCodeDetected(testNpubB);
          await tester.pumpAndSettle();

          expect(find.byType(UserProfileScreen), findsOneWidget);
        },
      );

      testWidgets(
        'calling onQrCodeDetected with user deep link navigates to start chat',
        (tester) async {
          await pumpScanNpubScreen(tester);

          final qrScanner = tester.widget<QrScanner>(find.byType(QrScanner));
          qrScanner.onQrCodeDetected('whitenoise://user/$testNpubB');
          await tester.pumpAndSettle();

          final screen = tester.widget<UserProfileScreen>(
            find.byType(UserProfileScreen),
          );
          expect(screen.userPubkey, testPubkeyB);
        },
      );

      testWidgets(
        'calling onQrCodeDetected with chat deep link navigates to chat',
        (tester) async {
          await pumpScanNpubScreen(tester);

          final qrScanner = tester.widget<QrScanner>(find.byType(QrScanner));
          qrScanner.onQrCodeDetected('whitenoise://chat/$testGroupId');
          await tester.pumpAndSettle();

          final screen = tester.widget<ChatScreen>(find.byType(ChatScreen));
          expect(screen.groupId, testGroupId);
        },
      );

      testWidgets(
        'calling onQrCodeDetected with non-npub value does nothing',
        (tester) async {
          await pumpScanNpubScreen(tester);

          final qrScanner = tester.widget<QrScanner>(find.byType(QrScanner));
          qrScanner.onQrCodeDetected('https://example.com');
          await tester.pumpAndSettle();

          expect(find.byType(QrScanner), findsOneWidget);
          expect(find.text('Scan a contact\'s QR code.'), findsOneWidget);
        },
      );

      testWidgets(
        'calling onQrCodeDetected with invalid npub shows error',
        (tester) async {
          await pumpScanNpubScreen(tester);

          final qrScanner = tester.widget<QrScanner>(find.byType(QrScanner));
          qrScanner.onQrCodeDetected('npub1invalid');
          await tester.pumpAndSettle();

          expect(find.byType(QrScanner), findsOneWidget);
          expect(
            find.text('Invalid public key. Please try again.'),
            findsOneWidget,
          );
        },
      );
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

      expect(find.byType(QrScanner), findsOneWidget);
    });
  });
}
