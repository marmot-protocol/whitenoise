import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:whitenoise/hooks/use_user_search.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/providers/account_pubkey_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/utils/formatting.dart' show formatPublicKey, npubFromHex;
import 'package:whitenoise/utils/metadata.dart' show presentName;
import 'package:whitenoise/widgets/wn_avatar.dart';
import 'package:whitenoise/widgets/wn_fade_overlay.dart';
import 'package:whitenoise/widgets/wn_icon.dart';
import 'package:whitenoise/widgets/wn_menu_item.dart';
import 'package:whitenoise/widgets/wn_search_field.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';
import 'package:whitenoise/widgets/wn_user_item.dart';

class UserSearchScreen extends HookConsumerWidget {
  const UserSearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final typography = context.typographyScaled;
    final accountPubkey = ref.watch(accountPubkeyProvider);
    final searchController = useTextEditingController();
    final searchQuery = useState('');

    final state = useUserSearch(
      accountPubkey: accountPubkey,
      searchQuery: searchQuery.value,
    );

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: SafeArea(
        child: WnSlate(
          header: WnSlateNavigationHeader(
            title: context.l10n.startNewChat,
            onNavigate: () => Routes.goBack(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Gap(16.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                child: WnSearchField(
                  placeholder: context.l10n.searchByNameOrNpub,
                  controller: searchController,
                  onChanged: (value) => searchQuery.value = value,
                  onScan: () => Routes.pushToScanNpub(context),
                  isLoading: state.isSearching,
                ),
              ),
              Gap(12.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                child: Column(
                  children: [
                    WnMenuItem(
                      key: const Key('create_group_menu_item'),
                      label: context.l10n.newGroupChat,
                      icon: WnIcons.newGroupChat,
                      onTap: () => Routes.pushToUserSelection(context),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: state.isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: colors.backgroundContentPrimary,
                          strokeCap: StrokeCap.round,
                        ),
                      )
                    : state.users.isEmpty
                    ? Center(
                        child: Text(
                          state.hasSearchQuery ? context.l10n.noResults : context.l10n.noFollowsYet,
                          style: typography.medium14.copyWith(
                            color: colors.backgroundContentTertiary,
                          ),
                        ),
                      )
                    : Stack(
                        children: [
                          ListView.builder(
                            padding: EdgeInsets.only(top: 4.h),
                            itemCount: state.users.length,
                            itemBuilder: (context, index) {
                              final user = state.users[index];
                              final displayName = presentName(user.metadata);
                              final formattedPubKey = formatPublicKey(
                                npubFromHex(user.pubkey) ?? user.pubkey,
                              );
                              return WnUserItem(
                                displayName: displayName ?? formattedPubKey,
                                npub: formattedPubKey,
                                pictureUrl: user.metadata.picture,
                                avatarColor: AvatarColor.fromPubkey(user.pubkey),
                                size: WnUserItemSize.big,
                                onTap: () => Routes.pushToStartChat(
                                  context,
                                  user.pubkey,
                                ),
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
