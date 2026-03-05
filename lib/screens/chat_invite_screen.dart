import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:whitenoise/hooks/use_active_chat.dart';
import 'package:whitenoise/hooks/use_chat_messages.dart';
import 'package:whitenoise/hooks/use_chat_profile.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/providers/account_pubkey_provider.dart';
import 'package:whitenoise/providers/active_chat_provider.dart';
import 'package:whitenoise/providers/notification_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/services/user_service.dart';
import 'package:whitenoise/src/rust/api/account_groups.dart' as account_groups_api;
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/utils/bubble_grouping.dart';
import 'package:whitenoise/utils/metadata.dart';
import 'package:whitenoise/widgets/chat_message_bubble.dart';
import 'package:whitenoise/widgets/chat_scroll_down_button.dart';
import 'package:whitenoise/widgets/wn_avatar.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_chat_system_message.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_chat_header.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart';

class ChatInviteScreen extends HookConsumerWidget {
  final String mlsGroupId;

  const ChatInviteScreen({super.key, required this.mlsGroupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final typography = context.typographyScaled;
    final pubkey = ref.watch(accountPubkeyProvider);

    final isAccepting = useState(false);
    final isDeclining = useState(false);
    final isProcessing = isAccepting.value || isDeclining.value;
    final noticeMessage = useState<String?>(null);

    void showNotice(String message) {
      noticeMessage.value = message;
    }

    void dismissNotice() {
      noticeMessage.value = null;
    }

    final chatProfile = useChatProfile(context, pubkey, mlsGroupId);
    final chatMessages = useChatMessages(mlsGroupId);

    final accountGroup = useMemoized(
      () => account_groups_api.getAccountGroup(
        accountPubkey: pubkey,
        mlsGroupId: mlsGroupId,
      ),
      [pubkey, mlsGroupId],
    );
    final inviterName = useFuture(
      useMemoized(
        () async {
          final group = await accountGroup;
          final welcomerPubkey = group.welcomerPubkey;
          if (welcomerPubkey == null) return null;
          final metadata = await UserService(welcomerPubkey).fetchMetadata();
          return presentName(metadata);
        },
        [accountGroup],
      ),
    );

    useActiveChat(
      groupId: mlsGroupId,
      setActiveChat: ref.read(activeChatProvider.notifier).set,
      clearActiveChat: ref.read(activeChatProvider.notifier).clear,
      cancelGroupNotifications: ref.read(notificationServiceProvider).cancelForGroup,
    );

    void handleAvatarTap() {
      final otherPubkey = chatProfile.data?.otherMemberPubkey;
      if (otherPubkey != null) {
        unawaited(Routes.pushToInviteInfo(context, otherPubkey));
      } else {
        Routes.pushToGroupInfo(context, mlsGroupId);
      }
    }

    Future<void> handleAccept() async {
      isAccepting.value = true;
      try {
        await account_groups_api.acceptAccountGroup(
          accountPubkey: pubkey,
          mlsGroupId: mlsGroupId,
        );
        if (chatMessages.latestMessageId != null) {
          account_groups_api
              .markMessageRead(
                accountPubkey: pubkey,
                messageId: chatMessages.latestMessageId!,
              )
              .ignore();
        }
        if (context.mounted) {
          Routes.goToChat(context, mlsGroupId);
        }
      } catch (e) {
        if (context.mounted) {
          showNotice(context.l10n.failedToAcceptInvitation(e.toString()));
        }
      } finally {
        if (context.mounted) isAccepting.value = false;
      }
    }

    Future<void> handleDecline() async {
      isDeclining.value = true;
      try {
        await account_groups_api.declineAccountGroup(
          accountPubkey: pubkey,
          mlsGroupId: mlsGroupId,
        );
        if (context.mounted) {
          Routes.goToChatList(context);
        }
      } catch (e) {
        if (context.mounted) {
          showNotice(context.l10n.failedToDeclineInvitation(e.toString()));
        }
      } finally {
        if (context.mounted) isDeclining.value = false;
      }
    }

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: SafeArea(
        child: Column(
          children: [
            if (noticeMessage.value != null)
              WnSystemNotice(
                key: ValueKey(noticeMessage.value),
                title: noticeMessage.value!,
                type: WnSystemNoticeType.error,
                onDismiss: dismissNotice,
              ),
            WnSlate(
              tag: 'wn-slate-invite-header',
              header: WnSlateChatHeader(
                displayName:
                    chatProfile.data?.displayName ??
                    (chatProfile.data?.isDm == true
                        ? context.l10n.unknownUser
                        : context.l10n.unknownGroup),
                avatarColor: chatProfile.data?.color ?? AvatarColor.neutral,
                pictureUrl: chatProfile.data?.pictureUrl,
                onBack: () => Routes.goToChatList(context),
                onAvatarTap: handleAvatarTap,
              ),
            ),
            Column(
              children: [
                SizedBox(height: 48.h),
                GestureDetector(
                  key: const Key('large_avatar_tap_area'),
                  onTap: handleAvatarTap,
                  child: WnAvatar(
                    pictureUrl: chatProfile.data?.pictureUrl,
                    displayName: chatProfile.data?.displayName,
                    size: WnAvatarSize.large,
                    color: chatProfile.data?.color ?? AvatarColor.neutral,
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  chatProfile.data?.displayName ??
                      (chatProfile.data?.isDm == true
                          ? context.l10n.unknownUser
                          : context.l10n.unknownGroup),
                  style: typography.semiBold18.copyWith(
                    color: colors.backgroundContentPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),
              ],
            ),
            if (inviterName.data != null && inviterName.data!.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: WnChatSystemMessage(
                  text: '${inviterName.data!}${context.l10n.invitedYouToChatSuffix}',
                  textSpan: TextSpan(
                    style: typography.medium14.copyWith(
                      color: colors.backgroundContentSecondary,
                    ),
                    children: [
                      TextSpan(
                        text: inviterName.data,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: context.l10n.invitedYouToChatSuffix),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: chatMessages.isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: colors.backgroundContentPrimary,
                      ),
                    )
                  : _InviteMessageList(
                      chatMessages: chatMessages,
                      pubkey: pubkey,
                      isGroupChat: chatProfile.data?.isDm != true,
                    ),
            ),
            WnSlate(
              child: Padding(
                padding: EdgeInsets.all(14.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 12.h,
                  children: [
                    WnButton(
                      text: context.l10n.decline,
                      type: WnButtonType.outline,
                      loading: isDeclining.value,
                      disabled: isProcessing,
                      onPressed: handleDecline,
                    ),
                    WnButton(
                      text: context.l10n.accept,
                      loading: isAccepting.value,
                      disabled: isProcessing,
                      onPressed: handleAccept,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteMessageList extends HookWidget {
  const _InviteMessageList({
    required this.chatMessages,
    required this.pubkey,
    required this.isGroupChat,
  });

  final ChatMessagesResult chatMessages;
  final String pubkey;
  final bool isGroupChat;

  @override
  Widget build(BuildContext context) {
    final scrollController = useScrollController();
    final hasMoreBelow = useState(false);

    useEffect(() {
      void updateHasMoreBelow() {
        if (!scrollController.hasClients) return;
        final position = scrollController.position;
        hasMoreBelow.value = position.pixels < position.maxScrollExtent - 50;
      }

      scrollController.addListener(updateHasMoreBelow);
      WidgetsBinding.instance.addPostFrameCallback((_) => updateHasMoreBelow());
      return () => scrollController.removeListener(updateHasMoreBelow);
    }, [scrollController]);

    void scrollToBottom() {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }

    return Stack(
      children: [
        ListView.builder(
          controller: scrollController,
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          itemCount: chatMessages.messageCount,
          itemBuilder: (context, index) {
            final reversedIndex = chatMessages.messageCount - 1 - index;
            final message = chatMessages.getMessage(reversedIndex);
            final isOwnMessage = message.pubkey == pubkey;
            final replyPreview = message.isReply
                ? chatMessages.getChatMessageQuote(message.replyToId)
                : null;
            final nextMessage = reversedIndex > 0
                ? chatMessages.getMessage(reversedIndex - 1)
                : null;
            final showAvatar = shouldShowAvatar(
              current: message,
              next: nextMessage,
              isOwnMessage: isOwnMessage,
              isGroupChat: isGroupChat,
            );
            final showTail = shouldShowTail(current: message, next: nextMessage);
            final authorMetadata = chatMessages.getAuthorMetadata(message.pubkey);
            final senderName = isOwnMessage
                ? context.l10n.you
                : presentName(authorMetadata) ?? context.l10n.unknownUser;
            final senderPictureUrl = authorMetadata?.picture;
            return ChatMessageBubble(
              message: message,
              isOwnMessage: isOwnMessage,
              currentUserPubkey: pubkey,
              replyPreview: replyPreview,
              senderName: senderName,
              senderPictureUrl: senderPictureUrl,
              showAvatar: showAvatar,
              showTail: showTail,
              isGroupChat: isGroupChat,
            );
          },
        ),
        if (hasMoreBelow.value)
          Positioned(
            bottom: 8.h,
            left: 0,
            right: 0,
            child: Center(
              child: ChatScrollDownButton(
                show: true,
                onTap: scrollToBottom,
              ),
            ),
          ),
      ],
    );
  }
}
