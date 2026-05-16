import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show AsyncData, ProviderContainer, ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/main.dart'
    show
        WnApp,
        initializeAppContainer,
        kDataVersion,
        kDataVersionFile,
        resolveWhitenoiseBaseDirectory;
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/providers/chat_list_refresh_provider.dart';
import 'package:whitenoise/providers/theme_provider.dart';
import 'package:whitenoise/src/rust/api.dart' as rust_api;
import 'package:whitenoise/src/rust/frb_generated.dart';

import 'mocks/mock_secure_storage.dart';
import 'mocks/mock_wn_api.dart';
import 'test_helpers.dart';

({Directory tempDir, void Function() reset}) _mockPathProvider() {
  final tempDir = Directory.systemTemp.createTempSync('whitenoise_test');

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (call) async {
      if (call.method == 'getApplicationDocumentsDirectory') {
        return tempDir.path;
      }
      return null;
    },
  );

  return (
    tempDir: tempDir,
    reset: () {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        null,
      );
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    },
  );
}

void Function() _mockSecureStorage() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
    (call) async {
      if (call.method == 'read') {
        return null;
      }
      return null;
    },
  );

  return () {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      null,
    );
  };
}

void _mockAppGroupContainerPath(String? path) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('org.parres.whitenoise/app_group'),
    (call) async {
      if (call.method == 'getAppGroupContainerPath') {
        return path;
      }
      return null;
    },
  );
}

void _resetAppGroupContainerPath() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('org.parres.whitenoise/app_group'),
    null,
  );
}

class _MockAuthNotifier extends AuthNotifier {
  int ensureExternalSignersRegisteredCount = 0;

  @override
  Future<String?> build() async {
    state = const AsyncData(testPubkeyA);
    return testPubkeyA;
  }

  @override
  Future<void> ensureExternalSignersRegistered() async {
    ensureExternalSignersRegisteredCount++;
  }
}

class _MockThemeNotifier extends ThemeNotifier {
  ThemeMode _mode = ThemeMode.system;

  @override
  Future<ThemeMode> build() async {
    state = AsyncData(_mode);
    return _mode;
  }

  void setMode(ThemeMode mode) {
    _mode = mode;
    state = AsyncData(mode);
  }
}

class _MockInitApi extends MockWnApi {
  String? createdConfigDataDir;
  String? createdConfigLogsDir;
  rust_api.WhitenoiseConfig? initializedConfig;
  int initCallCount = 0;

  @override
  Future<rust_api.WhitenoiseConfig> crateApiCreateWhitenoiseConfig({
    required String dataDir,
    required String logsDir,
  }) async {
    createdConfigDataDir = dataDir;
    createdConfigLogsDir = logsDir;
    return rust_api.WhitenoiseConfig(dataDir: dataDir, logsDir: logsDir);
  }

  @override
  Future<void> crateApiInitializeWhitenoise({
    required rust_api.WhitenoiseConfig config,
  }) async {
    initCallCount++;
    initializedConfig = config;
  }

  @override
  void reset() {
    super.reset();
    createdConfigDataDir = null;
    createdConfigLogsDir = null;
    initializedConfig = null;
    initCallCount = 0;
  }
}

