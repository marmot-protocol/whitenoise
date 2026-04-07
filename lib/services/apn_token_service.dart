import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

final _logger = Logger('ApnTokenService');

class ApnTokenService {
  static const _channel = MethodChannel('org.parres.whitenoise/apn_token');

  const ApnTokenService();

  Future<String?> getToken() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return null;
    }

    try {
      final token = await _channel.invokeMethod<String>('getToken');
      _logger.fine('APNs token retrieved: ${token != null ? '(present)' : '(null)'}');
      return token;
    } on PlatformException catch (e, stackTrace) {
      _logger.warning('Failed to get APNs token: ${e.code} - ${e.message}', e, stackTrace);
      return null;
    } catch (e, stackTrace) {
      _logger.warning('Failed to get APNs token', e, stackTrace);
      return null;
    }
  }
}
