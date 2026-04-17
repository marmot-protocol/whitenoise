import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/providers/active_chat_provider.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/providers/foreground_service_provider.dart';
import 'package:whitenoise/providers/locale_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/services/android_play_services_service.dart';
import 'package:whitenoise/services/foreground_service.dart';
import 'package:whitenoise/services/notification_service.dart';
import 'package:whitenoise/services/notification_subscription.dart';

final _logger = Logger('NotificationProvider');

// coverage:ignore-start
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(
    onNotificationTap: (groupId, isInvite, receiverPubkey) {
      _onNotificationTap(ref, groupId, isInvite, receiverPubkey);
    },
  );
});

final notificationListenerProvider = Provider.autoDispose<void>((ref) {
  if (!Platform.isAndroid) return;

  final pubkey = ref.watch(authProvider).value;
  if (pubkey == null) return;

  const androidPlayServicesService = AndroidPlayServicesService();
  final notificationService = ref.read(notificationServiceProvider);
  final foregroundService = ref.read(foregroundServiceProvider);

  final subscription = NotificationSubscription(
    notificationService: notificationService,
    getActiveChatId: () => ref.read(activeChatProvider),
    getLocale: () => ref.read(localeProvider.notifier).resolveLocale(),
  );

  ref.onDispose(() {
    subscription.stop();
    foregroundService.stop();
    _logger.info('Notification listener disposed');
  });

  _startForegroundAndSubscribe(
    androidPlayServicesService,
    foregroundService,
    subscription,
    ref,
  );
});

Future<void> _startForegroundAndSubscribe(
  AndroidPlayServicesService playServicesService,
  ForegroundService foregroundService,
  NotificationSubscription subscription,
  Ref ref,
) async {
  try {
    final playServicesAvailability = await playServicesService.getAvailability();
    if (!ref.mounted) return;
    if (playServicesAvailability.isAvailable) {
      _logger.info(
        'Google Play services are available; continuing the foreground notification '
        'transport until FCM is configured',
      );
    } else {
      _logger.info(
        'Google Play services are unavailable; continuing the foreground notification '
        'transport',
      );
    }

    await foregroundService.start();
    if (!ref.mounted) {
      await foregroundService.stop();
      return;
    }
    await foregroundService.requestBatteryOptimizationExemption();

    await subscription.start();
    if (!ref.mounted) {
      await subscription.stop();
      await foregroundService.stop();
      return;
    }
    _logger.info('Notification listener started');
  } catch (error, stackTrace) {
    _logger.severe('Failed to initialize notification listener', error, stackTrace);
  }
}

Future<void> _onNotificationTap(
  Ref ref,
  String groupId,
  bool isInvite,
  String receiverPubkey,
) async {
  final activePubkey = ref.read(authProvider).value;
  if (activePubkey != receiverPubkey) {
    await ref.read(authProvider.notifier).switchProfile(receiverPubkey);
    _logger.info('Switched to account $receiverPubkey for notification tap');
  }

  _navigateToNotificationTarget(groupId: groupId, isInvite: isInvite);
}

void _navigateToNotificationTarget({
  required String groupId,
  required bool isInvite,
}) {
  final context = Routes.navigatorKey.currentContext;
  if (context == null) {
    _logger.warning('No navigator context available for notification tap');
    return;
  }

  if (isInvite) {
    Routes.pushToInvite(context, groupId);
  } else {
    Routes.goToChat(context, groupId);
  }
}

// coverage:ignore-end
