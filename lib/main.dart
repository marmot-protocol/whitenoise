import 'dart:async' show unawaited;
import 'dart:io' show Directory, File, FileSystemException, Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show DeviceOrientation, MethodChannel, SystemChrome;
import 'package:flutter_foreground_task/flutter_foreground_task.dart' show FlutterForegroundTask;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart' show ScreenUtilInit;
import 'package:flutter_secure_storage/flutter_secure_storage.dart' show FlutterSecureStorage;
import 'package:go_router/go_router.dart' show GoRouter;
import 'package:hooks_riverpod/hooks_riverpod.dart'
    show ConsumerStatefulWidget, ConsumerState, ProviderContainer, UncontrolledProviderScope;
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart' show getApplicationDocumentsDirectory;
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/providers/app_log_provider.dart' show appLogStore;
import 'package:whitenoise/providers/auth_provider.dart' show authProvider;
import 'package:whitenoise/providers/chat_list_refresh_provider.dart';
import 'package:whitenoise/providers/foreground_service_provider.dart';
import 'package:whitenoise/providers/locale_provider.dart';
import 'package:whitenoise/providers/notification_provider.dart'
    show consumePendingNotificationTap, notificationListenerProvider, routePendingTap;
import 'package:whitenoise/providers/push_registration_provider.dart';
import 'package:whitenoise/providers/theme_provider.dart' show themeProvider;
import 'package:whitenoise/routes.dart' show Routes;
import 'package:whitenoise/screens/fatal_error_screen.dart';
import 'package:whitenoise/src/rust/api.dart' as rust_api;
import 'package:whitenoise/src/rust/api/relays.dart' as relays_api;
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/theme.dart';

final _logger = Logger('WnApp');
const _appGroupChannel = MethodChannel('org.parres.whitenoise/app_group');
const _getAppGroupContainerPathMethod = 'getAppGroupContainerPath';

// TODO: Remove migration gate and related code in the next release.
const kDataVersion = 1;
const kDataVersionFile = 'data_version';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Logger.root.level = Level.WARNING;
  Logger.root.onRecord.listen((record) {
    appLogStore.add(record);
    final buf = StringBuffer(
      '${record.level.name}: ${record.loggerName}: ${record.message}',
    );
    if (record.error != null) {
      buf.writeln();
      buf.write('  error: ${record.error}');
    }
    if (record.stackTrace != null) {
      buf.writeln();
      buf.write('  stackTrace: ${record.stackTrace}');
    }
    debugPrint(buf.toString());
  });
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  try {
    await RustLib.init();
    final container = await initializeAppContainer();
    runApp(
      UncontrolledProviderScope(container: container, child: const WnApp()),
    );
  } catch (e, stackTrace) {
    runApp(
      FatalErrorScreen(errorMessage: e.toString(), stackTrace: stackTrace),
    );
  }
}

Future<ProviderContainer> initializeAppContainer() async {
  final baseDir = await resolveWhitenoiseBaseDirectory();
  final dataDir = '${baseDir.path}/data';
  final logsDir = '${baseDir.path}/logs';
  await Directory(dataDir).create(recursive: true);
  await Directory(logsDir).create(recursive: true);

  await _migrateDataIfNeeded(dataDir);

  final config = await rust_api.createWhitenoiseConfig(
    dataDir: dataDir,
    logsDir: logsDir,
  );
  await rust_api.initializeWhitenoise(config: config);

  final container = ProviderContainer();
  await container.read(authProvider.future);
  return container;
}

