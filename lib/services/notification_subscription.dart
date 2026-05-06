import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:logging/logging.dart';
import 'package:whitenoise/l10n/generated/app_localizations.dart';
import 'package:whitenoise/services/notification_service.dart';
import 'package:whitenoise/services/user_service.dart';
import 'package:whitenoise/src/rust/api/accounts.dart' as accounts_api;
import 'package:whitenoise/src/rust/api/mute_list.dart' as mute_list_api;
import 'package:whitenoise/src/rust/api/notifications.dart' as notifications_api;
import 'package:whitenoise/utils/metadata.dart';

final _logger = Logger('NotificationSubscription');

typedef ActiveChatGetter = String? Function();
typedef LocaleGetter = Locale Function();

/// Subscribes to the Rust-side notification stream and dispatches each update
/// to [NotificationService.show]. Designed to be usable from both the main UI
/// isolate (via a Riverpod provider that wires Ref-backed callbacks) and the
/// foreground-task background isolate (via callbacks that read persisted
/// defaults — no Riverpod, no widget tree).
class NotificationSubscription {
  NotificationSubscription({
    required NotificationService notificationService,
    required ActiveChatGetter getActiveChatId,
    required LocaleGetter getLocale,
    bool? enabled,
  }) : _notificationService = notificationService,
       _getActiveChatId = getActiveChatId,
       _getLocale = getLocale,
       _enabled = enabled ?? Platform.isAndroid;

  final NotificationService _notificationService;
  final ActiveChatGetter _getActiveChatId;
  final LocaleGetter _getLocale;
  final bool _enabled;

  StreamSubscription<notifications_api.NotificationUpdate>? _subscription;
  bool _stopped = false;

  bool get isRunning => _subscription != null;

  Future<void> start() async {
    if (!_enabled) return;
    if (_subscription != null) return;
    _stopped = false;

    try {
      await _notificationService.initialize();
      if (_stopped) return;
      await _notificationService.requestPermission();
      if (_stopped) return;

      final stream = notifications_api.subscribeToNotifications();
      _subscription = stream.listen(
        (update) async {
          try {
            await _handleUpdate(update);
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

      // coverage:ignore-start
      // Defensive: there's no await between the earlier _stopped check
      // (after requestPermission) and here, so in practice _stopped cannot
      // flip to true in this window. Keep the guard for safety if future
      // edits introduce an await above.
      if (_stopped) {
        await _subscription?.cancel();
        _subscription = null;
        return;
      }
      // coverage:ignore-end
      _logger.info('NotificationSubscription started');
    } catch (error, stackTrace) {
      _logger.severe('Failed to start notification subscription', error, stackTrace);
    }
  }

  Future<void> stop() async {
    _stopped = true;
    await _subscription?.cancel();
    _subscription = null;
    _logger.info('NotificationSubscription stopped');
  }

  @visibleForTesting
  Future<void> handleUpdate(notifications_api.NotificationUpdate update) => _handleUpdate(update);

  Future<void> _handleUpdate(notifications_api.NotificationUpdate update) async {
    final activeChat = _getActiveChatId();
    if (activeChat == update.mlsGroupId) {
      _logger.fine('Skipping notification for active chat ${update.mlsGroupId}');
      return;
    }
    if (await mute_list_api.isUserBlocked(
      accountPubkey: update.receiver.pubkey,
      targetPubkey: update.sender.pubkey,
    )) {
      _logger.fine('Skipping notification from blocked sender ${update.sender.pubkey}');
      return;
    }

    final locale = _getLocale();
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

    await _notificationService.show(
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
      final metadata = await UserService(sender.pubkey).getInitialMetadata();
      return presentName(metadata);
    } catch (e) {
      _logger.warning('Failed to fetch sender metadata', e);
      return null;
    }
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
