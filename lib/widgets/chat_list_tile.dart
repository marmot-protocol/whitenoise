import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/providers/account_pubkey_provider.dart';
import 'package:whitenoise/providers/locale_provider.dart';
import 'package:whitenoise/routes.dart' show Routes;
import 'package:whitenoise/services/user_service.dart';
import 'package:whitenoise/src/rust/api/chat_list.dart' show ChatSummary, setChatPinOrder;
import 'package:whitenoise/src/rust/api/groups.dart' show GroupType;
import 'package:whitenoise/src/rust/api/messages.dart' show ChatMessageSummary;
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/utils/metadata.dart';
import 'package:whitenoise/widgets/wn_avatar.dart';
import 'package:whitenoise/widgets/wn_chat_list_context_menu.dart';
import 'package:whitenoise/widgets/wn_chat_list_item.dart';
import 'package:whitenoise/widgets/wn_chat_status.dart';
import 'package:whitenoise/widgets/wn_icon.dart';

final _logger = Logger('ChatListTile');

({String subtitle, Widget? icon})? _mediaSubtitle(
  BuildContext context,
  ChatMessageSummary? lastMessage,
) {
  if (lastMessage == null ||
      lastMessage.content.isNotEmpty ||
      lastMessage.mediaAttachmentCount <= BigInt.zero) {
    return null;
  }
  return (
    subtitle: context.l10n.photoCount(lastMessage.mediaAttachmentCount.toInt()),
    icon: WnIcon(
      WnIcons.image,
      key: const Key('media_subtitle_icon'),
      size: 16.w,
      color: context.colors.backgroundContentSecondary,
    ),
  );
}

class ChatListTile extends HookConsumerWidget {
  final ChatSummary chatSummary;
  final VoidCallback? onChatListChanged;
  final void Function(String message)? onError;

