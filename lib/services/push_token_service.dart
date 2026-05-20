import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/src/rust/api/notifications.dart' as notifications_api;

final _logger = Logger('PushTokenService');

class ProviderPushToken {
  const ProviderPushToken({required this.platform, required this.rawToken});

  final notifications_api.PushPlatform platform;
  final String rawToken;

  static ProviderPushToken? fromMap(Map<Object?, Object?> map) {
    final rawToken = (map['rawToken'] as String?)?.trim();
    if (rawToken == null || rawToken.isEmpty) return null;

    final platform = switch (map['platform']) {
      'apns' => notifications_api.PushPlatform.apns,
      'fcm' => notifications_api.PushPlatform.fcm,
      _ => null,
    };
    if (platform == null) return null;

    return ProviderPushToken(platform: platform, rawToken: rawToken);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProviderPushToken &&
          runtimeType == other.runtimeType &&
          platform == other.platform &&
          rawToken == other.rawToken;

  @override
  int get hashCode => Object.hash(platform, rawToken);
}

abstract class PushTokenSource {
  Stream<ProviderPushToken> get tokenUpdates;

  Future<ProviderPushToken?> getProviderPushToken();

  Future<bool> requestNotificationPermission();
}

class PushTokenService implements PushTokenSource {
  PushTokenService({MethodChannel? channel, bool? enabled})
    : _channel = channel ?? const MethodChannel(_channelName),
      _enabled = enabled ?? _isMobileTarget {
    _channel.setMethodCallHandler(_handleNativeMethodCall);
  }

  static const _channelName = 'org.parres.whitenoise/push_notifications';
  static const _methodGetProviderPushToken = 'getProviderPushToken';
  static const _methodRequestNotificationPermission = 'requestNotificationPermission';
  static const _methodProviderPushTokenUpdated = 'providerPushTokenUpdated';

  final MethodChannel _channel;
  final bool _enabled;
  final _tokenUpdates = StreamController<ProviderPushToken>.broadcast();

  @override
  Stream<ProviderPushToken> get tokenUpdates => _tokenUpdates.stream;

  @override
  Future<ProviderPushToken?> getProviderPushToken() async {
    if (!_enabled) return null;

    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>(
        _methodGetProviderPushToken,
      );
      if (result == null) return null;
      return ProviderPushToken.fromMap(result);
    } on PlatformException catch (error, stackTrace) {
      _logger.warning('Failed to get provider push token', error, stackTrace);
      return null;
    } catch (error, stackTrace) {
      _logger.warning('Failed to get provider push token', error, stackTrace);
      return null;
    }
  }

  @override
  Future<bool> requestNotificationPermission() async {
    if (!_enabled) return false;

    try {
      return await _channel.invokeMethod<bool>(
            _methodRequestNotificationPermission,
          ) ??
          false;
    } on PlatformException catch (error, stackTrace) {
      _logger.warning(
        'Failed to request notification permission',
        error,
        stackTrace,
      );
      return false;
    } catch (error, stackTrace) {
      _logger.warning(
        'Failed to request notification permission',
        error,
        stackTrace,
      );
      return false;
    }
  }

  Future<void> _handleNativeMethodCall(MethodCall call) async {
    if (call.method != _methodProviderPushTokenUpdated) return;
    final arguments = call.arguments;
    if (arguments is! Map) return;

    final token = ProviderPushToken.fromMap(
      Map<Object?, Object?>.from(arguments),
    );
    if (token != null) {
      _tokenUpdates.add(token);
    }
  }

  void dispose() {
    _channel.setMethodCallHandler(null);
    _tokenUpdates.close();
  }
}

bool get _isMobileTarget =>
    defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;
