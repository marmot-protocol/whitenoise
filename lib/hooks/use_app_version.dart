import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:package_info_plus/package_info_plus.dart';

AsyncSnapshot<String> useAppVersion() {
  final future = useMemoized(() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  });
  return useFuture(future);
}
