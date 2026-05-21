// Per-test backend lifecycle: FFI/Whitenoise init, reset, app mount, relay checks.
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:whitenoise/main.dart' show WnApp;
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/providers/notification_provider.dart';
import 'package:whitenoise/providers/offline_provider.dart';
import 'package:whitenoise/providers/push_registration_provider.dart';
import 'package:whitenoise/src/rust/api.dart' as rust_api;
import 'package:whitenoise/src/rust/frb_generated.dart';

import '../../test/mocks/mock_secure_storage.dart';
import 'tester_helpers.dart';

const _relayUrls = ['ws://localhost:8080', 'ws://localhost:7777'];

bool _rustBridgeInitialized = false;
Directory? _backendRoot;

/// Resets the backend so each test starts from a clean, logged-out state. The
/// bundled `all_tests.dart` entrypoint runs every test in one process:
/// `RustLib` (the FFI bridge) initialises once, while `deleteAllData` clears
/// the process-global Whitenoise instance — which must then be re-installed
/// with a fresh `initializeWhitenoise`, per that API's documented contract.
Future<void> _resetBackend() async {
  if (_rustBridgeInitialized) {
    await rust_api.deleteAllData();
  } else {
    await RustLib.init();
    _rustBridgeInitialized = true;
  }

  final root = _backendRoot ??= await Directory.systemTemp.createTemp('whitenoise_integration_');
  final dataDir = Directory('${root.path}/data');
  final logsDir = Directory('${root.path}/logs');
  await dataDir.create(recursive: true);
  await logsDir.create(recursive: true);

  final config = await rust_api.createWhitenoiseConfig(
    dataDir: dataDir.path,
    logsDir: logsDir.path,
    defaultRelayUrls: _relayUrls,
  );
  await rust_api.initializeWhitenoise(config: config);
}

/// Mounts a fresh app for one test, after resetting the backend so the test
/// starts logged-out with an empty database regardless of run order.
Future<ProviderContainer> mountApp(WidgetTester tester) async {
  await _resetBackend();

  final container = ProviderContainer(
    overrides: [
      secureStorageProvider.overrideWithValue(MockSecureStorage()),
      checkConnectivityFunctionProvider.overrideWithValue(
        () async => [ConnectivityResult.wifi],
      ),
      connectivityStreamProvider.overrideWithValue(const Stream.empty()),
      reachAnyRelayHostFunctionProvider.overrideWithValue((_) async => true),
      // No-op the notification and push controllers so the run never
      // triggers the iOS notification-permission prompt.
      notificationListenerProvider.overrideWith((_) {}),
      pushRegistrationControllerProvider.overrideWith((_) {}),
    ],
  );
  addTearDown(container.dispose);
  await container.read(authProvider.future);

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const WnApp()),
  );
  await pumpUntilFound(tester, find.byKey(const Key('auth_signup_button')));
  return container;
}

Future<void> expectLocalRelaysAvailable() async {
  await _expectLocalRelayAvailable(8080);
  await _expectLocalRelayAvailable(7777);
}

Future<void> _expectLocalRelayAvailable(int port) async {
  try {
    final socket = await Socket.connect(
      '127.0.0.1',
      port,
      timeout: const Duration(seconds: 1),
    );
    socket.destroy();
  } catch (error) {
    fail(
      'Expected a local Nostr relay on 127.0.0.1:$port before running this integration test. '
      'Run `docker compose up -d`, then run the test again. '
      'Connection error: $error',
    );
  }
}