  const ChatListTile({
    super.key,
    required this.chatSummary,
    this.onChatListChanged,
    this.onError,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemKey = useMemoized(GlobalKey.new);
    final formatters = ref.watch(localeFormattersProvider);
    final myPubkey = ref.watch(accountPubkeyProvider);
    final isDm = chatSummary.groupType == GroupType.directMessage;
    final isPending = chatSummary.pendingConfirmation;
    final hasWelcomer = chatSummary.welcomerPubkey != null;

    final welcomerMetadata = useMemoized(() async {
      if (!isPending || !hasWelcomer) return null;

      try {
        return UserService(chatSummary.welcomerPubkey!).fetchMetadata();
      } catch (_) {
        return null;
      }
    }, [chatSummary.welcomerPubkey, isPending, hasWelcomer]);
    final welcomerSnapshot = useFuture(welcomerMetadata);

    final hasGroupName = chatSummary.name?.isNotEmpty ?? false;
    final welcomerName = presentName(welcomerSnapshot.data);

    final String title;
    final String? pictureUrl;
    final String subtitle;
    final String? avatarName;
    Widget? subtitleIcon;

    final media = _mediaSubtitle(context, chatSummary.lastMessage);

    if (isPending) {
      final hasMessages = chatSummary.lastMessage != null;
      if (isDm) {
        title = welcomerName ?? chatSummary.name ?? context.l10n.unknownUser;
        pictureUrl = welcomerSnapshot.data?.picture ?? chatSummary.groupImageUrl;
        avatarName = welcomerName ?? chatSummary.name;
        if (media != null) {
          subtitle = media.subtitle;
          subtitleIcon = media.icon;
        } else if (hasMessages) {
          subtitle = chatSummary.lastMessage!.content;
        } else {
          subtitle = context.l10n.hasInvitedYouToSecureChat;
        }
      } else {
        title = hasGroupName ? chatSummary.name! : context.l10n.unknownGroup;
        pictureUrl = chatSummary.groupImagePath;
        avatarName = hasGroupName ? chatSummary.name! : null;
        if (media != null) {
          subtitle = media.subtitle;
          subtitleIcon = media.icon;
        } else if (hasMessages) {
          subtitle = chatSummary.lastMessage!.content;
        } else if (welcomerName != null) {
          subtitle = context.l10n.userInvitedYouToSecureChat(welcomerName);
        } else {
          subtitle = context.l10n.youHaveBeenInvitedToSecureChat;
        }
      }
    } else {
      if (isDm) {
        title = hasGroupName ? chatSummary.name! : context.l10n.unknownUser;
        pictureUrl = chatSummary.groupImageUrl;
      } else {
        title = hasGroupName ? chatSummary.name! : context.l10n.unknownGroup;
        pictureUrl = chatSummary.groupImagePath;
      }
      avatarName = hasGroupName ? chatSummary.name! : null;
      if (media != null) {
        subtitle = media.subtitle;
        subtitleIcon = media.icon;
      } else {
        subtitle = chatSummary.lastMessage?.content ?? '';
      }
    }

    final timestamp = chatSummary.lastMessage?.createdAt ?? chatSummary.createdAt;
    final formattedTime = formatters.formatRelativeTime(
      timestamp,
      context.l10n,
    );

    ChatStatusType? status;
    final unreadCount = chatSummary.unreadCount.toInt();
    if (isPending) {
      status = ChatStatusType.request;
    } else if (unreadCount > 0) {
      status = ChatStatusType.unreadCount;
    }

    String? prefixSubtitle;
    if (!isPending && chatSummary.lastMessage != null) {
      if (chatSummary.lastMessage!.author == myPubkey) {
        prefixSubtitle = '${context.l10n.you}: ';
      } else if (!isDm) {
        final authorName = chatSummary.lastMessage!.authorDisplayName;
        if (authorName != null && authorName.isNotEmpty) {
          prefixSubtitle = '$authorName: ';
        }
      }
    }

    final avatarColorKey = isDm
        ? (chatSummary.dmPeerPubkey ?? chatSummary.mlsGroupId)
        : chatSummary.mlsGroupId;

    void showContextMenu() {
      final renderBox = itemKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null || !renderBox.hasSize) return;

      final l10n = context.l10n;

      final isPinned = chatSummary.pinOrder != null;

      WnChatListContextMenu.show(
        context,
        childRenderBox: renderBox,
        child: WnChatListItem(
          title: title,
          subtitle: subtitle,
          timestamp: formattedTime,
          avatarUrl: pictureUrl,
          avatarName: avatarName,
          avatarColor: AvatarColor.fromPubkey(avatarColorKey),
          showPinned: isPinned,
          status: status,
          unreadCount: unreadCount,
          prefixSubtitle: prefixSubtitle,
          subtitleIcon: subtitleIcon,
        ),
        actions: [
          WnChatListContextMenuAction(
            id: isPinned ? 'unpin' : 'pin',
            label: isPinned ? l10n.unpin : l10n.pin,
            icon: isPinned ? WnIcons.unpin : WnIcons.pin,
            onTap: () async {
              try {
                await setChatPinOrder(
                  accountPubkey: myPubkey,
                  mlsGroupId: chatSummary.mlsGroupId,
                  pinOrder: isPinned ? null : 0,
                );
                onChatListChanged?.call();
              } catch (e, st) {
                _logger.severe('Failed to update pin order', e, st);
                onError?.call(l10n.failedToPinChat);
              }
            },
          ),
        ],
      );
    }

    return WnChatListItem(
      key: itemKey,
      onTap: isPending
          ? () => Routes.pushToInvite(context, chatSummary.mlsGroupId)
          : () => Routes.goToChat(context, chatSummary.mlsGroupId),
      onLongPress: isPending ? null : showContextMenu,
      title: title,
      subtitle: subtitle,
      timestamp: formattedTime,
      avatarUrl: pictureUrl,
      avatarName: avatarName,
      avatarColor: AvatarColor.fromPubkey(avatarColorKey),
      showPinned: chatSummary.pinOrder != null,
      status: status,
      unreadCount: unreadCount,
      prefixSubtitle: prefixSubtitle,
      subtitleIcon: subtitleIcon,
    );
  }
}
