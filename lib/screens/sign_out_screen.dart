import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:whitenoise/hooks/use_clipboard_guard.dart';
import 'package:whitenoise/hooks/use_nsec.dart';
import 'package:whitenoise/hooks/use_system_notice.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_callout.dart';
import 'package:whitenoise/widgets/wn_copyable_field.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart'
    show WnSystemNotice, WnSystemNoticeType, WnSystemNoticeVariant;

class SignOutScreen extends HookConsumerWidget {
  const SignOutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final pubkey = ref.watch(authProvider).value;
    final (:nsecState) = useNsec(pubkey);
    final obscurePrivateKey = useState(true);
    final isLoggingOut = useState(false);
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

    if (pubkey == null) {
      return const SizedBox.shrink();
    }

    void togglePrivateKeyVisibility() {
      obscurePrivateKey.value = !obscurePrivateKey.value;
    }

    Future<void> signOut() async {
      isLoggingOut.value = true;
      final nextPubkey = await ref.read(authProvider.notifier).logout();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          if (nextPubkey != null) {
            Routes.goBack(context);
          } else {
            Routes.goToHome(context);
          }
        }
      });
    }

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: SafeArea(
        child: WnSlate(
          header: WnSlateNavigationHeader(
            title: context.l10n.signOut,
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
                        WnCallout(
                          title: context.l10n.signOutConfirmation,
                          description: nsecState.nsecStorage == NsecStorage.local
                              ? '${context.l10n.signOutWarning}\n\n${context.l10n.signOutWarningBackupKey}'
                              : context.l10n.signOutWarning,
                          type: CalloutType.warning,
                        ),
                        if (nsecState.nsecStorage == NsecStorage.local) ...[
                          Gap(24.h),
                          Text(
                            context.l10n.backUpPrivateKey,
                            style: context.typographyScaled.semiBold16.copyWith(
                              color: colors.backgroundContentPrimary,
                            ),
                          ),
                          Gap(8.h),
                          Text(
                            context.l10n.copyPrivateKeyHint,
                            style: context.typographyScaled.medium14.copyWith(
                              color: colors.backgroundContentSecondary,
                            ),
                          ),
                          Gap(16.h),
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
                        ],
                        Gap(32.h),
                        SizedBox(
                          width: double.infinity,
                          child: WnButton(
                            text: context.l10n.signOut,
                            onPressed: signOut,
                            loading: isLoggingOut.value,
                            size: WnButtonSize.medium,
                          ),
                        ),
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
    case 'privateKeyCopied':
      return l10n.privateKeyCopied;
    default:
      return key;
  }
}
