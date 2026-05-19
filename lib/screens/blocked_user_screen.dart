import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:whitenoise/hooks/use_block_actions.dart';
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
    final systemNotice = useSystemNotice();
    final isBannerCollapsed = useState(false);

    Future<void> handleUnblock() async {
      try {
        await blockState.toggleBlock();
        if (!context.mounted) return;
        Routes.goBack(context);
      } catch (_) {
        if (context.mounted) {
          systemNotice.showErrorNotice(context.l10n.failedToUnblockUser);
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
                    WnSystemNotice(
                      key: const Key('blocked_user_detail_notice'),
                      title: context.l10n.userIsBlocked,
                      description: Text(
                        context.l10n.blockedUserDetailDescription,
                        style: typography.medium14.copyWith(
                          color: colors.backgroundContentSecondary,
                        ),
                      ),
                      type: WnSystemNoticeType.neutral,
                      variant: isBannerCollapsed.value
                          ? WnSystemNoticeVariant.collapsed
                          : WnSystemNoticeVariant.expanded,
                      animateEntrance: false,
                      onToggle: () => isBannerCollapsed.value = !isBannerCollapsed.value,
                      primaryAction: WnButton(
                        key: const Key('blocked_user_unblock_button'),
                        text: context.l10n.unblockUser,
                        type: WnButtonType.outline,
                        size: WnButtonSize.medium,
                        loading: blockState.isActionLoading,
                        disabled: blockState.isLoading || blockState.isActionLoading,
                        trailingIcon: WnIcons.userCheck,
                        onPressed: handleUnblock,
                      ),
                    ),
                    Gap(16.h),
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
