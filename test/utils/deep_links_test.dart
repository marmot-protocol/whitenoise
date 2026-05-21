import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/utils/deep_links.dart';

import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

void main() {
  setUpAll(() {
    RustLib.initMock(api: MockWnApi());
  });

  group('DeepLinks.parse', () {
    test('maps production user links to the user profile route', () {
      final target = DeepLinks.parse(Uri.parse('whitenoise://user/$testNpubB'));

      expect(target?.location, '/user-profile/$testPubkeyB');
    });

    test('maps staging user links to the user profile route', () {
      final target = DeepLinks.parse(Uri.parse('whitenoise-staging://user/$testNpubB'));

      expect(target?.location, '/user-profile/$testPubkeyB');
    });

    test('maps triple-slash user links to the user profile route', () {
      final target = DeepLinks.parse(Uri.parse('whitenoise:///user/$testNpubB'));

      expect(target?.location, '/user-profile/$testPubkeyB');
    });

    test('maps chat links to the chat route', () {
      final target = DeepLinks.parse(Uri.parse('whitenoise://chat/$testGroupId'));

      expect(target?.location, '/chats/$testGroupId');
    });

    test('maps settings links to settings routes', () {
      const expected = {
        'whitenoise://settings': '/settings',
        'whitenoise://settings/share-profile': '/share-profile',
        'whitenoise://settings/switch-profile': '/switch-profile',
        'whitenoise://settings/edit-profile': '/edit-profile',
        'whitenoise://settings/profile-keys': '/profile-keys',
        'whitenoise://settings/network': '/network',
        'whitenoise://settings/privacy-security': '/privacy-security',
        'whitenoise://settings/appearance': '/appearance',
        'whitenoise://settings/notifications': '/notification-settings',
        'whitenoise://settings/report-bug': '/report-bug',
        'whitenoise://settings/donate': '/donate',
        'whitenoise://settings/developer': '/developer-settings',
        'whitenoise://settings/developer/key-packages': '/key-package-management',
        'whitenoise://settings/developer/relay-state': '/relay-control-state',
        'whitenoise://settings/developer/app-logs': '/app-logs',
      };

      for (final entry in expected.entries) {
        expect(
          DeepLinks.parse(Uri.parse(entry.key))?.location,
          entry.value,
          reason: entry.key,
        );
      }
    });

    test('returns null for unsupported schemes and unknown paths', () {
      expect(DeepLinks.parse(Uri.parse('https://user/$testNpubB')), isNull);
      expect(DeepLinks.parse(Uri.parse('whitenoise://unknown/$testNpubB')), isNull);
      expect(DeepLinks.parse(Uri.parse('whitenoise://user/npub1invalid')), isNull);
      expect(DeepLinks.parse(Uri.parse('whitenoise://settings/sign-out')), isNull);
    });
  });

  group('DeepLinks.userUri', () {
    test('builds production user links by default', () {
      expect(DeepLinks.userUri(testNpubB), 'whitenoise://user/$testNpubB');
    });

    test('builds staging user links with the staging scheme', () {
      expect(
        DeepLinks.userUri(testNpubB, scheme: DeepLinks.stagingScheme),
        'whitenoise-staging://user/$testNpubB',
      );
    });
  });

  group('DeepLinks.chatUri', () {
    test('builds production chat links by default', () {
      expect(DeepLinks.chatUri(testGroupId), 'whitenoise://chat/$testGroupId');
    });

    test('builds staging chat links with the staging scheme', () {
      expect(
        DeepLinks.chatUri(testGroupId, scheme: DeepLinks.stagingScheme),
        'whitenoise-staging://chat/$testGroupId',
      );
    });
  });
}
