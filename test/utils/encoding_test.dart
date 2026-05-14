import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/utils/encoding.dart';
import 'package:whitenoise_frb/src/rust/frb_generated.dart';

import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

void main() {
  late MockWnApi mockApi;

  setUpAll(() {
    mockApi = MockWnApi();
    RustLib.initMock(api: mockApi);
  });

  setUp(() {
    mockApi.reset();
  });

  group('npubFromHex', () {
    test('returns npub string for valid hex pubkey', () {
      final result = npubFromHex(testPubkeyA);
      expect(result, isNotNull);
      expect(result, testNpubA);
    });

    test('returns null when API throws error', () {
      mockApi.shouldFailNpubConversion = true;
      final result = npubFromHex(testPubkeyA);
      expect(result, isNull);
    });
  });

  group('hexFromNpub', () {
    test('returns hex string for valid npub', () {
      final result = hexFromNpub(testNpubA);
      expect(result, isNotNull);
      expect(result, testPubkeyA);
    });

    test('returns null when API throws error', () {
      mockApi.shouldFailHexFromNpub = true;
      final result = hexFromNpub(testNpubA);
      expect(result, isNull);
    });
  });
}
