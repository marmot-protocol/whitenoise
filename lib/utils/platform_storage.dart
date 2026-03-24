import 'dart:io' show Platform;

import 'package:whitenoise/utils/platform_storage_linux.dart';
import 'package:whitenoise/utils/platform_storage_mobile.dart';

/// Cross-platform key-value storage abstraction.
///
/// Dispatches to [LinuxPlatformStorage] (file-based JSON) on Linux to avoid
/// the gnome-keyring prompt triggered by flutter_secure_storage_linux, and to
/// [MobilePlatformStorage] (FlutterSecureStorage) on Android/iOS for
/// hardware-backed encryption via the OS keystore.
class PlatformStorage {
  const PlatformStorage();

  Future<String?> read({required String key}) => Platform.isLinux
      ? const LinuxPlatformStorage().read(key: key)
      : const MobilePlatformStorage().read(key: key);

  Future<void> write({required String key, required String? value}) =>
      Platform.isLinux
          ? const LinuxPlatformStorage().write(key: key, value: value)
          : const MobilePlatformStorage().write(key: key, value: value);

  Future<void> delete({required String key}) => Platform.isLinux
      ? const LinuxPlatformStorage().delete(key: key)
      : const MobilePlatformStorage().delete(key: key);

  Future<Map<String, String>> readAll() => Platform.isLinux
      ? const LinuxPlatformStorage().readAll()
      : const MobilePlatformStorage().readAll();

  Future<void> deleteAll() => Platform.isLinux
      ? const LinuxPlatformStorage().deleteAll()
      : const MobilePlatformStorage().deleteAll();
}
