import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// File-based key-value storage used on Linux instead of FlutterSecureStorage.
///
/// flutter_secure_storage_linux calls libsecret / Secret Service, which pops
/// up a gnome-keyring password prompt when the default collection is locked.
/// The values stored here (active-account pubkey, debug flags) are not
/// sensitive, so a plain JSON file in the app documents directory is fine.
class LinuxPlatformStorage {
  const LinuxPlatformStorage();

  static Future<File> _storageFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final storageDir = Directory('${dir.path}/whitenoise');
    await storageDir.create(recursive: true);
    return File('${storageDir.path}/platform_storage.json');
  }

  static Future<Map<String, String>> _load() async {
    try {
      final file = await _storageFile();
      if (!await file.exists()) return {};
      final content = await file.readAsString();
      final decoded = json.decode(content) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return {};
    }
  }

  static Future<void> _save(Map<String, String> data) async {
    final file = await _storageFile();
    await file.writeAsString(json.encode(data));
  }

  Future<String?> read({required String key}) async {
    final data = await _load();
    return data[key];
  }

  Future<void> write({required String key, required String? value}) async {
    if (value == null) {
      return delete(key: key);
    }
    final data = await _load();
    data[key] = value;
    await _save(data);
  }

  Future<void> delete({required String key}) async {
    final data = await _load();
    data.remove(key);
    await _save(data);
  }

  Future<Map<String, String>> readAll() async {
    return _load();
  }

  Future<void> deleteAll() async {
    await _save({});
  }
}
