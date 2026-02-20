import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/hooks/use_follow_actions.dart';
import 'package:whitenoise/hooks/use_system_notice.dart';
import 'package:whitenoise/hooks/use_user_has_key_package.dart';
import 'package:whitenoise/hooks/use_user_metadata.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/providers/account_pubkey_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/src/rust/api/groups.dart' as groups_api;
import 'package:whitenoise/src/rust/api/metadata.dart' show FlutterMetadata;
import 'package:whitenoise/src/rust/api/users.dart' show KeyPackageStatus;
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/utils/metadata.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_callout.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart' show WnSystemNotice;
import 'package:whitenoise/widgets/wn_user_profile_card.dart';

final _logger = Logger('StartChatScreen');

class StartChatScreen extends HookConsumerWidget {
  const StartChatScreen({super.key, required this.userPubkey, this.initialMetadata});

  final String userPubkey;
  final FlutterMetadata? initialMetadata;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final accountPubkey = ref.watch(accountPubkeyProvider);

    final metadataSnapshot = useUserMetadata(context, userPubkey);
    final keyPackageSnapshot = useUserHasKeyPackage(userPubkey);
    final isStartingChat = useState(false);
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

    final fetchedMetadata = metadataSnapshot.data;
    final hasContent = fetchedMetadata != null && presentName(fetchedMetadata) != null;
    final metadata = hasContent ? fetchedMetadata : (initialMetadata ?? fetchedMetadata);
    final isLoading =
        metadataSnapshot.connectionState == ConnectionState.waiting ||
        keyPackageSnapshot.connectionState == ConnectionState.waiting ||
        followState.isLoading;
    final isFollowing = followState.isFollowing;
    final keyPackageStatus = keyPackageSnapshot.data;

    Future<void> startChat() async {
      isStartingChat.value = true;

      try {
        final group = await groups_api.createGroup(
          creatorPubkey: accountPubkey,
          memberPubkeys: [userPubkey],
          adminPubkeys: [accountPubkey],
          groupName: '',
          groupDescription: '',
          groupType: groups_api.GroupType.directMessage,
        );

        if (context.mounted) {
          Routes.goToChat(context, group.mlsGroupId);
        }
      } catch (e) {
        _logger.severe('Failed to start chat: $e');
        if (context.mounted) {
          showErrorNotice(context.l10n.failedToStartChat);
        }
      } finally {
        if (context.mounted) {
          isStartingChat.value = false;
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

    ({String title, String description}) calloutTitleAndDescription() {
      final name = presentName(metadata);
      if (keyPackageStatus == KeyPackageStatus.incompatible) {
        return (
          title: context.l10n.userNeedsUpdate,
          description: name != null
              ? context.l10n.userNeedsUpdateDescription(name)
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

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: GestureDetector(
        key: const Key('start_chat_background'),
        onTap: () => Routes.goBack(context),
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              WnSlate(
                header: WnSlateNavigationHeader(
                  title: context.l10n.startNewChat,
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
                  padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (isLoading)
                        Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40.h),
                            child: CircularProgressIndicator(
                              color: colors.backgroundContentPrimary,
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                        )
                      else ...[
                        WnUserProfileCard(
                          userPubkey: userPubkey,
                          metadata: metadata,
                          onPublicKeyCopied: () => showSuccessNotice(context.l10n.publicKeyCopied),
                          onPublicKeyCopyError: () =>
                              showErrorNotice(context.l10n.publicKeyCopyError),
                        ),
                        Gap(24.h),
                        if (keyPackageStatus == KeyPackageStatus.valid) ...[
                          SizedBox(
                            width: double.infinity,
                            child: WnButton(
                              key: const Key('follow_button'),
                              text: isFollowing ? context.l10n.unfollow : context.l10n.follow,
                              type: WnButtonType.outline,
                              loading: followState.isActionLoading,
                              onPressed: handleFollowAction,
                            ),
                          ),
                          Gap(8.h),
                          SizedBox(
                            width: double.infinity,
                            child: WnButton(
                              key: const Key('start_chat_button'),
                              text: context.l10n.startChat,
                              loading: isStartingChat.value,
                              onPressed: startChat,
                            ),
                          ),
                        ] else ...[
                          () {
                            final callout = calloutTitleAndDescription();
                            return WnCallout(
                              title: callout.title,
                              description: callout.description,
                              type: CalloutType.info,
                            );
                          }(),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
