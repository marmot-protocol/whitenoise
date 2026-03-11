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
import 'package:whitenoise/widgets/wn_icon.dart';
import 'package:whitenoise/widgets/wn_search_field.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';
import 'package:whitenoise/widgets/wn_user_bubble.dart';
import 'package:whitenoise/widgets/wn_user_item.dart';

class UserSelectionScreen extends HookConsumerWidget {
  const UserSelectionScreen({super.key, this.initialUsers = const []});

  final List<User> initialUsers;

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

    final selectionHook = useUserSelection(initialUsers: initialUsers);

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: SafeArea(
        child: WnSlate(
          header: WnSlateNavigationHeader(
            title: context.l10n.newGroupChat,
            onNavigate: () => Routes.goBack(context),
          ),
          footer: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: SizedBox(
              width: double.infinity,
              child: WnButton(
                onPressed: selectionHook.state.selectedCount > 0
                    ? () => Routes.pushToSetUpGroup(
                        context,
                        selectionHook.state.selectedUsers,
                      )
                    : null,
                text: context.l10n.continueButton,
                size: WnButtonSize.medium,
                trailingIcon: WnIcons.arrowRight,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                child: WnSearchField(
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
                      key: const Key('selected_users_bubbles'),
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
                          key: Key('bubble_${user.pubkey}'),
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
                            padding: EdgeInsets.only(top: 4.h),
                            itemCount: searchState.users.length,
                            itemBuilder: (context, index) {
                              final user = searchState.users[index];
                              final displayName = presentName(user.metadata);
                              final formattedPubKey = formatPublicKey(
                                npubFromHex(user.pubkey) ?? user.pubkey,
                              );
                              final isSelected = selectionHook.state.isSelected(user);
                              return WnUserItem(
                                key: Key(user.pubkey),
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
