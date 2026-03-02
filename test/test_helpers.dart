import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart' show ScreenUtilInit;
import 'package:flutter_test/flutter_test.dart'
    show TestWidgetsFlutterBinding, WidgetTester, addTearDown;
import 'package:whitenoise/l10n/generated/app_localizations.dart';
import 'package:whitenoise/routes.dart';

const double testDesignWidth = 420;
const double testDesignHeight = 912;
const testDesignSize = Size(testDesignWidth, testDesignHeight);

const testPubkeyA = 'a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4';
const testNpubA = 'npub1a1b2c31111111111111111111111111111111111111111111111111111';
const testNpubAFormatted =
    'npub 1a1b 2c31 1111 1111 1111 1111 1111 1111 1111 1111 1111 1111 1111 1111 111';
const testPubkeyB = 'b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5';
const testNpubB = 'npub1b2c3d422222222222222222222222222222222222222222222222222';
const testNpubBFormatted =
    'npub 1b2c 3d42 2222 2222 2222 2222 2222 2222 2222 2222 2222 2222 2222 2222';
const testPubkeyC = 'c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6';
const testNpubC = 'npub1c3d4e533333333333333333333333333333333333333333333333333';
const testNpubCFormatted =
    'npub 1c3d 4e53 3333 3333 3333 3333 3333 3333 3333 3333 3333 3333 3333 3333 333';
const testPubkeyD = 'd4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1';
const testNpubD = 'npub1d4e5f644444444444444444444444444444444444444444444444444';
const testHexToNpub = <String, String>{
  testPubkeyA: testNpubA,
  testPubkeyB: testNpubB,
  testPubkeyC: testNpubC,
  testPubkeyD: testNpubD,
};
const testNpubToHex = <String, String>{
  testNpubA: testPubkeyA,
  testNpubB: testPubkeyB,
  testNpubC: testPubkeyC,
  testNpubD: testPubkeyD,
};
const testGroupId = 'abcd1234abcd1234abcd1234abcd1234abcd1234abcd1234abcd1234abcd1234';
const otherTestGroupId = 'dbcd1234abcd1234abcd1234abcd1234abcd1234abcd1234abcd1234abcd1234';
const testNostrGroupId = 'dcba4321dcba4321dcba4321dcba4321dcba4321dcba4321dcba4321dcba4321';

final testImageProvider = MemoryImage(
  Uint8List.fromList([
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    0x00,
    0x00,
    0x00,
    0x0D,
    0x49,
    0x48,
    0x44,
    0x52,
    0x00,
    0x00,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x01,
    0x08,
    0x06,
    0x00,
    0x00,
    0x00,
    0x1F,
    0x15,
    0xC4,
    0x89,
    0x00,
    0x00,
    0x00,
    0x0A,
    0x49,
    0x44,
    0x41,
    0x54,
    0x78,
    0x9C,
    0x63,
    0x00,
    0x01,
    0x00,
    0x00,
    0x05,
    0x00,
    0x01,
    0x0D,
    0x0A,
    0x2D,
    0xB4,
    0x00,
    0x00,
    0x00,
    0x00,
    0x49,
    0x45,
    0x4E,
    0x44,
    0xAE,
    0x42,
    0x60,
    0x82,
  ]),
);

void mockPathProvider() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
    final dir = await Directory.systemTemp.createTemp('wn_test_');
    return dir.path;
  });
}

void setUpTestView(WidgetTester tester) {
  tester.view.physicalSize = testDesignSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

const _localizationsDelegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

Future<void> mountTestApp(
  WidgetTester tester, {
  List overrides = const [],
}) async {
  setUpTestView(tester);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [...overrides],
      child: ScreenUtilInit(
        designSize: testDesignSize,
        builder: (_, _) => Consumer(
          builder: (context, ref, _) {
            return MaterialApp.router(
              routerConfig: Routes.build(ref),
              locale: const Locale('en'),
              localizationsDelegates: _localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            );
          },
        ),
      ),
    ),
  );
}

Future<T Function()> mountHook<T>(
  WidgetTester tester,
  T Function() useHook,
) async {
  setUpTestView(tester);
  late T result;
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: _localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: _HookTestWidget<T>(useHook, (r) => result = r),
    ),
  );
  return () => result;
}

class _HookTestWidget<T> extends HookWidget {
  const _HookTestWidget(this.useHook, this.onBuild);
  final T Function() useHook;
  final void Function(T) onBuild;

  @override
  Widget build(BuildContext context) {
    onBuild(useHook());
    return const SizedBox();
  }
}

Future<void> mountWidget(
  Widget child,
  WidgetTester tester, {
  List overrides = const [],
}) async {
  setUpTestView(tester);
  final widget = ProviderScope(
    overrides: overrides.cast(),
    child: ScreenUtilInit(
      designSize: testDesignSize,
      builder: (_, _) {
        return MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: _localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: child),
        );
      },
    ),
  );
  await tester.pumpWidget(widget);
}

Future<void> mountStackedWidget(Widget child, WidgetTester tester) async {
  setUpTestView(tester);
  final widget = ScreenUtilInit(
    designSize: testDesignSize,
    builder: (_, _) {
      return MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: _localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: Stack(children: [child])),
      );
    },
  );
  await tester.pumpWidget(widget);
}
