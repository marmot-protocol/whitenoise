import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:whitenoise/hooks/use_clipboard_guard.dart';
import 'package:whitenoise/hooks/use_nsec.dart';
import 'package:whitenoise/hooks/use_system_notice.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/providers/account_pubkey_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/utils/formatting.dart';
import 'package:whitenoise/widgets/wn_callout.dart';
import 'package:whitenoise/widgets/wn_copyable_field.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart'
    show WnSystemNotice, WnSystemNoticeType, WnSystemNoticeVariant;

class ProfileKeysScreen extends HookConsumerWidget {
  const ProfileKeysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final typography = context.typographyScaled;
    final pubkey = ref.watch(accountPubkeyProvider);
    final npub = npubFromHex(pubkey);
    final (:nsecState) = useNsec(pubkey);
    final obscurePrivateKey = useState(true);
    final scheduleClipboardClear = useClipboardGuard();
    final (:noticeMessage, :noticeType, :showSuccessNotice, :showErrorNotice, :dismissNotice) =
        useSystemNotice();

    useEffect(() {
      if (nsecState.error != null) {
        Future.microtask(() => showErrorNotice('failedToLoadPrivateKey'));
      } else {
        dismissNotice();
      }
      return null;
    }, [nsecState.error]);

    void togglePrivateKeyVisibility() {
      obscurePrivateKey.value = !obscurePrivateKey.value;
    }

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: SafeArea(
        child: WnSlate(
          header: WnSlateNavigationHeader(
            title: context.l10n.profileKeys,
            onNavigate: () => Routes.goBack(context),
          ),
          systemNotice: noticeMessage != null
              ? WnSystemNotice(
                  key: ValueKey(noticeMessage),
                  title: _noticeMessageL10n(context, noticeMessage),
                  type: noticeType,
                  variant: noticeType == WnSystemNoticeType.error
                      ? WnSystemNoticeVariant.dismissible
                      : WnSystemNoticeVariant.temporary,
                  onDismiss: dismissNotice,
                )
              : null,
          child: Padding(
            padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Gap(24.h),
                        WnCopyableField(
                          label: context.l10n.publicKey,
                          value: npub ?? '',
                          onCopied: () => showSuccessNotice('publicKeyCopied'),
                        ),
                        Gap(4.h),
                        Text(
                          context.l10n.publicKeyDescription,
                          style: typography.medium14.copyWith(
                            color: colors.backgroundContentSecondary,
                          ),
                        ),
                        if (nsecState.nsecStorage == NsecStorage.local) ...[
                          Gap(36.h),
                          WnCopyableField(
                            label: context.l10n.privateKey,
                            value: nsecState.nsec ?? '',
                            obscurable: true,
                            obscured: obscurePrivateKey.value,
                            onToggleVisibility: togglePrivateKeyVisibility,
                            onCopied: () {
                              showSuccessNotice('privateKeyCopied');
                              scheduleClipboardClear();
                            },
                          ),
                          Gap(4.h),
                          Text(
                            context.l10n.privateKeyDescription,
                            style: context.typographyScaled.medium14.copyWith(
                              color: colors.backgroundContentSecondary,
                            ),
                          ),
                          Gap(12.h),
                          WnCallout(
                            title: context.l10n.keepPrivateKeySecure,
                            description: context.l10n.privateKeyWarning,
                            type: CalloutType.warning,
                          ),
                        ] else if (nsecState.nsecStorage == NsecStorage.externalSigner) ...[
                          Gap(12.h),
                          WnCallout(
                            title: context.l10n.nsecOnExternalSigner,
                            description: context.l10n.nsecOnExternalSignerDescription,
                            type: CalloutType.info,
                          ),
                        ],
                        Gap(24.h),
                      ],
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

String _noticeMessageL10n(BuildContext context, String key) {
  final l10n = context.l10n;
  switch (key) {
    case 'failedToLoadPrivateKey':
      return l10n.failedToLoadPrivateKey;
    case 'publicKeyCopied':
      return l10n.publicKeyCopied;
    case 'privateKeyCopied':
      return l10n.privateKeyCopied;
    default:
      return key;
  }
}
