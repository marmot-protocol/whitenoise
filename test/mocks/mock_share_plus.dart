import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _sharePlusChannel = MethodChannel('dev.fluttercommunity.plus/share');

List<MethodCall> _shareCalls = [];

List<MethodCall> mockSharePlus() {
  _shareCalls = [];
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    _sharePlusChannel,
    (call) async {
      _shareCalls.add(call);
      return null;
    },
  );
  return _shareCalls;
}

void mockSharePlusFailing() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    _sharePlusChannel,
    (call) async {
      throw PlatformException(code: 'ERROR', message: 'Share failed');
    },
  );
}

void clearSharePlusMock() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    _sharePlusChannel,
    null,
  );
  _shareCalls = [];
}
