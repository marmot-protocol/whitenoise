import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_callout.dart';
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
    final contributionCalloutExpanded = useState(false);

    void showCopiedNotice(String message) {
      noticeMessage.value = message;
    }

    void dismissNotice() {
      noticeMessage.value = null;
    }

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: SafeArea(
        child: WnSlate(
          shrinkWrapContent: true,
          header: WnSlateNavigationHeader(
            title: context.l10n.donate,
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
              spacing: 12.h,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.donateDescription,
                  style: context.typographyScaled.medium14.copyWith(
                    color: colors.backgroundContentPrimary,
                  ),
                ),
                Column(
                  spacing: 12.h,
                  children: [
                    WnCopyableField(
                      key: const Key('lightning_copyable_field'),
                      label: context.l10n.lightningAddress,
                      value: _lightningAddress,
                      onCopied: () => showCopiedNotice(context.l10n.copiedToClipboardThankYou),
                    ),
                    WnCopyableField(
                      key: const Key('bitcoin_copyable_field'),
                      label: context.l10n.bitcoinSilentPayment,
                      value: _bitcoinAddress,
                      onCopied: () => showCopiedNotice(context.l10n.copiedToClipboardThankYou),
                    ),
                  ],
                ),
                WnCallout(
                  key: const Key('contribution_acknowledgment_callout'),
                  title: context.l10n.donateContributionAcknowledgmentTitle,
                  descriptionWidget: contributionCalloutExpanded.value
                      ? _ContributionDescription(
                          before: context.l10n.donateContributionLetterBefore,
                          after: context.l10n.donateContributionLetterAfter,
                        )
                      : null,
                  type: CalloutType.info,
                  compact: true,
                  isExpanded: contributionCalloutExpanded.value,
                  onToggle: () {
                    contributionCalloutExpanded.value = !contributionCalloutExpanded.value;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContributionDescription extends StatelessWidget {
  const _ContributionDescription({required this.before, required this.after});

  final String before;
  final String after;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typographyScaled;
    final descriptionColor = colors.backgroundContentQuaternary;

    return Text.rich(
      TextSpan(
        style: typography.medium14.copyWith(color: descriptionColor),
        children: [
          TextSpan(text: before),
          TextSpan(
            text: 'info@ipf.dev',
            style: typography.medium14.copyWith(
              color: colors.backgroundContentPrimary,
              decoration: TextDecoration.underline,
              decorationColor: colors.backgroundContentPrimary,
            ),
          ),
          if (after.isNotEmpty) TextSpan(text: after),
        ],
      ),
    );
  }
}
