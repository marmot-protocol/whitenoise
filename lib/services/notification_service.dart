import 'dart:convert' show utf8;
import 'dart:io' show Platform;

import 'package:crypto/crypto.dart' show sha256;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logging/logging.dart';

final _logger = Logger('NotificationService');

const _payloadTriggerMessage = 'message';
const _payloadTriggerInvite = 'invite';

class NotificationService {
  NotificationService({
    FlutterLocalNotificationsPlugin? plugin,
    void Function(String groupId, bool isInvite)? onNotificationTap,
    bool? enabled,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _onNotificationTap = onNotificationTap,
       _enabled = enabled ?? Platform.isAndroid;

  final FlutterLocalNotificationsPlugin _plugin;
  final void Function(String groupId, bool isInvite)? _onNotificationTap;
  final bool _enabled;
  bool _initialized = false;

  static const _channelId = 'messages';
  static const _channelName = 'Messages';
  static const _channelDescription = 'Notifications for new messages and invites';

  Future<void> initialize() async {
    if (!_enabled) return;
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );

    _initialized = true;
    _logger.info('NotificationService initialized');
  }

  void _handleNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || _onNotificationTap == null) return;

    final parts = payload.split('|');
    if (parts.length < 2) return;

    final groupId = parts[0];
    final isInvite = parts[1] == _payloadTriggerInvite;
    _onNotificationTap(groupId, isInvite);
  }

  Future<void> show({
    required String groupId,
    required String title,
    required String body,
    bool isInvite = false,
  }) async {
    if (!_enabled) return;
    if (!_initialized) {
      _logger.warning('NotificationService not initialized, skipping notification');
      return;
    }

    final notificationId = generateNotificationId(groupId);
    final payload = '$groupId|${isInvite ? _payloadTriggerInvite : _payloadTriggerMessage}';

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(notificationId, title, body, details, payload: payload);
    _logger.fine('Showed notification for group $groupId: $title');
  }

  Future<void> cancelForGroup(String groupId) async {
    if (!_enabled) return;

    final notificationId = generateNotificationId(groupId);
    await _plugin.cancel(notificationId);
    _logger.fine('Cancelled notification for group $groupId');
  }

  Future<bool> requestPermission() async {
    if (!_enabled) return false;

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return false;

    final granted = await androidPlugin.requestNotificationsPermission();
    _logger.info('Notification permission ${granted == true ? 'granted' : 'denied'}');
    return granted ?? false;
  }

  static int generateNotificationId(String groupId) {
    final bytes = sha256.convert(utf8.encode(groupId)).bytes;
    final id = (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
    return id & 0x7FFFFFFF;
  }
}
