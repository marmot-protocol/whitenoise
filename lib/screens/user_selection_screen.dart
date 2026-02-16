import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:whitenoise/hooks/use_user_search.dart';
import 'package:whitenoise/hooks/use_user_selection.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/providers/account_pubkey_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/src/rust/api/users.dart' show User;
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/utils/formatting.dart' show formatPublicKey, npubFromHex;
import 'package:whitenoise/utils/metadata.dart' show presentName;
import 'package:whitenoise/widgets/wn_avatar.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_fade_overlay.dart';
import 'package:whitenoise/widgets/wn_middle_ellipsis_text.dart';
import 'package:whitenoise/widgets/wn_search_field.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';

class UserSelectionScreen extends HookConsumerWidget {
  const UserSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final typography = context.typographyScaled;
    final accountPubkey = ref.watch(accountPubkeyProvider);
    final searchController = useTextEditingController();
    final searchQuery = useState('');

    final searchState = useUserSearch(
      accountPubkey: accountPubkey,
      searchQuery: searchQuery.value,
    );

    final selectionHook = useUserSelection();

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          child: WnSlate(
            header: WnSlateNavigationHeader(
              title: context.l10n.selectMembers,
              onNavigate: () => Routes.goBack(context),
            ),
            footer: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              child: SizedBox(
                width: double.infinity,
                child: WnButton(
                  onPressed: selectionHook.state.selectedCount > 0
                      ? () => Routes.pushToGroupDetails(
                          context,
                          selectionHook.state.selectedUsers,
                        )
                      : null,
                  text: context.l10n.continueButton,
                  size: WnButtonSize.medium,
                ),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Gap(16.h),
                  WnSearchField(
                    placeholder: context.l10n.searchByNameOrNpub,
                    controller: searchController,
                    onChanged: (value) => searchQuery.value = value,
                    onScan: () => Routes.pushToScanNpub(context),
                    isLoading: searchState.isSearching,
                  ),
                  if (selectionHook.state.selectedCount > 0) ...[
                    Gap(16.h),
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: colors.backgroundSecondary,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              context.l10n.selectedCount(selectionHook.state.selectedCount),
                              style: typography.medium14.copyWith(
                                color: colors.backgroundContentPrimary,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: selectionHook.actions.clearSelection,
                            child: Text(
                              context.l10n.clearSelection,
                              style: typography.medium14.copyWith(
                                color: colors.fillPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  Expanded(
                    child: searchState.isLoading
                        ? Center(
                            child: CircularProgressIndicator(
                              color: colors.backgroundContentPrimary,
                              strokeCap: StrokeCap.round,
                            ),
                          )
                        : searchState.users.isEmpty
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
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                itemCount: searchState.users.length,
                                itemBuilder: (context, index) {
                                  final user = searchState.users[index];
                                  final isSelected = selectionHook.state.isSelected(user);
                                  return _UserSelectionTile(
                                    key: Key(user.pubkey),
                                    user: user,
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
        ),
      ),
    );
  }
}

class _UserSelectionTile extends StatelessWidget {
  const _UserSelectionTile({
    super.key,
    required this.user,
    required this.isSelected,
    required this.onTap,
  });

  final User user;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typographyScaled;
    final displayName = presentName(user.metadata);
    final formattedPubKey = formatPublicKey(npubFromHex(user.pubkey) ?? user.pubkey);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
        margin: EdgeInsets.only(bottom: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? colors.backgroundSecondary : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            WnAvatar(
              size: WnAvatarSize.medium,
              pictureUrl: user.metadata.picture,
              displayName: displayName,
              color: AvatarColor.fromPubkey(user.pubkey),
            ),
            Gap(12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (displayName != null)
                    Text(
                      displayName,
                      style: typography.medium16.copyWith(
                        color: colors.backgroundContentPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    )
                  else
                    WnMiddleEllipsisText(
                      text: formattedPubKey,
                      style: typography.medium16.copyWith(
                        color: colors.backgroundContentPrimary,
                      ),
                    ),
                  Gap(4.h),
                  WnMiddleEllipsisText(
                    text: formattedPubKey,
                    style: typography.medium12.copyWith(
                      color: colors.backgroundContentSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Gap(12.w),
            Container(
              width: 24.w,
              height: 24.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? colors.fillPrimary : colors.backgroundContentTertiary,
                  width: 2.w,
                ),
                color: isSelected ? colors.fillPrimary : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      size: 16.sp,
                      color: colors.backgroundPrimary,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
