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
// Re-export so main.dart can import PendingNotificationTap + the consumer
// plus the routing helper from one place.
export 'package:whitenoise/services/foreground_service.dart'
    show consumePendingNotificationTap, PendingNotificationTap;

final _logger = Logger('NotificationProvider');

// coverage:ignore-start
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(
    onNotificationTap: (groupId, isInvite, receiverPubkey) {
      handleNotificationTap(
        currentActivePubkey: ref.read(authProvider).value,
        switchToProfile: (pk) => ref.read(authProvider.notifier).switchProfile(pk),
        groupId: groupId,
        isInvite: isInvite,
        receiverPubkey: receiverPubkey,
      );
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

/// Routes a notification tap — whether fired synchronously from the
/// NotificationService's tap callback (in-app) or consumed from persisted
/// state after a headless tap woke the app. Switches the active account if
/// needed, then navigates to the chat/invite screen.
///
/// Takes plain values and callbacks instead of a `Ref` so it can be called
/// from both Provider contexts (Ref.read) and ConsumerState contexts
/// (WidgetRef.read).
Future<void> handleNotificationTap({
  required String? currentActivePubkey,
  required Future<void> Function(String pubkey) switchToProfile,
  required String groupId,
  required bool isInvite,
  required String receiverPubkey,
}) async {
  if (currentActivePubkey != receiverPubkey) {
    await switchToProfile(receiverPubkey);
    _logger.info('Switched to account $receiverPubkey for notification tap');
  }

  _navigateToNotificationTarget(groupId: groupId, isInvite: isInvite);
}

/// Routes a previously-stashed notification tap if one exists. Intended to be
/// called from the main isolate on startup / resume — after the task isolate
/// fired a headless notification and stashed the tap payload via
/// [FlutterForegroundTask.saveData].
///
/// Guards against acting on an unmounted widget state (pass `mounted` from
/// the calling ConsumerState). No-op when no payload is pending.
Future<void> routePendingTap({
  required PendingNotificationTap? pending,
  required bool isMounted,
  required String? currentActivePubkey,
  required Future<void> Function(String pubkey) switchToProfile,
}) async {
  if (pending == null) return;
  if (!isMounted) return;
  await handleNotificationTap(
    currentActivePubkey: currentActivePubkey,
    switchToProfile: switchToProfile,
    groupId: pending.groupId,
    isInvite: pending.isInvite,
    receiverPubkey: pending.receiverPubkey,
  );
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
