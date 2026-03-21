import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:whitenoise/hooks/use_accounts.dart';
import 'package:whitenoise/hooks/use_user_metadata.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/utils/metadata.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_profile_switcher_item.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';

class SwitchProfileScreen extends HookConsumerWidget {
  const SwitchProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final typography = context.typographyScaled;
    final currentPubkey = ref.watch(authProvider).value;
    final (:accounts, :state, :switchTo) = useAccounts(context, ref, currentPubkey);

    if (accounts.connectionState == ConnectionState.waiting) {
      return Scaffold(
        backgroundColor: colors.backgroundPrimary,
        body: SafeArea(
          child: WnSlate(
            header: WnSlateNavigationHeader(
              title: context.l10n.profilesTitle,
              onNavigate: () => Routes.goBack(context),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: colors.backgroundContentPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final accountsList = accounts.data ?? [];

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: SafeArea(
        child: WnSlate(
          header: WnSlateNavigationHeader(
            title: context.l10n.profilesTitle,
            onNavigate: () => Routes.goBack(context),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (state.error != null) ...[
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Text(
                      state.error!,
                      style: typography.medium14.copyWith(
                        color: colors.fillDestructive,
                      ),
                    ),
                  ),
                  Gap(12.h),
                ],
                Expanded(
                  child: accountsList.isEmpty
                      ? Center(
                          child: Text(
                            context.l10n.noAccountsAvailable,
                            style: typography.medium16.copyWith(
                              color: colors.backgroundContentSecondary,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: accountsList.length,
                          separatorBuilder: (context, index) => Gap(8.h),
                          itemBuilder: (context, index) {
                            final account = accountsList[index];
                            final isCurrentAccount = account.pubkey == currentPubkey;

                            return _AccountTile(
                              pubkey: account.pubkey,
                              isCurrent: isCurrentAccount,
                              isSwitching: state.isSwitching,
                              onTap: () => switchTo(account.pubkey),
                            );
                          },
                        ),
                ),
                Gap(16.h),
                SizedBox(
                  width: double.infinity,
                  child: WnButton(
                    text: context.l10n.connectAnotherProfile,
                    onPressed: () => Routes.pushToAddProfile(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountTile extends HookConsumerWidget {
  const _AccountTile({
    required this.pubkey,
    required this.isCurrent,
    required this.isSwitching,
    required this.onTap,
  });

  final String pubkey;
  final bool isCurrent;
  final bool isSwitching;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metadataSnapshot = useUserMetadata(context, pubkey);
    final metadata = metadataSnapshot.data;
    final displayName = presentName(metadata) ?? context.l10n.noName;

    return WnProfileSwitcherItem(
      pubkey: pubkey,
      displayName: displayName,
      pictureUrl: metadata?.picture,
      isSelected: isCurrent,
      onTap: isSwitching ? () {} : onTap,
    );
  }
}
