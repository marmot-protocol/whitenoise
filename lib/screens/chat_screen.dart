import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:scroll_to_index/scroll_to_index.dart'
    show AutoScrollController, AutoScrollPosition, AutoScrollTag;
import 'package:whitenoise/hooks/use_active_chat.dart';
import 'package:whitenoise/hooks/use_block_actions.dart';
import 'package:whitenoise/hooks/use_blocked_pubkeys.dart';
import 'package:whitenoise/hooks/use_chat_archive.dart';
import 'package:whitenoise/hooks/use_chat_input.dart';
import 'package:whitenoise/hooks/use_chat_messages.dart' show ChatMessageQuoteData, useChatMessages;
import 'package:whitenoise/hooks/use_chat_scroll.dart';
import 'package:whitenoise/hooks/use_chat_summary.dart';
import 'package:whitenoise/hooks/use_group_members.dart';
import 'package:whitenoise/hooks/use_media_upload.dart';
import 'package:whitenoise/hooks/use_message_search.dart';
import 'package:whitenoise/hooks/use_scroll_to_message.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/providers/account_pubkey_provider.dart';
import 'package:whitenoise/providers/active_chat_provider.dart';
import 'package:whitenoise/providers/debug_view_provider.dart';
import 'package:whitenoise/providers/message_debug_log_provider.dart';
import 'package:whitenoise/providers/notification_provider.dart';
import 'package:whitenoise/providers/offline_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/screens/message_actions_screen.dart';
import 'package:whitenoise/services/message_service.dart';
import 'package:whitenoise/src/rust/api/groups.dart' show GroupType;
import 'package:whitenoise/src/rust/api/media_files.dart';
import 'package:whitenoise/src/rust/api/messages.dart' show ChatMessage, DeliveryStatus_Failed;
import 'package:whitenoise/src/rust/api/metadata.dart' show FlutterMetadata;
import 'package:whitenoise/src/rust/api/users.dart' as users_api;
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/utils/avatar_color.dart';
import 'package:whitenoise/utils/bubble_grouping.dart';
import 'package:whitenoise/utils/chat_summary_display.dart';
import 'package:whitenoise/utils/encoding.dart' show hexFromNpub, npubFromHex;
import 'package:whitenoise/utils/mention_query.dart';
import 'package:whitenoise/utils/mention_text_editing_controller.dart';
import 'package:whitenoise/utils/metadata.dart';
import 'package:whitenoise/utils/scroll_duration.dart';
import 'package:whitenoise/utils/search_context.dart';
import 'package:whitenoise/widgets/chat_media_upload_preview.dart';
import 'package:whitenoise/widgets/chat_message_bubble.dart';
import 'package:whitenoise/widgets/chat_message_quote.dart';
import 'package:whitenoise/widgets/chat_scroll_down_button.dart';
import 'package:whitenoise/widgets/offline_system_notice.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_chat_message_input.dart';
import 'package:whitenoise/widgets/wn_icon.dart';
import 'package:whitenoise/widgets/wn_icon_button.dart';
import 'package:whitenoise/widgets/wn_scroll_edge_effect.dart';
import 'package:whitenoise/widgets/wn_search_field.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_chat_header.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart';
import 'package:whitenoise/widgets/wn_user_item.dart';

final _logger = Logger('ChatScreen');

const _slateHeight = 80.0;
const _searchBarHeight = 80.0;
const _searchNavigationHeight = 60.0;
const _mentionSuggestionLimit = 5;

class _MentionMember {
  const _MentionMember({
    required this.pubkey,
    required this.npub,
    required this.displayName,
    this.pictureUrl,
  });

  final String pubkey;
  final String npub;
  final String displayName;
  final String? pictureUrl;
}

Future<List<_MentionMember>> _loadMentionMembers({
  required List<String> pubkeys,
  required String currentUserPubkey,
}) async {
  final mentionablePubkeys = {
    ...pubkeys,
  }.where((pubkey) => pubkey != currentUserPubkey).toList();
  final members = await Future.wait(mentionablePubkeys.map(_loadMentionMember));
  return members.nonNulls.toList();
}

Future<_MentionMember?> _loadMentionMember(String pubkey) async {
  final npub = npubFromHex(pubkey);
  if (npub == null) return null;
  FlutterMetadata? metadata;
  try {
    metadata = await users_api.userMetadata(pubkey: pubkey, blockingDataSync: false);
  } catch (_) {
    metadata = null;
  }
  return _MentionMember(
    pubkey: pubkey,
    npub: npub,
    displayName: presentName(metadata) ?? pubkey.substring(0, 8),
    pictureUrl: metadata?.picture,
  );
}

