import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/providers/deep_link_provider.dart';
import 'package:whitenoise/utils/deep_links.dart';

void main() {
  group('deepLinkSchemeForPackageName', () {
    test('returns production scheme for production package names', () {
      expect(
        deepLinkSchemeForPackageName('org.parres.whitenoise'),
        DeepLinks.productionScheme,
      );
    });

    test('returns staging scheme for staging package names', () {
      expect(
        deepLinkSchemeForPackageName('org.parres.whitenoise.staging'),
        DeepLinks.stagingScheme,
      );
      expect(
        deepLinkSchemeForPackageName('dev.ipf.whitenoise.staging'),
        DeepLinks.stagingScheme,
      );
    });
  });
}
