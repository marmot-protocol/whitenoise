import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:whitenoise/hooks/use_app_version.dart';

late AsyncSnapshot<String> Function() getResult;

Future<void> _mountHook(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: HookBuilder(
        builder: (context) {
          final result = useAppVersion();
          getResult = () => result;
          return const SizedBox();
        },
      ),
    ),
  );
}

void main() {
  group('useAppVersion', () {
    testWidgets('returns version string from PackageInfo', (tester) async {
      PackageInfo.setMockInitialValues(
        appName: 'Whitenoise',
        packageName: 'com.example.whitenoise',
        version: '1.2.3',
        buildNumber: '42',
        buildSignature: '',
      );

      await _mountHook(tester);
      await tester.pump();

      expect(getResult().hasData, isTrue);
      expect(getResult().data, equals('1.2.3'));
    });

    testWidgets('is loading before future resolves', (tester) async {
      PackageInfo.setMockInitialValues(
        appName: 'Whitenoise',
        packageName: 'com.example.whitenoise',
        version: '0.3.0',
        buildNumber: '15',
        buildSignature: '',
      );

      await _mountHook(tester);

      expect(getResult().connectionState, equals(ConnectionState.waiting));
    });
  });
}