List<_MentionMember> _filterMentionMembers(List<_MentionMember> members, String query) {
  final normalizedQuery = query.toLowerCase();
  return members
      .where((member) {
        if (normalizedQuery.isEmpty) return true;
        return member.displayName.toLowerCase().contains(normalizedQuery) ||
            member.npub.toLowerCase().contains(normalizedQuery) ||
            member.pubkey.toLowerCase().contains(normalizedQuery);
      })
      .take(_mentionSuggestionLimit)
      .toList();
}

String _mentionMemberPubkeyKey(List<String> pubkeys) {
  if (pubkeys.isEmpty) return '';
  return (pubkeys.toSet().toList()..sort()).join('');
}

void _scrollToMatch(
  AutoScrollController controller,
  List<SearchDisplayItem>? items,
  int matchIndex,
) {
  if (items == null) return;
  for (var i = 0; i < items.length; i++) {
    if (items[i].isMatch && items[i].matchIndex == matchIndex) {
      controller.scrollToIndex(
        i,
        preferPosition: AutoScrollPosition.middle,
        duration: scrollDuration(controller, i),
      );
      return;
    }
  }
}

class ChatScreen extends HookConsumerWidget {
  final String groupId;

  const ChatScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final typography = context.typographyScaled;
    final pubkey = ref.watch(accountPubkeyProvider);
    final isOffline = ref.watch(offlineProvider).value ?? false;
    final debugLog = ref.read(messageDebugLogProvider.notifier);
    final blockActionsRefreshKey = useState(0);
    final blockedPubkeysState = useBlockedPubkeys(pubkey);
    final hiddenPubkeys = blockedPubkeysState.blockedPubkeys;
    final (
      :messageCount,
      :getMessage,
      :getReversedMessageIndex,
      :getMessageById,
      :isLoading,
      :isLoadingOlderMessages,
      :hasMoreMessages,
      :loadOlderMessages,
      :latestMessageId,
      :latestMessagePubkey,
      :getChatMessageQuote,
      :getAuthorMetadata,
    ) = useChatMessages(
      groupId,
      pubkey: pubkey,
      debugLog: debugLog,
      hiddenPubkeys: hiddenPubkeys,
    );
    final chatSummary = useChatSummary(context, pubkey, groupId);
    final header = chatSummaryDisplay(chatSummary.data, groupId);
    final isGroupChat = chatSummary.data?.groupType == GroupType.group;
    final groupMembers = useGroupMembers(
      accountPubkey: pubkey,
      groupId: groupId,
    );
    final mentionMemberPubkeys = isGroupChat ? groupMembers.members : const <String>[];
    final mentionMemberPubkeyKey = _mentionMemberPubkeyKey(mentionMemberPubkeys);
    final mentionMembersFuture = useMemoized(
      () => _loadMentionMembers(
        pubkeys: mentionMemberPubkeys,
        currentUserPubkey: pubkey,
      ),
      [mentionMemberPubkeyKey, pubkey],
    );
    final mentionMembersSnapshot = useFuture(
      mentionMembersFuture,
      initialData: const <_MentionMember>[],
    );
    final mentionMembers = isGroupChat
        ? mentionMembersSnapshot.data ?? const <_MentionMember>[]
        : const <_MentionMember>[];
    final mentionNamesByPubkey = useMemoized(
      () => {
        for (final member in mentionMembers) member.pubkey: member.displayName,
      },
      [mentionMembers],
    );
    String? resolveMentionDisplayName(String hexPubkey) =>
        mentionNamesByPubkey[hexPubkey] ?? presentName(getAuthorMetadata(hexPubkey));
    final resolveMentionDisplayNameRef = useRef(resolveMentionDisplayName);
    resolveMentionDisplayNameRef.value = resolveMentionDisplayName;
    final scrollToMessageResult = useScrollToMessage(
      getReversedMessageIndex: getReversedMessageIndex,
      loadOlderMessages: loadOlderMessages,
      hasMoreMessages: hasMoreMessages,
      messageCount: messageCount,
    );
    final scrollController = scrollToMessageResult.scrollController;
    final mediaUpload = useMediaUpload(pubkey: pubkey, groupId: groupId);
    final input = useChatInput(
      pubkey: pubkey,
      groupId: groupId,
      findMessage: getMessageById,
    );
    final messageService = useMemoized(
      () => MessageService(pubkey: pubkey, groupId: groupId),
      [pubkey, groupId],
    );
    useActiveChat(
      groupId: groupId,
      setActiveChat: ref.read(activeChatProvider.notifier).set,
      clearActiveChat: ref.read(activeChatProvider.notifier).clear,
      cancelGroupNotifications: ref.read(notificationServiceProvider).cancelForGroup,
    );

