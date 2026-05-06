import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/constants/feature_flags.dart';
import 'package:whitenoise/hooks/use_leave_group.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/providers/account_pubkey_provider.dart';
import 'package:whitenoise/providers/feature_flags_provider.dart';
import 'package:whitenoise/providers/locale_provider.dart';
import 'package:whitenoise/routes.dart' show Routes;
import 'package:whitenoise/services/user_service.dart';
import 'package:whitenoise/src/rust/api/account_groups.dart' show archiveChat, unarchiveChat;
import 'package:whitenoise/src/rust/api/chat_list.dart' show setChatPinOrder;
import 'package:whitenoise/src/rust/api/chat_summary.dart' show ChatSummary;
import 'package:whitenoise/src/rust/api/groups.dart' show GroupType;
import 'package:whitenoise/src/rust/api/messages.dart' show ChatMessageSummary;
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/utils/metadata.dart';
import 'package:whitenoise/widgets/chat_list_menu.dart';
import 'package:whitenoise/widgets/wn_avatar.dart';
import 'package:whitenoise/widgets/wn_chat_list_item.dart';
import 'package:whitenoise/widgets/wn_chat_status.dart';
import 'package:whitenoise/widgets/wn_icon.dart';

final _logger = Logger('ChatListTile');

typedef _TileDisplay = ({
  String title,
  String subtitle,
  String? prefixSubtitle,
  String? pictureUrl,
  String? avatarName,
  AvatarColor avatarColor,
  String formattedTime,
  ChatStatusType? status,
  int unreadCount,
  Widget? subtitleIcon,
  bool showPinned,
});

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
    subtitle: context.l10n.mediaCount(lastMessage.mediaAttachmentCount.toInt()),
    icon: WnIcon(
      WnIcons.image,
      key: const Key('media_subtitle_icon'),
      size: 16.w,
      color: context.colors.backgroundContentSecondary,
    ),
  );
}

_TileDisplay _buildTileDisplay({
  required BuildContext context,
  required ChatSummary chatSummary,
  required String myPubkey,
  required String? welcomerName,
  required String? welcomerPicture,
  required String formattedTime,
  required String? searchSnippet,
}) {
  final isDm = chatSummary.groupType == GroupType.directMessage;
  final isPending = chatSummary.pendingConfirmation;
  final hasGroupName = chatSummary.name?.isNotEmpty ?? false;

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
      pictureUrl = welcomerPicture ?? chatSummary.groupImageUrl;
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
    if (chatSummary.selfRemoved) {
      subtitle = context.l10n.youLeftTheGroup;
    } else if (media != null) {
      subtitle = media.subtitle;
      subtitleIcon = media.icon;
    } else {
      subtitle = chatSummary.lastMessage?.content ?? '';
    }
  }

  final unreadCount = chatSummary.unreadCount.toInt();
  ChatStatusType? status;
  if (isPending) {
    status = ChatStatusType.request;
  } else if (unreadCount > 0) {
    status = ChatStatusType.unreadCount;
  }

  String? prefixSubtitle;
  if (!isPending && !chatSummary.selfRemoved && chatSummary.lastMessage != null) {
    if (chatSummary.lastMessage!.author == myPubkey) {
      prefixSubtitle = '${context.l10n.you}: ';
    } else if (!isDm) {
      final authorName = chatSummary.lastMessage!.authorDisplayName;
      if (authorName != null && authorName.isNotEmpty) {
        prefixSubtitle = '$authorName: ';
      }
    }
  }

  final String displaySubtitle;
  final String? displayPrefixSubtitle;
  final Widget? displaySubtitleIcon;
  if (searchSnippet != null) {
    displaySubtitle = searchSnippet;
    displayPrefixSubtitle = null;
    displaySubtitleIcon = null;
  } else {
    displaySubtitle = subtitle;
    displayPrefixSubtitle = prefixSubtitle;
    displaySubtitleIcon = subtitleIcon;
  }

  final avatarColorKey = isDm
      ? (chatSummary.dmPeerPubkey ?? chatSummary.mlsGroupId)
      : chatSummary.mlsGroupId;

  return (
    title: title,
    subtitle: displaySubtitle,
    prefixSubtitle: displayPrefixSubtitle,
    pictureUrl: pictureUrl,
    avatarName: avatarName,
    avatarColor: AvatarColor.fromPubkey(avatarColorKey),
    formattedTime: formattedTime,
    status: status,
    unreadCount: unreadCount,
    subtitleIcon: displaySubtitleIcon,
    showPinned: chatSummary.pinOrder != null,
  );
}

