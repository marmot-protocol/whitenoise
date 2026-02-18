import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:whitenoise/hooks/use_active_chat.dart';
import 'package:whitenoise/hooks/use_chat_input.dart';
import 'package:whitenoise/hooks/use_chat_messages.dart';
import 'package:whitenoise/hooks/use_chat_profile.dart';
import 'package:whitenoise/hooks/use_chat_scroll.dart';
import 'package:whitenoise/hooks/use_scroll_to_message.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/models/reply_preview.dart';
import 'package:whitenoise/providers/account_pubkey_provider.dart';
import 'package:whitenoise/providers/active_chat_provider.dart';
import 'package:whitenoise/providers/notification_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/screens/message_actions_screen.dart';
import 'package:whitenoise/services/message_service.dart';
import 'package:whitenoise/src/rust/api/messages.dart' show ChatMessage;
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/utils/avatar_color.dart';
import 'package:whitenoise/widgets/wn_icon.dart';
import 'package:whitenoise/widgets/wn_message_bubble.dart';
import 'package:whitenoise/widgets/wn_reply_preview.dart';
import 'package:whitenoise/widgets/wn_scroll_edge_effect.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_chat_header.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart';

final _logger = Logger('ChatScreen');

const _slateHeight = 80.0;

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
      :isLoading,
      :latestMessageId,
      :latestMessagePubkey,
      :getReplyPreview,
    ) = useChatMessages(
      groupId,
    );
    final chatProfile = useChatProfile(context, pubkey, groupId);
    final scrollToMessageResult = useScrollToMessage(
      getReversedMessageIndex: getReversedMessageIndex,
    );
    final scrollController = scrollToMessageResult.scrollController;
    final input = useChatInput();
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

    void showNotice(String message) {
      noticeMessage.value = message;
    }

    void dismissNotice() {
      noticeMessage.value = null;
    }

    useChatScroll(
      scrollController: scrollController,
      focusNode: input.focusNode,
      latestMessageId: latestMessageId,
      isLatestMessageOwn: latestMessagePubkey == pubkey,
    );

    Future<void> sendMessage(String message, ChatMessage? replyingTo) async {
      await messageService.sendTextMessage(
        content: message,
        replyToMessageId: replyingTo?.id,
        replyToMessagePubkey: replyingTo?.pubkey,
        replyToMessageKind: replyingTo?.kind,
      );
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
    final slateTopPadding = safeAreaTop + _slateHeight.h;

    Widget messageListContent;
    if (isLoading) {
      messageListContent = Center(
        child: CircularProgressIndicator(color: colors.backgroundContentPrimary),
      );
    } else if (messageCount == 0) {
      messageListContent = Center(
        child: Text(
          context.l10n.noMessagesYet,
          style: typography.medium14.copyWith(color: colors.backgroundContentTertiary),
        ),
      );
    } else {
      messageListContent = ListView.builder(
        controller: scrollController,
        reverse: true,
        padding: EdgeInsets.only(top: slateTopPadding + 8.h, bottom: 12.h),
        itemCount: messageCount,
        findChildIndexCallback: (key) {
          if (key is ValueKey<String>) {
            return getReversedMessageIndex(key.value);
          }
          return null;
        },
        itemBuilder: (context, index) {
          final message = getMessage(index);
          final isOwnMessage = message.pubkey == pubkey;
          final replyPreview = message.isReply ? getReplyPreview(message.replyToId) : null;

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
            ),
          );
        },
      );
    }

    return GestureDetector(
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
                    child: WnSlate(
                      header: WnSlateChatHeader(
                        displayName: chatProfile.data?.displayName ?? '',
                        avatarColor: chatProfile.data?.color ?? AvatarColor.neutral,
                        pictureUrl: chatProfile.data?.pictureUrl,
                        onBack: () => Routes.goToChatList(context),
                        onAvatarTap: () {
                          final otherPubkey = chatProfile.data?.otherMemberPubkey;
                          if (otherPubkey != null) {
                            Routes.pushToChatInfo(context, otherPubkey);
                          } else {
                            Routes.pushToGroupInfo(context, groupId);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: _ChatInput(
                input: input,
                currentUserPubkey: pubkey,
                onSend: sendMessage,
                onError: showNotice,
                getReplyPreview: getReplyPreview,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatInput extends StatelessWidget {
  const _ChatInput({
    required this.input,
    required this.currentUserPubkey,
    required this.onSend,
    required this.onError,
    required this.getReplyPreview,
  });

  final ChatInputState input;
  final String currentUserPubkey;
  final Future<void> Function(String message, ChatMessage? replyingTo) onSend;
  final void Function(String message) onError;
  final ReplyPreview? Function(String? replyId) getReplyPreview;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typographyScaled;

    Future<void> handleSend() async {
      final text = input.controller.text.trim();
      if (text.isEmpty) return;
      try {
        await onSend(text, input.replyingTo);
        input.clear();
      } catch (e, st) {
        _logger.severe('Failed to send message', e, st);
        if (context.mounted) {
          onError(context.l10n.failedToSendMessage);
        }
      }
    }

    return Container(
      padding: EdgeInsets.only(left: 12.w, right: 12.w, top: 2.h, bottom: 24.h),
      color: colors.backgroundPrimary,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colors.backgroundTertiary,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: colors.borderTertiary),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (input.replyingTo != null) ...[
                    Padding(
                      padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 0.h),
                      child: WnReplyPreview(
                        data: getReplyPreview(input.replyingTo!.id)!,
                        currentUserPubkey: currentUserPubkey,
                        onCancel: input.cancelReply,
                      ),
                    ),
                  ],
                  TextField(
                    controller: input.controller,
                    focusNode: input.focusNode,
                    maxLines: 5,
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
                      fillColor: colors.backgroundTertiary,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 20.h,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            child: input.hasContent
                ? Padding(
                    padding: EdgeInsets.only(left: 8.w),
                    child: GestureDetector(
                      key: const Key('send_button'),
                      onTap: handleSend,
                      child: Container(
                        width: 44.w,
                        height: 44.h,
                        decoration: BoxDecoration(
                          color: colors.fillPrimary,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Center(
                          child: WnIcon(
                            WnIcons.arrowUp,
                            color: colors.fillContentPrimary,
                            size: 20.sp,
                          ),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