    final debugViewEnabled = ref.watch(debugViewProvider).value ?? false;

    final isRemovedFromGroup = chatSummary.data?.removedAt != null;
    final selfRemoved = chatSummary.data?.selfRemoved ?? false;
    final isRemovedNoticeCollapsed = useState(false);

    final peerPubkey = chatSummary.data?.dmPeerPubkey;
    final blockState = useBlockActions(
      accountPubkey: pubkey,
      userPubkey: peerPubkey,
      refreshKey: blockActionsRefreshKey.value,
    );
    final isBlocked = peerPubkey != null ? blockState.isBlocked : false;
    final isBlockedNoticeCollapsed = useState(false);
    final archiveState = useChatArchive(pubkey, groupId);

    final noticeMessage = useState<String?>(null);
    final isSearchActive = useState(false);
    final searchQuery = useState('');
    final searchController = useTextEditingController();
    final inputAreaHeight = useState(0.0);

    useEffect(() {
      if (isRemovedFromGroup) inputAreaHeight.value = 0;
      return null;
    }, [isRemovedFromGroup]);

    final displayNameResolver = useMemoized<String? Function(String)>(
      () => (npub) {
        final hex = hexFromNpub(npub);
        if (hex == null) return null;
        return resolveMentionDisplayNameRef.value(hex);
      },
      const [],
    );
    useEffect(() {
      input.controller.displayNameForNpub = displayNameResolver;
      return null;
    }, [input.controller, displayNameResolver]);

    final search = useMessageSearch(
      pubkey: pubkey,
      groupId: groupId,
      query: isSearchActive.value ? searchQuery.value : '',
      hiddenPubkeys: hiddenPubkeys,
    );

    void showNotice(String message) {
      noticeMessage.value = message;
    }

    void dismissNotice() {
      noticeMessage.value = null;
    }

    Future<void> handleUnblock() async {
      if (!blockState.isBlocked) return;
      try {
        await blockState.toggleBlock();
        if (!context.mounted) return;
        blockActionsRefreshKey.value++;
        blockedPubkeysState.refresh();
      } catch (_) {
        if (context.mounted) showNotice(context.l10n.failedToUnblockUser);
      }
    }

    Future<void> handleArchive() async {
      final currentIsArchived = archiveState.isArchived;
      try {
        await archiveState.toggle();
      } catch (_) {
        if (context.mounted) {
          showNotice(
            currentIsArchived
                ? context.l10n.failedToUnarchiveChat
                : context.l10n.failedToArchiveChat,
          );
        }
      }
    }

    void openSearch() {
      isSearchActive.value = true;
    }

    void closeSearch() {
      isSearchActive.value = false;
      searchQuery.value = '';
      searchController.clear();
    }

    String? getMessageIdByIndex(int reversedIndex) {
      if (reversedIndex < 0 || reversedIndex >= messageCount) return null;
      return getMessage(reversedIndex).id;
    }

    final chatScroll = useChatScroll(
      scrollController: scrollController,
      focusNode: input.focusNode,
      latestMessageId: latestMessageId,
      latestMessagePubkey: latestMessagePubkey,
      accountPubkey: pubkey,
      groupId: groupId,
      messageCount: messageCount,
      getMessageId: getMessageIdByIndex,
      getReversedIndex: getReversedMessageIndex,
      hasMoreMessages: hasMoreMessages,
      loadOlderMessages: loadOlderMessages,
    );

    Future<void> sendMessage(
      String message,
      ChatMessage? replyingTo,
      List<MediaFile> mediaFiles,
    ) async {
      debugLog.logStarted(
        groupId: groupId,
        contentLen: message.length,
        mediaCount: mediaFiles.length,
        replyToId: replyingTo?.id,
      );
      try {
        await messageService.sendMessage(
          content: message,
          replyToMessageId: replyingTo?.id,
          replyToMessagePubkey: replyingTo?.pubkey,
          replyToMessageKind: replyingTo?.kind,
          mediaFiles: mediaFiles,
        );
        debugLog.logOk(groupId: groupId, resultId: '');
        mediaUpload.clearAll();
      } catch (e, st) {
        debugLog.logFailed(groupId: groupId, error: e, stackTrace: st);
        rethrow;
      }
    }

    Future<void> toggleReaction(ChatMessage message, String emoji) {
      return messageService.toggleReaction(message: message, emoji: emoji);
    }

