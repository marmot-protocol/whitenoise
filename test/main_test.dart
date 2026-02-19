import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show AsyncData, ProviderContainer, ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/main.dart'
    show WnApp, initializeAppContainer, kDataVersion, kDataVersionFile;
import 'package:whitenoise/providers/auth_provider.dart';
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

class _MockAuthNotifier extends AuthNotifier {
  @override
  Future<String?> build() async {
    state = const AsyncData(testPubkeyA);
    return testPubkeyA;
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
    late _MockThemeNotifier mockTheme;

    Future<void> pumpWnApp(WidgetTester tester) async {
      setUpTestView(tester);
      mockTheme = _MockThemeNotifier();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(() => _MockAuthNotifier()),
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

    test('wipes data directory when no version file exists', () async {
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

      expect(oldSecrets.existsSync(), isFalse);
      expect(oldUuid.existsSync(), isFalse);
      expect(oldDb.existsSync(), isFalse);
      expect(dataDir.existsSync(), isTrue);
      final versionFile = File('${dataDir.path}/$kDataVersionFile');
      expect(versionFile.existsSync(), isTrue);
      expect(versionFile.readAsStringSync().trim(), '$kDataVersion');
    });

    test('wipes data directory when version is outdated', () async {
      final dataDir = Directory('${pathProvider.tempDir.path}/whitenoise/data');
      await dataDir.create(recursive: true);
      final versionFile = File('${dataDir.path}/$kDataVersionFile');
      versionFile.writeAsStringSync('0');
      final marker = File('${dataDir.path}/whitenoise.json');
      await marker.create();

      await initializeAppContainer();

      expect(marker.existsSync(), isFalse);
      expect(versionFile.readAsStringSync().trim(), '$kDataVersion');
    });
  });
}
