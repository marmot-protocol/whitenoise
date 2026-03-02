import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/utils/app_flavor.dart';

void main() {
  const appFlavor = String.fromEnvironment('APP_FLAVOR');

  group('isStaging', () {
    test('matches APP_FLAVOR', () {
      expect(isStaging, appFlavor == 'staging');
    });

    test('is a bool', () {
      expect(isStaging, isA<bool>());
    });
  });
}
