// ignore_for_file: avoid_slow_async_io

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/utils/reset_marker.dart';

import '../test_helpers.dart';

void main() {
  setUpAll(() {
    mockPathProvider();
  });

  setUp(() {
    final markerDir = Directory.systemTemp.createTempSync('wn_reset_marker_');
    debugResetPendingMarkerFile = () async => File('${markerDir.path}/reset_pending');
    addTearDown(() async {
      debugResetPendingMarkerFile = null;
      if (await markerDir.exists()) {
        await markerDir.delete(recursive: true);
      }
    });
  });

  tearDown(() async {
    await clearResetPending();
    debugMarkResetPending = null;
    debugClearResetPending = null;
  });

  test('markResetPending creates marker and clearResetPending removes it', () async {
    final marker = await resetPendingMarkerFile();

    await markResetPending();

    expect(await marker.exists(), true);
    expect(await marker.parent.exists(), true);
    expect(await marker.readAsString(), isNotEmpty);

    await clearResetPending();

    expect(await marker.exists(), false);
  });

  test('markResetPending and clearResetPending use debug overrides when provided', () async {
    var markCalled = false;
    var clearCalled = false;
    debugMarkResetPending = () async => markCalled = true;
    debugClearResetPending = () async => clearCalled = true;

    await markResetPending();
    await clearResetPending();

    expect(markCalled, true);
    expect(clearCalled, true);
  });

  test('recoverPendingReset does nothing when no marker exists', () async {
    var clearedSecureStorage = false;
    var clearedForegroundTaskData = false;
    final dataDir = await Directory.systemTemp.createTemp('wn_data_');
    final logsDir = await Directory.systemTemp.createTemp('wn_logs_');

    await recoverPendingReset(
      dataDir: dataDir.path,
      logsDir: logsDir.path,
      clearSecureStorage: () async => clearedSecureStorage = true,
      clearForegroundTaskData: () async => clearedForegroundTaskData = true,
    );

    expect(await dataDir.exists(), true);
    expect(await logsDir.exists(), true);
    expect(clearedSecureStorage, false);
    expect(clearedForegroundTaskData, false);

    await dataDir.delete(recursive: true);
    await logsDir.delete(recursive: true);
  });

  test('recoverPendingReset clears local reset surface and marker', () async {
    var clearedSecureStorage = false;
    var clearedForegroundTaskData = false;
    final dataDir = await Directory.systemTemp.createTemp('wn_data_');
    final logsDir = await Directory.systemTemp.createTemp('wn_logs_');
    await File('${dataDir.path}/data.sqlite').writeAsString('data');
    await File('${logsDir.path}/app.log').writeAsString('logs');

    await markResetPending();
    expect(await (await resetPendingMarkerFile()).exists(), true);

    await recoverPendingReset(
      dataDir: dataDir.path,
      logsDir: logsDir.path,
      clearSecureStorage: () async => clearedSecureStorage = true,
      clearForegroundTaskData: () async => clearedForegroundTaskData = true,
    );

    expect(await dataDir.exists(), false);
    expect(await logsDir.exists(), false);
    expect(clearedSecureStorage, true);
    expect(clearedForegroundTaskData, true);
    expect(await (await resetPendingMarkerFile()).exists(), false);
  });
}
