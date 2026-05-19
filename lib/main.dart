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
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart' show getApplicationDocumentsDirectory;
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/providers/app_log_provider.dart' show appLogStore;
import 'package:whitenoise/providers/auth_provider.dart' show authProvider;
import 'package:whitenoise/providers/chat_list_refresh_provider.dart';
import 'package:whitenoise/providers/foreground_service_provider.dart';
import 'package:whitenoise/providers/locale_provider.dart';
import 'package:whitenoise/providers/notification_provider.dart'
    show
        consumePendingNotificationTap,
        localNotificationResumeSuppressionDuration,
        localNotificationSuppressedUntilProvider,
        notificationListenerProvider,
        routePendingTap;
import 'package:whitenoise/providers/push_registration_provider.dart';
import 'package:whitenoise/providers/theme_provider.dart' show themeProvider;
import 'package:whitenoise/routes.dart' show Routes;
import 'package:whitenoise/screens/fatal_error_screen.dart';
import 'package:whitenoise/src/rust/api.dart' as rust_api;
import 'package:whitenoise/src/rust/api/relays.dart' as relays_api;
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/utils/reset_marker.dart';

final _logger = Logger('WnApp');
const _appGroupChannel = MethodChannel('org.parres.whitenoise/app_group');
const _getAppGroupContainerPathMethod = 'getAppGroupContainerPath';
const _initializeWhitenoiseMaxAttempts = 3;
const _initializeWhitenoiseRetryDelay = Duration(milliseconds: 500);

// TODO: Remove migration gate and related code in the next release.
const kDataVersion = 1;
const kDataVersionFile = 'data_version';

class _AppGroupContainerUnavailableException implements Exception {
  const _AppGroupContainerUnavailableException();

