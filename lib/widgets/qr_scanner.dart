import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart' show Gap;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:whitenoise/hooks/use_qr_scanner.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_icon.dart';

export 'package:whitenoise/hooks/use_qr_scanner.dart'
    show
        ScannerState,
        createScannerController,
        setScannerControllerFactory,
        resetScannerControllerFactory,
        requestCameraPermission,
        setPermissionRequester,
        resetPermissionRequester,
        checkCameraPermissionStatus,
        setPermissionStatusChecker,
        resetPermissionStatusChecker;

class QrScanner extends HookWidget {
  const QrScanner({
    super.key,
    required this.onQrCodeDetected,
    this.width,
    this.height,
  });

  final void Function(String value) onQrCodeDetected;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (:scannerState, :controller, :retryScanner, :setErrorState) = useQrScanner(
      onQrCodeDetected: onQrCodeDetected,
    );
    final showScanner = scannerState == ScannerState.ready;
    final isError = scannerState != ScannerState.loading && !showScanner;

    return Container(
      key: const Key('qr_scanner'),
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
                key: ValueKey(controller),
                controller: controller,
                errorBuilder: (context, error) {
                  final newState = switch (error.errorCode) {
                    MobileScannerErrorCode.permissionDenied => ScannerState.permissionDenied,
                    MobileScannerErrorCode.controllerAlreadyInitialized => ScannerState.initError,
                    _ => ScannerState.error,
                  };
                  Future.microtask(() {
                    setErrorState(newState);
                  });
                  return _ScannerNotice(
                    scannerState: newState,
                    onRetry: retryScanner,
                  );
                },
              )
            : isError
            ? _ScannerNotice(
                scannerState: scannerState,
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

class _ScannerNotice extends StatelessWidget {
  const _ScannerNotice({required this.scannerState, this.onRetry});

  final ScannerState scannerState;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final typography = context.typographyScaled;
    final isPermissionDenied = scannerState == ScannerState.permissionDenied;
    final noticeColor = isPermissionDenied
        ? colors.intentionWarningContent
        : colors.intentionErrorContent;
    final icon = isPermissionDenied ? WnIcons.warningFilled : WnIcons.errorFilled;

    return Container(
      key: const Key('scanner_notice'),
      color: colors.backgroundSecondary,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              WnIcon(
                icon,
                key: const Key('scanner_notice_icon'),
                size: 20.w,
                color: noticeColor,
              ),
              Gap(8.h),
              Text(
                isPermissionDenied ? l10n.cameraPermissionDenied : l10n.scannerError,
                key: const Key('scanner_error_title'),
                textAlign: TextAlign.center,
                style: typography.bold14.copyWith(color: noticeColor),
              ),
              Gap(4.h),
              Text(
                isPermissionDenied
                    ? l10n.cameraPermissionDeniedDescription
                    : l10n.scannerErrorDescription,
                key: const Key('scanner_error_description'),
                textAlign: TextAlign.center,
                style: typography.medium12.copyWith(
                  color: colors.backgroundContentSecondary,
                ),
              ),
              Gap(12.h),
              if (isPermissionDenied)
                WnButton(
                  key: const Key('open_settings_button'),
                  text: l10n.openSettings,
                  onPressed: openAppSettings,
                  size: WnButtonSize.small,
                  type: WnButtonType.outline,
                )
              else
                WnButton(
                  key: const Key('retry_scanner_button'),
                  text: l10n.retry,
                  onPressed: onRetry,
                  size: WnButtonSize.small,
                  type: WnButtonType.outline,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
