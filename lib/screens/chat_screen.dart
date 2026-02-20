import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:whitenoise/hooks/use_active_chat.dart';
import 'package:whitenoise/hooks/use_chat_input.dart';
import 'package:whitenoise/hooks/use_chat_messages.dart' show ChatMessageQuoteData, useChatMessages;
import 'package:whitenoise/hooks/use_chat_profile.dart';
import 'package:whitenoise/hooks/use_chat_scroll.dart';
import 'package:whitenoise/hooks/use_media_upload.dart';
import 'package:whitenoise/hooks/use_scroll_to_message.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/providers/account_pubkey_provider.dart';
import 'package:whitenoise/providers/active_chat_provider.dart';
import 'package:whitenoise/providers/notification_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/screens/message_actions_screen.dart';
import 'package:whitenoise/services/message_service.dart';
import 'package:whitenoise/src/rust/api/media_files.dart';
import 'package:whitenoise/src/rust/api/messages.dart' show ChatMessage;
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/utils/avatar_color.dart';
import 'package:whitenoise/utils/chat_messages_search.dart';
import 'package:whitenoise/utils/metadata.dart';
import 'package:whitenoise/widgets/chat_media_upload_preview.dart';
import 'package:whitenoise/widgets/chat_message_quote.dart';
import 'package:whitenoise/widgets/chat_scroll_down_button.dart';
import 'package:whitenoise/widgets/wn_chat_message_input.dart';
import 'package:whitenoise/widgets/wn_icon.dart';
import 'package:whitenoise/widgets/wn_message_bubble.dart';
import 'package:whitenoise/widgets/wn_scroll_edge_effect.dart';
import 'package:whitenoise/widgets/wn_search_field.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_chat_header.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart';

final _logger = Logger('ChatScreen');

const _slateHeight = 80.0;
const _searchBarHeight = 80.0;

class ChatScreen extends HookConsumerWidget {
  final String groupId;

