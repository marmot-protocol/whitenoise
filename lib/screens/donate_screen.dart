import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_copyable_field.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart';

class DonateScreen extends HookWidget {
  const DonateScreen({super.key});

  static const _lightningAddress = 'whitenoise@npub.cash';
  static const _bitcoinAddress =
      'sp1qqvp56mxcj9pz9xudvlch5g4ah5hrc8rj6neu25p34rc9gxhp38cwqqlmld28u57w2srgckr34dkyg3q02phu8tm05cyj483q026xedp0s5f5j40p';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final noticeMessage = useState<String?>(null);
    final bodyStyle = context.typographyScaled.medium14.copyWith(
      color: colors.backgroundContentTertiary,
    );

    void showCopiedNotice(String message) {
      noticeMessage.value = message;
    }

    void dismissNotice() {
      noticeMessage.value = null;
    }

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          child: WnSlate(
            header: WnSlateNavigationHeader(
              title: context.l10n.donateToWhiteNoise,
              type: WnSlateNavigationType.back,
              onNavigate: () => Routes.goBack(context),
            ),
            systemNotice: noticeMessage.value != null
                ? WnSystemNotice(
                    key: ValueKey(noticeMessage.value),
                    title: noticeMessage.value!,
                    onDismiss: dismissNotice,
                  )
                : null,
            child: Padding(
              padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
              child: Column(
                spacing: 24.h,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.donateDescription,
                    style: bodyStyle,
                  ),
                  WnCopyableField(
                    label: context.l10n.lightningAddress,
                    value: _lightningAddress,
                    onCopied: () => showCopiedNotice(context.l10n.copiedToClipboardThankYou),
                  ),
                  WnCopyableField(
                    label: context.l10n.bitcoinSilentPayment,
                    value: _bitcoinAddress,
                    onCopied: () => showCopiedNotice(context.l10n.copiedToClipboardThankYou),
                  ),
                  Text(
                    context.l10n.donateContributionLetter,
                    style: bodyStyle,
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
