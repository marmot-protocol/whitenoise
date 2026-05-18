import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:whitenoise/hooks/use_blocked_pubkeys.dart';
import 'package:whitenoise/hooks/use_route_refresh.dart';
import 'package:whitenoise/hooks/use_user_metadata.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/providers/account_pubkey_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/utils/avatar_color.dart';
import 'package:whitenoise/utils/formatting.dart';
import 'package:whitenoise/utils/metadata.dart' show presentName;
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';
import 'package:whitenoise/widgets/wn_user_item.dart';

class BlockedUsersScreen extends HookConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final typography = context.typographyScaled;
    final accountPubkey = ref.watch(accountPubkeyProvider);
    final blocked = useBlockedPubkeys(accountPubkey);

    useRouteRefresh(context, blocked.refresh);

    final sortedPubkeys = blocked.blockedPubkeys.toList()..sort();

    Widget body;
    if (blocked.isLoading) {
      body = Center(
        key: const Key('blocked_users_loading'),
        child: CircularProgressIndicator(
          color: colors.backgroundContentPrimary,
        ),
      );
    } else if (blocked.error != null) {
      body = Center(
        child: Text(
          context.l10n.failedToFetchBlockedUsers,
          key: const Key('blocked_users_error'),
          style: typography.medium16.copyWith(
            color: colors.backgroundContentSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      );
    } else if (sortedPubkeys.isEmpty) {
      body = Center(
        child: Text(
          context.l10n.blockedUsersEmpty,
          key: const Key('blocked_users_empty'),
          style: typography.medium16.copyWith(
            color: colors.backgroundContentSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      );
    } else {
      body = ListView.separated(
        key: const Key('blocked_users_list'),
        padding: EdgeInsets.zero,
        itemCount: sortedPubkeys.length,
        separatorBuilder: (context, index) => Gap(8.h),
        itemBuilder: (context, index) => _BlockedUserTile(
          pubkey: sortedPubkeys[index],
          onTap: () => Routes.pushToBlockedUser(context, sortedPubkeys[index]),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: SafeArea(
        child: WnSlate(
          tag: 'blocked-users-list-slate',
          header: WnSlateNavigationHeader(
            title: context.l10n.blockedUsers,
            onNavigate: () => Routes.goBack(context),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
            child: body,
          ),
        ),
      ),
    );
  }
}

class _BlockedUserTile extends HookWidget {
  const _BlockedUserTile({
    required this.pubkey,
    required this.onTap,
  });

  final String pubkey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final metadataSnapshot = useUserMetadata(context, pubkey);
    final metadata = metadataSnapshot.data;
    final displayName = presentName(metadata) ?? pubkey.substring(0, 8);
    final npub = npubFromHex(pubkey);

    return WnUserItem(
      key: Key('blocked_user_tile_$pubkey'),
      displayName: displayName,
      npub: npub,
      pictureUrl: metadata?.picture,
      avatarColor: AvatarColor.fromPubkey(pubkey),
      size: WnUserItemSize.medium,
      onTap: onTap,
    );
  }
}