Future<void> _runAction({
  required Future<void> Function() action,
  required VoidCallback onSuccess,
  required void Function(String) onError,
  required Logger logger,
  required String errorMessage,
  required String logMessage,
}) async {
  try {
    await action();
    onSuccess();
  } catch (e, st) {
    logger.severe(logMessage, e, st);
    onError(errorMessage);
  }
}

List<ChatListAction> _buildLeaveConfirmationActions({
  required AppLocalizations l10n,
  required BuildContext context,
  required Future<void> Function() leaveGroup,
  required VoidCallback onSuccess,
  required void Function(String) onError,
  required VoidCallback onBack,
}) => [
  ChatListAction(
    id: 'cancel_leave',
    label: l10n.cancel,
    icon: WnIcons.closeLarge,
    onTap: () async {},
  ),
  ChatListAction(
    id: 'confirm_leave_group',
    label: l10n.leave,
    icon: WnIcons.leave,
    isDestructive: true,
    onTap: () => _runAction(
      action: leaveGroup,
      onSuccess: onSuccess,
      onError: onError,
      logger: _logger,
      errorMessage: l10n.failedToLeaveGroup,
      logMessage: 'Failed to leave group',
    ),
  ),
];

class ChatListTile extends HookConsumerWidget {
  final ChatSummary chatSummary;
  final VoidCallback? onChatListChanged;
  final void Function(String message)? onError;
  final bool isArchived;
  final String? searchSnippet;

