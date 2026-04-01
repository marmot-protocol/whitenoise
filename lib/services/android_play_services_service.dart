import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

final _logger = Logger('AndroidPlayServicesService');

class AndroidPlayServicesAvailability {
  const AndroidPlayServicesAvailability({
    required this.isAvailable,
    this.statusCode,
  });

  const AndroidPlayServicesAvailability.unavailable() : isAvailable = false, statusCode = null;

  final bool isAvailable;
  final int? statusCode;

  factory AndroidPlayServicesAvailability.fromMap(Map<Object?, Object?> map) {
    return AndroidPlayServicesAvailability(
      isAvailable: map['isAvailable'] as bool? ?? false,
      statusCode: map['statusCode'] as int?,
    );
  }

  @override
  String toString() {
    return 'AndroidPlayServicesAvailability(isAvailable: $isAvailable, statusCode: $statusCode)';
  }
}

class AndroidPlayServicesService {
  static const _channel = MethodChannel('org.parres.whitenoise/android_play_services');

  const AndroidPlayServicesService();

  Future<AndroidPlayServicesAvailability> getAvailability() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return const AndroidPlayServicesAvailability.unavailable();
    }

    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>('getAvailability');
      if (result == null) {
        _logger.warning('Android play services availability channel returned null');
        return const AndroidPlayServicesAvailability.unavailable();
      }

      final availability = AndroidPlayServicesAvailability.fromMap(result);
      _logger.fine(
        'Google Play services available: ${availability.isAvailable} '
        '(statusCode: ${availability.statusCode})',
      );
      return availability;
    } on PlatformException catch (e, stackTrace) {
      _logger.warning(
        'Failed to check Google Play services availability: ${e.code} - ${e.message}',
        e,
        stackTrace,
      );
      return const AndroidPlayServicesAvailability.unavailable();
    } catch (e, stackTrace) {
      _logger.warning('Failed to check Google Play services availability', e, stackTrace);
      return const AndroidPlayServicesAvailability.unavailable();
    }
  }

  Future<bool> isAvailable() async {
    return (await getAvailability()).isAvailable;
  }
}