  @override
  String toString() => 'App Group container unavailable for iOS White Noise data';
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Logger.root.level = Level.WARNING;
  Logger.root.onRecord.listen((record) {
    appLogStore.add(record);
    debugPrint(formatAppLogRecord(record));
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

@visibleForTesting
String formatAppLogRecord(LogRecord record) {
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
  return buf.toString();
}

Future<ProviderContainer> initializeAppContainer({
  Future<void> Function(Duration delay) initializeRetryDelay = _defaultInitializeRetryDelay,
  bool? isIOS,
}) async {
  final hadPendingReset = await _hasPendingReset();
  final baseDir = await resolveWhitenoiseBaseDirectory(
    isIOS: isIOS,
    skipDocumentsMigration: hadPendingReset,
  );
  final dataDir = '${baseDir.path}/data';
  final logsDir = '${baseDir.path}/logs';
  await recoverPendingReset(dataDir: dataDir, logsDir: logsDir);
  if (hadPendingReset) {
    await _deleteDocumentsDataAfterPendingReset(baseDir);
  }
  await Directory(dataDir).create(recursive: true);
  await Directory(logsDir).create(recursive: true);

  await _migrateDataIfNeeded(dataDir);

  final config = await rust_api.createWhitenoiseConfig(
    dataDir: dataDir,
    logsDir: logsDir,
  );
  await initializeWhitenoiseWithRetry(
    config,
    retryDelay: initializeRetryDelay,
  );

  final container = ProviderContainer();
  await container.read(authProvider.future);
  return container;
}

Future<void> _defaultInitializeRetryDelay(Duration delay) => Future<void>.delayed(delay);

Future<bool> _hasPendingReset() async => (await resetPendingMarkerFile()).existsSync();

Future<void> _deleteDocumentsDataAfterPendingReset(Directory activeBaseDir) async {
  final documentsDir = await getApplicationDocumentsDirectory();
  final documentsBaseDir = Directory('${documentsDir.path}/whitenoise');
  if (documentsBaseDir.path == activeBaseDir.path) return;
  await _deleteDirectoryIfExists(Directory(p.join(documentsBaseDir.path, 'data')));
  await _deleteDirectoryIfExists(Directory(p.join(documentsBaseDir.path, 'logs')));
}

Future<void> _deleteDirectoryIfExists(Directory directory) async {
  if (directory.existsSync()) {
    await directory.delete(recursive: true);
  }
}

@visibleForTesting
Future<void> initializeWhitenoiseWithRetry(
  rust_api.WhitenoiseConfig config, {
  Future<void> Function(Duration delay) retryDelay = _defaultInitializeRetryDelay,
}) async {
  for (var attempt = 1; attempt <= _initializeWhitenoiseMaxAttempts; attempt++) {
    try {
      await rust_api.initializeWhitenoise(config: config);
      return;
    } catch (error, stackTrace) {
      if (!_isDatabasePoolTimeout(error) || attempt == _initializeWhitenoiseMaxAttempts) {
        rethrow;
      }
      _logger.warning(
        'Whitenoise database pool was temporarily exhausted during startup; retrying',
        error,
        stackTrace,
      );
      await retryDelay(_initializeWhitenoiseRetryDelay);
    }
  }
}

bool _isDatabasePoolTimeout(Object error) {
  final message = error.toString().toLowerCase();
  return message.contains('pool timed out while waiting for an open connection');
}

@visibleForTesting
Future<Directory> resolveWhitenoiseBaseDirectory({
  bool? isIOS,
  MethodChannel appGroupChannel = _appGroupChannel,
  Future<Directory> Function(Directory from, String newPath)? renameDirectory,
  Future<void> Function(Directory from, Directory to)? copyDirectory,
  Future<void> Function(Directory directory)? deleteSourceDirectory,
  bool skipDocumentsMigration = false,
}) async {
  final documentsDir = await getApplicationDocumentsDirectory();
  final documentsBaseDir = Directory('${documentsDir.path}/whitenoise');
  if (!(isIOS ?? Platform.isIOS)) return documentsBaseDir;

  try {
    final appGroupContainerPath = await _getAppGroupContainerPath(appGroupChannel);
    if (appGroupContainerPath == null || appGroupContainerPath.isEmpty) {
      throw const _AppGroupContainerUnavailableException();
    }

    final appGroupBaseDir = Directory('$appGroupContainerPath/whitenoise');
    if (!skipDocumentsMigration) {
      await _moveWhitenoiseDirectoryIfNeeded(
        from: documentsBaseDir,
        to: appGroupBaseDir,
        renameDirectory: renameDirectory ?? _renameDirectory,
        copyDirectory: copyDirectory ?? _copyDirectory,
        deleteSourceDirectory: deleteSourceDirectory ?? _deleteDirectory,
      );
    }
    return appGroupBaseDir;
  } on _AppGroupContainerUnavailableException catch (error, stackTrace) {
    _logger.severe('Failed to resolve App Group container', error, stackTrace);
    Error.throwWithStackTrace(error, stackTrace);
  } catch (error, stackTrace) {
    _logger.warning(
      'Failed to resolve App Group container; falling back to Documents',
      error,
      stackTrace,
    );
    return documentsBaseDir;
  }
}

Future<String?> _getAppGroupContainerPath(MethodChannel appGroupChannel) async {
  try {
    return await appGroupChannel.invokeMethod<String>(
      _getAppGroupContainerPathMethod,
    );
  } catch (_, stackTrace) {
    Error.throwWithStackTrace(const _AppGroupContainerUnavailableException(), stackTrace);
  }
}

Future<void> _moveWhitenoiseDirectoryIfNeeded({
  required Directory from,
  required Directory to,
  required Future<Directory> Function(Directory from, String newPath) renameDirectory,
  required Future<void> Function(Directory from, Directory to) copyDirectory,
  required Future<void> Function(Directory directory) deleteSourceDirectory,
}) async {
  if (!from.existsSync()) return;

  if (to.existsSync()) {
    if (_hasMainAppDataMarker(to)) {
      await _deleteLegacyDocumentsDataBestEffort(from);
      return;
    }
    _logger.info('Replacing unversioned App Group data during Documents migration');
    await to.delete(recursive: true);
  }
  await to.parent.create(recursive: true);
  try {
    await renameDirectory(from, to.path);
  } on FileSystemException {
    try {
      await copyDirectory(from, to);
    } catch (error, stackTrace) {
      if (to.existsSync()) {
        await to.delete(recursive: true);
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
    try {
      await deleteSourceDirectory(from);
    } catch (error, stackTrace) {
      _logger.warning(
        'Failed to remove old Documents data after App Group migration',
        error,
        stackTrace,
      );
    }
  }
}

Future<void> _deleteLegacyDocumentsDataBestEffort(Directory from) async {
  try {
    await _deleteDirectory(from);
  } catch (error, stackTrace) {
    _logger.warning(
      'Failed to remove old Documents data after App Group data was already accepted',
      error,
      stackTrace,
    );
  }
}

Future<Directory> _renameDirectory(Directory from, String newPath) => from.rename(newPath);

Future<void> _deleteDirectory(Directory directory) => directory.delete(recursive: true);

bool _hasMainAppDataMarker(Directory baseDir) =>
    File(p.join(baseDir.path, 'data', kDataVersionFile)).existsSync();

Future<void> _copyDirectory(Directory from, Directory to) async {
  await to.create(recursive: true);
  await for (final entity in from.list()) {
    final targetPath = p.join(to.path, p.basename(entity.path));
    if (entity is Directory) {
      await _copyDirectory(entity, Directory(targetPath));
    } else if (entity is File) {
      await entity.copy(targetPath);
    }
  }
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

  // Read triggers any flutter_secure_storage platform migration while keeping
  // Flutter-owned keys such as the active account selection intact.
  const secureStorage = FlutterSecureStorage();
  await secureStorage.readAll();
  await FlutterForegroundTask.clearAllData();
  versionFile.writeAsStringSync('$kDataVersion');
}

@visibleForTesting
Future<void> refreshAfterNotificationRoute({
  required Future<void> Function() ensureRelaySubscriptions,
}) async {
  await ensureRelaySubscriptions();
}

class WnApp extends ConsumerStatefulWidget {
  const WnApp({super.key});

  @override
  ConsumerState<WnApp> createState() => _WnAppState();
}

class _WnAppState extends ConsumerState<WnApp> with WidgetsBindingObserver {
  late final GoRouter _router;
  AppLifecycleState? _lastLifecycleState;

  @override
  void initState() {
    super.initState();
    _router = Routes.build(ref);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _suppressLocalNotificationsDuringResume();
      unawaited(
        _consumePendingNotificationTap(afterNavigate: _ensureRelaySubscriptionsAfterResume),
      );
    });
  }

  Future<bool> _consumePendingNotificationTap({
    Future<void> Function()? afterNavigate,
  }) async {
    final pending = await consumePendingNotificationTap();
    return routePendingTap(
      pending: pending,
      isMounted: mounted,
      currentActivePubkey: ref.read(authProvider).value,
      switchToProfile: ref.read(authProvider.notifier).switchProfile,
      afterNavigate: afterNavigate,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final previousState = _lastLifecycleState;
    _lastLifecycleState = state;
    unawaited(
      ref.read(foregroundServiceProvider).handleAppLifecycleChange(state),
    );
    if (state == AppLifecycleState.resumed &&
        previousState != null &&
        previousState != AppLifecycleState.resumed) {
      _suppressLocalNotificationsDuringResume();
      unawaited(_handleAppResumed());
    }
  }

  void _suppressLocalNotificationsDuringResume() {
    ref
        .read(localNotificationSuppressedUntilProvider.notifier)
        .suppressFor(localNotificationResumeSuppressionDuration);
  }

  Future<void> _handleAppResumed() async {
    try {
      await ref.read(authProvider.notifier).ensureExternalSignersRegistered();
    } catch (error, stackTrace) {
      _logger.warning('Failed to reconcile external signers on resume', error, stackTrace);
    }

    var routed = false;
    try {
      routed = await _consumePendingNotificationTap(
        afterNavigate: _ensureRelaySubscriptionsAfterResume,
      );
    } catch (error, stackTrace) {
      _logger.warning('Failed to route pending notification tap on resume', error, stackTrace);
    }

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
