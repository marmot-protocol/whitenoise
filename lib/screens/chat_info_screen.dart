import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:whitenoise/hooks/use_chat_archive.dart';
import 'package:whitenoise/hooks/use_chat_profile.dart';
import 'package:whitenoise/hooks/use_follow_actions.dart';
import 'package:whitenoise/hooks/use_system_notice.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/providers/account_pubkey_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_chat_info_profile_card.dart';
import 'package:whitenoise/widgets/wn_icon.dart';
import 'package:whitenoise/widgets/wn_overlay.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart' show WnSystemNotice;

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
    final chatProfile = useChatProfile(context, accountPubkey, mlsGroupId);
    final profile = chatProfile.data;

    final peerPubkey = profile?.otherMemberPubkey;
    final hasPeerPubkey = peerPubkey != null;
    final isUnresolvedDm = profile?.isDm == true && !hasPeerPubkey;

    final followState = useFollowActions(
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
                        chatProfile: chatProfile,
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
    required this.chatProfile,
    required this.mlsGroupId,
    required this.onPublicKeyCopied,
    required this.onPublicKeyCopyError,
  });

  final AsyncSnapshot<ChatProfile> chatProfile;
  final String mlsGroupId;
  final VoidCallback onPublicKeyCopied;
  final VoidCallback onPublicKeyCopyError;

  @override
  Widget build(BuildContext context) {
    if (chatProfile.hasError) {
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

    if (!chatProfile.hasData) {
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

    final profile = chatProfile.data!;
    if (!profile.isDm) {
      return WnChatInfoProfileCard(
        userPubkey: mlsGroupId,
        displayName: profile.displayName,
        pictureUrl: profile.pictureUrl,
        avatarColor: profile.color,
        onPublicKeyCopied: onPublicKeyCopied,
        onPublicKeyCopyError: onPublicKeyCopyError,
      );
    }

    final peer = profile.otherMemberPubkey;
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
      displayName: profile.displayName,
      pictureUrl: profile.pictureUrl,
      avatarColor: profile.color,
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
  final bool isArchived;
  final bool isArchiveLoading;
  final VoidCallback? onArchiveTap;

  @override
  Widget build(BuildContext context) {
    final contactLabel = isFollowing ? context.l10n.removeAsContact : context.l10n.addAsContact;

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
        if (onAddToGroupTap != null)
          WnButton(
            key: const Key('add_to_group_button'),
            text: context.l10n.addToGroup,
            type: WnButtonType.outline,
            size: WnButtonSize.medium,
            trailingIcon: WnIcons.newGroupChat,
            onPressed: onAddToGroupTap,
          ),
        if (onArchiveTap != null) ...[
          Gap(8.h),
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
