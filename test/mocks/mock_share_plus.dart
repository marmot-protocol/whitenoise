import 'package:flutter/services.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';

class _MockSharePlatform extends SharePlatform {
  bool shouldFail = false;

  @override
  Future<ShareResult> share(ShareParams params) async {
    if (shouldFail) {
      throw PlatformException(code: 'ERROR', message: 'Share failed');
    }
    _shareCalls.add(params);
    return ShareResult.unavailable;
  }
}

// Single shared instance — SharePlus.instance captures SharePlatform.instance
// once at static init time, so swapping the platform later has no effect.
// Mutating this object's shouldFail flag changes behavior via the already-captured ref.
final _mockSharePlatform = _MockSharePlatform();
List<ShareParams> _shareCalls = [];
SharePlatform? _originalInstance;

List<ShareParams> mockSharePlus() {
  _shareCalls = [];
  _mockSharePlatform.shouldFail = false;
  _originalInstance ??= SharePlatform.instance;
  SharePlatform.instance = _mockSharePlatform;
  return _shareCalls;
}

void mockSharePlusFailing() {
  _mockSharePlatform.shouldFail = true;
  _originalInstance ??= SharePlatform.instance;
  SharePlatform.instance = _mockSharePlatform;
}

void clearSharePlusMock() {
  _mockSharePlatform.shouldFail = false;
  if (_originalInstance != null) {
    SharePlatform.instance = _originalInstance!;
    _originalInstance = null;
  }
  _shareCalls = [];
}
