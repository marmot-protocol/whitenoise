import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/hooks/use_system_notice.dart';
import 'package:whitenoise/hooks/use_user_search.dart';
import 'package:whitenoise/hooks/use_user_selection.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/providers/account_pubkey_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/src/rust/api/groups.dart' as groups_api;
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/utils/avatar_color.dart';
import 'package:whitenoise/utils/formatting.dart' show formatPublicKey, npubFromHex;
import 'package:whitenoise/utils/metadata.dart' show presentName;
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_fade_overlay.dart';
import 'package:whitenoise/widgets/wn_icon.dart';
import 'package:whitenoise/widgets/wn_search_field.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart';
import 'package:whitenoise/widgets/wn_user_bubble.dart';
import 'package:whitenoise/widgets/wn_user_item.dart';

final _logger = Logger('AddGroupMembersScreen');

class AddGroupMembersScreen extends HookConsumerWidget {
  const AddGroupMembersScreen({
    super.key,
    required this.groupId,
    required this.existingMemberPubkeys,
  });

  final String groupId;
  final List<String> existingMemberPubkeys;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final typography = context.typographyScaled;
    final accountPubkey = ref.watch(accountPubkeyProvider);
    final searchController = useTextEditingController();
    final searchQuery = useState('');
    final isSubmitting = useState(false);

    final searchState = useUserSearch(
      accountPubkey: accountPubkey,
      searchQuery: searchQuery.value,
    );

    final selectionHook = useUserSelection();

    final (:noticeMessage, :noticeType, :showErrorNotice, :showSuccessNotice, :dismissNotice) =
        useSystemNotice();

    final existingMembersSet = useMemoized(
      () => existingMemberPubkeys.toSet(),
      [existingMemberPubkeys],
    );

    final candidates = searchState.users
        .where((user) => !existingMembersSet.contains(user.pubkey))
        .toList();

    Future<void> handleSubmit() async {
      if (isSubmitting.value) return;
      final selected = selectionHook.state.selectedUsers;
      if (selected.isEmpty) return;

      isSubmitting.value = true;
      try {
        await groups_api.addMembersToGroup(
          pubkey: accountPubkey,
          groupId: groupId,
          memberPubkeys: selected.map((u) => u.pubkey).toList(),
        );
        if (context.mounted) {
          Routes.goBack(context);
        }
      } catch (e) {
        _logger.severe('Failed to add members to group: $e');
        if (context.mounted) {
          showErrorNotice(context.l10n.failedToAddMembers);
        }
      } finally {
        if (context.mounted) {
          isSubmitting.value = false;
        }
      }
    }

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: SafeArea(
        child: WnSlate(
          header: WnSlateNavigationHeader(
            title: context.l10n.addMembers,
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
          footer: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: SizedBox(
              width: double.infinity,
              child: WnButton(
                key: const Key('add_members_submit_button'),
                text: context.l10n.addMembers,
                size: WnButtonSize.medium,
                trailingIcon: WnIcons.userFollow,
                loading: isSubmitting.value,
                onPressed: selectionHook.state.selectedCount > 0 ? handleSubmit : null,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                child: WnSearchField(
                  key: const Key('add_members_search_field'),
                  placeholder: context.l10n.searchByNameOrNpub,
                  controller: searchController,
                  onChanged: (value) => searchQuery.value = value,
                  onScan: () => Routes.pushToScanNpub(context),
                  isLoading: searchState.isSearching,
                ),
              ),
              if (selectionHook.state.selectedCount > 0) ...[
                Gap(12.h),
                SizedBox(
                  height: 28.h,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14.w),
                    child: ListView.separated(
                      key: const Key('add_members_selected_bubbles'),
                      scrollDirection: Axis.horizontal,
                      itemCount: selectionHook.state.selectedUsers.length,
                      separatorBuilder: (_, _) => Gap(6.w),
                      itemBuilder: (context, index) {
                        final user = selectionHook.state.selectedUsers[index];
                        final displayName = presentName(user.metadata);
                        final formattedPubKey = formatPublicKey(
                          npubFromHex(user.pubkey) ?? user.pubkey,
                        );
                        return WnUserBubble(
                          key: Key('add_members_bubble_${user.pubkey}'),
                          displayName: displayName ?? formattedPubKey,
                          pictureUrl: user.metadata.picture,
                          avatarColor: AvatarColor.fromPubkey(user.pubkey),
                          onTap: () => selectionHook.actions.toggleUser(user),
                        );
                      },
                    ),
                  ),
                ),
                Gap(12.h),
              ],
              Expanded(
                child: searchState.isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: colors.backgroundContentPrimary,
                          strokeCap: StrokeCap.round,
                        ),
                      )
                    : candidates.isEmpty
                    ? Center(
                        child: Text(
                          searchState.hasSearchQuery
                              ? context.l10n.noResults
                              : context.l10n.noFollowsYet,
                          style: typography.medium14.copyWith(
                            color: colors.backgroundContentTertiary,
                          ),
                        ),
                      )
                    : Stack(
                        children: [
                          ListView.builder(
                            padding: EdgeInsets.only(top: 4.h),
                            itemCount: candidates.length,
                            itemBuilder: (context, index) {
                              final user = candidates[index];
                              final displayName = presentName(user.metadata);
                              final formattedPubKey = formatPublicKey(
                                npubFromHex(user.pubkey) ?? user.pubkey,
                              );
                              final isSelected = selectionHook.state.isSelected(user);
                              return WnUserItem(
                                key: Key('add_members_user_${user.pubkey}'),
                                displayName: displayName ?? formattedPubKey,
                                npub: formattedPubKey,
                                pictureUrl: user.metadata.picture,
                                avatarColor: AvatarColor.fromPubkey(user.pubkey),
                                size: WnUserItemSize.medium,
                                showCheckbox: true,
                                isSelected: isSelected,
                                onTap: () => selectionHook.actions.toggleUser(user),
                              );
                            },
                          ),
                          WnFadeOverlay.top(color: colors.backgroundSecondary),
                          WnFadeOverlay.bottom(color: colors.backgroundSecondary),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
