import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/services/apn_token_service.dart';

import '../mocks/mock_apn_token_channel.dart';

void main() {
  group('ApnTokenService', () {
    late MockApnTokenChannel mockChannel;

    setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

    setUp(() {
      mockChannel = mockApnTokenChannel();
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    });

    tearDown(() {
      mockChannel.reset();
      debugDefaultTargetPlatformOverride = null;
    });

    test('returns null on non-iOS platforms', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      const service = ApnTokenService();
      final token = await service.getToken();

      expect(token, isNull);
      expect(mockChannel.log, isEmpty);
    });

    test('returns token from native channel', () async {
      mockChannel.setResult('getToken', 'abcdef1234567890');

      const service = ApnTokenService();
      final token = await service.getToken();

      expect(token, 'abcdef1234567890');
      expect(mockChannel.log, hasLength(1));
      expect(mockChannel.log.single.method, 'getToken');
    });

    test('returns null when native channel returns null', () async {
      mockChannel.setResult('getToken', null);

      const service = ApnTokenService();
      final token = await service.getToken();

      expect(token, isNull);
    });

    test('returns null when native channel throws PlatformException', () async {
      mockChannel.setException(
        'getToken',
        PlatformException(code: 'ERROR', message: 'Token unavailable'),
      );

      const service = ApnTokenService();
      final token = await service.getToken();

      expect(token, isNull);
    });

    test('returns null when native channel throws a non-platform error', () async {
      mockChannel.setError('getToken', StateError('channel failed'));

      const service = ApnTokenService();
      final token = await service.getToken();

      expect(token, isNull);
    });
  });
}