void main() {
  late _MockInitApi mockApi;

  setUpAll(() {
    mockApi = _MockInitApi();
    RustLib.initMock(api: mockApi);
  });

  setUp(() {
    mockApi.reset();
  });

  group('WnApp', () {
    late _MockAuthNotifier mockAuth;
    late _MockThemeNotifier mockTheme;

    Future<void> pumpWnApp(WidgetTester tester) async {
      setUpTestView(tester);
      mockAuth = _MockAuthNotifier();
      mockTheme = _MockThemeNotifier();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(() => mockAuth),
            themeProvider.overrideWith(() => mockTheme),
            secureStorageProvider.overrideWithValue(MockSecureStorage()),
          ],
          child: const WnApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('has app title', (tester) async {
      await pumpWnApp(tester);
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.title, 'White Noise');
    });

    testWidgets('defaults to system theme mode', (tester) async {
      await pumpWnApp(tester);
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.system);
    });

    testWidgets('responds to theme mode changes', (tester) async {
      await pumpWnApp(tester);

      mockTheme.setMode(ThemeMode.dark);
      await tester.pumpAndSettle();

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.dark);
    });

    testWidgets('has routes configured', (tester) async {
      await pumpWnApp(tester);
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.routerConfig, isNotNull);
    });

    testWidgets('forwards lifecycle state changes without error', (tester) async {
      await pumpWnApp(tester);

      // ForegroundService is disabled on the test host (Platform.isAndroid
      // is false), so the observer chain ultimately no-ops — we're
      // verifying that didChangeAppLifecycleState wires through without
      // throwing and that each branch of the switch is exercised.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpAndSettle();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pumpAndSettle();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      await tester.pumpAndSettle();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
    });

    testWidgets('reconciles external signer callbacks on app resume', (tester) async {
      await pumpWnApp(tester);
      mockAuth.ensureExternalSignersRegisteredCount = 0;

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(mockAuth.ensureExternalSignersRegisteredCount, 1);
    });

    testWidgets('ensures relay subscriptions on app resume', (tester) async {
      await pumpWnApp(tester);
      mockApi.ensureAllSubscriptionsCallCount = 0;
      final container = ProviderScope.containerOf(
        tester.element(find.byType(WnApp)),
        listen: false,
      );

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(mockApi.ensureAllSubscriptionsCallCount, 1);
      expect(container.read(chatListRefreshProvider), 1);
    });

    testWidgets('logs relay subscription resume failures without throwing', (tester) async {
      await pumpWnApp(tester);
      mockApi.shouldFailEnsureAllSubscriptions = true;
      final container = ProviderScope.containerOf(
        tester.element(find.byType(WnApp)),
        listen: false,
      );

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(mockApi.ensureAllSubscriptionsCallCount, 1);
      expect(container.read(chatListRefreshProvider), 0);
    });
  });

  group('initializeAppContainer', () {
    late ({Directory tempDir, void Function() reset}) pathProvider;
    late void Function() resetSecureStorage;

    setUp(() {
      pathProvider = _mockPathProvider();
      resetSecureStorage = _mockSecureStorage();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/shared_preferences'),
        (call) async => <String, Object>{},
      );
    });

    tearDown(() {
      pathProvider.reset();
      resetSecureStorage();
      _resetAppGroupContainerPath();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/shared_preferences'),
        null,
      );
    });

    test('creates data directory', () async {
      await initializeAppContainer();

      expect(Directory('${pathProvider.tempDir.path}/whitenoise/data').existsSync(), isTrue);
    });

    test('creates logs directory', () async {
      await initializeAppContainer();

      expect(Directory('${pathProvider.tempDir.path}/whitenoise/logs').existsSync(), isTrue);
    });

    test('calls createWhitenoiseConfig with data directory', () async {
      await initializeAppContainer();

      expect(mockApi.createdConfigDataDir, '${pathProvider.tempDir.path}/whitenoise/data');
    });

    test('calls createWhitenoiseConfig with logs directory', () async {
      await initializeAppContainer();

      expect(mockApi.createdConfigLogsDir, '${pathProvider.tempDir.path}/whitenoise/logs');
    });

    test('calls initializeWhitenoise with config', () async {
      await initializeAppContainer();

      expect(mockApi.initializedConfig, isNotNull);
    });

    test('returns a ProviderContainer', () async {
      final container = await initializeAppContainer();

      expect(container, isA<ProviderContainer>());
    });

    test('awaits authProvider', () async {
      final container = await initializeAppContainer();

      expect(container.read(authProvider), isA<AsyncData>());
    });

    test('writes version file on fresh install', () async {
      await initializeAppContainer();

      final versionFile = File('${pathProvider.tempDir.path}/whitenoise/data/$kDataVersionFile');
      expect(versionFile.existsSync(), isTrue);
      expect(versionFile.readAsStringSync().trim(), '$kDataVersion');
    });

    test('skips migration when version matches', () async {
      final dataDir = Directory('${pathProvider.tempDir.path}/whitenoise/data');
      await dataDir.create(recursive: true);
      final versionFile = File('${dataDir.path}/$kDataVersionFile');
      versionFile.writeAsStringSync('$kDataVersion');
      final marker = File('${dataDir.path}/whitenoise.json');
      await marker.create();

      await initializeAppContainer();

      expect(marker.existsSync(), isTrue);
    });

    test('preserves data directory when no version file exists', () async {
      final dataDir = Directory('${pathProvider.tempDir.path}/whitenoise/data');
      await dataDir.create(recursive: true);
      final oldSecrets = File('${dataDir.path}/whitenoise.json');
      final oldUuid = File('${dataDir.path}/whitenoise_uuid');
      final oldDb = File('${dataDir.path}/release/whitenoise.sqlite');
      await Directory('${dataDir.path}/release').create(recursive: true);
      await oldSecrets.create();
      await oldUuid.create();
      await oldDb.create();

      await initializeAppContainer();

      expect(oldSecrets.existsSync(), isTrue);
      expect(oldUuid.existsSync(), isTrue);
      expect(oldDb.existsSync(), isTrue);
      expect(dataDir.existsSync(), isTrue);
      final versionFile = File('${dataDir.path}/$kDataVersionFile');
      expect(versionFile.existsSync(), isTrue);
      expect(versionFile.readAsStringSync().trim(), '$kDataVersion');
    });

    test('preserves data directory when version is outdated', () async {
      final dataDir = Directory('${pathProvider.tempDir.path}/whitenoise/data');
      await dataDir.create(recursive: true);
      final versionFile = File('${dataDir.path}/$kDataVersionFile');
      versionFile.writeAsStringSync('0');
      final marker = File('${dataDir.path}/whitenoise.json');
      await marker.create();

      await initializeAppContainer();

      expect(marker.existsSync(), isTrue);
      expect(versionFile.readAsStringSync().trim(), '$kDataVersion');
    });

    test('uses App Group container on iOS when available', () async {
      final appGroupDir = Directory.systemTemp.createTempSync('whitenoise_app_group_test');
      _mockAppGroupContainerPath(appGroupDir.path);
      addTearDown(() {
        if (appGroupDir.existsSync()) {
          appGroupDir.deleteSync(recursive: true);
        }
      });

      final baseDir = await resolveWhitenoiseBaseDirectory(isIOS: true);

      expect(baseDir.path, '${appGroupDir.path}/whitenoise');
    });

    test('moves existing Documents data into App Group container on iOS', () async {
      final appGroupDir = Directory.systemTemp.createTempSync('whitenoise_app_group_test');
      _mockAppGroupContainerPath(appGroupDir.path);
      final oldDataDir = Directory('${pathProvider.tempDir.path}/whitenoise/data');
      await oldDataDir.create(recursive: true);
      final marker = File('${oldDataDir.path}/marker.txt');
      await marker.writeAsString('existing');
      addTearDown(() {
        if (appGroupDir.existsSync()) {
          appGroupDir.deleteSync(recursive: true);
        }
      });

      final baseDir = await resolveWhitenoiseBaseDirectory(isIOS: true);

      expect(baseDir.path, '${appGroupDir.path}/whitenoise');
      expect(File('${baseDir.path}/data/marker.txt').readAsStringSync(), 'existing');
      expect(Directory('${pathProvider.tempDir.path}/whitenoise').existsSync(), isFalse);
    });

    test('moves Documents data when App Group container only has empty directories', () async {
      final appGroupDir = Directory.systemTemp.createTempSync('whitenoise_app_group_test');
      _mockAppGroupContainerPath(appGroupDir.path);
      final oldDataDir = Directory('${pathProvider.tempDir.path}/whitenoise/data');
      await oldDataDir.create(recursive: true);
      await File('${oldDataDir.path}/marker.txt').writeAsString('existing');
      await Directory('${appGroupDir.path}/whitenoise/data').create(recursive: true);
      await Directory('${appGroupDir.path}/whitenoise/logs').create(recursive: true);
      addTearDown(() {
        if (appGroupDir.existsSync()) {
          appGroupDir.deleteSync(recursive: true);
        }
      });

      final baseDir = await resolveWhitenoiseBaseDirectory(isIOS: true);

      expect(baseDir.path, '${appGroupDir.path}/whitenoise');
      expect(File('${baseDir.path}/data/marker.txt').readAsStringSync(), 'existing');
      expect(Directory('${pathProvider.tempDir.path}/whitenoise').existsSync(), isFalse);
    });

    test('preserves App Group data when both storage locations contain data', () async {
      final appGroupDir = Directory.systemTemp.createTempSync('whitenoise_app_group_test');
      _mockAppGroupContainerPath(appGroupDir.path);
      final oldDataDir = Directory('${pathProvider.tempDir.path}/whitenoise/data');
      await oldDataDir.create(recursive: true);
      await File('${oldDataDir.path}/old-marker.txt').writeAsString('old');
      final appGroupDataDir = Directory('${appGroupDir.path}/whitenoise/data');
      await appGroupDataDir.create(recursive: true);
      await File('${appGroupDataDir.path}/new-marker.txt').writeAsString('new');
      addTearDown(() {
        if (appGroupDir.existsSync()) {
          appGroupDir.deleteSync(recursive: true);
        }
      });

      final baseDir = await resolveWhitenoiseBaseDirectory(isIOS: true);

      expect(baseDir.path, '${appGroupDir.path}/whitenoise');
      expect(File('${baseDir.path}/data/new-marker.txt').readAsStringSync(), 'new');
      expect(
        File('${pathProvider.tempDir.path}/whitenoise/data/old-marker.txt').existsSync(),
        isTrue,
      );
    });

    test('falls back to Documents on iOS when App Group container is unavailable', () async {
      _mockAppGroupContainerPath(null);

      final baseDir = await resolveWhitenoiseBaseDirectory(isIOS: true);

      expect(baseDir.path, '${pathProvider.tempDir.path}/whitenoise');
    });
  });
}
