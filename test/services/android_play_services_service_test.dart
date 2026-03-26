import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/services/android_play_services_service.dart';

import '../mocks/mock_android_play_services_channel.dart';

void main() {
  group('AndroidPlayServicesAvailability', () {
    test('fromMap creates availability with all fields', () {
      final availability = AndroidPlayServicesAvailability.fromMap({
        'isAvailable': true,
        'statusCode': 0,
      });

      expect(availability.isAvailable, isTrue);
      expect(availability.statusCode, 0);
    });

    test('fromMap handles missing fields', () {
      final availability = AndroidPlayServicesAvailability.fromMap({});

      expect(availability.isAvailable, isFalse);
      expect(availability.statusCode, isNull);
    });

    test('unavailable constructor sets false values', () {
      const availability = AndroidPlayServicesAvailability.unavailable();

      expect(availability.isAvailable, isFalse);
      expect(availability.statusCode, isNull);
    });

    test('toString returns formatted string', () {
      const availability = AndroidPlayServicesAvailability(isAvailable: true, statusCode: 0);

      expect(
        availability.toString(),
        'AndroidPlayServicesAvailability(isAvailable: true, statusCode: 0)',
      );
    });
  });

  group('AndroidPlayServicesService', () {
    late MockAndroidPlayServicesChannel mockChannel;

    setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

    setUp(() {
      mockChannel = mockAndroidPlayServicesChannel();
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
    });

    tearDown(() {
      mockChannel.reset();
      debugDefaultTargetPlatformOverride = null;
    });

    test('returns unavailable on non-android platforms', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      const service = AndroidPlayServicesService();
      final availability = await service.getAvailability();

      expect(availability.isAvailable, isFalse);
      expect(availability.statusCode, isNull);
      expect(mockChannel.log, isEmpty);
    });

    test('returns availability from the native channel', () async {
      mockChannel.setResult('getAvailability', {
        'isAvailable': true,
        'statusCode': 0,
      });

      const service = AndroidPlayServicesService();
      final availability = await service.getAvailability();

      expect(availability.isAvailable, isTrue);
      expect(availability.statusCode, 0);
      expect(mockChannel.log, hasLength(1));
      expect(mockChannel.log.single.method, 'getAvailability');
    });

    test('returns unavailable when the native channel returns null', () async {
      mockChannel.setResult('getAvailability', null);

      const service = AndroidPlayServicesService();
      final availability = await service.getAvailability();

      expect(availability.isAvailable, isFalse);
      expect(availability.statusCode, isNull);
    });

    test('returns unavailable when the native channel throws PlatformException', () async {
      mockChannel.setException(
        'getAvailability',
        PlatformException(code: 'ERROR', message: 'Play services unavailable'),
      );

      const service = AndroidPlayServicesService();
      final availability = await service.getAvailability();

      expect(availability.isAvailable, isFalse);
      expect(availability.statusCode, isNull);
    });

    test('returns unavailable when the native channel throws a non-platform error', () async {
      mockChannel.setError('getAvailability', StateError('channel failed'));

      const service = AndroidPlayServicesService();
      final availability = await service.getAvailability();

      expect(availability.isAvailable, isFalse);
      expect(availability.statusCode, isNull);
    });

    test('isAvailable returns the availability flag', () async {
      mockChannel.setResult('getAvailability', {
        'isAvailable': true,
        'statusCode': 0,
      });

      const service = AndroidPlayServicesService();
      expect(await service.isAvailable(), isTrue);
    });
  });
}
