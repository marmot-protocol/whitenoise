import 'dart:io' show Directory, File, FileSystemException;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show DeviceOrientation, SystemChrome;
import 'package:flutter_foreground_task/flutter_foreground_task.dart' show FlutterForegroundTask;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart' show ScreenUtilInit;
import 'package:flutter_secure_storage/flutter_secure_storage.dart' show FlutterSecureStorage;
import 'package:go_router/go_router.dart' show GoRouter;
import 'package:hooks_riverpod/hooks_riverpod.dart'
    show ConsumerStatefulWidget, ConsumerState, ProviderContainer, UncontrolledProviderScope;
import 'package:path_provider/path_provider.dart' show getApplicationDocumentsDirectory;
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/providers/auth_provider.dart' show authProvider;
import 'package:whitenoise/providers/locale_provider.dart';
import 'package:whitenoise/providers/notification_provider.dart' show notificationListenerProvider;
import 'package:whitenoise/providers/theme_provider.dart' show themeProvider;
import 'package:whitenoise/routes.dart' show Routes;
import 'package:whitenoise/src/rust/api.dart' as rust_api;
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/theme.dart';

// TODO: Remove migration gate and related code in the next release.
const kDataVersion = 1;
const kDataVersionFile = 'data_version';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await RustLib.init();
  final container = await initializeAppContainer();
  runApp(UncontrolledProviderScope(container: container, child: const WnApp()));
}

Future<ProviderContainer> initializeAppContainer() async {
  final dir = await getApplicationDocumentsDirectory();
  final dataDir = '${dir.path}/whitenoise/data';
  final logsDir = '${dir.path}/whitenoise/logs';
  await Directory(dataDir).create(recursive: true);
  await Directory(logsDir).create(recursive: true);

  await _migrateDataIfNeeded(dataDir);

  final config = await rust_api.createWhitenoiseConfig(dataDir: dataDir, logsDir: logsDir);
  await rust_api.initializeWhitenoise(config: config);

  final container = ProviderContainer();
  await container.read(authProvider.future);
  return container;
}

Future<void> _migrateDataIfNeeded(String dataDir) async {
  final versionFile = File('$dataDir/$kDataVersionFile');
  int? currentVersion;
  try {
    if (versionFile.existsSync()) {
      currentVersion = int.tryParse(versionFile.readAsStringSync().trim());
    }
  } on FileSystemException {
    // Corrupt or unreadable file — treat as no version.
  }

  if (currentVersion == kDataVersion) return;

  final dataDirObj = Directory(dataDir);
  if (dataDirObj.existsSync()) {
    await dataDirObj.delete(recursive: true);
    await dataDirObj.create(recursive: true);
  }

  // Read triggers the internal migration from EncryptedSharedPreferences to
  // the new cipher storage. Then deleteAll clears everything including any
  // keys the migration re-introduced from the old app.
  const secureStorage = FlutterSecureStorage();
  await secureStorage.readAll();
  await secureStorage.deleteAll();
  await FlutterForegroundTask.clearAllData();
  versionFile.writeAsStringSync('$kDataVersion');
}

class WnApp extends ConsumerStatefulWidget {
  const WnApp({super.key});

  @override
  ConsumerState<WnApp> createState() => _WnAppState();
}

class _WnAppState extends ConsumerState<WnApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = Routes.build(ref);
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider).value ?? ThemeMode.system;
    ref.watch(localeProvider);
    ref.watch(notificationListenerProvider);
    final locale = ref.read(localeProvider.notifier).resolveLocale();

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, child) {
        return MaterialApp.router(
          title: 'White Noise',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeMode,
          locale: locale,
          routerConfig: _router,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
        );
      },
    );
  }
}
