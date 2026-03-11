import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:whitenoise/hooks/use_follow_actions.dart';
import 'package:whitenoise/hooks/use_system_notice.dart';
import 'package:whitenoise/hooks/use_user_metadata.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/providers/account_pubkey_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/widgets/wn_chat_info_actions.dart';
import 'package:whitenoise/widgets/wn_chat_info_profile_card.dart';
import 'package:whitenoise/widgets/wn_overlay.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart' show WnSystemNotice;

class ChatInfoScreen extends HookConsumerWidget {
  const ChatInfoScreen({super.key, required this.userPubkey, this.showSearch = true});

  final String userPubkey;
  final bool showSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountPubkey = ref.watch(accountPubkeyProvider);

    final metadataSnapshot = useUserMetadata(context, userPubkey);
    final followState = useFollowActions(
      accountPubkey: accountPubkey,
      userPubkey: userPubkey,
    );
    final (:noticeMessage, :noticeType, :showErrorNotice, :showSuccessNotice, :dismissNotice) =
        useSystemNotice();

    final metadata = metadataSnapshot.data;
    final isFollowing = followState.isFollowing;
    final isOwnProfile = userPubkey == accountPubkey;

    Future<void> handleFollowAction() async {
      try {
        await followState.toggleFollow();
      } catch (_) {
        if (context.mounted) {
          showErrorNotice(context.l10n.failedToUpdateFollow);
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
                      Column(
                        children: [
                          WnChatInfoProfileCard(
                            userPubkey: userPubkey,
                            metadata: metadata,
                            onPublicKeyCopied: () =>
                                showSuccessNotice(context.l10n.publicKeyCopied),
                            onPublicKeyCopyError: () =>
                                showErrorNotice(context.l10n.publicKeyCopyError),
                          ),
                          Gap(12.h),
                          WnChatInfoActions(
                            isOwnProfile: isOwnProfile,
                            isFollowing: isFollowing,
                            isFollowLoading: followState.isActionLoading,
                            onFollowTap: handleFollowAction,
                            onSearchTap: showSearch ? () => GoRouter.of(context).pop(true) : null,
                            onAddToGroupTap: () => Routes.pushToAddToGroup(context, userPubkey),
                          ),
                        ],
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
