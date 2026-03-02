import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/utils/app_flavor.dart';

void main() {
  group('isStaging', () {
    test('is false when APP_FLAVOR is not set', () {
      expect(isStaging, isFalse);
    });

    test('is a bool', () {
      expect(isStaging, isA<bool>());
    });
  });
}
