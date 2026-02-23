import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/hooks/use_follow_actions.dart';
import 'package:whitenoise/hooks/use_group_members.dart';
import 'package:whitenoise/hooks/use_start_dm.dart';
import 'package:whitenoise/hooks/use_system_notice.dart';
import 'package:whitenoise/hooks/use_user_metadata.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/providers/account_pubkey_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/utils/metadata.dart' show presentName;
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_chat_info_profile_card.dart';
import 'package:whitenoise/widgets/wn_confirmation_slate.dart';
import 'package:whitenoise/widgets/wn_icon.dart';
import 'package:whitenoise/widgets/wn_overlay.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart' show WnSystemNotice;

final _logger = Logger('GroupMemberScreen');

String _groupMemberErrorL10n(String errorKey, AppLocalizations l10n) {
  return switch (errorKey) {
    'failedToFetchGroupMembers' => l10n.failedToFetchGroupMembers,
    'failedToAddMembers' => l10n.failedToAddMembers,
    'failedToRemoveFromGroup' => l10n.failedToRemoveFromGroup,
    'failedToMakeAdmin' => l10n.failedToMakeAdmin,
    'failedToRemoveAdmin' => l10n.failedToRemoveAdmin,
    _ => l10n.somethingWentWrong,
  };
}

class GroupMemberScreen extends HookConsumerWidget {
  const GroupMemberScreen({
    super.key,
    required this.groupId,
    required this.memberPubkey,
  });

  final String groupId;
  final String memberPubkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountPubkey = ref.watch(accountPubkeyProvider);
    final isOwnProfile = memberPubkey == accountPubkey;

    final metadataSnapshot = useUserMetadata(context, memberPubkey);
    final metadata = metadataSnapshot.data;

    final membersState = useGroupMembers(
      accountPubkey: accountPubkey,
      groupId: groupId,
    );

    final (:noticeMessage, :noticeType, :showErrorNotice, :showSuccessNotice, :dismissNotice) =
        useSystemNotice();

    final followState = useFollowActions(
      accountPubkey: accountPubkey,
      userPubkey: memberPubkey,
    );

    final dmState = useStartDm(
      accountPubkey: accountPubkey,
      peerPubkey: memberPubkey,
    );

