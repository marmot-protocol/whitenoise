import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/theme.dart';

MobileScannerController Function() _controllerFactory = _defaultControllerFactory;

MobileScannerController _defaultControllerFactory() =>
    MobileScannerController(formats: [BarcodeFormat.qrCode], autoStart: false);

MobileScannerController createScannerController() => _controllerFactory();

void setScannerControllerFactory(MobileScannerController Function() factory) {
  _controllerFactory = factory;
}

void resetScannerControllerFactory() {
  _controllerFactory = _defaultControllerFactory;
}

class WnScanBox extends HookWidget {
  const WnScanBox({
    super.key,
    required this.onBarcodeDetected,
    this.onError,
    this.width,
    this.height,
  });

  final void Function(String value) onBarcodeDetected;
  final void Function(MobileScannerException error)? onError;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isProcessing = useState(false);
    final scannerKey = useState(0);
    final hasError = useRef(false);
    final isMounted = useRef(true);

    useEffect(() {
      isMounted.value = true;
      return () => isMounted.value = false;
    }, const []);

    final controller = useMemoized(
      createScannerController,
      [scannerKey.value],
    );

    useEffect(() {
      void handleBarcode(BarcodeCapture capture) {
        if (capture.barcodes.isEmpty) return;
        if (isProcessing.value) return;

        final barcode = capture.barcodes.first;
        final rawValue = barcode.rawValue ?? '';
        if (rawValue.isEmpty) return;

        isProcessing.value = true;
        onBarcodeDetected(rawValue.trim());
        Future.delayed(const Duration(milliseconds: 500), () {
          if (isMounted.value) {
            isProcessing.value = false;
          }
        });
      }

      hasError.value = false;
      final subscription = controller.barcodes.listen(handleBarcode);
      unawaited(controller.start());

      return () {
        unawaited(subscription.cancel());
        controller.dispose();
      };
    }, [controller]);

    useOnAppLifecycleStateChange((previous, current) {
      if (current == AppLifecycleState.resumed && hasError.value) {
        if (isMounted.value) {
          scannerKey.value++;
        }
      }
    });

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: colors.borderTertiary, width: 1.w),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7.r),
        child: MobileScanner(
          key: ValueKey(scannerKey.value),
          controller: controller,
          errorBuilder: (context, error) {
            hasError.value = true;
            onError?.call(error);
            if (error.errorCode == MobileScannerErrorCode.permissionDenied) {
              return _CameraPermissionDenied(colors: colors);
            }
            return _ScannerError(colors: colors);
          },
        ),
      ),
    );
  }
}

class _CameraPermissionDenied extends StatelessWidget {
  const _CameraPermissionDenied({required this.colors});

  final SemanticColors colors;

  @override
  Widget build(BuildContext context) {
    final typography = context.typographyScaled;
    return Container(
      color: colors.backgroundSecondary,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Text(
            context.l10n.cameraPermissionDenied,
            textAlign: TextAlign.center,
            style: typography.medium14.copyWith(color: colors.backgroundContentSecondary),
          ),
        ),
      ),
    );
  }
}

class _ScannerError extends StatelessWidget {
  const _ScannerError({required this.colors});

  final SemanticColors colors;

  @override
  Widget build(BuildContext context) {
    final typography = context.typographyScaled;
    return Container(
      color: colors.backgroundSecondary,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Text(
            context.l10n.somethingWentWrong,
            textAlign: TextAlign.center,
            style: typography.medium14.copyWith(color: colors.backgroundContentSecondary),
          ),
        ),
      ),
    );
  }
}