  const ChatListTile({
    super.key,
    required this.chatSummary,
    this.onChatListChanged,
    this.onError,
    this.isArchived = false,
    this.searchSnippet,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemKey = useMemoized(GlobalKey.new);
    final formatters = ref.watch(localeFormattersProvider);
    final myPubkey = ref.watch(accountPubkeyProvider);
    final isPending = chatSummary.pendingConfirmation;
    final hasWelcomer = chatSummary.welcomerPubkey != null;

    final leaveGroupEnabled = ref.watch(featureFlagProvider(FeatureFlag.leaveGroup));
    final leaveGroupState = useLeaveGroup(
      accountPubkey: myPubkey,
      groupId: chatSummary.mlsGroupId,
      featureEnabled: leaveGroupEnabled,
      groupType: chatSummary.groupType,
      pendingConfirmation: chatSummary.pendingConfirmation,
      selfRemoved: chatSummary.selfRemoved,
    );

    final welcomerStream = useMemoized(() {
      if (!isPending || !hasWelcomer) return null;
      return UserService(chatSummary.welcomerPubkey!).watchMetadata();
    }, [chatSummary.welcomerPubkey, isPending, hasWelcomer]);
    final welcomerSnapshot = useStream(welcomerStream);

    final welcomerName = presentName(welcomerSnapshot.data);

    final timestamp = chatSummary.lastMessage?.createdAt ?? chatSummary.createdAt;
    final formattedTime = formatters.formatRelativeTime(timestamp, context.l10n);

    final display = _buildTileDisplay(
      context: context,
      chatSummary: chatSummary,
      myPubkey: myPubkey,
      welcomerName: welcomerName,
      welcomerPicture: welcomerSnapshot.data?.picture,
      formattedTime: formattedTime,
      searchSnippet: searchSnippet,
    );

    void showContextMenu() {
      final renderBox = itemKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null || !renderBox.hasSize) return;

      final l10n = context.l10n;
      final isPinned = chatSummary.pinOrder != null;

      ChatListMenuController? menuController;

      List<ChatListAction> buildInitialActions() => [
        ChatListAction(
          id: isPinned ? 'unpin' : 'pin',
          label: isPinned ? l10n.unpin : l10n.pin,
          icon: isPinned ? WnIcons.unpin : WnIcons.pin,
          onTap: () => _runAction(
            action: () => setChatPinOrder(
              accountPubkey: myPubkey,
              mlsGroupId: chatSummary.mlsGroupId,
              pinOrder: isPinned ? null : 0,
            ),
            onSuccess: () => onChatListChanged?.call(),
            onError: (msg) => onError?.call(msg),
            logger: _logger,
            errorMessage: l10n.failedToPinChat,
            logMessage: 'Failed to update pin order',
          ),
        ),
        ChatListAction(
          id: isArchived ? 'unarchive' : 'archive',
          label: isArchived ? l10n.unarchive : l10n.archive,
          icon: isArchived ? WnIcons.unarchive : WnIcons.archive,
          onTap: () => _runAction(
            action: () => isArchived
                ? unarchiveChat(
                    accountPubkey: myPubkey,
                    mlsGroupId: chatSummary.mlsGroupId,
                  )
                : archiveChat(
                    accountPubkey: myPubkey,
                    mlsGroupId: chatSummary.mlsGroupId,
                  ),
            onSuccess: () => onChatListChanged?.call(),
            onError: (msg) => onError?.call(msg),
            logger: _logger,
            errorMessage: isArchived ? l10n.failedToUnarchiveChat : l10n.failedToArchiveChat,
            logMessage: 'Failed to archive/unarchive chat',
          ),
        ),
        if (leaveGroupState.canLeave)
          ChatListAction(
            id: 'leave_group',
            label: l10n.delete,
            icon: WnIcons.trashCan,
            isDestructive: true,
            autoDismiss: false,
            onTap: () async {
              menuController?.updateState(
                _buildLeaveConfirmationActions(
                  l10n: l10n,
                  context: context,
                  leaveGroup: leaveGroupState.leaveGroup,
                  onSuccess: () => onChatListChanged?.call(),
                  onError: (msg) => onError?.call(msg),
                  onBack: () => menuController?.updateState(buildInitialActions()),
                ),
                title: l10n.leaveGroup,
                middleContent: Text(
                  l10n.leaveGroupWarning,
                  style: context.typographyScaled.medium14.copyWith(
                    color: context.colors.backgroundContentPrimary,
                  ),
                ),
                onBack: () => menuController?.updateState(buildInitialActions()),
              );
            },
          ),
      ];

      menuController = ChatListMenu.show(
        context,
        childRenderBox: renderBox,
        child: WnChatListItem(
          title: display.title,
          subtitle: display.subtitle,
          timestamp: display.formattedTime,
          avatarUrl: display.pictureUrl,
          avatarName: display.avatarName,
          avatarColor: display.avatarColor,
          showPinned: display.showPinned,
          status: display.status,
          unreadCount: display.unreadCount,
          prefixSubtitle: display.prefixSubtitle,
          subtitleIcon: display.subtitleIcon,
        ),
        actions: buildInitialActions(),
      );
    }

    return WnChatListItem(
      key: itemKey,
      onTap: isPending
          ? () => Routes.pushToInvite(context, chatSummary.mlsGroupId)
          : () => Routes.goToChat(context, chatSummary.mlsGroupId),
      onLongPress: isPending ? null : showContextMenu,
      title: display.title,
      subtitle: display.subtitle,
      timestamp: display.formattedTime,
      avatarUrl: display.pictureUrl,
      avatarName: display.avatarName,
      avatarColor: display.avatarColor,
      showPinned: display.showPinned,
      status: display.status,
      unreadCount: display.unreadCount,
      prefixSubtitle: display.prefixSubtitle,
      subtitleIcon: display.subtitleIcon,
    );
  }
}
