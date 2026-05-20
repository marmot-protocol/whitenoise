import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/hooks/use_block_actions.dart';
import 'package:whitenoise/hooks/use_follow_actions.dart';
import 'package:whitenoise/hooks/use_start_dm.dart';
import 'package:whitenoise/hooks/use_system_notice.dart';
import 'package:whitenoise/hooks/use_user_metadata.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/providers/account_pubkey_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/utils/avatar_color.dart';
import 'package:whitenoise/utils/metadata.dart' show presentName;
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_chat_info_profile_card.dart';
import 'package:whitenoise/widgets/wn_icon.dart';
import 'package:whitenoise/widgets/wn_overlay.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart';

final _logger = Logger('BlockedUserScreen');

class BlockedUserScreen extends HookConsumerWidget {
  const BlockedUserScreen({super.key, required this.userPubkey});

  final String userPubkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final typography = context.typographyScaled;
    final accountPubkey = ref.watch(accountPubkeyProvider);
    final metadataSnapshot = useUserMetadata(context, userPubkey);
    final metadata = metadataSnapshot.data;
    final blockState = useBlockActions(
      accountPubkey: accountPubkey,
      userPubkey: userPubkey,
    );
    final followState = useFollowActions(
      accountPubkey: accountPubkey,
      userPubkey: userPubkey,
    );
    final dmState = useStartDm(
      accountPubkey: accountPubkey,
      peerPubkey: userPubkey,
    );
    final systemNotice = useSystemNotice();
    final isBannerCollapsed = useState(false);

    Future<void> handleToggleBlock({required bool wasBlocked}) async {
      try {
        await blockState.toggleBlock();
      } catch (_) {
        if (context.mounted) {
          systemNotice.showErrorNotice(
            wasBlocked
                ? context.l10n.failedToUnblockUser
                : context.l10n.failedToBlockUser,
          );
        }
      }
    }

    Future<void> handleToggleFollow() async {
      try {
        await followState.toggleFollow();
      } catch (_) {
        if (context.mounted) {
          systemNotice.showErrorNotice(context.l10n.failedToUpdateFollow);
        }
      }
    }

    Future<void> handleStartChat() async {
      try {
        final groupId = await dmState.startDm();
        if (context.mounted) {
          Routes.goToChat(context, groupId);
        }
      } catch (e, st) {
        _logger.severe('Failed to start chat after unblock', e, st);
        if (context.mounted) {
          systemNotice.showErrorNotice(context.l10n.failedToStartChat);
        }
      }
    }

    final isBlocked = blockState.isBlocked;

    Widget bottomPanel;
    if (isBlocked == false) {
      bottomPanel = _UnblockedActionsPanel(
        followState: followState,
        blockState: blockState,
        dmState: dmState,
        onFollow: handleToggleFollow,
        onAddToGroup: () => Routes.pushToAddToGroup(context, userPubkey),
        onBlock: () => handleToggleBlock(wasBlocked: false),
        onSendMessage: handleStartChat,
      );
    } else {
      bottomPanel = WnSystemNotice(
        key: const Key('blocked_user_detail_notice'),
        title: context.l10n.userIsBlocked,
        description: Text(
          context.l10n.blockedUserDetailDescription,
          style: typography.medium14.copyWith(
            color: colors.backgroundContentSecondary,
          ),
        ),
        type: WnSystemNoticeType.elevatedCard,
        variant: isBannerCollapsed.value
            ? WnSystemNoticeVariant.collapsed
            : WnSystemNoticeVariant.expanded,
        animateEntrance: false,
        onToggle: () => isBannerCollapsed.value = !isBannerCollapsed.value,
        primaryAction: WnButton(
          key: const Key('blocked_user_unblock_button'),
          text: context.l10n.unblockUser,
          type: WnButtonType.overlay,
          size: WnButtonSize.medium,
          loading: blockState.isActionLoading,
          disabled: blockState.isLoading || blockState.isActionLoading,
          trailingIcon: WnIcons.userCheck,
          onPressed: () => handleToggleBlock(wasBlocked: true),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const WnOverlay(variant: WnOverlayVariant.light),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: WnSlate(
                shrinkWrapContent: true,
                header: WnSlateNavigationHeader(
                  title: context.l10n.profile,
                  onNavigate: () => Routes.goBack(context),
                ),
                systemNotice: systemNotice.noticeMessage != null
                    ? WnSystemNotice(
                        key: ValueKey(systemNotice.noticeMessage),
                        title: systemNotice.noticeMessage!,
                        type: systemNotice.noticeType,
                        variant: WnSystemNoticeVariant.dismissible,
                        onDismiss: systemNotice.dismissNotice,
                      )
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
                      child: WnChatInfoProfileCard(
                        userPubkey: userPubkey,
                        displayName: presentName(metadata),
                        pictureUrl: metadata?.picture,
                        avatarColor: AvatarColor.fromPubkey(userPubkey),
                        onPublicKeyCopied: () => systemNotice.showSuccessNotice(
                          context.l10n.publicKeyCopied,
                        ),
                        onPublicKeyCopyError: () => systemNotice.showErrorNotice(
                          context.l10n.publicKeyCopyError,
                        ),
                      ),
                    ),
                    bottomPanel,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnblockedActionsPanel extends StatelessWidget {
  const _UnblockedActionsPanel({
    required this.followState,
    required this.blockState,
    required this.dmState,
    required this.onFollow,
    required this.onAddToGroup,
    required this.onBlock,
    required this.onSendMessage,
  });

  final FollowActionsState followState;
  final BlockActionsState blockState;
  final StartDmState dmState;
  final VoidCallback onFollow;
  final VoidCallback onAddToGroup;
  final VoidCallback onBlock;
  final VoidCallback onSendMessage;

  @override
  Widget build(BuildContext context) {
    final isFollowing = followState.isFollowing;
    return Padding(
      key: const Key('blocked_user_unblocked_panel'),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WnButton(
            key: const Key('blocked_user_follow_button'),
            text: isFollowing == true ? context.l10n.unfollow : context.l10n.follow,
            type: WnButtonType.outline,
            size: WnButtonSize.medium,
            trailingIcon: isFollowing == true ? WnIcons.userUnfollow : WnIcons.userFollow,
            loading: followState.isLoading || followState.isActionLoading,
            onPressed: onFollow,
          ),
          Gap(8.h),
          WnButton(
            key: const Key('blocked_user_add_to_group_button'),
            text: context.l10n.addToGroup,
            type: WnButtonType.outline,
            size: WnButtonSize.medium,
            trailingIcon: WnIcons.newGroupChat,
            onPressed: onAddToGroup,
          ),
          Gap(8.h),
          WnButton(
            key: const Key('blocked_user_block_button'),
            text: context.l10n.blockUser,
            type: WnButtonType.outline,
            size: WnButtonSize.medium,
            trailingIcon: WnIcons.closeOutline,
            loading: blockState.isActionLoading,
            disabled: blockState.isLoading || blockState.isActionLoading,
            onPressed: onBlock,
          ),
          Gap(8.h),
          WnButton(
            key: const Key('blocked_user_send_message_button'),
            text: context.l10n.sendMessage,
            size: WnButtonSize.medium,
            trailingIcon: WnIcons.newChat,
            loading: dmState.isLoading,
            onPressed: onSendMessage,
          ),
        ],
      ),
    );
  }
}