    Future<void> showMessageMenu(ChatMessage message) async {
      FocusScope.of(context).unfocus();
      final authorMetadata = getAuthorMetadata(message.pubkey);
      final senderName = message.pubkey == pubkey
          ? context.l10n.you
          : presentName(authorMetadata) ?? context.l10n.unknownUser;
      final senderPictureUrl = authorMetadata?.picture;
      await MessageActionsScreen.show(
        context,
        message: message,
        pubkey: pubkey,
        isOffline: isOffline,
        onDelete: () => messageService.deleteTextMessage(
          messageId: message.id,
          messagePubkey: message.pubkey,
        ),
        onAddReaction: (emoji) => messageService.sendReaction(
          messageId: message.id,
          messagePubkey: message.pubkey,
          messageKind: message.kind,
          emoji: emoji,
        ),
        onRemoveReaction: (reactionId) => messageService.deleteReaction(
          reactionId: reactionId,
          reactionPubkey: pubkey,
        ),
        onReply: (msg) => input.setReplyingTo(msg),
        senderName: senderName,
        getChatMessageQuote: getChatMessageQuote,
        senderPictureUrl: senderPictureUrl,
        isGroupChat: isGroupChat,
        mentionDisplayName: resolveMentionDisplayName,
      );
      if (context.mounted) FocusManager.instance.primaryFocus?.unfocus();
    }

    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final searchBarHeight = isSearchActive.value ? _searchBarHeight.h : 0.0;
    final searchNavHeight = searchQuery.value.isNotEmpty ? _searchNavigationHeight.h : 0.0;
    final slateTopPadding = safeAreaTop + _slateHeight.h + searchBarHeight + searchNavHeight;
    final listBottomPadding = inputAreaHeight.value + safeAreaBottom + 12.h;

    final searchDisplayItems = isSearchActive.value && searchQuery.value.isNotEmpty
        ? search.displayItems
        : null;
    final isSearchMode = searchDisplayItems != null && searchDisplayItems.isNotEmpty;
    final matchCount = isSearchMode ? search.results.length : 0;
    final displayCount = searchDisplayItems?.length ?? messageCount;
    final currentMatchIndex = useState(0);

    useEffect(() {
      currentMatchIndex.value = 0;
      return null;
    }, [searchQuery.value]);

