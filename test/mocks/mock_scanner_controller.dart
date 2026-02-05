import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:whitenoise/widgets/wn_scan_box.dart';

class MockScannerController implements MobileScannerController {
  MockScannerController();

  final _barcodeController = StreamController<BarcodeCapture>.broadcast();
  final List<VoidCallback> _listeners = [];

  bool startCalled = false;
  bool stopCalled = false;
  bool disposeCalled = false;

  MobileScannerState _value = const MobileScannerState.uninitialized();

  @override
  MobileScannerState get value => _value;

  @override
  set value(MobileScannerState newValue) {
    _value = newValue;
    for (final listener in _listeners) {
      listener();
    }
  }

  @override
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  @override
  bool get hasListeners => _listeners.isNotEmpty;

  @override
  void notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  @override
  void attach() {}

  @override
  Stream<BarcodeCapture> get barcodes => _barcodeController.stream;

  @override
  List<BarcodeFormat> get formats => [BarcodeFormat.qrCode];

  @override
  bool get autoStart => false;

  @override
  Future<void> start({CameraFacing? cameraDirection}) async {
    startCalled = true;
  }

  @override
  Future<void> stop() async {
    stopCalled = true;
  }

  @override
  Future<void> dispose() async {
    disposeCalled = true;
    _listeners.clear();
    await _barcodeController.close();
  }

  void emitBarcode(String barcodeValue) {
    final barcode = Barcode(rawValue: barcodeValue);
    _barcodeController.add(BarcodeCapture(barcodes: [barcode]));
  }

  void emitEmpty() {
    _barcodeController.add(const BarcodeCapture());
  }

  void emitBarcodeWithEmptyValue() {
    const barcode = Barcode(rawValue: '');
    _barcodeController.add(const BarcodeCapture(barcodes: [barcode]));
  }

  void reset() {
    startCalled = false;
    stopCalled = false;
    disposeCalled = false;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

MockScannerController? _mockInstance;

MockScannerController setupMockScannerController() {
  _mockInstance = MockScannerController();
  setScannerControllerFactory(() => _mockInstance!);
  return _mockInstance!;
}

void tearDownMockScannerController() {
  resetScannerControllerFactory();
  _mockInstance = null;
}
