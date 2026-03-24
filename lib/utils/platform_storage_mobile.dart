import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// FlutterSecureStorage wrapper used on Android and iOS.
///
/// On mobile platforms the OS keystore (Keychain / EncryptedSharedPreferences)
/// provides hardware-backed encryption without prompting the user.
class MobilePlatformStorage {
  const MobilePlatformStorage();

  static const _storage = FlutterSecureStorage();

  Future<String?> read({required String key}) => _storage.read(key: key);

  Future<void> write({required String key, required String? value}) =>
      _storage.write(key: key, value: value);

  Future<void> delete({required String key}) => _storage.delete(key: key);

  Future<Map<String, String>> readAll() => _storage.readAll();

  Future<void> deleteAll() => _storage.deleteAll();
}
