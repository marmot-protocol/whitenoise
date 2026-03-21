import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart' show useEffect, useFuture, useMemoized, useState;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:whitenoise/hooks/use_group_members.dart';
import 'package:whitenoise/hooks/use_route_refresh.dart';
import 'package:whitenoise/hooks/use_system_notice.dart';
import 'package:whitenoise/hooks/use_user_metadata.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/providers/account_pubkey_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/src/rust/api/groups.dart' as groups_api;
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/utils/avatar_color.dart';
import 'package:whitenoise/utils/metadata.dart' show presentName;
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_group_info_card.dart';
import 'package:whitenoise/widgets/wn_icon.dart';
import 'package:whitenoise/widgets/wn_overlay.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart';
import 'package:whitenoise/widgets/wn_user_item.dart';

class GroupInfoScreen extends HookConsumerWidget {
  const GroupInfoScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final typography = context.typographyScaled;
    final accountPubkey = ref.watch(accountPubkeyProvider);

    final refreshKey = useState(0);

    useRouteRefresh(context, () => refreshKey.value++);

    final membersState = useGroupMembers(
      accountPubkey: accountPubkey,
      groupId: groupId,
      refreshKey: refreshKey.value,
    );

    final (:noticeMessage, :noticeType, :showErrorNotice, :showSuccessNotice, :dismissNotice) =
        useSystemNotice();

    useEffect(() {
      if (membersState.error != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            showErrorNotice(context.l10n.failedToFetchGroupMembers);
          }
        });
        membersState.clearError();
      }
      return null;
    }, [membersState.error]);

    final groupFuture = useMemoized(
      () => groups_api.getGroup(accountPubkey: accountPubkey, groupId: groupId),
      [accountPubkey, groupId, refreshKey.value],
    );
    final groupSnapshot = useFuture(groupFuture);

    final imageFuture = useMemoized(
      () => groups_api.getGroupImagePath(accountPubkey: accountPubkey, groupId: groupId),
      [accountPubkey, groupId, refreshKey.value],
    );
    final imageSnapshot = useFuture(imageFuture);

    final group = groupSnapshot.data;
    final isAdmin = membersState.admins.contains(accountPubkey);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const WnOverlay(variant: WnOverlayVariant.light),
          SafeArea(
            child: WnSlate(
              showTopScrollEffect: true,
              header: WnSlateNavigationHeader(
                title: context.l10n.groupInformation,
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
                    WnGroupInfoCard(
                      groupId: groupId,
                      name: group?.name,
                      description: group?.description,
                      imagePath: imageSnapshot.data,
                    ),
                    Gap(16.h),
                    if (isAdmin) ...[
                      SizedBox(
                        width: double.infinity,
                        child: WnButton(
                          key: const Key('edit_group_button'),
                          text: context.l10n.editGroupAction,
                          trailingIcon: WnIcons.editSettings,
                          size: WnButtonSize.medium,
                          onPressed: () => Routes.pushToEditGroup(context, groupId),
                        ),
                      ),
                      Gap(16.h),
                    ],
                    Text(
                      context.l10n.membersLabel,
                      key: const Key('members_label'),
                      style: typography.medium16.copyWith(
                        color: colors.backgroundContentSecondary,
                      ),
                    ),
                    Gap(16.h),
                    ...membersState.members.map(
                      (pubkey) => Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: _GroupMemberItem(
                          key: Key('member_$pubkey'),
                          pubkey: pubkey,
                          isAdmin: membersState.admins.contains(pubkey),
                          groupId: groupId,
                        ),
                      ),
                    ),
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

class _GroupMemberItem extends HookConsumerWidget {
  const _GroupMemberItem({
    super.key,
    required this.pubkey,
    required this.isAdmin,
    required this.groupId,
  });

  final String pubkey;
  final bool isAdmin;
  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metadataSnapshot = useUserMetadata(context, pubkey);
    final metadata = metadataSnapshot.data;
    final displayName = presentName(metadata) ?? pubkey.substring(0, 8);

    return WnUserItem(
      displayName: displayName,
      label: isAdmin ? context.l10n.adminBadge : null,
      pictureUrl: metadata?.picture,
      avatarColor: AvatarColor.fromPubkey(pubkey),
      onTap: () => Routes.pushToGroupMember(context, groupId, pubkey),
    );
  }
}
