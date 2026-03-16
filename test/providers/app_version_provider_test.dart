import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:whitenoise/providers/app_version_provider.dart';

void main() {
  group('appVersionProvider', () {
    test('returns version and build number from PackageInfo', () async {
      PackageInfo.setMockInitialValues(
        appName: 'Whitenoise',
        packageName: 'com.example.whitenoise',
        version: '1.2.3',
        buildNumber: '45',
        buildSignature: '',
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final version = await container.read(appVersionProvider.future);

      expect(version, '1.2.3+45');
    });
  });
}
