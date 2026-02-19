import 'dart:ui' show AppLifecycleState;

import 'package:flutter/material.dart' show Key, SizedBox;
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:whitenoise/widgets/wn_scan_box.dart';
import '../mocks/mock_scanner_controller.dart';
import '../test_helpers.dart' show mountWidget;

void main() {
  group('WnScanBox', () {
    late MockScannerController mockController;

    setUp(() {
      mockController = setupMockScannerController();
      setPermissionRequester(() async => PermissionStatus.granted);
    });

    tearDown(() {
      tearDownMockScannerController();
      resetPermissionRequester();
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
        WnScanBox(onBarcodeDetected: (_) {}),
        tester,
      );

      expect(find.byKey(const Key('scanner_placeholder')), findsOneWidget);

      resolvePermission = true;
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();
    });

    testWidgets('renders scanner container after permission granted', (tester) async {
      await mountWidget(
        WnScanBox(onBarcodeDetected: (_) {}),
        tester,
      );
      await tester.pump();

      expect(find.byType(MobileScanner), findsOneWidget);
    });

    testWidgets('shows placeholder when permission is denied', (tester) async {
      setPermissionRequester(() async => PermissionStatus.denied);

      await mountWidget(
        WnScanBox(onBarcodeDetected: (_) {}),
        tester,
      );
      await tester.pump();

      expect(find.byKey(const Key('scanner_placeholder')), findsOneWidget);
      expect(find.byType(MobileScanner), findsNothing);
    });

    testWidgets('shows error UI when permission is denied', (tester) async {
      setPermissionRequester(() async => PermissionStatus.denied);

      await mountWidget(
        WnScanBox(onBarcodeDetected: (_) {}),
        tester,
      );
      await tester.pump();

      expect(find.byKey(const Key('scanner_error_icon')), findsOneWidget);
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
        WnScanBox(onBarcodeDetected: (_) {}),
        tester,
      );

      expect(find.byKey(const Key('scanner_placeholder')), findsOneWidget);
      expect(find.byKey(const Key('scanner_error_icon')), findsNothing);

      resolvePermission = true;
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();
    });

    testWidgets('uses custom dimensions when provided', (tester) async {
      await mountWidget(
        WnScanBox(
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
        WnScanBox(onBarcodeDetected: (_) {}),
        tester,
      );
      await tester.pump();

      expect(find.byKey(const Key('scan_button')), findsNothing);
    });

    testWidgets('scanner is configured for qrCode format', (tester) async {
      await mountWidget(
        WnScanBox(onBarcodeDetected: (_) {}),
        tester,
      );
      await tester.pump();

      final scanner = tester.widget<MobileScanner>(find.byType(MobileScanner));
      expect(scanner.controller?.formats, contains(BarcodeFormat.qrCode));
    });

    testWidgets('controller has autoStart disabled', (tester) async {
      await mountWidget(
        WnScanBox(onBarcodeDetected: (_) {}),
        tester,
      );
      await tester.pump();

      final scanner = tester.widget<MobileScanner>(find.byType(MobileScanner));
      expect(scanner.controller?.autoStart, isFalse);
    });

    testWidgets('calls start on controller when mounted', (tester) async {
      await mountWidget(
        WnScanBox(onBarcodeDetected: (_) {}),
        tester,
      );
      await tester.pump();

      expect(mockController.startCalled, isTrue);
    });

    testWidgets('disposes controller on unmount', (tester) async {
      await mountWidget(
        WnScanBox(onBarcodeDetected: (_) {}),
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
          WnScanBox(onBarcodeDetected: (value) => detectedValue = value),
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
          WnScanBox(onBarcodeDetected: (value) => detectedValue = value),
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
          WnScanBox(onBarcodeDetected: (value) => detectedValue = value),
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
          WnScanBox(onBarcodeDetected: (value) => detectedValue = value),
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
          WnScanBox(onBarcodeDetected: (value) => detectedValues.add(value)),
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
          WnScanBox(onBarcodeDetected: (value) => detectedValues.add(value)),
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
      testWidgets('recreates scanner on resume', (tester) async {
        await mountWidget(
          WnScanBox(onBarcodeDetected: (_) {}),
          tester,
        );
        await tester.pump();

        final scanner = tester.widget<MobileScanner>(find.byType(MobileScanner));
        final initialKey = scanner.key;

        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pump();
        await tester.pump();

        final newScanner = tester.widget<MobileScanner>(find.byType(MobileScanner));
        expect(newScanner.key, isNot(equals(initialKey)));
      });
    });

    group('error handling', () {
      testWidgets('errorBuilder returns placeholder widget', (tester) async {
        await mountWidget(
          WnScanBox(onBarcodeDetected: (_) {}),
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
          WnScanBox(onBarcodeDetected: (_) {}),
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

        expect(find.text('Camera permission denied'), findsOneWidget);
        expect(find.byKey(const Key('open_settings_button')), findsOneWidget);
      });

      testWidgets('shows scanner error UI with retry after generic error', (tester) async {
        await mountWidget(
          WnScanBox(onBarcodeDetected: (_) {}),
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

        expect(find.text('Scanner error'), findsOneWidget);
        expect(find.byKey(const Key('retry_scanner_button')), findsOneWidget);
      });
    });

    group('start guard', () {
      testWidgets('does not call start twice on the same controller', (tester) async {
        await mountWidget(
          WnScanBox(onBarcodeDetected: (_) {}),
          tester,
        );
        await tester.pump();

        expect(mockController.startCallCount, 1);
      });

      testWidgets('resets start guard on retry', (tester) async {
        await mountWidget(
          WnScanBox(onBarcodeDetected: (_) {}),
          tester,
        );
        await tester.pump();

        expect(mockController.startCallCount, 1);

        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pump();
        await tester.pump();

        expect(mockController.startCallCount, 2);
      });
    });

    group('permission handling', () {
      testWidgets('shows placeholder when permission is permanently denied', (tester) async {
        setPermissionRequester(() async => PermissionStatus.permanentlyDenied);

        await mountWidget(
          WnScanBox(onBarcodeDetected: (_) {}),
          tester,
        );
        await tester.pump();

        expect(find.byKey(const Key('scanner_placeholder')), findsOneWidget);
        expect(find.byType(MobileScanner), findsNothing);
      });

      testWidgets('shows scanner when permission is limited', (tester) async {
        setPermissionRequester(() async => PermissionStatus.limited);

        await mountWidget(
          WnScanBox(onBarcodeDetected: (_) {}),
          tester,
        );
        await tester.pump();

        expect(find.byType(MobileScanner), findsOneWidget);
      });
    });
  });
}
