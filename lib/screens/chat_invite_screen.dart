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
import 'package:whitenoise/src/rust/api/account_groups.dart' as account_groups_api;
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_avatar.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_message_bubble.dart';
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

    useActiveChat(
      groupId: mlsGroupId,
      setActiveChat: ref.read(activeChatProvider.notifier).set,
      clearActiveChat: ref.read(activeChatProvider.notifier).clear,
      cancelGroupNotifications: ref.read(notificationServiceProvider).cancelForGroup,
    );

    void handleAvatarTap() {
      final otherPubkey = chatProfile.data?.otherMemberPubkey;
      if (otherPubkey != null) {
        Routes.pushToChatInfo(context, otherPubkey);
      } else {
        Routes.pushToWip(context);
      }
    }

    Future<void> handleAccept() async {
      isAccepting.value = true;
      try {
        await account_groups_api.acceptAccountGroup(
          accountPubkey: pubkey,
          mlsGroupId: mlsGroupId,
        );
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
                displayName: chatProfile.data?.displayName ?? '',
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
                  chatProfile.data?.displayName ?? '',
                  style: typography.semiBold18.copyWith(
                    color: colors.backgroundContentPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),
              ],
            ),
            Expanded(
              child: chatMessages.isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: colors.backgroundContentPrimary,
                      ),
                    )
                  : chatMessages.messageCount == 0
                  ? Center(
                      child: Text(
                        context.l10n.invitedToSecureChat,
                        style: typography.medium14.copyWith(
                          color: colors.backgroundContentTertiary,
                        ),
                      ),
                    )
                  : ListView.builder(
                      reverse: true,
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      itemCount: chatMessages.messageCount,
                      itemBuilder: (context, index) {
                        final message = chatMessages.getMessage(index);
                        final isOwnMessage = message.pubkey == pubkey;
                        final replyPreview = message.isReply
                            ? chatMessages.getReplyPreview(message.replyToId)
                            : null;
                        return WnMessageBubble(
                          message: message,
                          isOwnMessage: isOwnMessage,
                          currentUserPubkey: pubkey,
                          replyPreview: replyPreview,
                        );
                      },
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
