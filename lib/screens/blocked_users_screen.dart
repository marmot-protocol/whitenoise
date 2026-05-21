import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:whitenoise/hooks/use_blocked_pubkeys.dart';
import 'package:whitenoise/hooks/use_route_refresh.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/providers/account_pubkey_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/services/user_service.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
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

    final pubkeysKey = Object.hashAllUnordered(blocked.blockedPubkeys);
    final sortedFuture = useMemoized(
      () => _sortByDisplayName(blocked.blockedPubkeys),
      [pubkeysKey],
    );
    final sortedSnapshot = useFuture(sortedFuture);
    final sortedEntries = sortedSnapshot.data ?? const <_BlockedUserEntry>[];

    Widget body;
    if (blocked.isLoading || sortedSnapshot.connectionState != ConnectionState.done) {
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
    } else if (sortedEntries.isEmpty) {
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
        itemCount: sortedEntries.length,
        separatorBuilder: (context, index) => Gap(8.h),
        itemBuilder: (context, index) {
          final entry = sortedEntries[index];
          return _BlockedUserTile(
            pubkey: entry.pubkey,
            metadata: entry.metadata,
            onTap: () => Routes.pushToUserProfile(
              context,
              entry.pubkey,
              topAligned: true,
            ),
          );
        },
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

typedef _BlockedUserEntry = ({String pubkey, FlutterMetadata? metadata});

Future<List<_BlockedUserEntry>> _sortByDisplayName(Set<String> pubkeys) async {
  if (pubkeys.isEmpty) return const [];
  final entries = await Future.wait(
    pubkeys.map((pubkey) async {
      FlutterMetadata? metadata;
      try {
        metadata = await UserService(pubkey).getInitialMetadata();
      } catch (_) {
        metadata = null;
      }
      final name = presentName(metadata);
      final sortKey = (name ?? npubFromHex(pubkey) ?? pubkey).toLowerCase();
      return (pubkey: pubkey, sortKey: sortKey, metadata: metadata);
    }),
  );
  entries.sort((a, b) => a.sortKey.compareTo(b.sortKey));
  return entries.map<_BlockedUserEntry>((e) => (pubkey: e.pubkey, metadata: e.metadata)).toList();
}

class _BlockedUserTile extends StatelessWidget {
  const _BlockedUserTile({
    required this.pubkey,
    required this.metadata,
    required this.onTap,
  });

  final String pubkey;
  final FlutterMetadata? metadata;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final npub = npubFromHex(pubkey);
    final displayName = presentName(metadata) ?? npub ?? pubkey.substring(0, 8);

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