@visibleForTesting
Future<Directory> resolveWhitenoiseBaseDirectory({
  bool? isIOS,
  MethodChannel appGroupChannel = _appGroupChannel,
}) async {
  final documentsDir = await getApplicationDocumentsDirectory();
  final documentsBaseDir = Directory('${documentsDir.path}/whitenoise');
  if (!(isIOS ?? Platform.isIOS)) return documentsBaseDir;

  try {
    final appGroupContainerPath = await appGroupChannel.invokeMethod<String>(
      _getAppGroupContainerPathMethod,
    );
    if (appGroupContainerPath == null || appGroupContainerPath.isEmpty) {
      return documentsBaseDir;
    }

    final appGroupBaseDir = Directory('$appGroupContainerPath/whitenoise');
    await _moveWhitenoiseDirectoryIfNeeded(
      from: documentsBaseDir,
      to: appGroupBaseDir,
    );
    return appGroupBaseDir;
  } catch (error, stackTrace) {
    _logger.warning(
      'Failed to resolve App Group container; falling back to Documents',
      error,
      stackTrace,
    );
    return documentsBaseDir;
  }
}

Future<void> _moveWhitenoiseDirectoryIfNeeded({
  required Directory from,
  required Directory to,
}) async {
  if (!from.existsSync()) return;

  if (to.existsSync()) {
    if (await _directoryHasFiles(Directory('${to.path}/data'))) return;
    await to.delete(recursive: true);
  }
  await to.parent.create(recursive: true);
  try {
    await from.rename(to.path);
  } on FileSystemException {
    await _copyDirectory(from, to);
    await from.delete(recursive: true);
  }
}

Future<void> _copyDirectory(Directory from, Directory to) async {
  await to.create(recursive: true);
  await for (final entity in from.list(recursive: false)) {
    final targetPath = '${to.path}/${entity.uri.pathSegments.last}';
    if (entity is Directory) {
      await _copyDirectory(entity, Directory(targetPath));
    } else if (entity is File) {
      await entity.copy(targetPath);
    }
  }
}

Future<bool> _directoryHasFiles(Directory directory) async {
  if (!directory.existsSync()) return false;
  await for (final entity in directory.list(recursive: true)) {
    if (entity is File) return true;
  }
  return false;
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

  // Read triggers the internal migration from EncryptedSharedPreferences to
  // the new cipher storage. Then deleteAll clears legacy Flutter-side storage
  // without touching the Rust-owned database in dataDir.
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

class _WnAppState extends ConsumerState<WnApp> with WidgetsBindingObserver {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = Routes.build(ref);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_consumePendingNotificationTap(refreshBeforeRoute: true));
    });
  }

  Future<bool> _consumePendingNotificationTap({
    bool refreshBeforeRoute = false,
  }) async {
    final pending = await consumePendingNotificationTap();
    return routePendingTap(
      pending: pending,
      isMounted: mounted,
      currentActivePubkey: ref.read(authProvider).value,
      switchToProfile: ref.read(authProvider.notifier).switchProfile,
      beforeNavigate: refreshBeforeRoute ? _ensureRelaySubscriptionsAfterResume : null,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    unawaited(
      ref.read(foregroundServiceProvider).handleAppLifecycleChange(state),
    );
    if (state == AppLifecycleState.resumed) {
      unawaited(_handleAppResumed());
    }
  }

  Future<void> _handleAppResumed() async {
    await ref.read(authProvider.notifier).ensureExternalSignersRegistered();
    final routed = await _consumePendingNotificationTap(refreshBeforeRoute: true);
    if (!routed) {
      await _ensureRelaySubscriptionsAfterResume();
    }
  }

  Future<void> _ensureRelaySubscriptionsAfterResume() async {
    try {
      await relays_api.ensureAllSubscriptions();
      ref.read(chatListRefreshProvider.notifier).requestRefresh();
    } catch (error, stackTrace) {
      _logger.warning('Failed to ensure relay subscriptions on resume', error, stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider).value ?? ThemeMode.system;
    ref.watch(localeProvider);
    ref.watch(notificationListenerProvider);
    ref.watch(pushRegistrationControllerProvider);
    final locale = ref.read(localeProvider.notifier).resolveLocale();

    return ScreenUtilInit(
      designSize: const Size(420, 912),
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
