import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncData;
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/screens/login_screen.dart';
import 'package:whitenoise/src/rust/api/accounts.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/widgets/wn_scan_box.dart';
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
}

class _MockAuthNotifier extends AuthNotifier {
  @override
  Future<String?> build() async => null;

  @override
  Future<LoginResult> loginStart(String nsec) async {
    state = const AsyncData(testPubkeyA);
    return LoginResult(
      account: Account(
        pubkey: testPubkeyA,
        accountType: AccountType.local,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      status: LoginStatus.complete,
    );
  }
}

void main() {
  setUpAll(() {
    RustLib.initMock(api: _MockApi());
  });

  setUp(() {
    setPermissionRequester(() async => PermissionStatus.granted);
  });

  tearDown(() {
    resetPermissionRequester();
  });

  late _MockAuthNotifier mockAuth;

  Future<void> pumpScanNsecScreen(WidgetTester tester) async {
    mockAuth = _MockAuthNotifier();

    await mountTestApp(
      tester,
      overrides: [authProvider.overrideWith(() => mockAuth)],
    );

    Routes.pushToLogin(tester.element(find.byType(Scaffold)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('scan_button')));
    await tester.pumpAndSettle();
  }

  group('ScanNsecScreen', () {
    group('UI', () {
      testWidgets('displays scan box', (tester) async {
        await pumpScanNsecScreen(tester);
        expect(find.byType(WnScanBox), findsOneWidget);
      });

      testWidgets('displays mobile scanner', (tester) async {
        await pumpScanNsecScreen(tester);
        expect(find.byType(MobileScanner), findsOneWidget);
      });

      testWidgets('displays hint text', (tester) async {
        await pumpScanNsecScreen(tester);
        expect(find.text('Scan your private key QR code to login.'), findsOneWidget);
      });

      testWidgets('displays title', (tester) async {
        await pumpScanNsecScreen(tester);
        expect(find.text('Scan QR code'), findsOneWidget);
      });
    });

    group('navigation', () {
      testWidgets('tapping back button returns to login screen', (tester) async {
        await pumpScanNsecScreen(tester);
        await tester.tap(find.byKey(const Key('slate_back_button')));
        await tester.pumpAndSettle();
        expect(find.byType(LoginScreen), findsOneWidget);
      });

      testWidgets('tapping outside slate returns to login screen', (tester) async {
        await pumpScanNsecScreen(tester);
        await tester.tapAt(const Offset(5, 400));
        await tester.pumpAndSettle();
        expect(find.byType(LoginScreen), findsOneWidget);
      });
    });

    group('barcode detection', () {
      testWidgets('calling onBarcodeDetected pops with scanned value', (tester) async {
        await pumpScanNsecScreen(tester);

        final scanBox = tester.widget<WnScanBox>(find.byType(WnScanBox));
        scanBox.onBarcodeDetected('nsec1scannedvalue');
        await tester.pumpAndSettle();

        expect(find.byType(LoginScreen), findsOneWidget);
        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.controller?.text, 'nsec1scannedvalue');
      });
    });
  });

  group('LoginScreen scan button', () {
    testWidgets('navigates to scan screen when tapped', (tester) async {
      mockAuth = _MockAuthNotifier();
      await mountTestApp(
        tester,
        overrides: [authProvider.overrideWith(() => mockAuth)],
      );
      Routes.pushToLogin(tester.element(find.byType(Scaffold)));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('scan_button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('scan_button')));
      await tester.pumpAndSettle();

      expect(find.byType(WnScanBox), findsOneWidget);
    });
  });
}
