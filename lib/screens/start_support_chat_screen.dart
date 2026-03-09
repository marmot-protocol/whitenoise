import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/hooks/use_start_dm.dart';
import 'package:whitenoise/hooks/use_support_chat.dart';
import 'package:whitenoise/hooks/use_system_notice.dart';
import 'package:whitenoise/hooks/use_user_metadata.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/providers/account_pubkey_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_icon.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart' show WnSystemNotice;
import 'package:whitenoise/widgets/wn_user_profile_card.dart';

final _logger = Logger('StartSupportChatScreen');

class StartSupportChatScreen extends HookConsumerWidget {
  const StartSupportChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final accountPubkey = ref.watch(accountPubkeyProvider);

    final metadataSnapshot = useUserMetadata(context, supportPubkey);
    final (
      :noticeMessage,
      :noticeType,
      :showErrorNotice,
      :dismissNotice,
      :showSuccessNotice,
    ) = useSystemNotice();

    final dmState = useStartDm(
      accountPubkey: accountPubkey,
      peerPubkey: supportPubkey,
    );

    final metadata = metadataSnapshot.data;
    final isLoading = metadataSnapshot.connectionState == ConnectionState.waiting;

    Future<void> startChat() async {
      try {
        final groupId = await dmState.startDm();
        if (context.mounted) {
          Routes.goToSupportChat(context, groupId);
        }
      } catch (e) {
        _logger.severe('Failed to start help chat: $e');
        if (context.mounted) {
          showErrorNotice(context.l10n.failedToStartHelpChat);
        }
      }
    }

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              key: const Key('start_support_chat_background'),
              onTap: () => Routes.goBack(context),
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                WnSlate(
                  header: WnSlateNavigationHeader(
                    title: context.l10n.chatWithSupport,
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
                    padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (isLoading)
                          Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 40.h),
                              child: CircularProgressIndicator(
                                color: colors.backgroundContentPrimary,
                                strokeCap: StrokeCap.round,
                              ),
                            ),
                          )
                        else ...[
                          WnUserProfileCard(
                            userPubkey: supportPubkey,
                            metadata: metadata,
                            onPublicKeyCopied: () =>
                                showSuccessNotice(context.l10n.publicKeyCopied),
                            onPublicKeyCopyError: () =>
                                showErrorNotice(context.l10n.publicKeyCopyError),
                          ),
                          Gap(8.h),
                          SizedBox(
                            width: double.infinity,
                            child: WnButton(
                              key: const Key('start_support_chat_button'),
                              text: context.l10n.sendMessage,
                              size: WnButtonSize.medium,
                              trailingIcon: WnIcons.newChat,
                              loading: dmState.isLoading,
                              onPressed: startChat,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
