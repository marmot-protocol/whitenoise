import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart' show Gap;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_icon.dart';

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

Future<PermissionStatus> Function() _permissionRequester = _defaultPermissionRequester;

Future<PermissionStatus> _defaultPermissionRequester() => Permission.camera.request();

Future<PermissionStatus> requestCameraPermission() => _permissionRequester();

void setPermissionRequester(Future<PermissionStatus> Function() requester) {
  _permissionRequester = requester;
}

void resetPermissionRequester() {
  _permissionRequester = _defaultPermissionRequester;
}

enum ScannerState {
  loading,
  ready,
  permissionDenied,
  initError,
  error,
}

class WnScanBox extends HookWidget {
  const WnScanBox({
    super.key,
    required this.onBarcodeDetected,
    this.width,
    this.height,
  });

  final void Function(String value) onBarcodeDetected;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isProcessing = useState(false);
    final scannerRetryKey = useState(UniqueKey());
    final isMounted = useRef(true);
    final controllerStarted = useRef(false);
    final boxState = useState(ScannerState.loading);

    useEffect(() {
      isMounted.value = true;
      return () => isMounted.value = false;
    }, const []);

    useEffect(() {
      Future<void> checkPermission() async {
        final status = await requestCameraPermission();
        if (!isMounted.value) return;

        if (status.isGranted || status.isLimited) {
          boxState.value = ScannerState.ready;
        } else {
          boxState.value = ScannerState.permissionDenied;
        }
      }

      unawaited(checkPermission());
      return null;
    }, [scannerRetryKey.value]);

    final controller = useMemoized(
      createScannerController,
      [scannerRetryKey.value],
    );

    useEffect(() {
      if (boxState.value != ScannerState.ready) return null;

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

      Future<void> startController() async {
        if (controllerStarted.value) return;
        controllerStarted.value = true;
        await controller.start();
      }

      final subscription = controller.barcodes.listen(handleBarcode);
      unawaited(startController());

      return () {
        controllerStarted.value = false;
        unawaited(subscription.cancel());
        controller.dispose();
      };
    }, [controller, boxState.value]);

    void retryScanner() {
      boxState.value = ScannerState.loading;
      scannerRetryKey.value = UniqueKey();
    }

    useOnAppLifecycleStateChange((previous, current) {
      if (current == AppLifecycleState.resumed) {
        if (isMounted.value) {
          retryScanner();
        }
      }
    });

    final showScanner = boxState.value == ScannerState.ready;
    final isError = boxState.value != ScannerState.loading && !showScanner;

    return Container(
      key: const Key('scan_box'),
      width: width,
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: colors.borderTertiary, width: 1.w),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7.r),
        child: showScanner
            ? MobileScanner(
                key: ValueKey(scannerRetryKey.value),
                controller: controller,
                errorBuilder: (context, error) {
                  final newState = switch (error.errorCode) {
                    MobileScannerErrorCode.permissionDenied => ScannerState.permissionDenied,
                    MobileScannerErrorCode.controllerAlreadyInitialized => ScannerState.initError,
                    _ => ScannerState.error,
                  };
                  Future.microtask(() {
                    if (isMounted.value) {
                      boxState.value = newState;
                    }
                  });
                  return _ScannerError(
                    scannerState: ScannerState.error,
                    onRetry: retryScanner,
                  );
                },
              )
            : isError
            ? _ScannerError(
                scannerState: boxState.value,
                onRetry: retryScanner,
              )
            : _ScannerPlaceholder(colors: colors),
      ),
    );
  }
}

class _ScannerPlaceholder extends StatelessWidget {
  const _ScannerPlaceholder({required this.colors});

  final SemanticColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('scanner_placeholder'),
      color: colors.backgroundSecondary,
    );
  }
}

class _ScannerError extends StatelessWidget {
  const _ScannerError({required this.scannerState, this.onRetry});

  final ScannerState scannerState;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final typography = context.typographyScaled;
    final isPermissionDenied = scannerState == ScannerState.permissionDenied;
    final errorContentColor = colors.intentionErrorContent;

    return Container(
      key: const Key('scanner_placeholder'),
      color: colors.intentionErrorBackground,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              WnIcon(
                WnIcons.errorFilled,
                key: const Key('scanner_error_icon'),
                size: 20.w,
                color: errorContentColor,
              ),
              Gap(8.h),
              Text(
                isPermissionDenied ? l10n.cameraPermissionDenied : l10n.scannerError,
                key: const Key('scanner_error_title'),
                textAlign: TextAlign.center,
                style: typography.bold14.copyWith(color: errorContentColor),
              ),
              Gap(4.h),
              Text(
                isPermissionDenied
                    ? l10n.cameraPermissionDeniedDescription
                    : l10n.scannerErrorDescription,
                key: const Key('scanner_error_description'),
                textAlign: TextAlign.center,
                style: typography.medium14.copyWith(
                  color: colors.backgroundContentQuaternary,
                ),
              ),
              Gap(8.h),
              if (isPermissionDenied)
                WnButton(
                  key: const Key('open_settings_button'),
                  text: l10n.openSettings,
                  onPressed: openAppSettings,
                  size: WnButtonSize.small,
                )
              else
                WnButton(
                  key: const Key('retry_scanner_button'),
                  text: l10n.retry,
                  onPressed: onRetry,
                  size: WnButtonSize.small,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
