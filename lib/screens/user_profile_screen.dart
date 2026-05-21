import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:share_plus/share_plus.dart';
import 'package:whitenoise/hooks/use_block_actions.dart';
import 'package:whitenoise/hooks/use_follow_actions.dart';
import 'package:whitenoise/hooks/use_start_dm.dart';
import 'package:whitenoise/hooks/use_system_notice.dart';
import 'package:whitenoise/hooks/use_user_has_key_package.dart';
import 'package:whitenoise/hooks/use_user_metadata.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/providers/account_pubkey_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/src/rust/api/users.dart' show KeyPackageStatus;
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/utils/logging.dart';
import 'package:whitenoise/utils/metadata.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_callout.dart';
import 'package:whitenoise/widgets/wn_icon.dart';
import 'package:whitenoise/widgets/wn_overlay.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart';
import 'package:whitenoise/widgets/wn_user_profile_card.dart';

final _logger = Logger('UserProfileScreen');

class UserProfileScreen extends HookConsumerWidget {
  const UserProfileScreen({
    super.key,
    required this.userPubkey,
    this.asShade = false,
    this.topAligned = false,
  });

  final String userPubkey;
  final bool asShade;
  final bool topAligned;

  static Future<void> show(BuildContext context, {required String userPubkey}) {
    FocusScope.of(context).unfocus();
    final colors = context.colors;
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: colors.backgroundPrimary.withValues(alpha: 0.8),
        pageBuilder: (_, _, _) => UserProfileScreen(userPubkey: userPubkey, asShade: true),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final typography = context.typographyScaled;
    final accountPubkey = ref.watch(accountPubkeyProvider);
    final isSelf = accountPubkey == userPubkey;

    final metadataSnapshot = useUserMetadata(context, userPubkey);
    final keyPackageSnapshot = useUserHasKeyPackage(userPubkey);
    final (
      :noticeMessage,
      :noticeType,
      :showErrorNotice,
      :showSuccessNotice,
      :dismissNotice,
    ) = useSystemNotice();

    final followState = useFollowActions(
      accountPubkey: accountPubkey,
      userPubkey: userPubkey,
    );

    final blockState = useBlockActions(
      accountPubkey: accountPubkey,
      userPubkey: userPubkey,
    );

    final dmState = useStartDm(
      accountPubkey: accountPubkey,
      peerPubkey: userPubkey,
    );

    final isBlockedNoticeCollapsed = useState(false);

    final metadata = metadataSnapshot.data;
    final isFollowing = followState.isFollowing;
    final keyPackageStatus = keyPackageSnapshot.data;
    final isKeyPackageLoading = keyPackageSnapshot.connectionState == ConnectionState.waiting;

    Future<void> startChat() async {
      if (isSelf) return;
      final stopWatch = Stopwatch()..start();
      try {
        final groupId = await dmState.startDm();
        logDuration(_logger, 'startDm took', stopWatch.elapsedMilliseconds);

        if (context.mounted) {
          Routes.goToChat(context, groupId);
        } else {
          _logger.warning('Context not mounted after DM creation. Aborting navigation.');
        }
      } catch (e, stackTrace) {
        _logger.severe(
          'Failed to start chat after ${stopWatch.elapsedMilliseconds}ms',
          e,
          stackTrace,
        );
        if (context.mounted) {
          showErrorNotice(context.l10n.failedToStartChat);
        }
      }
    }

    Future<void> handleFollowAction() async {
      if (isSelf) return;
      try {
        await followState.toggleFollow();
      } catch (_) {
        if (context.mounted) {
          showErrorNotice(context.l10n.failedToUpdateFollow);
        }
      }
    }

    Future<void> handleToggleBlock({required bool wasBlocked}) async {
      if (isSelf) return;
      try {
        await blockState.toggleBlock();
      } catch (_) {
        if (context.mounted) {
          showErrorNotice(
            wasBlocked ? context.l10n.failedToUnblockUser : context.l10n.failedToBlockUser,
          );
        }
      }
    }

    Widget validActionsColumn({bool showLoadingStates = true}) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: double.infinity,
            child: WnButton(
              key: const Key('follow_button'),
              text: isFollowing == true ? context.l10n.unfollow : context.l10n.follow,
              type: WnButtonType.outline,
              size: WnButtonSize.medium,
              trailingIcon: isFollowing == true ? WnIcons.userUnfollow : WnIcons.userFollow,
              loading: showLoadingStates && (followState.isLoading || followState.isActionLoading),
              onPressed: handleFollowAction,
            ),
          ),
          Gap(8.h),
          SizedBox(
            width: double.infinity,
            child: WnButton(
              key: const Key('add_to_group_button'),
              text: context.l10n.addToGroup,
              type: WnButtonType.outline,
              size: WnButtonSize.medium,
              trailingIcon: WnIcons.newGroupChat,
              onPressed: () => Routes.pushToAddToGroup(context, userPubkey),
            ),
          ),
          Gap(8.h),
          SizedBox(
            width: double.infinity,
            child: WnButton(
              key: const Key('block_button'),
              text: context.l10n.blockUser,
              type: WnButtonType.outline,
              size: WnButtonSize.medium,
              trailingIcon: WnIcons.closeOutline,
              loading: showLoadingStates && (blockState.isLoading || blockState.isActionLoading),
              disabled: blockState.isLoading || blockState.isActionLoading,
              onPressed: () => handleToggleBlock(wasBlocked: false),
            ),
          ),
          Gap(8.h),
          SizedBox(
            width: double.infinity,
            child: WnButton(
              key: const Key('start_chat_button'),
              text: context.l10n.sendMessage,
              size: WnButtonSize.medium,
              trailingIcon: WnIcons.newChat,
              loading: showLoadingStates && dmState.isLoading,
              onPressed: startChat,
            ),
          ),
        ],
      );
    }

    ({String title, String description}) calloutTitleAndDescription() {
      final name = presentName(metadata);
      if (keyPackageStatus == KeyPackageStatus.incompatible) {
        return (
          title: name != null
              ? context.l10n.updateNeeded(name)
              : context.l10n.unknownUserNeedsUpdate,
          description: name != null
              ? context.l10n.updateNeededDescription(name)
              : context.l10n.unknownUserNeedsUpdateDescription,
        );
      }
      return (
        title: context.l10n.inviteToWhiteNoise,
        description: name != null
            ? context.l10n.inviteToWhiteNoiseDescription(name)
            : context.l10n.unknownInviteToWhiteNoiseDescription,
      );
    }

    final isBlocked = blockState.isBlocked;

    final blockedNotice = WnSystemNotice(
      key: const Key('blocked_user_detail_notice'),
      title: context.l10n.userIsBlocked,
      description: Text(
        context.l10n.blockedUserDetailDescription,
        style: typography.medium14.copyWith(
          color: colors.backgroundContentSecondary,
        ),
      ),
      type: WnSystemNoticeType.neutral,
      backgroundColor: colors.fillSecondary,
      variant: isBlockedNoticeCollapsed.value
          ? WnSystemNoticeVariant.collapsed
          : WnSystemNoticeVariant.expanded,
      animateEntrance: false,
      onToggle: () => isBlockedNoticeCollapsed.value = !isBlockedNoticeCollapsed.value,
      primaryAction: WnButton(
        key: const Key('unblock_button'),
        text: context.l10n.unblockUser,
        type: WnButtonType.overlay,
        size: WnButtonSize.medium,
        loading: blockState.isActionLoading,
        disabled: blockState.isLoading || blockState.isActionLoading,
        trailingIcon: WnIcons.userCheck,
        onPressed: () => handleToggleBlock(wasBlocked: true),
      ),
    );

    Widget topAlignedBottomPanel() {
      if (isBlocked == true) return blockedNotice;
      if (isSelf) return const SizedBox.shrink();
      if (isKeyPackageLoading) {
        return Padding(
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Visibility(
                visible: false,
                maintainState: true,
                maintainAnimation: true,
                maintainSize: true,
                child: validActionsColumn(showLoadingStates: false),
              ),
              CircularProgressIndicator(
                color: colors.backgroundContentPrimary,
                strokeCap: StrokeCap.round,
              ),
            ],
          ),
        );
      }
      if (keyPackageStatus == KeyPackageStatus.valid) {
        return Padding(
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
          child: validActionsColumn(),
        );
      }
      final callout = calloutTitleAndDescription();
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WnCallout(
              title: callout.title,
              description: callout.description,
              type: CalloutType.info,
            ),
            if (keyPackageStatus == KeyPackageStatus.notFound || keyPackageStatus == null) ...[
              Gap(8.h),
              SizedBox(
                width: double.infinity,
                child: WnButton(
                  key: const Key('invite_button'),
                  text: context.l10n.share,
                  size: WnButtonSize.medium,
                  onPressed: () async {
                    try {
                      await SharePlus.instance.share(
                        ShareParams(text: context.l10n.inviteMessage),
                      );
                    } catch (e) {
                      _logger.severe('Failed to share invite: $e');
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      );
    }

    final Widget slateChild = topAligned
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
                child: WnUserProfileCard(
                  userPubkey: userPubkey,
                  metadata: metadata,
                  onPublicKeyCopied: () => showSuccessNotice(context.l10n.publicKeyCopied),
                  onPublicKeyCopyError: () => showErrorNotice(context.l10n.publicKeyCopyError),
                ),
              ),
              topAlignedBottomPanel(),
            ],
          )
        : SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                WnUserProfileCard(
                  userPubkey: userPubkey,
                  metadata: metadata,
                  onPublicKeyCopied: () => showSuccessNotice(context.l10n.publicKeyCopied),
                  onPublicKeyCopyError: () => showErrorNotice(context.l10n.publicKeyCopyError),
                ),
                Gap(8.h),
                if (isBlocked == true)
                  blockedNotice
                else if (isSelf)
                  ...[]
                else if (isKeyPackageLoading)
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Visibility(
                        visible: false,
                        maintainState: true,
                        maintainAnimation: true,
                        maintainSize: true,
                        child: validActionsColumn(showLoadingStates: false),
                      ),
                      CircularProgressIndicator(
                        color: colors.backgroundContentPrimary,
                        strokeCap: StrokeCap.round,
                      ),
                    ],
                  )
                else if (keyPackageStatus == KeyPackageStatus.valid)
                  validActionsColumn()
                else ...[
                  () {
                    final callout = calloutTitleAndDescription();
                    return WnCallout(
                      title: callout.title,
                      description: callout.description,
                      type: CalloutType.info,
                    );
                  }(),
                  if (keyPackageStatus == KeyPackageStatus.notFound ||
                      keyPackageStatus == null) ...[
                    Gap(8.h),
                    SizedBox(
                      width: double.infinity,
                      child: WnButton(
                        key: const Key('invite_button'),
                        text: context.l10n.share,
                        size: WnButtonSize.medium,
                        onPressed: () async {
                          try {
                            await SharePlus.instance.share(
                              ShareParams(text: context.l10n.inviteMessage),
                            );
                          } catch (e) {
                            _logger.severe('Failed to share invite: $e');
                          }
                        },
                      ),
                    ),
                  ],
                ],
              ],
            ),
          );

    final slate = WnSlate(
      shrinkWrapContent: topAligned,
      header: WnSlateNavigationHeader(
        title: context.l10n.profile,
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
      child: slateChild,
    );

    return Scaffold(
      backgroundColor: (asShade || topAligned) ? Colors.transparent : colors.backgroundPrimary,
      body: Stack(
        children: [
          if (topAligned) const WnOverlay(variant: WnOverlayVariant.light),
          GestureDetector(
            key: const Key('user_profile_background'),
            onTap: () => Routes.goBack(context),
            behavior: HitTestBehavior.opaque,
            child: SafeArea(
              child: topAligned
                  ? Align(alignment: Alignment.topCenter, child: slate)
                  : Column(children: [const Spacer(), slate]),
            ),
          ),
        ],
      ),
    );
  }
}
