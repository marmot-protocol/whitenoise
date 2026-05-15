import 'dart:async';
import 'dart:ui' show AppLifecycleState;

import 'package:flutter/material.dart' show Key;
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:whitenoise/widgets/qr_scanner.dart';
import '../mocks/mock_scanner_controller.dart';
import '../test_helpers.dart' show mountWidget;

void main() {
  group('useQrScanner', () {
    late MockScannerController mockController;

    setUp(() {
      mockController = setupMockScannerController();
      setPermissionRequester(() async => PermissionStatus.granted);
      setPermissionStatusChecker(() async => PermissionStatus.granted);
    });

    tearDown(() {
      tearDownMockScannerController();
      resetPermissionRequester();
      resetPermissionStatusChecker();
    });

    group('qrCode detection', () {
      testWidgets('calls onQrCodeDetected when qr code is scanned', (
        tester,
      ) async {
        String? detectedValue;

        await mountWidget(
          QrScanner(onQrCodeDetected: (value) => detectedValue = value),
          tester,
        );
        await tester.pump();

        mockController.emitBarcode('npub1testvalue');
        await tester.pump();

        expect(detectedValue, 'npub1testvalue');

        await tester.pump(const Duration(milliseconds: 600));
      });

      testWidgets('ignores empty barcode list', (tester) async {
        String? detectedValue;

        await mountWidget(
          QrScanner(onQrCodeDetected: (value) => detectedValue = value),
          tester,
        );
        await tester.pump();

        mockController.emitEmpty();
        await tester.pump();

        expect(detectedValue, isNull);
      });

      testWidgets('ignores barcode with empty value', (tester) async {
        String? detectedValue;

        await mountWidget(
          QrScanner(onQrCodeDetected: (value) => detectedValue = value),
          tester,
        );
        await tester.pump();

        mockController.emitBarcodeWithEmptyValue();
        await tester.pump();

        expect(detectedValue, isNull);
      });

      testWidgets('trims whitespace from scanned value', (tester) async {
        String? detectedValue;

        await mountWidget(
          QrScanner(onQrCodeDetected: (value) => detectedValue = value),
          tester,
        );
        await tester.pump();

        mockController.emitBarcode('  npub1test  ');
        await tester.pump();

        expect(detectedValue, 'npub1test');

        await tester.pump(const Duration(milliseconds: 600));
      });

      testWidgets('ignores qr codes while processing', (tester) async {
        final detectedValues = <String>[];

        await mountWidget(
          QrScanner(onQrCodeDetected: (value) => detectedValues.add(value)),
          tester,
        );
        await tester.pump();

        mockController.emitBarcode('first');
        await tester.pump();
        mockController.emitBarcode('second');
        await tester.pump();

        expect(detectedValues, ['first']);

        await tester.pump(const Duration(milliseconds: 600));
      });

      testWidgets('resets processing state after delay', (tester) async {
        final detectedValues = <String>[];

        await mountWidget(
          QrScanner(onQrCodeDetected: (value) => detectedValues.add(value)),
          tester,
        );
        await tester.pump();

        mockController.emitBarcode('first');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        mockController.emitBarcode('second');
        await tester.pump();

        expect(detectedValues, ['first', 'second']);

        await tester.pump(const Duration(milliseconds: 600));
      });
    });

    group('lifecycle', () {
      testWidgets('recreates scanner controller on resume', (tester) async {
        setPermissionStatusChecker(() async => PermissionStatus.granted);

        await mountWidget(QrScanner(onQrCodeDetected: (_) {}), tester);
        await tester.pump();

        expect(mockController.startCallCount, 1);
        expect(mockController.disposeCalled, isFalse);

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
        await tester.pump();
        await tester.pump();

        expect(mockController.startCallCount, 2);
        expect(mockController.disposeCalled, isTrue);
        expect(find.byType(MobileScanner), findsOneWidget);
      });

      testWidgets(
        'recreates scanner controller after first-time permission grant when app resumes',
        (tester) async {
          final completer = Completer<PermissionStatus>();
          setPermissionRequester(() => completer.future);

          await mountWidget(QrScanner(onQrCodeDetected: (_) {}), tester);
          await tester.pump();

          expect(find.byKey(const Key('scanner_placeholder')), findsOneWidget);

          completer.complete(PermissionStatus.granted);
          await tester.pump();
          await tester.pump();
          expect(find.byType(MobileScanner), findsOneWidget);
          expect(mockController.startCallCount, 1);

          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.resumed,
          );
          await tester.pump();
          await tester.pump();

          expect(mockController.startCallCount, 2);
          expect(mockController.disposeCalled, isTrue);
          expect(find.byType(MobileScanner), findsOneWidget);
        },
      );

      testWidgets('does not re-request permission on resume when denied', (
        tester,
      ) async {
        var requestCount = 0;
        setPermissionRequester(() async {
          requestCount++;
          return PermissionStatus.denied;
        });
        setPermissionStatusChecker(() async => PermissionStatus.denied);

        await mountWidget(QrScanner(onQrCodeDetected: (_) {}), tester);
        await tester.pump();

        expect(requestCount, 1);

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
        await tester.pump();

        expect(requestCount, 1);
      });

      testWidgets('shows error UI after denial when lifecycle resume fires', (
        tester,
      ) async {
        setPermissionRequester(() async => PermissionStatus.denied);
        setPermissionStatusChecker(() async => PermissionStatus.denied);

        await mountWidget(QrScanner(onQrCodeDetected: (_) {}), tester);
        await tester.pump();

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
        await tester.pump();
        await tester.pump();

        expect(find.byKey(const Key('scanner_notice_icon')), findsOneWidget);
        expect(find.byKey(const Key('open_settings_button')), findsOneWidget);
        expect(find.byType(MobileScanner), findsNothing);
      });

      testWidgets(
        'retries scanner on resume after user grants permission in settings',
        (tester) async {
          setPermissionRequester(() async => PermissionStatus.denied);
          setPermissionStatusChecker(() async => PermissionStatus.denied);

          await mountWidget(QrScanner(onQrCodeDetected: (_) {}), tester);
          await tester.pump();

          expect(find.byKey(const Key('open_settings_button')), findsOneWidget);

          setPermissionRequester(() async => PermissionStatus.granted);
          setPermissionStatusChecker(() async => PermissionStatus.granted);

          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.resumed,
          );
          await tester.pump();
          await tester.pump();
          await tester.pump();
          await tester.pump();

          expect(find.byType(MobileScanner), findsOneWidget);
        },
      );

      testWidgets(
        'does not retry permission on resume after dialog dismissal even if status returns granted',
        (tester) async {
          var requestCount = 0;
          setPermissionRequester(() async {
            requestCount++;
            return PermissionStatus.denied;
          });
          setPermissionStatusChecker(() async => PermissionStatus.granted);

          await mountWidget(QrScanner(onQrCodeDetected: (_) {}), tester);
          await tester.pump();

          expect(requestCount, 1);
          expect(find.byKey(const Key('open_settings_button')), findsOneWidget);

          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.resumed,
          );
          await tester.pump();
          await tester.pump();
          await tester.pump();

          expect(
            requestCount,
            1,
            reason:
                'must not retry permission on lifecycle resume just because the cached '
                'status checker returned granted; only an explicit settings trip should retry',
          );
          expect(find.byKey(const Key('open_settings_button')), findsOneWidget);
        },
      );
    });

    group('permission handling', () {
      testWidgets('shows placeholder when permission is permanently denied', (
        tester,
      ) async {
        setPermissionRequester(() async => PermissionStatus.permanentlyDenied);

        await mountWidget(QrScanner(onQrCodeDetected: (_) {}), tester);
        await tester.pump();

        expect(find.byKey(const Key('scanner_notice')), findsOneWidget);
        expect(find.byType(MobileScanner), findsNothing);
      });

      testWidgets('shows scanner when permission is limited', (tester) async {
        setPermissionRequester(() async => PermissionStatus.limited);

        await mountWidget(QrScanner(onQrCodeDetected: (_) {}), tester);
        await tester.pump();

        expect(find.byType(MobileScanner), findsOneWidget);
      });
    });

    group('start guard', () {
      testWidgets('does not call start twice on the same controller', (
        tester,
      ) async {
        await mountWidget(QrScanner(onQrCodeDetected: (_) {}), tester);
        await tester.pump();

        expect(mockController.startCallCount, 1);
      });

      testWidgets('resets start guard on resume', (tester) async {
        setPermissionStatusChecker(() async => PermissionStatus.granted);

        await mountWidget(QrScanner(onQrCodeDetected: (_) {}), tester);
        await tester.pump();

        expect(mockController.startCallCount, 1);

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
        await tester.pump();
        await tester.pump();

        expect(mockController.startCallCount, 2);
      });
    });

    group('controller.start failures', () {
      testWidgets(
        'transitions to initError when controller.start throws controllerNotAttached',
        (tester) async {
          mockController.startException = const MobileScannerException(
            errorCode: MobileScannerErrorCode.controllerNotAttached,
          );

          await mountWidget(QrScanner(onQrCodeDetected: (_) {}), tester);
          await tester.pump();
          await tester.pump();

          expect(find.byType(MobileScanner), findsNothing);
          expect(find.byKey(const Key('retry_scanner_button')), findsOneWidget);
        },
      );

      testWidgets(
        'transitions to initError when controller.start throws controllerDisposed',
        (tester) async {
          mockController.startException = const MobileScannerException(
            errorCode: MobileScannerErrorCode.controllerDisposed,
          );

          await mountWidget(QrScanner(onQrCodeDetected: (_) {}), tester);
          await tester.pump();
          await tester.pump();

          expect(find.byType(MobileScanner), findsNothing);
          expect(find.byKey(const Key('retry_scanner_button')), findsOneWidget);
        },
      );

      testWidgets('retry recovers from initError when start no longer throws', (
        tester,
      ) async {
        mockController.startException = const MobileScannerException(
          errorCode: MobileScannerErrorCode.controllerNotAttached,
        );

        await mountWidget(QrScanner(onQrCodeDetected: (_) {}), tester);
        await tester.pump();
        await tester.pump();

        expect(find.byKey(const Key('retry_scanner_button')), findsOneWidget);

        mockController.startException = null;
        await tester.tap(find.byKey(const Key('retry_scanner_button')));
        await tester.pump();
        await tester.pump();
        await tester.pump();

        expect(find.byType(MobileScanner), findsOneWidget);
      });
    });
  });
}
