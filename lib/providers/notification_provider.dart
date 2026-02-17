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
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/services/foreground_service.dart';
import 'package:whitenoise/services/notification_service.dart';
import 'package:whitenoise/services/user_service.dart';
import 'package:whitenoise/src/rust/api/accounts.dart' as accounts_api;
import 'package:whitenoise/src/rust/api/notifications.dart' as notifications_api;
import 'package:whitenoise/utils/metadata.dart';

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

void _initializeAndListen(
  NotificationService notificationService,
  ForegroundService foregroundService,
  Ref ref,
  void Function(StreamSubscription<notifications_api.NotificationUpdate>) onSubscription,
) async {
  try {
    await notificationService.initialize();
    if (!ref.mounted) return;
    await notificationService.requestPermission();
    if (!ref.mounted) return;

    await foregroundService.start();
    if (!ref.mounted) {
      await foregroundService.stop();
      return;
    }
    await foregroundService.requestBatteryOptimizationExemption();

    final stream = notifications_api.subscribeToNotifications();

    final subscription = stream.listen(
      (update) async {
        try {
          await handleNotificationUpdate(update, notificationService, ref);
        } catch (error, stackTrace) {
          _logger.severe('Error handling notification update', error, stackTrace);
        }
      },
      onError: (error) {
        _logger.severe('Notification stream error', error);
      },
      onDone: () {
        _logger.info('Notification stream closed');
      },
    );

    if (!ref.mounted) {
      await subscription.cancel();
      await foregroundService.stop();
      return;
    }
    onSubscription(subscription);
    _logger.info('Notification listener started');
  } catch (error, stackTrace) {
    _logger.severe('Failed to initialize notification listener', error, stackTrace);
  }
}
// coverage:ignore-end

@visibleForTesting
Future<void> handleNotificationUpdate(
  notifications_api.NotificationUpdate update,
  NotificationService notificationService,
  Ref ref,
) async {
  final activeChat = ref.read(activeChatProvider);
  if (activeChat == update.mlsGroupId) {
    _logger.fine('Skipping notification for active chat ${update.mlsGroupId}');
    return;
  }

  final locale = ref.read(localeProvider.notifier).resolveLocale();
  final l10n = lookupAppLocalizations(locale);

  final accounts = await accounts_api.getAccounts();
  final String? receiverName = accounts.length > 1
      ? (update.receiver.displayName ?? l10n.unknownUser)
      : null;

  final senderName = await _resolveSenderName(update.sender);

  final (title, body, isInvite) = formatNotification(
    update,
    l10n,
    receiverName: receiverName,
    senderName: senderName,
  );

  await notificationService.show(
    groupId: update.mlsGroupId,
    title: title,
    body: body,
    receiverPubkey: update.receiver.pubkey,
    isInvite: isInvite,
  );
}

Future<String?> _resolveSenderName(notifications_api.NotificationUser sender) async {
  if (sender.displayName != null) return sender.displayName;
  try {
    final metadata = await UserService(sender.pubkey).fetchMetadata();
    return presentName(metadata);
  } catch (e) {
    _logger.warning('Failed to fetch sender metadata', e);
    return null;
  }
}

@visibleForTesting
(String title, String body, bool isInvite) formatNotification(
  notifications_api.NotificationUpdate update,
  AppLocalizations l10n, {
  String? receiverName,
  String? senderName,
}) {
  senderName ??= update.sender.displayName ?? l10n.unknownUser;

  String applyReceiver(String title) {
    if (receiverName == null) return title;
    return '$title ($receiverName)';
  }

  switch (update.trigger) {
    case notifications_api.NotificationTrigger.newMessage:
      if (update.isDm) {
        return (applyReceiver(senderName), update.content, false);
      } else {
        final groupName = update.groupName ?? l10n.unknownGroup;
        return (applyReceiver(groupName), '$senderName: ${update.content}', false);
      }
    case notifications_api.NotificationTrigger.groupInvite:
      if (update.isDm) {
        return (applyReceiver(senderName), l10n.hasInvitedYouToSecureChat, true);
      } else {
        final groupName = update.groupName ?? l10n.unknownGroup;
        return (applyReceiver(groupName), l10n.userInvitedYouToSecureChat(senderName), true);
      }
  }
}

// coverage:ignore-start
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
