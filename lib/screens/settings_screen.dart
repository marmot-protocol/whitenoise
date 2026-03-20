import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:whitenoise/hooks/use_support_chat.dart';
import 'package:whitenoise/hooks/use_user_metadata.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/providers/app_version_provider.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/utils/formatting.dart';
import 'package:whitenoise/utils/metadata.dart';
import 'package:whitenoise/widgets/wn_avatar.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_icon.dart';
import 'package:whitenoise/widgets/wn_menu.dart';
import 'package:whitenoise/widgets/wn_menu_item.dart';
import 'package:whitenoise/widgets/wn_separator.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';

class SettingsScreen extends HookConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final typography = context.typographyScaled;
    final pubkey = ref.watch(authProvider).value;
    final helpState = useSupportChat(accountPubkey: pubkey);
    final metadataSnapshot = useUserMetadata(context, pubkey);
    final appVersion = ref.watch(appVersionProvider);

    if (pubkey == null) {
      return const SizedBox.shrink();
    }

    final metadata = metadataSnapshot.data;
    final displayName = presentName(metadata);

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: SafeArea(
        child: WnSlate(
          showTopScrollEffect: true,
          showBottomScrollEffect: true,
          header: WnSlateNavigationHeader(
            title: context.l10n.settings,
            onNavigate: () => Routes.goBack(context),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
            child: Column(
              spacing: 16.h,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  spacing: 8.w,
                  children: [
                    WnAvatar(
                      pictureUrl: metadata?.picture,
                      displayName: displayName,
                      size: WnAvatarSize.medium,
                      color: AvatarColor.fromPubkey(pubkey),
                    ),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName ?? context.l10n.noName,
                            style: typography.medium16.copyWith(
                              color: colors.backgroundContentPrimary,
                              letterSpacing: 0.2.sp,
                            ),
                          ),
                          Text(
                            formatPublicKey(
                              npubFromHex(pubkey) ?? pubkey,
                            ),
                            maxLines: 2,
                            style: typography.medium12.copyWith(
                              color: colors.backgroundContentSecondary,
                              letterSpacing: 0.6.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Column(
                  spacing: 8.h,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: WnButton(
                        key: const Key('share_and_connect_button'),
                        text: context.l10n.shareAndConnect,
                        trailingIcon: WnIcons.qrCode,
                        size: WnButtonSize.medium,
                        onPressed: () => Routes.pushToShareProfile(context),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: WnButton(
                        text: context.l10n.switchProfile,
                        type: WnButtonType.outline,
                        trailingIcon: WnIcons.change,
                        size: WnButtonSize.medium,
                        onPressed: () => Routes.pushToSwitchProfile(context),
                      ),
                    ),
                  ],
                ),
                WnMenu(
                  children: [
                    WnMenuItem(
                      icon: WnIcons.user,
                      label: context.l10n.editProfile,
                      onTap: () => Routes.pushToEditProfile(context),
                    ),
                    WnMenuItem(
                      icon: WnIcons.key,
                      label: context.l10n.profileKeys,
                      onTap: () => Routes.pushToProfileKeys(context),
                    ),
                    WnMenuItem(
                      icon: WnIcons.network,
                      label: context.l10n.networkRelays,
                      onTap: () => Routes.pushToNetwork(context),
                    ),
                    WnMenuItem(
                      icon: WnIcons.privacy,
                      label: context.l10n.privacySecurity,
                      onTap: () => Routes.pushToPrivacySecurity(context),
                    ),
                    WnMenuItem(
                      icon: WnIcons.appearance,
                      label: context.l10n.appearance,
                      onTap: () => Routes.pushToAppearance(context),
                    ),
                    WnMenuItem(
                      key: const Key('help_and_support_menu_item'),
                      icon: WnIcons.helpChat,
                      label: context.l10n.chatWithSupport,
                      onTap: () {
                        if (helpState.isLoading) return;
                        final groupId = helpState.existingGroupId;
                        if (groupId != null) {
                          Routes.goToChat(context, groupId);
                        } else {
                          Routes.pushToStartSupportChat(context);
                        }
                      },
                    ),
                    WnMenuItem(
                      icon: WnIcons.logout,
                      label: context.l10n.signOut,
                      onTap: () => Routes.pushToSignOut(context),
                    ),
                  ],
                ),
                const WnSeparator(),
                WnMenu(
                  children: [
                    WnMenuItem(
                      icon: WnIcons.flag,
                      label: context.l10n.reportBug,
                      type: WnMenuItemType.secondary,
                      onTap: () => Routes.pushToReportBug(context),
                    ),
                    WnMenuItem(
                      icon: WnIcons.heart,
                      label: context.l10n.donate,
                      type: WnMenuItemType.secondary,
                      onTap: () => Routes.pushToDonate(context),
                    ),
                    WnMenuItem(
                      icon: WnIcons.developerSettings,
                      label: context.l10n.developerSettings,
                      type: WnMenuItemType.secondary,
                      onTap: () => Routes.pushToDeveloperSettings(context),
                    ),
                  ],
                ),
                if (appVersion.value != null)
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      key: const Key('app_version_text'),
                      'v${appVersion.value}',
                      textAlign: TextAlign.center,
                      style: typography.medium12.copyWith(
                        color: colors.backgroundContentSecondary,
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
}
