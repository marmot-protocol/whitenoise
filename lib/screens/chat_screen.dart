import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
import 'package:whitenoise/providers/debug_view_provider.dart';
import 'package:whitenoise/providers/message_debug_log_provider.dart';
import 'package:whitenoise/providers/notification_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/screens/message_actions_screen.dart';
import 'package:whitenoise/services/message_service.dart';
import 'package:whitenoise/src/rust/api/media_files.dart';
import 'package:whitenoise/src/rust/api/messages.dart' show ChatMessage;
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/utils/app_flavor.dart';
import 'package:whitenoise/utils/avatar_color.dart';
import 'package:whitenoise/utils/bubble_grouping.dart';
import 'package:whitenoise/utils/chat_messages_search.dart';
import 'package:whitenoise/utils/metadata.dart';
import 'package:whitenoise/widgets/chat_media_upload_preview.dart';
import 'package:whitenoise/widgets/chat_message_bubble.dart';
import 'package:whitenoise/widgets/chat_message_quote.dart';
import 'package:whitenoise/widgets/chat_scroll_down_button.dart';
import 'package:whitenoise/widgets/wn_chat_message_input.dart';
import 'package:whitenoise/widgets/wn_icon.dart';
import 'package:whitenoise/widgets/wn_icon_button.dart';
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
    final debugLog = ref.read(messageDebugLogProvider.notifier);
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
      debugLog: debugLog,
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

    final debugViewEnabled = isStaging && (ref.watch(debugViewProvider).value ?? false);

    final noticeMessage = useState<String?>(null);
    final isSearchActive = useState(false);
    final searchQuery = useState('');
    final searchController = useTextEditingController();
    final inputAreaHeight = useState(0.0);

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
      final isGroupChat = chatProfile.data?.isDm != true;
      final authorMetadata = getAuthorMetadata(message.pubkey);
      final senderName = message.pubkey == pubkey
          ? context.l10n.you
          : presentName(authorMetadata) ?? context.l10n.unknownUser;
      final senderPictureUrl = authorMetadata?.picture;
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
        senderName: senderName,
        getChatMessageQuote: getChatMessageQuote,
        senderPictureUrl: senderPictureUrl,
        isGroupChat: isGroupChat,
      );
      if (context.mounted) FocusManager.instance.primaryFocus?.unfocus();
    }

    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final searchBarHeight = isSearchActive.value ? _searchBarHeight.h : 0.0;
    final slateTopPadding = safeAreaTop + _slateHeight.h + searchBarHeight;
    final listBottomPadding = inputAreaHeight.value + safeAreaBottom + 12.h;

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
          padding: EdgeInsets.fromLTRB(10.w, slateTopPadding + 8.h, 10.w, listBottomPadding),
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

            final nextMessage = index > 0 ? getMessage(index - 1) : null;
            final isGroupChat = chatProfile.data?.isDm != true;
            final showAvatar = shouldShowAvatar(
              current: message,
              next: nextMessage,
              isOwnMessage: isOwnMessage,
              isGroupChat: isGroupChat,
            );
            final showTail = shouldShowTail(current: message, next: nextMessage);

            return AutoScrollTag(
              key: ValueKey(message.id),
              controller: scrollController,
              index: index,
              child: ChatMessageBubble(
                message: message,
                isOwnMessage: isOwnMessage,
                currentUserPubkey: pubkey,
                onLongPress: () => showMessageMenu(message),
                onReaction: (emoji) => toggleReaction(message, emoji),
                onHorizontalDragEnd: () => input.setReplyingTo(message),
                replyPreview: replyPreview,
                onReplyTap: replyPreview != null && !replyPreview.isNotFound
                    ? () => scrollToMessageResult.scrollToMessage(replyPreview.messageId)
                    : null,
                senderName: senderName,
                senderPictureUrl: senderPictureUrl,
                showAvatar: showAvatar,
                showTail: showTail,
                isGroupChat: isGroupChat,
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
                            chatProfile.data?.displayName ??
                            (chatProfile.data?.isDm == true
                                ? context.l10n.unknownUser
                                : context.l10n.unknownGroup),
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
                        trailingWidget: debugViewEnabled
                            ? WnIconButton(
                                key: const Key('chat_raw_debug_button'),
                                icon: WnIcons.dataUsage,
                                onPressed: () => Routes.pushToChatRawDebug(context, groupId),
                              )
                            : null,
                      ),
                      systemNotice: noticeMessage.value != null
                          ? WnSystemNotice(
                              key: ValueKey(noticeMessage.value),
                              title: noticeMessage.value!,
                              type: WnSystemNoticeType.error,
                              onDismiss: dismissNotice,
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
                                icon: WnIcons.chevronUp,
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
                              WnIconButton(
                                key: const Key('chat_search_next_button'),
                                onPressed: displayCount == 0
                                    ? null
                                    : () {
                                        final next = (currentMatchIndex.value + 1) % displayCount;
                                        currentMatchIndex.value = next;
                                        scrollController.scrollToIndex(
                                          displayCount - 1 - next,
                                          preferPosition: AutoScrollPosition.middle,
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
                      isGroupChat: chatProfile.data?.isDm != true,
                      onSend: sendMessage,
                      onError: showNotice,
                      getChatMessageQuote: getChatMessageQuote,
                    ),
                  ),
                ),
              ),
              WnScrollEdgeEffect.canvasBottom(
                color: colors.backgroundPrimary,
                height: safeAreaBottom,
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

class _ChatInput extends StatelessWidget {
  const _ChatInput({
    required this.input,
    required this.mediaUpload,
    required this.currentUserPubkey,
    required this.isGroupChat,
    required this.onSend,
    required this.onError,
    required this.getChatMessageQuote,
  });

  final ChatInputState input;
  final MediaUploadState mediaUpload;
  final String currentUserPubkey;
  final bool isGroupChat;
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
      final hasMedia = mediaUpload.canSend;
      _logger.info(
        'handleSend textLen=${text.length} hasMedia=$hasMedia replyTo=${input.replyingTo?.id}',
      );
      if (text.isEmpty && !hasMedia) {
        _logger.info('handleSend early return: empty text and no sendable media');
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

    Widget? buildAttachmentArea() {
      final hasQuote = input.replyingTo != null;
      if (!hasQuote && !hasMedia) return null;

      final quoteData = hasQuote ? getChatMessageQuote(input.replyingTo!.id) : null;
      final shouldRenderQuote = hasQuote && quoteData != null && !quoteData.isNotFound;
      final replyAuthorColor = isGroupChat && shouldRenderQuote
          ? AvatarColor.fromPubkey(quoteData.authorPubkey).toColorSet(context.colors).content
          : null;

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (shouldRenderQuote)
            ChatMessageQuote(
              data: quoteData,
              currentUserPubkey: currentUserPubkey,
              onCancel: input.cancelReply,
              authorColor: replyAuthorColor,
            ),
          if (shouldRenderQuote && hasMedia) SizedBox(height: 8.h),
          if (hasMedia)
            ChatMediaUploadPreview(
              items: mediaUpload.items,
              onRemove: mediaUpload.removeItem,
            ),
        ],
      );
    }

    final inputStyle = typography.medium14.copyWith(color: colors.backgroundContentPrimary);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      child: WnChatMessageInput(
        isFocused: input.hasFocus,
        attachmentArea: buildAttachmentArea(),
        controller: input.controller,
        inputStyle: inputStyle,
        onAddTap: () {
          input.focusNode.unfocus();
          mediaUpload.pickImages();
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
        onSend: showSend ? handleSend : null,
        sendEnabled: sendEnabled,
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
  void updateRenderObject(BuildContext context, _SizeReporterRenderObject renderObject) {
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
