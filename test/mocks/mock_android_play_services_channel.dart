import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _channelName = 'org.parres.whitenoise/android_play_services';

typedef MockAndroidPlayServicesChannel = ({
  void Function(String, Object?) setResult,
  void Function(String, PlatformException) setException,
  void Function(String, Object) setError,
  List<MethodCall> log,
  void Function() reset,
});

MockAndroidPlayServicesChannel mockAndroidPlayServicesChannel() {
  final log = <MethodCall>[];
  final results = <String, Object?>{};
  final exceptions = <String, PlatformException>{};
  final errors = <String, Object>{};
  final channel = const MethodChannel(_channelName);

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    channel,
    (MethodCall call) async {
      log.add(call);
      final anyErr = errors[call.method];
      if (anyErr != null) throw anyErr;
      final e = exceptions[call.method];
      if (e != null) throw e;
      return results[call.method];
    },
  );

  return (
    setResult: (String method, Object? value) {
      results[method] = value;
      exceptions.remove(method);
      errors.remove(method);
    },
    setException: (String method, PlatformException e) {
      exceptions[method] = e;
      results.remove(method);
      errors.remove(method);
    },
    setError: (String method, Object error) {
      errors[method] = error;
      results.remove(method);
      exceptions.remove(method);
    },
    log: log,
    reset: () {
      results.clear();
      exceptions.clear();
      errors.clear();
      log.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      );
    },
  );
}
