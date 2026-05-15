import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:whitenoise/hooks/use_user_metadata.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/utils/formatting.dart' show formatPublicKey, npubFromHex;
import 'package:whitenoise/utils/metadata.dart' show presentName;
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';
import 'package:whitenoise/widgets/wn_user_profile_card.dart';

class UserProfileShade extends HookConsumerWidget {
  const UserProfileShade._({required this.userPubkey});

  final String userPubkey;

  static Future<void> show(BuildContext context, {required String userPubkey}) {
    // Drop input focus so the keyboard isn't re-shown when the shade dismisses
    // — otherwise the chat list resizes on keyboard reappear and snaps to the
    // bottom. Mirrors what chat_screen does before MessageActionsScreen.show.
    FocusScope.of(context).unfocus();
    final colors = context.colors;
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: colors.backgroundPrimary.withValues(alpha: 0.8),
        pageBuilder: (_, _, _) => UserProfileShade._(userPubkey: userPubkey),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountPubkey = ref.watch(authProvider).value;
    final isSelf = accountPubkey == userPubkey;
    final metadataSnapshot = useUserMetadata(context, userPubkey);
    final metadata = metadataSnapshot.data;

    void showSnack(String message) => ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 2)));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          child: WnSlate(
            shrinkWrapContent: true,
            header: WnSlateNavigationHeader(
              title:
                  presentName(metadata) ?? formatPublicKey(npubFromHex(userPubkey) ?? userPubkey),
              onNavigate: () => Navigator.of(context).pop(),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  WnUserProfileCard(
                    userPubkey: userPubkey,
                    metadata: metadata,
                    onPublicKeyCopied: () => showSnack(context.l10n.publicKeyCopied),
                    onPublicKeyCopyError: () => showSnack(context.l10n.publicKeyCopyError),
                  ),
                  if (!isSelf) ...[
                    Gap(16.h),
                    WnButton(
                      key: const Key('user_profile_shade_start_chat'),
                      text: context.l10n.startChat,
                      onPressed: () => _handleStartChat(context),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleStartChat(BuildContext context) {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        Routes.pushToStartChat(context, userPubkey);
      }
    });
  }
}
