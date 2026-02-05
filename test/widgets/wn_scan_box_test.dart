import 'dart:ui' show AppLifecycleState;

import 'package:flutter/material.dart' show Key, Locale, MaterialApp, SizedBox, Widget;
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/widgets/wn_scan_box.dart';
import '../mocks/mock_scanner_controller.dart';
import '../test_helpers.dart' show mountWidget;

void main() {
  group('WnScanBox', () {
    late MockScannerController mockController;

    setUp(() {
      mockController = setupMockScannerController();
    });

    tearDown(() {
      tearDownMockScannerController();
    });

    testWidgets('renders scanner container', (tester) async {
      await mountWidget(
        WnScanBox(onBarcodeDetected: (_) {}),
        tester,
      );
      expect(find.byType(MobileScanner), findsOneWidget);
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
      final container = tester.getSize(find.byType(MobileScanner).first);
      expect(container.width, lessThanOrEqualTo(200));
      expect(container.height, lessThanOrEqualTo(300));
    });

    testWidgets('does not show scan button key by default', (tester) async {
      await mountWidget(
        WnScanBox(onBarcodeDetected: (_) {}),
        tester,
      );
      expect(find.byKey(const Key('scan_button')), findsNothing);
    });

    testWidgets('scanner is configured for qrCode format', (tester) async {
      await mountWidget(
        WnScanBox(onBarcodeDetected: (_) {}),
        tester,
      );

      final scanner = tester.widget<MobileScanner>(find.byType(MobileScanner));
      expect(scanner.controller?.formats, contains(BarcodeFormat.qrCode));
    });

    testWidgets('controller has autoStart disabled', (tester) async {
      await mountWidget(
        WnScanBox(onBarcodeDetected: (_) {}),
        tester,
      );

      final scanner = tester.widget<MobileScanner>(find.byType(MobileScanner));
      expect(scanner.controller?.autoStart, isFalse);
    });

    testWidgets('calls start on controller when mounted', (tester) async {
      await mountWidget(
        WnScanBox(onBarcodeDetected: (_) {}),
        tester,
      );

      expect(mockController.startCalled, isTrue);
    });

    testWidgets('disposes controller on unmount', (tester) async {
      await mountWidget(
        WnScanBox(onBarcodeDetected: (_) {}),
        tester,
      );

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
      testWidgets('recreates scanner on resume when error occurred', (tester) async {
        await mountWidget(
          WnScanBox(onBarcodeDetected: (_) {}),
          tester,
        );

        final scanner = tester.widget<MobileScanner>(find.byType(MobileScanner));
        const error = MobileScannerException(
          errorCode: MobileScannerErrorCode.genericError,
        );
        scanner.errorBuilder!(tester.element(find.byType(MobileScanner)), error);
        await tester.pump();

        final initialKey = scanner.key;

        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pump();

        final newScanner = tester.widget<MobileScanner>(find.byType(MobileScanner));
        expect(newScanner.key, isNot(equals(initialKey)));
      });

      testWidgets('does not recreate scanner on resume when no error', (tester) async {
        await mountWidget(
          WnScanBox(onBarcodeDetected: (_) {}),
          tester,
        );

        final scanner = tester.widget<MobileScanner>(find.byType(MobileScanner));
        final initialKey = scanner.key;

        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pump();

        final newScanner = tester.widget<MobileScanner>(find.byType(MobileScanner));
        expect(newScanner.key, equals(initialKey));
      });
    });

    group('error handling', () {
      testWidgets('calls onError when error occurs', (tester) async {
        MobileScannerException? receivedError;

        await mountWidget(
          WnScanBox(
            onBarcodeDetected: (_) {},
            onError: (error) => receivedError = error,
          ),
          tester,
        );

        final scanner = tester.widget<MobileScanner>(find.byType(MobileScanner));
        const error = MobileScannerException(
          errorCode: MobileScannerErrorCode.genericError,
        );

        scanner.errorBuilder!(tester.element(find.byType(MobileScanner)), error);
        await tester.pump();

        expect(receivedError, error);
      });

      testWidgets('shows permission denied message when permission denied', (tester) async {
        await mountWidget(
          WnScanBox(onBarcodeDetected: (_) {}),
          tester,
        );

        final scanner = tester.widget<MobileScanner>(find.byType(MobileScanner));
        final context = tester.element(find.byType(MobileScanner));
        const error = MobileScannerException(
          errorCode: MobileScannerErrorCode.permissionDenied,
        );

        final errorWidget = scanner.errorBuilder!(context, error);
        await tester.pumpWidget(
          _wrapWithLocalization(errorWidget),
        );

        expect(find.text('Camera permission denied'), findsOneWidget);
      });

      testWidgets('shows generic error message for other errors', (tester) async {
        await mountWidget(
          WnScanBox(onBarcodeDetected: (_) {}),
          tester,
        );

        final scanner = tester.widget<MobileScanner>(find.byType(MobileScanner));
        final context = tester.element(find.byType(MobileScanner));
        const error = MobileScannerException(
          errorCode: MobileScannerErrorCode.genericError,
        );

        final errorWidget = scanner.errorBuilder!(context, error);
        await tester.pumpWidget(
          _wrapWithLocalization(errorWidget),
        );

        expect(find.text('Something went wrong'), findsOneWidget);
      });
    });
  });
}

MaterialApp _wrapWithLocalization(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: child,
  );
}
