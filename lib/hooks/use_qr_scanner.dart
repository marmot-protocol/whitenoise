import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class _Injectable<T extends Function> {
  final T _default;
  late T _current;
  _Injectable(this._default) : _current = _default;
  T get value => _current;
  void set(T v) => _current = v;
  void reset() => _current = _default;
}

final _controllerFactory = _Injectable<MobileScannerController Function()>(
  () => MobileScannerController(
    formats: [BarcodeFormat.qrCode],
    autoStart: false,
  ),
);
final _permissionRequester = _Injectable<Future<PermissionStatus> Function()>(
  () => Permission.camera.request(),
);
final _permissionStatusChecker = _Injectable<Future<PermissionStatus> Function()>(
  () => Permission.camera.status,
);

MobileScannerController createScannerController() => _controllerFactory.value();
Future<PermissionStatus> requestCameraPermission() => _permissionRequester.value();
Future<PermissionStatus> checkCameraPermissionStatus() => _permissionStatusChecker.value();

void setScannerControllerFactory(MobileScannerController Function() factory) =>
    _controllerFactory.set(factory);
void resetScannerControllerFactory() => _controllerFactory.reset();
void setPermissionRequester(Future<PermissionStatus> Function() requester) =>
    _permissionRequester.set(requester);
void resetPermissionRequester() => _permissionRequester.reset();
void setPermissionStatusChecker(Future<PermissionStatus> Function() checker) =>
    _permissionStatusChecker.set(checker);
void resetPermissionStatusChecker() => _permissionStatusChecker.reset();

enum ScannerState { loading, ready, permissionDenied, initError, error }

({
  ScannerState scannerState,
  MobileScannerController controller,
  VoidCallback retryScanner,
  void Function(ScannerState) setErrorState,
})
useQrScanner({required void Function(String) onQrCodeDetected}) {
  final isProcessing = useState(false);
  final scannerRetryKey = useState(UniqueKey());
  final isMounted = useRef(true);
  final scannerState = useState(ScannerState.loading);
  final permissionStatusAtDenial = useRef<PermissionStatus?>(null);

  useEffect(() {
    isMounted.value = true;
    return () => isMounted.value = false;
  }, const []);

  useEffect(() {
    Future<void> checkPermission() async {
      final status = await requestCameraPermission();
      if (!isMounted.value) return;

      if (status.isGranted || status.isLimited) {
        permissionStatusAtDenial.value = null;
        scannerState.value = ScannerState.ready;
      } else {
        final currentStatus = await checkCameraPermissionStatus();
        if (!isMounted.value) return;
        permissionStatusAtDenial.value = currentStatus;
        scannerState.value = ScannerState.permissionDenied;
      }
    }

    unawaited(checkPermission());
    return null;
  }, [scannerRetryKey.value]);

  final controller = useMemoized(createScannerController, [
    scannerRetryKey.value,
  ]);

  useEffect(() {
    if (scannerState.value != ScannerState.ready) return null;

    var startCalled = false;

    void handleQrCode(BarcodeCapture capture) {
      if (capture.barcodes.isEmpty) return;
      if (isProcessing.value) return;
      final barcode = capture.barcodes.first;
      final rawValue = barcode.rawValue ?? '';
      if (rawValue.isEmpty) return;
      isProcessing.value = true;
      onQrCodeDetected(rawValue.trim());
      Future.delayed(const Duration(milliseconds: 500), () {
        if (isMounted.value) isProcessing.value = false;
      });
    }

    Future<void> startController() async {
      if (startCalled) return;
      startCalled = true;
      try {
        await controller.start();
      } on MobileScannerException {
        if (isMounted.value) scannerState.value = ScannerState.initError;
      }
    }

    final subscription = controller.barcodes.listen(handleQrCode);
    unawaited(startController());

    return () {
      unawaited(subscription.cancel());
      unawaited(controller.dispose());
    };
  }, [controller, scannerState.value]);

  void retryScanner() {
    scannerState.value = ScannerState.loading;
    scannerRetryKey.value = UniqueKey();
  }

  useOnAppLifecycleStateChange((previous, current) {
    if (current != AppLifecycleState.resumed || !isMounted.value) return;
    if (scannerState.value == ScannerState.permissionDenied) {
      Future<void> checkAndMaybeRetry() async {
        final cameraPermissionStatus = await checkCameraPermissionStatus();
        if (!isMounted.value) return;
        final snapshotWasDenied =
            permissionStatusAtDenial.value != null &&
            !(permissionStatusAtDenial.value!.isGranted ||
                permissionStatusAtDenial.value!.isLimited);
        if (snapshotWasDenied &&
            (cameraPermissionStatus.isGranted || cameraPermissionStatus.isLimited)) {
          retryScanner();
        }
      }

      unawaited(checkAndMaybeRetry());
    } else {
      retryScanner();
    }
  });

  void setErrorState(ScannerState state) {
    if (isMounted.value) {
      scannerState.value = state;
    }
  }

  return (
    scannerState: scannerState.value,
    controller: controller,
    retryScanner: retryScanner,
    setErrorState: setErrorState,
  );
}