  const ChatScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final typography = context.typographyScaled;
    final pubkey = ref.watch(accountPubkeyProvider);
    final (
      :messageCount,
      :getMessage,
      :getReversedMessageIndex,
      :getMessageById,
      :isLoading,
      :latestMessageId,
      :latestMessagePubkey,
      :getChatMessageQuote,
      :getAuthorMetadata,
    ) = useChatMessages(
      groupId,
    );
    final chatProfile = useChatProfile(context, pubkey, groupId);
    final scrollToMessageResult = useScrollToMessage(
      getReversedMessageIndex: getReversedMessageIndex,
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

    final noticeMessage = useState<String?>(null);
    final isSearchActive = useState(false);
    final searchQuery = useState('');
    final searchController = useTextEditingController();

    void showNotice(String message) {
      noticeMessage.value = message;
    }

    void dismissNotice() {
      noticeMessage.value = null;
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
    );

    Future<void> sendMessage(
      String message,
      ChatMessage? replyingTo,
      List<MediaFile> mediaFiles,
    ) async {
      await messageService.sendMessage(
        content: message,
        replyToMessageId: replyingTo?.id,
        replyToMessagePubkey: replyingTo?.pubkey,
        replyToMessageKind: replyingTo?.kind,
        mediaFiles: mediaFiles,
      );
      mediaUpload.clearAll();
    }

    Future<void> toggleReaction(ChatMessage message, String emoji) {
      return messageService.toggleReaction(message: message, emoji: emoji);
    }

    Future<void> showMessageMenu(ChatMessage message) async {
      FocusScope.of(context).unfocus();
      await MessageActionsScreen.show(
        context,
        message: message,
        pubkey: pubkey,
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
      );
      if (context.mounted) FocusManager.instance.primaryFocus?.unfocus();
    }

    final safeAreaTop = MediaQuery.of(context).padding.top;
    final searchBarHeight = isSearchActive.value ? _searchBarHeight.h : 0.0;
    final slateTopPadding = safeAreaTop + _slateHeight.h + searchBarHeight;

    final allMessages = List.generate(messageCount, getMessage);
    final displayMessages = isSearchActive.value
        ? filterMessagesBySearch(allMessages, searchQuery.value)
        : null;
    final displayCount = displayMessages?.length ?? messageCount;
    final currentMatchIndex = useState(0);

    useEffect(() {
      currentMatchIndex.value = 0;
      return null;
    }, [searchQuery.value]);

    Widget messageListContent;
    if (isLoading) {
      messageListContent = Center(
        child: CircularProgressIndicator(color: colors.backgroundContentPrimary),
      );
    } else if (displayCount == 0 && !isSearchActive.value) {
      messageListContent = Center(
        child: Text(
          context.l10n.noMessagesYet,
          style: typography.medium14.copyWith(color: colors.backgroundContentTertiary),
        ),
      );
    } else {
      messageListContent = Opacity(
        opacity: chatScroll.isInitialPositionReady ? 1.0 : 0.0,
        child: ListView.builder(
          controller: scrollController,
          reverse: true,
          padding: EdgeInsets.only(top: slateTopPadding + 8.h, bottom: 12.h),
          itemCount: displayCount,
          findChildIndexCallback: displayMessages == null
              ? (key) {
                  if (key is ValueKey<String>) {
                    return getReversedMessageIndex(key.value);
                  }
                  return null;
                }
              : null,
          itemBuilder: (context, index) {
            final message = displayMessages != null ? displayMessages[index] : getMessage(index);
            final isOwnMessage = message.pubkey == pubkey;
            final replyPreview = message.isReply ? getChatMessageQuote(message.replyToId) : null;

            final authorMetadata = getAuthorMetadata(message.pubkey);
            final senderName = isOwnMessage
                ? context.l10n.you
                : presentName(authorMetadata) ?? context.l10n.unknownUser;
            final senderPictureUrl = authorMetadata?.picture;

            return AutoScrollTag(
              key: ValueKey(message.id),
              controller: scrollController,
              index: index,
              child: WnMessageBubble(
                message: message,
                isOwnMessage: isOwnMessage,
                currentUserPubkey: pubkey,
                onLongPress: () => showMessageMenu(message),
                onReaction: (emoji) => toggleReaction(message, emoji),
                replyPreview: replyPreview,
                onReplyTap: replyPreview != null && !replyPreview.isNotFound
                    ? () => scrollToMessageResult.scrollToMessage(replyPreview.messageId)
                    : null,
                senderName: senderName,
                senderPictureUrl: senderPictureUrl,
              ),
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
          body: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    messageListContent,
                    WnScrollEdgeEffect.canvasTop(
                      color: colors.backgroundPrimary,
                      height: slateTopPadding,
                    ),
                    WnScrollEdgeEffect.canvasBottom(
                      color: colors.backgroundPrimary,
                      height: 20.h,
                    ),
                    if (noticeMessage.value != null)
                      Positioned(
                        top: safeAreaTop,
                        left: 0,
                        right: 0,
                        child: WnSystemNotice(
                          key: ValueKey(noticeMessage.value),
                          title: noticeMessage.value!,
                          type: WnSystemNoticeType.error,
                          onDismiss: dismissNotice,
                        ),
                      ),
                    SafeArea(
                      bottom: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          WnSlate(
                            header: WnSlateChatHeader(
                              displayName: chatProfile.data?.displayName ?? '',
                              avatarColor: chatProfile.data?.color ?? AvatarColor.neutral,
                              pictureUrl: chatProfile.data?.pictureUrl,
                              onBack: isSearchActive.value
                                  ? closeSearch
                                  : () => Routes.goToChatList(context),
                              onAvatarTap: () async {
                                final otherPubkey = chatProfile.data?.otherMemberPubkey;
                                if (otherPubkey != null) {
                                  final result = await Routes.pushToChatInfo(context, otherPubkey);
                                  if (result == true) openSearch();
                                } else {
                                  Routes.pushToGroupInfo(context, groupId);
                                }
                              },
                            ),
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
                              ),
                            ),
                            if (searchQuery.value.isNotEmpty)
                              Padding(
                                key: const Key('chat_search_navigation'),
                                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      key: const Key('chat_search_prev_button'),
                                      onPressed: displayCount == 0
                                          ? null
                                          : () {
                                              final next =
                                                  (currentMatchIndex.value - 1 + displayCount) %
                                                  displayCount;
                                              currentMatchIndex.value = next;
                                              scrollController.scrollToIndex(
                                                displayCount - 1 - next,
                                                preferPosition: AutoScrollPosition.middle,
                                              );
                                            },
                                      icon: WnIcon(
                                        WnIcons.chevronUp,
                                        size: 18.sp,
                                        color: displayCount == 0
                                            ? colors.backgroundContentTertiary
                                            : colors.backgroundContentSecondary,
                                      ),
                                    ),
                                    Text(
                                      displayCount == 0
                                          ? context.l10n.noResults
                                          : context.l10n.chatSearchMatchCount(
                                              currentMatchIndex.value + 1,
                                              displayCount,
                                            ),
                                      key: const Key('chat_search_match_count'),
                                      style: typography.medium14.copyWith(
                                        color: colors.backgroundContentSecondary,
                                      ),
                                    ),
                                    IconButton(
                                      key: const Key('chat_search_next_button'),
                                      onPressed: displayCount == 0
                                          ? null
                                          : () {
                                              final next =
                                                  (currentMatchIndex.value + 1) % displayCount;
                                              currentMatchIndex.value = next;
                                              scrollController.scrollToIndex(
                                                displayCount - 1 - next,
                                                preferPosition: AutoScrollPosition.middle,
                                              );
                                            },
                                      icon: WnIcon(
                                        WnIcons.chevronDown,
                                        size: 18.sp,
                                        color: displayCount == 0
                                            ? colors.backgroundContentTertiary
                                            : colors.backgroundContentSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                    if (chatScroll.isScrollDownButtonVisible)
                      Positioned(
                        bottom: 8.h,
                        right: 16.w,
                        child: ChatScrollDownButton(
                          show: true,
                          onTap: chatScroll.scrollToBottom,
                        ),
                      ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: _ChatInput(
                  input: input,
                  mediaUpload: mediaUpload,
                  currentUserPubkey: pubkey,
                  onSend: sendMessage,
                  onError: showNotice,
                  getChatMessageQuote: getChatMessageQuote,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatInput extends StatelessWidget {
  const _ChatInput({
    required this.input,
    required this.mediaUpload,
    required this.currentUserPubkey,
    required this.onSend,
    required this.onError,
    required this.getChatMessageQuote,
  });

  final ChatInputState input;
  final MediaUploadState mediaUpload;
  final String currentUserPubkey;
  final Future<void> Function(
    String message,
    ChatMessage? replyingTo,
    List<MediaFile> mediaFiles,
  )
  onSend;
  final void Function(String message) onError;
  final ChatMessageQuoteData? Function(String? replyId) getChatMessageQuote;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typographyScaled;
    final hasMedia = mediaUpload.items.isNotEmpty;
    final showSend = input.hasContent || hasMedia;
    final sendEnabled = input.hasContent || (hasMedia && mediaUpload.canSend);

    Future<void> handleSend() async {
      final text = input.controller.text.trim();
      if (text.isEmpty && !mediaUpload.canSend) return;
      try {
        await onSend(text, input.replyingTo, mediaUpload.uploadedFiles);
        input.clear();
      } catch (e, st) {
        _logger.severe('Failed to send message', e, st);
        if (context.mounted) {
          onError(context.l10n.failedToSendMessage);
        }
      }
    }

    Widget? buildAttachmentArea() {
      final hasQuote = input.replyingTo != null;
      if (!hasQuote && !hasMedia) return null;

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasQuote)
            ChatMessageQuote(
              data: getChatMessageQuote(input.replyingTo!.id)!,
              currentUserPubkey: currentUserPubkey,
              onCancel: input.cancelReply,
            ),
          if (hasQuote && hasMedia) SizedBox(height: 8.h),
          if (hasMedia)
            ChatMediaUploadPreview(
              items: mediaUpload.items,
              onRemove: mediaUpload.removeItem,
            ),
        ],
      );
    }

    return Container(
      padding: EdgeInsets.only(left: 12.w, right: 12.w, top: 2.h, bottom: 24.h),
      color: colors.backgroundPrimary,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: WnChatMessageInput(
              isFocused: input.hasFocus,
              attachmentArea: buildAttachmentArea(),
              leadingAction: GestureDetector(
                key: const Key('attach_button'),
                onTap: () {
                  input.focusNode.unfocus();
                  mediaUpload.pickImages();
                },
                child: WnIcon(
                  WnIcons.addLarge,
                  color: colors.backgroundContentSecondary,
                  size: 20.sp,
                ),
              ),
              inputField: TextField(
                controller: input.controller,
                focusNode: input.focusNode,
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                style: typography.medium14.copyWith(
                  color: colors.backgroundContentPrimary,
                ),
                decoration: InputDecoration(
                  hintText: context.l10n.messagePlaceholder,
                  hintStyle: typography.medium14.copyWith(
                    color: colors.backgroundContentTertiary,
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 20.h,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
              trailingAction: showSend
                  ? GestureDetector(
                      key: const Key('send_button'),
                      onTap: sendEnabled ? handleSend : null,
                      child: Container(
                        width: 40.w,
                        height: 40.h,
                        decoration: BoxDecoration(
                          color: sendEnabled ? colors.fillPrimary : colors.fillSecondary,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Center(
                          child: WnIcon(
                            WnIcons.arrowUp,
                            color: sendEnabled
                                ? colors.fillContentPrimary
                                : colors.backgroundContentTertiary,
                            size: 18.sp,
                          ),
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
