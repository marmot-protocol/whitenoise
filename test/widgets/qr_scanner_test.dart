import 'dart:async';
import 'dart:ui' show AppLifecycleState;

import 'package:flutter/material.dart' show Key, SizedBox;
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:whitenoise/widgets/qr_scanner.dart';
import '../mocks/mock_scanner_controller.dart';
import '../test_helpers.dart' show mountWidget;

void main() {
  group('QrScanner', () {
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

    testWidgets('shows loading placeholder before permission resolves', (tester) async {
      var resolvePermission = false;
      setPermissionRequester(() async {
        while (!resolvePermission) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        return PermissionStatus.granted;
      });

      await mountWidget(
        QrScanner(onBarcodeDetected: (_) {}),
        tester,
      );

      expect(find.byKey(const Key('scanner_placeholder')), findsOneWidget);

      resolvePermission = true;
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();
    });

    testWidgets('renders scanner container after permission granted', (tester) async {
      await mountWidget(
        QrScanner(onBarcodeDetected: (_) {}),
        tester,
      );
      await tester.pump();

      expect(find.byType(MobileScanner), findsOneWidget);
    });

    testWidgets('shows placeholder when permission is denied', (tester) async {
      setPermissionRequester(() async => PermissionStatus.denied);

      await mountWidget(
        QrScanner(onBarcodeDetected: (_) {}),
        tester,
      );
      await tester.pump();

      expect(find.byKey(const Key('scanner_notice')), findsOneWidget);
      expect(find.byType(MobileScanner), findsNothing);
    });

    testWidgets('shows error UI when permission is denied', (tester) async {
      setPermissionRequester(() async => PermissionStatus.denied);

      await mountWidget(
        QrScanner(onBarcodeDetected: (_) {}),
        tester,
      );
      await tester.pump();

      expect(find.byKey(const Key('scanner_notice_icon')), findsOneWidget);
      expect(find.text('Camera permission denied'), findsOneWidget);
      expect(
        find.text('Please enable camera access in your device settings to scan QR codes.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('open_settings_button')), findsOneWidget);
    });

    testWidgets('does not show error UI while loading', (tester) async {
      var resolvePermission = false;
      setPermissionRequester(() async {
        while (!resolvePermission) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        return PermissionStatus.granted;
      });

      await mountWidget(
        QrScanner(onBarcodeDetected: (_) {}),
        tester,
      );

      expect(find.byKey(const Key('scanner_placeholder')), findsOneWidget);
      expect(find.byKey(const Key('scanner_notice_icon')), findsNothing);

      resolvePermission = true;
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();
    });

    testWidgets('uses custom dimensions when provided', (tester) async {
      await mountWidget(
        QrScanner(
          onBarcodeDetected: (_) {},
          width: 200,
          height: 300,
        ),
        tester,
      );
      await tester.pump();

      final container = tester.getSize(find.byType(MobileScanner).first);
      expect(container.width, lessThanOrEqualTo(200));
      expect(container.height, lessThanOrEqualTo(300));
    });

    testWidgets('does not show scan button key by default', (tester) async {
      await mountWidget(
        QrScanner(onBarcodeDetected: (_) {}),
        tester,
      );
      await tester.pump();

      expect(find.byKey(const Key('scan_button')), findsNothing);
    });

    testWidgets('scanner is configured for qrCode format', (tester) async {
      await mountWidget(
        QrScanner(onBarcodeDetected: (_) {}),
        tester,
      );
      await tester.pump();

      final scanner = tester.widget<MobileScanner>(find.byType(MobileScanner));
      expect(scanner.controller?.formats, contains(BarcodeFormat.qrCode));
    });

    testWidgets('controller has autoStart disabled', (tester) async {
      await mountWidget(
        QrScanner(onBarcodeDetected: (_) {}),
        tester,
      );
      await tester.pump();

      final scanner = tester.widget<MobileScanner>(find.byType(MobileScanner));
      expect(scanner.controller?.autoStart, isFalse);
    });

    testWidgets('calls start on controller when mounted', (tester) async {
      await mountWidget(
        QrScanner(onBarcodeDetected: (_) {}),
        tester,
      );
      await tester.pump();

      expect(mockController.startCalled, isTrue);
    });

    testWidgets('disposes controller on unmount', (tester) async {
      await mountWidget(
        QrScanner(onBarcodeDetected: (_) {}),
        tester,
      );
      await tester.pump();

      expect(mockController.disposeCalled, isFalse);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();

      expect(mockController.disposeCalled, isTrue);
    });

    group('barcode detection', () {
      testWidgets('calls onBarcodeDetected when barcode is scanned', (tester) async {
        String? detectedValue;

        await mountWidget(
          QrScanner(onBarcodeDetected: (value) => detectedValue = value),
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
          QrScanner(onBarcodeDetected: (value) => detectedValue = value),
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
          QrScanner(onBarcodeDetected: (value) => detectedValue = value),
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
          QrScanner(onBarcodeDetected: (value) => detectedValue = value),
          tester,
        );
        await tester.pump();

        mockController.emitBarcode('  npub1test  ');
        await tester.pump();

        expect(detectedValue, 'npub1test');

        await tester.pump(const Duration(milliseconds: 600));
      });

      testWidgets('ignores barcodes while processing', (tester) async {
        final detectedValues = <String>[];

        await mountWidget(
          QrScanner(onBarcodeDetected: (value) => detectedValues.add(value)),
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
          QrScanner(onBarcodeDetected: (value) => detectedValues.add(value)),
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

        await mountWidget(
          QrScanner(onBarcodeDetected: (_) {}),
          tester,
        );
        await tester.pump();

        expect(mockController.startCallCount, 1);
        expect(mockController.disposeCalled, isFalse);

        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
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

          await mountWidget(QrScanner(onBarcodeDetected: (_) {}), tester);
          await tester.pump();

          expect(find.byKey(const Key('scanner_placeholder')), findsOneWidget);

          completer.complete(PermissionStatus.granted);
          await tester.pump();
          await tester.pump();
          expect(find.byType(MobileScanner), findsOneWidget);
          expect(mockController.startCallCount, 1);

          tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
          await tester.pump();
          await tester.pump();

          expect(mockController.startCallCount, 2);
          expect(mockController.disposeCalled, isTrue);
          expect(find.byType(MobileScanner), findsOneWidget);
        },
      );

      testWidgets('does not re-request permission on resume when denied', (tester) async {
        var requestCount = 0;
        setPermissionRequester(() async {
          requestCount++;
          return PermissionStatus.denied;
        });
        setPermissionStatusChecker(() async => PermissionStatus.denied);

        await mountWidget(QrScanner(onBarcodeDetected: (_) {}), tester);
        await tester.pump();

        expect(requestCount, 1);

        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pump();
        await tester.pump();

        expect(requestCount, 1);
      });

      testWidgets('shows error UI after denial when lifecycle resume fires', (tester) async {
        setPermissionRequester(() async => PermissionStatus.denied);
        setPermissionStatusChecker(() async => PermissionStatus.denied);

        await mountWidget(QrScanner(onBarcodeDetected: (_) {}), tester);
        await tester.pump();

        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pump();
        await tester.pump();
        await tester.pump();

        expect(find.byKey(const Key('scanner_notice_icon')), findsOneWidget);
        expect(find.byKey(const Key('open_settings_button')), findsOneWidget);
        expect(find.byType(MobileScanner), findsNothing);
      });

      testWidgets('retries scanner on resume after user grants permission in settings', (
        tester,
      ) async {
        setPermissionRequester(() async => PermissionStatus.denied);
        setPermissionStatusChecker(() async => PermissionStatus.denied);

        await mountWidget(QrScanner(onBarcodeDetected: (_) {}), tester);
        await tester.pump();

        expect(find.byKey(const Key('open_settings_button')), findsOneWidget);

        setPermissionRequester(() async => PermissionStatus.granted);
        setPermissionStatusChecker(() async => PermissionStatus.granted);

        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pump();
        await tester.pump();
        await tester.pump();
        await tester.pump();

        expect(find.byType(MobileScanner), findsOneWidget);
      });

      testWidgets(
        'does not retry permission on resume after dialog dismissal even if status returns granted',
        (tester) async {
          var requestCount = 0;
          setPermissionRequester(() async {
            requestCount++;
            return PermissionStatus.denied;
          });
          setPermissionStatusChecker(() async => PermissionStatus.granted);

          await mountWidget(QrScanner(onBarcodeDetected: (_) {}), tester);
          await tester.pump();

          expect(requestCount, 1);
          expect(find.byKey(const Key('open_settings_button')), findsOneWidget);

          tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
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

    group('error handling', () {
      testWidgets('errorBuilder returns placeholder widget', (tester) async {
        await mountWidget(
          QrScanner(onBarcodeDetected: (_) {}),
          tester,
        );
        await tester.pump();

        final scanner = tester.widget<MobileScanner>(find.byType(MobileScanner));
        final context = tester.element(find.byType(MobileScanner));
        const error = MobileScannerException(
          errorCode: MobileScannerErrorCode.permissionDenied,
        );

        final errorWidget = scanner.errorBuilder!(context, error);
        expect(errorWidget, isNotNull);
      });

      testWidgets('shows permission denied message when permission is denied', (
        tester,
      ) async {
        await mountWidget(
          QrScanner(onBarcodeDetected: (_) {}),
          tester,
        );
        await tester.pump();

        final scanner = tester.widget<MobileScanner>(find.byType(MobileScanner));
        final context = tester.element(find.byType(MobileScanner));
        const error = MobileScannerException(
          errorCode: MobileScannerErrorCode.permissionDenied,
        );

        scanner.errorBuilder!(context, error);
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('scanner_notice_icon')), findsOneWidget);
        expect(find.text('Camera permission denied'), findsOneWidget);
        expect(find.byKey(const Key('open_settings_button')), findsOneWidget);
      });

      testWidgets('shows scanner error UI with retry after generic error', (tester) async {
        await mountWidget(
          QrScanner(onBarcodeDetected: (_) {}),
          tester,
        );
        await tester.pump();

        final scanner = tester.widget<MobileScanner>(find.byType(MobileScanner));
        final context = tester.element(find.byType(MobileScanner));
        const error = MobileScannerException(
          errorCode: MobileScannerErrorCode.genericError,
        );

        scanner.errorBuilder!(context, error);
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('scanner_notice_icon')), findsOneWidget);
        expect(find.text('Scanner error'), findsOneWidget);
        expect(find.byKey(const Key('retry_scanner_button')), findsOneWidget);
      });
    });

    group('start guard', () {
      testWidgets('does not call start twice on the same controller', (tester) async {
        await mountWidget(
          QrScanner(onBarcodeDetected: (_) {}),
          tester,
        );
        await tester.pump();

        expect(mockController.startCallCount, 1);
      });

      testWidgets('resets start guard on resume', (tester) async {
        setPermissionStatusChecker(() async => PermissionStatus.granted);

        await mountWidget(
          QrScanner(onBarcodeDetected: (_) {}),
          tester,
        );
        await tester.pump();

        expect(mockController.startCallCount, 1);

        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pump();
        await tester.pump();
        await tester.pump();

        expect(mockController.startCallCount, 2);
      });
    });

    group('permission handling', () {
      testWidgets('shows placeholder when permission is permanently denied', (tester) async {
        setPermissionRequester(() async => PermissionStatus.permanentlyDenied);

        await mountWidget(
          QrScanner(onBarcodeDetected: (_) {}),
          tester,
        );
        await tester.pump();

        expect(find.byKey(const Key('scanner_notice')), findsOneWidget);
        expect(find.byType(MobileScanner), findsNothing);
      });

      testWidgets('shows scanner when permission is limited', (tester) async {
        setPermissionRequester(() async => PermissionStatus.limited);

        await mountWidget(
          QrScanner(onBarcodeDetected: (_) {}),
          tester,
        );
        await tester.pump();

        expect(find.byType(MobileScanner), findsOneWidget);
      });
    });
  });
}
