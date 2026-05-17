import 'dart:io' show Directory, File;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_foreground_task/flutter_foreground_task.dart' show FlutterForegroundTask;
import 'package:flutter_secure_storage/flutter_secure_storage.dart' show FlutterSecureStorage;
import 'package:path_provider/path_provider.dart' show getApplicationDocumentsDirectory;

const kResetPendingFileName = 'reset_pending';

@visibleForTesting
Future<File> Function()? debugResetPendingMarkerFile;

@visibleForTesting
Future<void> Function()? debugMarkResetPending;

@visibleForTesting
Future<void> Function()? debugClearResetPending;

Future<File> resetPendingMarkerFile() async {
  final debugMarkerFile = debugResetPendingMarkerFile;
  if (debugMarkerFile != null) {
    return debugMarkerFile();
  }

  final dir = await getApplicationDocumentsDirectory();
  return File('${dir.path}/whitenoise/$kResetPendingFileName');
}

Future<void> markResetPending() async {
  final debugMark = debugMarkResetPending;
  if (debugMark != null) {
    await debugMark();
    return;
  }

  final marker = await resetPendingMarkerFile();
  await marker.parent.create(recursive: true);
  await marker.writeAsString(DateTime.now().toUtc().toIso8601String(), flush: true);
}

Future<void> clearResetPending() async {
  final debugClear = debugClearResetPending;
  if (debugClear != null) {
    await debugClear();
    return;
  }

  final marker = await resetPendingMarkerFile();
  if (await marker.exists()) {
    await marker.delete();
  }
}

Future<void> recoverPendingReset({
  required String dataDir,
  required String logsDir,
  Future<void> Function()? clearSecureStorage,
  Future<void> Function()? clearForegroundTaskData,
}) async {
  final marker = await resetPendingMarkerFile();
  if (!await marker.exists()) return;

  for (final path in [dataDir, logsDir]) {
    final dir = Directory(path);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  final clearStorage =
      clearSecureStorage ??
      () async {
        const secureStorage = FlutterSecureStorage();
        await secureStorage.deleteAll();
      };
  await clearStorage();
  // Foreground-task plugin state can contain account-bound service metadata;
  // clear it with the rest of the local reset surface.
  await (clearForegroundTaskData ?? FlutterForegroundTask.clearAllData)();
  await clearResetPending();
}
