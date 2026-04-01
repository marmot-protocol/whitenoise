import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:whitenoise/hooks/use_zapstore_update.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';

import '../mocks/mock_wn_api.dart';

late ({
  String? availableVersion,
  bool isDismissed,
  void Function() dismiss,
})
Function()
getResult;

final _api = MockWnApi();

void _setInstalledVersion(String version) {
  PackageInfo.setMockInitialValues(
    appName: 'Whitenoise',
    packageName: 'org.parres.whitenoise',
    version: version,
    buildNumber: '1',
    buildSignature: '',
  );
}

Future<void> _mountHook(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: HookBuilder(
        builder: (context) {
          final result = useZapstoreUpdate();
          getResult = () => result;
          return const SizedBox();
        },
      ),
    ),
  );
}

void main() {
  setUpAll(() => RustLib.initMock(api: _api));

  setUp(() {
    _api.zapstoreVersion = null;
    _api.zapstoreShouldThrow = false;
  });

  group('useZapstoreUpdate', () {
    group('when no version is available yet (loading)', () {
      testWidgets(
        'availableVersion is null before future resolves',
        (tester) async {
          _setInstalledVersion('2026.3.5');
          _api.zapstoreVersion = null;

          await _mountHook(tester);
          // Do not pump — future hasn't resolved yet.
          expect(getResult().availableVersion, isNull);
          expect(getResult().isDismissed, isFalse);
        },
        variant: TargetPlatformVariant.only(TargetPlatform.android),
      );
    });

    group('when Zapstore has a newer version', () {
      setUp(() {
        _api.zapstoreVersion = '2026.4.1';
        _setInstalledVersion('2026.3.5');
      });

      testWidgets(
        'returns the newer version',
        (tester) async {
          await _mountHook(tester);
          await tester.pump();

          expect(getResult().availableVersion, equals('2026.4.1'));
        },
        variant: TargetPlatformVariant.only(TargetPlatform.android),
      );

      testWidgets(
        'isDismissed starts false',
        (tester) async {
          await _mountHook(tester);
          await tester.pump();

          expect(getResult().isDismissed, isFalse);
        },
        variant: TargetPlatformVariant.only(TargetPlatform.android),
      );

      testWidgets(
        'dismiss sets isDismissed to true',
        (tester) async {
          await _mountHook(tester);
          await tester.pump();

          getResult().dismiss();
          await tester.pump();

          expect(getResult().isDismissed, isTrue);
        },
        variant: TargetPlatformVariant.only(TargetPlatform.android),
      );
    });

    group('when installed version matches Zapstore', () {
      setUp(() {
        _api.zapstoreVersion = '2026.3.5';
        _setInstalledVersion('2026.3.5');
      });

      testWidgets(
        'returns null (no update)',
        (tester) async {
          await _mountHook(tester);
          await tester.pump();

          expect(getResult().availableVersion, isNull);
        },
        variant: TargetPlatformVariant.only(TargetPlatform.android),
      );
    });

    group('when installed version is newer than Zapstore', () {
      setUp(() {
        _api.zapstoreVersion = '2026.3.4';
        _setInstalledVersion('2026.3.5');
      });

      testWidgets(
        'returns null (no update)',
        (tester) async {
          await _mountHook(tester);
          await tester.pump();

          expect(getResult().availableVersion, isNull);
        },
        variant: TargetPlatformVariant.only(TargetPlatform.android),
      );
    });

    group('when Zapstore returns null (no release published)', () {
      setUp(() {
        _api.zapstoreVersion = null;
        _setInstalledVersion('2026.3.5');
      });

      testWidgets(
        'returns null',
        (tester) async {
          await _mountHook(tester);
          await tester.pump();

          expect(getResult().availableVersion, isNull);
        },
        variant: TargetPlatformVariant.only(TargetPlatform.android),
      );
    });

    group('when fetch throws', () {
      setUp(() {
        _api.zapstoreShouldThrow = true;
        _setInstalledVersion('2026.3.5');
      });

      testWidgets(
        'availableVersion is null on error',
        (tester) async {
          await _mountHook(tester);
          await tester.pump();

          expect(getResult().availableVersion, isNull);
        },
        variant: TargetPlatformVariant.only(TargetPlatform.android),
      );
    });

    group('version comparison edge cases', () {
      testWidgets(
        'major segment bump is newer',
        (tester) async {
          _api.zapstoreVersion = '2027.1.0';
          _setInstalledVersion('2026.12.31');

          await _mountHook(tester);
          await tester.pump();

          expect(getResult().availableVersion, equals('2027.1.0'));
        },
        variant: TargetPlatformVariant.only(TargetPlatform.android),
      );

      testWidgets(
        'patch segment bump is newer',
        (tester) async {
          _api.zapstoreVersion = '2026.3.6';
          _setInstalledVersion('2026.3.5');

          await _mountHook(tester);
          await tester.pump();

          expect(getResult().availableVersion, equals('2026.3.6'));
        },
        variant: TargetPlatformVariant.only(TargetPlatform.android),
      );

      testWidgets(
        'minor segment bump is newer',
        (tester) async {
          _api.zapstoreVersion = '2026.4.0';
          _setInstalledVersion('2026.3.5');

          await _mountHook(tester);
          await tester.pump();

          expect(getResult().availableVersion, equals('2026.4.0'));
        },
        variant: TargetPlatformVariant.only(TargetPlatform.android),
      );

      testWidgets(
        'lexicographic non-numeric segment greater returns update',
        (tester) async {
          _api.zapstoreVersion = '2026.b.5';
          _setInstalledVersion('2026.a.5');

          await _mountHook(tester);
          await tester.pump();

          expect(getResult().availableVersion, equals('2026.b.5'));
        },
        variant: TargetPlatformVariant.only(TargetPlatform.android),
      );

      testWidgets(
        'lexicographic non-numeric segment lower returns no update',
        (tester) async {
          _api.zapstoreVersion = '2026.a.5';
          _setInstalledVersion('2026.b.5');

          await _mountHook(tester);
          await tester.pump();

          expect(getResult().availableVersion, isNull);
        },
        variant: TargetPlatformVariant.only(TargetPlatform.android),
      );
    });
  });
}