    Widget messageListContent;
    if (isLoading || blockedPubkeysState.isLoading) {
      messageListContent = Center(
        child: CircularProgressIndicator(
          color: colors.backgroundContentPrimary,
        ),
      );
    } else if (displayCount == 0 && !isSearchActive.value) {
      messageListContent = Center(
        child: Text(
          context.l10n.noMessagesYet,
          style: typography.medium14.copyWith(
            color: colors.backgroundContentTertiary,
          ),
        ),
      );
    } else {
      messageListContent = Opacity(
        opacity: chatScroll.isInitialPositionReady ? 1.0 : 0.0,
        child: ListView.builder(
          controller: scrollController,
          reverse: !isSearchMode,
          padding: EdgeInsets.fromLTRB(
            10.w,
            slateTopPadding + 8.h,
            10.w,
            listBottomPadding,
          ),
          itemCount: displayCount,
          findChildIndexCallback: !isSearchMode
              ? (key) {
                  if (key is ValueKey<String>) {
                    return getReversedMessageIndex(key.value);
                  }
                  return null;
                }
              : null,
          itemBuilder: (context, index) {
            final displayItem = searchDisplayItems?[index];

            if (displayItem != null && displayItem.isSeparator) {
              return Padding(
                key: Key('search_separator_$index'),
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: Center(
                  child: Container(
                    width: 40.w,
                    height: 2.h,
                    decoration: BoxDecoration(
                      color: colors.borderPrimary,
                      borderRadius: BorderRadius.circular(1.r),
                    ),
                  ),
                ),
              );
            }

            final message = displayItem?.message ?? getMessage(index);
            final isOwnMessage = message.pubkey == pubkey;
            final replyPreview = message.isReply ? getChatMessageQuote(message.replyToId) : null;

            final authorMetadata = getAuthorMetadata(message.pubkey);
            final senderName = isOwnMessage
                ? context.l10n.you
                : presentName(authorMetadata) ?? context.l10n.unknownUser;
            final senderPictureUrl = authorMetadata?.picture;

            final bool showAvatar;
            final bool showTail;
            if (isSearchMode) {
              final nextItem = index + 1 < displayCount ? searchDisplayItems[index + 1] : null;
              final nextMessage = nextItem != null && !nextItem.isSeparator
                  ? nextItem.message
                  : null;
              showAvatar = shouldShowAvatar(
                current: message,
                next: nextMessage,
                isOwnMessage: isOwnMessage,
                isGroupChat: isGroupChat,
              );
              showTail = shouldShowTail(current: message, next: nextMessage);
            } else {
              final nextMessage = index > 0 ? getMessage(index - 1) : null;
              showAvatar = shouldShowAvatar(
                current: message,
                next: nextMessage,
                isOwnMessage: isOwnMessage,
                isGroupChat: isGroupChat,
              );
              showTail = shouldShowTail(current: message, next: nextMessage);
            }

            final isMatchItem = displayItem != null && displayItem.isMatch;

            Widget bubble = ChatMessageBubble(
              message: message,
              highlightSpans: displayItem?.highlightSpans,
              isOwnMessage: isOwnMessage,
              currentUserPubkey: pubkey,
              replyPreview: replyPreview,
              senderName: senderName,
              senderPictureUrl: senderPictureUrl,
              showAvatar: showAvatar,
              showTail: showTail,
              isGroupChat: isGroupChat,
              onLongPress: isSearchMode ? null : () => showMessageMenu(message),
              onReaction: isSearchMode ? null : (emoji) => toggleReaction(message, emoji),
              onReplyTap: !isSearchMode && replyPreview != null && !replyPreview.isNotFound
                  ? () => scrollToMessageResult.scrollToMessage(
                      replyPreview.messageId,
                    )
                  : null,
              onHorizontalDragEnd: isSearchMode ? null : () => input.setReplyingTo(message),
              mentionDisplayName: resolveMentionDisplayName,
              groupId: isGroupChat ? groupId : null,
              onRetry:
                  !isSearchMode && isOwnMessage && message.deliveryStatus is DeliveryStatus_Failed
                  ? () async {
                      final failedMsg = context.l10n.failedToSendMessage;
                      try {
                        await messageService.retryMessage(eventId: message.id);
                      } catch (_) {
                        if (context.mounted) showNotice(failedMsg);
                      }
                    }
                  : null,
            );

            if (isSearchMode) {
              bubble = GestureDetector(
                key: isMatchItem ? Key('search_match_${displayItem.matchIndex}') : null,
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  final messagePosition = displayItem?.position;
                  isSearchActive.value = false;
                  searchQuery.value = '';
                  searchController.clear();
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    scrollToMessageResult.scrollToMessage(
                      message.id,
                      position: messagePosition,
                    );
                  });
                },
                child: Opacity(
                  opacity: isMatchItem ? 1.0 : 0.5,
                  child: IgnorePointer(child: bubble),
                ),
              );
            }

            return AutoScrollTag(
              key: ValueKey(message.id),
              controller: scrollController,
              index: index,
              child: bubble,
            );
          },
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Routes.goToChatList(context);
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: colors.backgroundPrimary,
          body: Stack(
            children: [
              messageListContent,
              WnScrollEdgeEffect.canvasTop(
                color: colors.backgroundPrimary,
                height: slateTopPadding,
              ),
              WnScrollEdgeEffect.canvasBottom(
                color: colors.backgroundPrimary,
                height: inputAreaHeight.value + safeAreaBottom + 48.h,
              ),
              SafeArea(
                bottom: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    WnSlate(
                      header: WnSlateChatHeader(
                        displayName:
                            header.displayName ??
                            (isGroupChat ? context.l10n.unknownGroup : context.l10n.unknownUser),
                        avatarColor: header.color,
                        pictureUrl: header.pictureUrl,
                        onBack: isSearchActive.value
                            ? closeSearch
                            : () => Routes.goToChatList(context),
                        onAvatarTap: () async {
                          if (isGroupChat) {
                            final result = await Routes.pushToGroupInfo(
                              context,
                              groupId,
                            );
                            if (!context.mounted) return;
                            if (result == true) openSearch();
                          } else {
                            final result = await Routes.pushToChatInfo(
                              context,
                              groupId,
                            );
                            if (!context.mounted) return;
                            blockActionsRefreshKey.value++;
                            blockedPubkeysState.refresh();
                            if (result == true) openSearch();
                          }
                        },
                        trailingWidget: debugViewEnabled
                            ? WnIconButton(
                                key: const Key('chat_raw_debug_button'),
                                icon: WnIcons.developerSettings,
                                onPressed: () => Routes.pushToChatRawDebug(context, groupId),
                              )
                            : null,
                      ),
                      systemNotice: isOffline
                          ? const OfflineSystemNotice()
                          : (noticeMessage.value != null
                                ? WnSystemNotice(
                                    key: ValueKey(noticeMessage.value),
                                    title: noticeMessage.value!,
                                    type: WnSystemNoticeType.error,
                                    onDismiss: dismissNotice,
                                  )
                                : null),
                      footer: isRemovedFromGroup
                          ? WnSystemNotice(
                              key: const Key('removed_from_group_notice'),
                              title: selfRemoved
                                  ? context.l10n.youLeftThisGroup
                                  : context.l10n.removedFromGroup,
                              description: Text(
                                context.l10n.removedFromGroupDescription,
                                style: typography.medium14.copyWith(
                                  color: colors.backgroundContentSecondary,
                                ),
                              ),
                              type: WnSystemNoticeType.neutral,
                              variant: isRemovedNoticeCollapsed.value
                                  ? WnSystemNoticeVariant.collapsed
                                  : WnSystemNoticeVariant.expanded,
                              animateEntrance: false,
                              onToggle: () =>
                                  isRemovedNoticeCollapsed.value = !isRemovedNoticeCollapsed.value,
                              primaryAction: WnButton(
                                key: const Key('removed_notice_archive_button'),
                                text: archiveState.isArchived
                                    ? context.l10n.unarchive
                                    : context.l10n.archive,
                                type: WnButtonType.outline,
                                size: WnButtonSize.medium,
                                loading: archiveState.isActionLoading,
                                disabled: archiveState.isLoading,
                                trailingIcon: archiveState.isArchived
                                    ? WnIcons.unarchive
                                    : WnIcons.archive,
                                onPressed: handleArchive,
                              ),
                            )
                          : isBlocked
                          ? WnSystemNotice(
                              key: const Key('user_blocked_notice'),
                              title: context.l10n.userIsBlocked,
                              description: Text(
                                context.l10n.userIsBlockedDescription,
                                style: typography.medium14.copyWith(
                                  color: colors.backgroundContentSecondary,
                                ),
                              ),
                              type: WnSystemNoticeType.neutral,
                              variant: isBlockedNoticeCollapsed.value
                                  ? WnSystemNoticeVariant.collapsed
                                  : WnSystemNoticeVariant.expanded,
                              animateEntrance: false,
                              onToggle: () =>
                                  isBlockedNoticeCollapsed.value = !isBlockedNoticeCollapsed.value,
                              secondaryAction: WnButton(
                                key: const Key('blocked_notice_unblock_button'),
                                text: context.l10n.unblock,
                                type: WnButtonType.outline,
                                size: WnButtonSize.medium,
                                loading: blockState.isActionLoading,
                                trailingIcon: WnIcons.userCheck,
                                onPressed: handleUnblock,
                              ),
                              primaryAction: WnButton(
                                key: const Key('blocked_notice_archive_button'),
                                text: archiveState.isArchived
                                    ? context.l10n.unarchive
                                    : context.l10n.archive,
                                type: WnButtonType.overlay,
                                size: WnButtonSize.medium,
                                loading: archiveState.isActionLoading,
                                disabled: archiveState.isLoading,
                                trailingIcon: archiveState.isArchived
                                    ? WnIcons.unarchive
                                    : WnIcons.archive,
                                onPressed: handleArchive,
                              ),
                            )
                          : null,
                    ),
                    if (isSearchActive.value) ...[
                      Padding(
                        key: const Key('chat_search_bar'),
                        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
                        child: WnSearchField(
                          key: const Key('chat_search_field'),
                          placeholder: context.l10n.search,
                          controller: searchController,
                          autofocus: true,
                          onChanged: (value) => searchQuery.value = value,
                          isLoading: search.isSearching,
                        ),
                      ),
                      if (searchQuery.value.isNotEmpty)
                        Padding(
                          key: const Key('chat_search_navigation'),
                          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              WnIconButton(
                                key: const Key('chat_search_prev_button'),
                                onPressed: matchCount == 0
                                    ? null
                                    : () {
                                        final next =
                                            (currentMatchIndex.value - 1 + matchCount) % matchCount;
                                        currentMatchIndex.value = next;
                                        _scrollToMatch(
                                          scrollController,
                                          searchDisplayItems,
                                          next,
                                        );
                                      },
                                icon: WnIcons.chevronUp,
                              ),
                              Text(
                                matchCount > 0
                                    ? context.l10n.chatSearchMatchCount(
                                        currentMatchIndex.value + 1,
                                        matchCount,
                                      )
                                    : search.isSearching
                                    ? ''
                                    : context.l10n.noResults,
                                key: const Key('chat_search_match_count'),
                                style: typography.medium14.copyWith(
                                  color: colors.backgroundContentSecondary,
                                ),
                              ),
                              WnIconButton(
                                key: const Key('chat_search_next_button'),
                                onPressed: matchCount == 0
                                    ? null
                                    : () {
                                        final next = (currentMatchIndex.value + 1) % matchCount;
                                        currentMatchIndex.value = next;
                                        _scrollToMatch(
                                          scrollController,
                                          searchDisplayItems,
                                          next,
                                        );
                                      },
                                icon: WnIcons.chevronDown,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              if (!isRemovedFromGroup && !isSearchActive.value)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    top: false,
                    child: _SizeReporter(
                      onSizeChanged: (size) => inputAreaHeight.value = size.height,
                      child: _ChatInput(
                        input: input,
                        mediaUpload: mediaUpload,
                        currentUserPubkey: pubkey,
                        isGroupChat: isGroupChat,
                        mentionMembers: mentionMembers,
                        onSend: sendMessage,
                        onError: showNotice,
                        getChatMessageQuote: getChatMessageQuote,
                        mentionDisplayName: resolveMentionDisplayName,
                        actionsEnabled: !isOffline,
                        isOffline: isOffline,
                      ),
                    ),
                  ),
                ),
              WnScrollEdgeEffect.canvasBottom(
                color: colors.backgroundPrimary,
                height: safeAreaBottom,
              ),
              if (isLoadingOlderMessages)
                Positioned(
                  key: const Key('loading_older_messages_indicator'),
                  top: slateTopPadding + 8.h,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: colors.backgroundSecondary,
                        borderRadius: BorderRadius.circular(999.r),
                      ),
                      child: SizedBox(
                        width: 16.w,
                        height: 16.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          strokeCap: StrokeCap.round,
                          color: colors.backgroundContentSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              if (chatScroll.isScrollDownButtonVisible)
                Positioned(
                  bottom: inputAreaHeight.value + safeAreaBottom + 8.h,
                  right: 16.w,
                  child: ChatScrollDownButton(
                    show: true,
                    onTap: chatScroll.scrollToBottom,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatInput extends HookWidget {
  const _ChatInput({
    required this.input,
    required this.mediaUpload,
    required this.currentUserPubkey,
    required this.isGroupChat,
    required this.mentionMembers,
    required this.onSend,
    required this.onError,
    required this.getChatMessageQuote,
    required this.mentionDisplayName,
    this.actionsEnabled = true,
    this.isOffline = false,
  });

  final ChatInputState input;
  final MediaUploadState mediaUpload;
  final String currentUserPubkey;
  final bool isGroupChat;
  final List<_MentionMember> mentionMembers;
  final bool actionsEnabled;
  final bool isOffline;
  final Future<void> Function(
    String message,
    ChatMessage? replyingTo,
    List<MediaFile> mediaFiles,
  )
  onSend;
  final void Function(String message) onError;
  final ChatMessageQuoteData? Function(String? replyId) getChatMessageQuote;
  final String? Function(String hexPubkey) mentionDisplayName;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typographyScaled;
    final hasMedia = mediaUpload.items.isNotEmpty;
    final showSend = input.hasContent || hasMedia;
    final textValue = useListenableSelector(input.controller, () => input.controller.value);
    final mentionQuery = input.controller.isCursorInsideMention
        ? null
        : activeMentionQuery(textValue);
    final mentionSuggestions = mentionQuery != null && actionsEnabled
        ? _filterMentionMembers(mentionMembers, mentionQuery.query)
        : const <_MentionMember>[];

    useEffect(() {
      input.controller.setMentionTargets([
        for (final member in mentionMembers)
          MentionTextTarget(
            uri: '@${member.npub}',
            displayText: '@${member.displayName}',
          ),
      ]);
      return null;
    }, [input.controller, mentionMembers]);

    void insertMention(_MentionMember member) {
      final query = mentionQuery;
      if (query == null) return;
      input.controller.insertMention(
        start: query.start,
        end: query.end,
        displayName: member.displayName,
        uri: '@${member.npub}',
      );
      input.focusNode.requestFocus();
    }

    Future<void> handleSend() async {
      final text = input.controller.messageText.trim();
      final hasMedia = mediaUpload.canSend;
      _logger.info(
        'handleSend textLen=${text.length} hasMedia=$hasMedia replyTo=${input.replyingTo?.id}',
      );
      if (text.isEmpty && !hasMedia) {
        _logger.info(
          'handleSend early return: empty text and no sendable media',
        );
        return;
      }
      try {
        await onSend(text, input.replyingTo, mediaUpload.uploadedFiles);
        input.clear();
        _logger.info('handleSend completed, input cleared');
      } catch (e, st) {
        _logger.severe('handleSend FAILED', e, st);
        if (context.mounted) {
          onError(context.l10n.failedToSendMessage);
        }
      }
    }

    final mentionMenu = mentionSuggestions.isNotEmpty
        ? _MentionSuggestionsMenu(
            members: mentionSuggestions,
            onSelected: insertMention,
          )
        : null;

    Widget? buildAttachmentArea() {
      final hasQuote = input.replyingTo != null;
      // When media is present and the picker is showing, the picker rides
      // along inside the attachment area so it appears BELOW the images
      // instead of pushing them down from above.
      final menuRidesAlong = hasMedia && mentionMenu != null;
      if (!hasQuote && !hasMedia && !menuRidesAlong) return null;

      final quoteData = hasQuote ? getChatMessageQuote(input.replyingTo!.id) : null;
      final shouldRenderQuote = hasQuote && quoteData != null && !quoteData.isNotFound;
      final replyAuthorColor = isGroupChat && shouldRenderQuote
          ? AvatarColor.fromPubkey(
              quoteData.authorPubkey,
            ).toColorSet(context.colors).content
          : null;

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (shouldRenderQuote)
            ChatMessageQuote(
              data: quoteData,
              currentUserPubkey: currentUserPubkey,
              mentionDisplayName: mentionDisplayName,
              onCancel: input.cancelReply,
              authorColor: replyAuthorColor,
            ),
          if (shouldRenderQuote && hasMedia) SizedBox(height: 8.h),
          if (hasMedia)
            ChatMediaUploadPreview(
              items: mediaUpload.items,
              onRemove: mediaUpload.removeItem,
            ),
          if (menuRidesAlong) ...[
            SizedBox(height: 8.h),
            mentionMenu,
          ],
        ],
      );
    }

    final inputStyle = typography.medium14.copyWith(
      color: colors.backgroundContentPrimary,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (mentionMenu != null && !hasMedia)
            Padding(
              padding: EdgeInsets.only(bottom: 6.h),
              child: mentionMenu,
            ),
          WnChatMessageInput(
            key: const ValueKey('chat_message_input'),
            isFocused: input.hasFocus,
            attachmentArea: buildAttachmentArea(),
            controller: input.controller,
            inputStyle: inputStyle,
            actionsEnabled: actionsEnabled,
            onAddTap: () {
              input.focusNode.unfocus();
              mediaUpload.pickMedia();
            },
            inputField: TextField(
              controller: input.controller,
              focusNode: input.focusNode,
              maxLines: 4,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              cursorColor: colors.backgroundContentPrimary,
              style: inputStyle,
              decoration: InputDecoration(
                hintText: context.l10n.messagePlaceholder,
                hintStyle: typography.medium14.copyWith(
                  color: colors.backgroundContentSecondary,
                ),
                filled: true,
                fillColor: Colors.transparent,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8.w,
                  vertical: 8.h,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
            onSend: showSend && !isOffline ? handleSend : null,
          ),
        ],
      ),
    );
  }
}

class _MentionSuggestionsMenu extends StatelessWidget {
  const _MentionSuggestionsMenu({
    required this.members,
    required this.onSelected,
  });

  final List<_MentionMember> members;
  final void Function(_MentionMember member) onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      key: const Key('mention_suggestions_menu'),
      constraints: BoxConstraints(maxHeight: 220.h),
      decoration: BoxDecoration(
        color: colors.backgroundPrimary,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: colors.borderSecondary),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.symmetric(vertical: 6.h),
        itemCount: members.length,
        separatorBuilder: (_, _) => SizedBox(height: 2.h),
        itemBuilder: (context, index) {
          final member = members[index];
          return GestureDetector(
            key: Key('mention_suggestion_${member.pubkey}'),
            behavior: HitTestBehavior.opaque,
            onTap: () => onSelected(member),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              child: WnUserItem(
                displayName: member.displayName,
                label: member.npub,
                pictureUrl: member.pictureUrl,
                avatarColor: AvatarColor.fromPubkey(member.pubkey),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SizeReporter extends SingleChildRenderObjectWidget {
  final ValueChanged<Size> onSizeChanged;

  const _SizeReporter({required this.onSizeChanged, required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _SizeReporterRenderObject(onSizeChanged);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _SizeReporterRenderObject renderObject,
  ) {
    renderObject.onSizeChanged = onSizeChanged;
  }
}

class _SizeReporterRenderObject extends RenderProxyBox {
  _SizeReporterRenderObject(this.onSizeChanged);

  ValueChanged<Size> onSizeChanged;
  Size? _previousSize;

  @override
  void performLayout() {
    super.performLayout();
    if (size != _previousSize) {
      _previousSize = size;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onSizeChanged(size);
      });
    }
  }
}
