import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/providers/active_chat_provider.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/providers/foreground_service_provider.dart';
import 'package:whitenoise/providers/locale_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/services/android_play_services_service.dart';
import 'package:whitenoise/services/foreground_service.dart'
    show ForegroundService, PendingNotificationTap;
import 'package:whitenoise/services/foreground_service.dart' as foreground_service;
import 'package:whitenoise/services/notification_service.dart';
import 'package:whitenoise/services/notification_subscription.dart';
// Re-export so main.dart can import PendingNotificationTap + the consumer
// plus the routing helper from one place.
export 'package:whitenoise/services/foreground_service.dart' show PendingNotificationTap;

final _logger = Logger('NotificationProvider');
const _pushChannel = MethodChannel('org.parres.whitenoise/push_notifications');
const _consumePendingNotificationTapMethod = 'consumePendingNotificationTap';

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
  if (!notificationsSupported()) return;

  final pubkey = ref.watch(authProvider).value;
  if (pubkey == null) return;

  final notificationService = ref.read(notificationServiceProvider);

  final subscription = NotificationSubscription(
    notificationService: notificationService,
    getActiveChatId: () => ref.read(activeChatProvider),
    getLocale: () => ref.read(localeProvider.notifier).resolveLocale(),
  );

  ref.onDispose(() {
    subscription.stop();
    _logger.info('Notification listener disposed');
  });

  if (!Platform.isAndroid) {
    _startNotificationSubscription(subscription, ref);
    return;
  }

  const androidPlayServicesService = AndroidPlayServicesService();
  final foregroundService = ref.read(foregroundServiceProvider);

  ref.onDispose(() {
    foregroundService.stop();
  });

  _startForegroundAndSubscribe(
    androidPlayServicesService,
    foregroundService,
    subscription,
    ref,
  );
});

Future<void> _startNotificationSubscription(
  NotificationSubscription subscription,
  Ref ref,
) async {
  try {
    await subscription.start();
    if (!ref.mounted) {
      await subscription.stop();
      return;
    }
    _logger.info('Notification listener started');
  } catch (error, stackTrace) {
    _logger.severe('Failed to initialize notification listener', error, stackTrace);
  }
}

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

    // Claim ownership of the notification channel before starting the main
    // subscription. If the service was started headlessly (post-reboot /
    // package-replaced), the task isolate is already subscribed; this signal
    // tells it to yield. WidgetsBindingObserver doesn't replay the current
    // lifecycle state on registration, so we can't rely on the eventual
    // `resumed` event firing in time to avoid a brief double-subscription
    // window.
    await foregroundService.notifyMainStarted();

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
  Future<void> Function()? beforeNavigate,
}) async {
  if (currentActivePubkey != receiverPubkey) {
    await switchToProfile(receiverPubkey);
    _logger.info('Switched to account $receiverPubkey for notification tap');
  }

  await beforeNavigate?.call();

  _navigateToNotificationTarget(groupId: groupId, isInvite: isInvite);
}

/// Routes a previously-stashed notification tap if one exists. Intended to be
/// called from the main isolate on startup / resume — after the task isolate
/// fired a headless notification and stashed the tap payload via
/// [FlutterForegroundTask.saveData].
///
/// Guards against acting on an unmounted widget state (pass `mounted` from
/// the calling ConsumerState). No-op when no payload is pending.
Future<bool> routePendingTap({
  required PendingNotificationTap? pending,
  required bool isMounted,
  required String? currentActivePubkey,
  required Future<void> Function(String pubkey) switchToProfile,
  Future<void> Function()? beforeNavigate,
}) async {
  if (pending == null) return false;
  if (!isMounted) return false;
  await handleNotificationTap(
    currentActivePubkey: currentActivePubkey,
    switchToProfile: switchToProfile,
    groupId: pending.groupId,
    isInvite: pending.isInvite,
    receiverPubkey: pending.receiverPubkey,
    beforeNavigate: beforeNavigate,
  );
  return true;
}

Future<PendingNotificationTap?> consumePendingNotificationTap({
  bool? isAndroid,
  bool? isIOS,
  Future<PendingNotificationTap?> Function()? consumeAndroidTap,
  MethodChannel pushChannel = _pushChannel,
}) async {
  if (isAndroid ?? Platform.isAndroid) {
    return (consumeAndroidTap ?? foreground_service.consumePendingNotificationTap)();
  }
  if (!(isIOS ?? Platform.isIOS)) return null;

  try {
    final result = await pushChannel.invokeMethod<Map<Object?, Object?>>(
      _consumePendingNotificationTapMethod,
    );
    if (result == null) return null;
    return PendingNotificationTap.fromMap(result);
  } catch (error, stackTrace) {
    _logger.warning('Failed to consume pending iOS notification tap', error, stackTrace);
    return null;
  }
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
