import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/l10n/generated/app_localizations.dart';
import 'package:whitenoise/providers/active_chat_provider.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/providers/foreground_service_provider.dart';
import 'package:whitenoise/providers/locale_provider.dart';
import 'package:whitenoise/services/foreground_service.dart';
import 'package:whitenoise/services/notification_service.dart';
import 'package:whitenoise/src/rust/api/notifications.dart' as notifications_api;

final _logger = Logger('NotificationProvider');

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final notificationListenerProvider = Provider.autoDispose<void>((ref) {
  if (!Platform.isAndroid) return;

  final pubkey = ref.watch(authProvider).value;
  if (pubkey == null) return;

  final notificationService = ref.read(notificationServiceProvider);
  final foregroundService = ref.read(foregroundServiceProvider);
  StreamSubscription<notifications_api.NotificationUpdate>? subscription;

  ref.onDispose(() {
    subscription?.cancel();
    foregroundService.stop();
    _logger.info('Notification listener disposed');
  });

  _initializeAndListen(notificationService, foregroundService, ref, (sub) {
    subscription = sub;
  });
});

Future<void> _initializeAndListen(
  NotificationService notificationService,
  ForegroundService foregroundService,
  Ref ref,
  void Function(StreamSubscription<notifications_api.NotificationUpdate>) onSubscription,
) async {
  try {
    await notificationService.initialize();
    await notificationService.requestPermission();

    await foregroundService.start();
    await foregroundService.requestBatteryOptimizationExemption();

    final stream = notifications_api.subscribeToNotifications();

    final subscription = stream.listen(
      (update) => _handleNotificationUpdate(update, notificationService, ref),
      onError: (error) {
        _logger.severe('Notification stream error', error);
      },
      onDone: () {
        _logger.info('Notification stream closed');
      },
    );

    onSubscription(subscription);
    _logger.info('Notification listener started');
  } catch (error, stackTrace) {
    _logger.severe('Failed to initialize notification listener', error, stackTrace);
  }
}

void _handleNotificationUpdate(
  notifications_api.NotificationUpdate update,
  NotificationService notificationService,
  Ref ref,
) {
  final activeChat = ref.read(activeChatProvider);
  if (activeChat == update.mlsGroupId) {
    _logger.fine('Skipping notification for active chat ${update.mlsGroupId}');
    return;
  }

  final locale = ref.read(localeProvider.notifier).resolveLocale();
  final l10n = lookupAppLocalizations(locale);
  final (title, body, isInvite) = formatNotification(update, l10n);

  notificationService.show(
    groupId: update.mlsGroupId,
    title: title,
    body: body,
    isInvite: isInvite,
  );
}

@visibleForTesting
(String title, String body, bool isInvite) formatNotification(
  notifications_api.NotificationUpdate update,
  AppLocalizations l10n,
) {
  final senderName = update.sender.displayName ?? l10n.unknownUser;

  switch (update.trigger) {
    case notifications_api.NotificationTrigger.newMessage:
      if (update.isDm) {
        return (senderName, update.content, false);
      } else {
        final groupName = update.groupName ?? l10n.unknownGroup;
        return (groupName, '$senderName: ${update.content}', false);
      }
    case notifications_api.NotificationTrigger.groupInvite:
      if (update.isDm) {
        return (senderName, l10n.hasInvitedYouToSecureChat, true);
      } else {
        final groupName = update.groupName ?? l10n.unknownGroup;
        return (groupName, l10n.userInvitedYouToSecureChat(senderName), true);
      }
  }
}
