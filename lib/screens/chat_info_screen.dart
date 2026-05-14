import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:whitenoise/hooks/use_block_actions.dart';
import 'package:whitenoise/hooks/use_chat_archive.dart';
import 'package:whitenoise/hooks/use_chat_summary.dart';
import 'package:whitenoise/hooks/use_follow_actions.dart';
import 'package:whitenoise/hooks/use_system_notice.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/providers/account_pubkey_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/utils/chat_summary_display.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_chat_info_profile_card.dart';
import 'package:whitenoise/widgets/wn_icon.dart';
import 'package:whitenoise/widgets/wn_overlay.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart' show WnSystemNotice;
import 'package:whitenoise_frb/src/rust/api/chat_summary.dart';
import 'package:whitenoise_frb/src/rust/api/groups.dart' show GroupType;

class ChatInfoScreen extends HookConsumerWidget {
  const ChatInfoScreen({
    super.key,
    required this.mlsGroupId,
    this.showSearch = true,
  });

  final String mlsGroupId;
  final bool showSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountPubkey = ref.watch(accountPubkeyProvider);
    final chatSummary = useChatSummary(context, accountPubkey, mlsGroupId);

    final isDm = chatSummary.data?.groupType == GroupType.directMessage;
    final peerPubkey = chatSummary.data?.dmPeerPubkey;
    final hasPeerPubkey = peerPubkey != null;
    final isUnresolvedDm = isDm && !hasPeerPubkey;

    final followState = useFollowActions(
      accountPubkey: accountPubkey,
      userPubkey: peerPubkey,
    );
    final blockState = useBlockActions(
      accountPubkey: accountPubkey,
      userPubkey: peerPubkey,
    );
    final archiveState = useChatArchive(accountPubkey, mlsGroupId);
    final (:noticeMessage, :noticeType, :showErrorNotice, :showSuccessNotice, :dismissNotice) =
        useSystemNotice();

    final isFollowing = hasPeerPubkey ? followState.isFollowing : false;
    final isOwnProfile = hasPeerPubkey && peerPubkey == accountPubkey;

    Future<void> handleFollowAction() async {
      if (!hasPeerPubkey) return;
      try {
        await followState.toggleFollow();
      } catch (_) {
        if (context.mounted) {
          showErrorNotice(context.l10n.failedToUpdateFollow);
        }
      }
    }

    Future<void> handleBlockAction() async {
      if (!hasPeerPubkey) return;
      final currentIsBlocked = blockState.isBlocked;
      try {
        await blockState.toggleBlock();
      } catch (_) {
        if (context.mounted) {
          if (currentIsBlocked) {
            showErrorNotice(context.l10n.failedToUnblockUser);
          } else {
            showErrorNotice(context.l10n.failedToBlockUser);
          }
        }
      }
    }

    Future<void> handleArchiveAction() async {
      final currentIsArchived = archiveState.isArchived;
      try {
        if (currentIsArchived) {
          await archiveState.unarchive();
        } else {
          await archiveState.archive();
        }
      } catch (_) {
        if (context.mounted) {
          if (currentIsArchived) {
            showErrorNotice(context.l10n.failedToUnarchiveChat);
          } else {
            showErrorNotice(context.l10n.failedToArchiveChat);
          }
        }
      }
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
                  title: context.l10n.chatInformation,
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
                      _ChatInfoProfileBlock(
                        chatSummary: chatSummary,
                        mlsGroupId: mlsGroupId,
                        onPublicKeyCopied: () => showSuccessNotice(context.l10n.publicKeyCopied),
                        onPublicKeyCopyError: () =>
                            showErrorNotice(context.l10n.publicKeyCopyError),
                      ),
                      Gap(12.h),
                      _ChatInfoActions(
                        isOwnProfile: isOwnProfile,
                        isFollowing: isFollowing,
                        isFollowLoading: followState.isActionLoading,
                        onFollowTap: hasPeerPubkey ? handleFollowAction : null,
                        onSearchTap: showSearch && !isUnresolvedDm
                            ? () => GoRouter.of(context).pop(true)
                            : null,
                        onAddToGroupTap: peerPubkey != null
                            ? () => Routes.pushToAddToGroup(context, peerPubkey)
                            : null,
                        isBlocked: blockState.isBlocked,
                        isBlockLoading: blockState.isActionLoading,
                        onBlockTap: hasPeerPubkey && !isOwnProfile && !blockState.isLoading
                            ? handleBlockAction
                            : null,
                        isArchived: archiveState.isArchived,
                        isArchiveLoading: archiveState.isActionLoading,
                        onArchiveTap: !isUnresolvedDm && !archiveState.isLoading
                            ? handleArchiveAction
                            : null,
                      ),
                    ],
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

class _ChatInfoProfileBlock extends StatelessWidget {
  const _ChatInfoProfileBlock({
    required this.chatSummary,
    required this.mlsGroupId,
    required this.onPublicKeyCopied,
    required this.onPublicKeyCopyError,
  });