    useEffect(() {
      if (membersState.error != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            showErrorNotice(
              _groupMemberErrorL10n(membersState.error!, context.l10n),
            );
          }
        });
        membersState.clearError();
      }
      return null;
    }, [membersState.error]);

    final isCurrentUserAdmin = membersState.admins.contains(accountPubkey);
    final isMemberAdmin = membersState.admins.contains(memberPubkey);
    final displayName = presentName(metadata) ?? memberPubkey.substring(0, 8);
    final roleLabel = isMemberAdmin ? context.l10n.adminBadge : context.l10n.memberBadge;

    Future<void> handleSendMessage() async {
      try {
        final groupId = await dmState.startDm();
        if (context.mounted) {
          Routes.goToChat(context, groupId);
        }
      } catch (e) {
        _logger.severe('Failed to start chat: $e');
        if (context.mounted) {
          showErrorNotice(context.l10n.failedToStartChat);
        }
      }
    }

    Future<void> handleFollowAction() async {
      try {
        await followState.toggleFollow();
      } catch (_) {
        if (context.mounted) {
          showErrorNotice(context.l10n.failedToUpdateFollow);
        }
      }
    }

    Future<void> handleMakeAdmin() async {
      await WnConfirmationSlate.show(
        context: context,
        title: context.l10n.makeAdminConfirmation,
        message: context.l10n.makeAdminWarning,
        confirmText: context.l10n.makeAdmin,
        cancelText: context.l10n.cancel,
        onConfirmAsync: () => membersState.makeAdmin(memberPubkey),
      );
    }

    Future<void> handleRemoveAdmin() async {
      await WnConfirmationSlate.show(
        context: context,
        title: context.l10n.removeAdminConfirmation,
        message: context.l10n.removeAdminWarning,
        confirmText: context.l10n.removeAdminRole,
        cancelText: context.l10n.cancel,
        onConfirmAsync: () => membersState.removeAdmin(memberPubkey),
      );
    }

    Future<void> handleRemoveFromGroup() async {
      final result = await WnConfirmationSlate.show(
        context: context,
        title: context.l10n.removeFromGroupConfirmation,
        message: context.l10n.removeFromGroupWarning,
        confirmText: context.l10n.removeFromGroup,
        cancelText: context.l10n.cancel,
        isDestructive: true,
        onConfirmAsync: () => membersState.removeMembers([memberPubkey]),
      );

      if (context.mounted && result == true) {
        Routes.goBack(context);
      }
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const WnOverlay(variant: WnOverlayVariant.light),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: Align(
                alignment: Alignment.topCenter,
                child: WnSlate(
                  shrinkWrapContent: true,
                  header: WnSlateNavigationHeader(
                    titleWidget: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: displayName,
                            style: context.typographyScaled.semiBold16.copyWith(
                              color: context.colors.backgroundContentPrimary,
                            ),
                          ),
                          TextSpan(
                            text: ' - $roleLabel',
                            style: context.typographyScaled.semiBold16.copyWith(
                              color: context.colors.backgroundContentSecondary,
                            ),
                          ),
                        ],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    type: WnSlateNavigationType.back,
                    onNavigate: () => Routes.goBack(context),
                  ),
                  systemNotice: noticeMessage != null
                      ? WnSystemNotice(
                          key: ValueKey(noticeMessage),
                          title: noticeMessage,
                          type: noticeType,
                          onDismiss: dismissNotice,
                        )
                      : null,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Gap(8.h),
                        WnChatInfoProfileCard(
                          userPubkey: memberPubkey,
                          metadata: metadata,
                          onPublicKeyCopied: () => showSuccessNotice(context.l10n.publicKeyCopied),
                          onPublicKeyCopyError: () =>
                              showErrorNotice(context.l10n.publicKeyCopyError),
                        ),
                        if (!isOwnProfile) ...[
                          Gap(8.h),
                          SizedBox(
                            width: double.infinity,
                            child: WnButton(
                              key: const Key('send_message_button'),
                              text: context.l10n.sendMessage,
                              type: WnButtonType.outline,
                              size: WnButtonSize.medium,
                              trailingIcon: WnIcons.newChat,
                              loading: dmState.isLoading,
                              onPressed: handleSendMessage,
                            ),
                          ),
                          Gap(8.h),
                          SizedBox(
                            width: double.infinity,
                            child: WnButton(
                              key: const Key('follow_button'),
                              text: followState.isFollowing
                                  ? context.l10n.removeAsContact
                                  : context.l10n.addAsContact,
                              type: WnButtonType.outline,
                              size: WnButtonSize.medium,
                              trailingIcon: followState.isFollowing
                                  ? WnIcons.userUnfollow
                                  : WnIcons.userFollow,
                              loading: followState.isActionLoading,
                              onPressed: handleFollowAction,
                            ),
                          ),
                          Gap(8.h),
                          SizedBox(
                            width: double.infinity,
                            child: WnButton(
                              key: const Key('add_to_another_group_button'),
                              text: context.l10n.addToAnotherGroup,
                              type: WnButtonType.outline,
                              size: WnButtonSize.medium,
                              trailingIcon: WnIcons.newGroupChat,
                              onPressed: () => Routes.pushToAddToGroup(context, memberPubkey),
                            ),
                          ),
                          if (isCurrentUserAdmin) ...[
                            Gap(8.h),
                            SizedBox(
                              width: double.infinity,
                              child: isMemberAdmin
                                  ? WnButton(
                                      key: const Key('remove_admin_button'),
                                      text: context.l10n.removeAdminRole,
                                      type: WnButtonType.outline,
                                      size: WnButtonSize.medium,
                                      trailingIcon: WnIcons.removeAdmin,
                                      onPressed: handleRemoveAdmin,
                                    )
                                  : WnButton(
                                      key: const Key('make_admin_button'),
                                      text: context.l10n.makeAdmin,
                                      type: WnButtonType.outline,
                                      size: WnButtonSize.medium,
                                      trailingIcon: WnIcons.makeAdmin,
                                      onPressed: handleMakeAdmin,
                                    ),
                            ),
                            Gap(8.h),
                            SizedBox(
                              width: double.infinity,
                              child: WnButton(
                                key: const Key('remove_from_group_button'),
                                text: context.l10n.removeFromGroup,
                                type: WnButtonType.destructive,
                                size: WnButtonSize.medium,
                                trailingIcon: WnIcons.removeCircle,
                                onPressed: handleRemoveFromGroup,
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