  final AsyncSnapshot<ChatSummary> chatSummary;
  final String mlsGroupId;
  final VoidCallback onPublicKeyCopied;
  final VoidCallback onPublicKeyCopyError;

  @override
  Widget build(BuildContext context) {
    if (chatSummary.hasError) {
      return SizedBox(
        width: double.infinity,
        child: Text(
          context.l10n.profileLoadError,
          style: context.typographyScaled.medium14.copyWith(
            color: context.colors.backgroundContentSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (!chatSummary.hasData) {
      return SizedBox(
        height: 120.h,
        width: double.infinity,
        child: Center(
          child: CircularProgressIndicator(
            color: context.colors.backgroundContentPrimary,
          ),
        ),
      );
    }

    final display = chatSummaryDisplay(chatSummary.data!, mlsGroupId);
    final isDm = chatSummary.data!.groupType == GroupType.directMessage;
    if (!isDm) {
      return WnChatInfoProfileCard(
        userPubkey: mlsGroupId,
        displayName: display.displayName,
        pictureUrl: display.pictureUrl,
        avatarColor: display.color,
        onPublicKeyCopied: onPublicKeyCopied,
        onPublicKeyCopyError: onPublicKeyCopyError,
      );
    }

    final peer = chatSummary.data!.dmPeerPubkey;
    if (peer == null) {
      return SizedBox(
        width: double.infinity,
        child: Text(
          context.l10n.profileLoadError,
          style: context.typographyScaled.medium14.copyWith(
            color: context.colors.backgroundContentSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return WnChatInfoProfileCard(
      userPubkey: peer,
      displayName: display.displayName,
      pictureUrl: display.pictureUrl,
      avatarColor: display.color,
      onPublicKeyCopied: onPublicKeyCopied,
      onPublicKeyCopyError: onPublicKeyCopyError,
    );
  }
}

class _ChatInfoActions extends StatelessWidget {
  const _ChatInfoActions({
    required this.isOwnProfile,
    required this.isFollowing,
    required this.isFollowLoading,
    this.onFollowTap,
    this.onSearchTap,
    this.onAddToGroupTap,
    this.isBlocked = false,
    this.isBlockLoading = false,
    this.onBlockTap,
    this.isArchived = false,
    this.isArchiveLoading = false,
    this.onArchiveTap,
  });

  final bool isOwnProfile;
  final bool isFollowing;
  final bool isFollowLoading;
  final VoidCallback? onFollowTap;
  final VoidCallback? onSearchTap;
  final VoidCallback? onAddToGroupTap;
  final bool isBlocked;
  final bool isBlockLoading;
  final VoidCallback? onBlockTap;
  final bool isArchived;
  final bool isArchiveLoading;
  final VoidCallback? onArchiveTap;

  @override
  Widget build(BuildContext context) {
    final contactLabel = isFollowing ? context.l10n.unfollow : context.l10n.follow;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (onSearchTap != null) ...[
          WnButton(
            key: const Key('search_button'),
            text: context.l10n.search,
            type: WnButtonType.outline,
            size: WnButtonSize.medium,
            trailingIcon: WnIcons.search,
            onPressed: onSearchTap,
          ),
          Gap(8.h),
        ],
        if (onFollowTap != null && !isOwnProfile) ...[
          WnButton(
            key: const Key('contact_button'),
            text: contactLabel,
            type: WnButtonType.outline,
            size: WnButtonSize.medium,
            loading: isFollowLoading,
            trailingIcon: isFollowing ? WnIcons.userUnfollow : WnIcons.userFollow,
            onPressed: onFollowTap,
          ),
          Gap(8.h),
        ],
        if (onAddToGroupTap != null) ...[
          WnButton(
            key: const Key('add_to_group_button'),
            text: context.l10n.addToGroup,
            type: WnButtonType.outline,
            size: WnButtonSize.medium,
            trailingIcon: WnIcons.newGroupChat,
            onPressed: onAddToGroupTap,
          ),
          Gap(8.h),
        ],
        if (onBlockTap != null) ...[
          WnButton(
            key: const Key('block_button'),
            text: isBlocked ? context.l10n.unblockUser : context.l10n.blockUser,
            type: WnButtonType.outline,
            size: WnButtonSize.medium,
            loading: isBlockLoading,
            trailingIcon: isBlocked ? WnIcons.userCheck : WnIcons.closeOutline,
            onPressed: onBlockTap,
          ),
          Gap(8.h),
        ],
        if (onArchiveTap != null) ...[
          WnButton(
            key: const Key('archive_button'),
            text: isArchived ? context.l10n.unarchive : context.l10n.archive,
            type: WnButtonType.outline,
            size: WnButtonSize.medium,
            loading: isArchiveLoading,
            trailingIcon: isArchived ? WnIcons.unarchive : WnIcons.archive,
            onPressed: onArchiveTap,
          ),
        ],
      ],
    );
  }
}
