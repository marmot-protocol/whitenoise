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
    final warningCalloutExpanded = useState(false);
    final obscurePrivateKey = useState(true);
    final isLoggingOut = useState(false);
    final scheduleClipboardClear = useClipboardGuard();
    final (
      :noticeMessage,
      :noticeType,
      :showSuccessNotice,
      :showErrorNotice,
      :dismissNotice,
    ) = useSystemNotice();

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
          shrinkWrapContent: true,
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
            padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WnCallout(
                  title: context.l10n.signOutConfirmation,
                  descriptionWidget: warningCalloutExpanded.value
                      ? _SignOutCalloutDescription(
                          nsec: nsecState.nsec,
                          obscured: obscurePrivateKey.value,
                          onToggleVisibility: () {
                            obscurePrivateKey.value = !obscurePrivateKey.value;
                          },
                          onCopied: () {
                            showSuccessNotice('privateKeyCopied');
                            scheduleClipboardClear();
                          },
                        )
                      : null,
                  type: CalloutType.warning,
                  compact: true,
                  isExpanded: warningCalloutExpanded.value,
                  onToggle: () {
                    warningCalloutExpanded.value = !warningCalloutExpanded.value;
                  },
                ),
                Gap(12.h),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 8.h,
                  children: [
                    WnButton(
                      text: context.l10n.cancel,
                      type: WnButtonType.outline,
                      size: WnButtonSize.medium,
                      onPressed: () => Routes.goBack(context),
                    ),
                    WnButton(
                      text: context.l10n.signOut,
                      size: WnButtonSize.medium,
                      onPressed: signOut,
                      loading: isLoggingOut.value,
                    ),
                  ],
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

class _SignOutCalloutDescription extends StatelessWidget {
  const _SignOutCalloutDescription({
    required this.nsec,
    required this.obscured,
    required this.onToggleVisibility,
    required this.onCopied,
  });

  final String? nsec;
  final bool obscured;
  final VoidCallback onToggleVisibility;
  final VoidCallback onCopied;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typographyScaled;
    final l10n = context.l10n;
    final descriptionColor = colors.backgroundContentQuaternary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.signOutCalloutDescription,
          style: typography.medium14.copyWith(color: descriptionColor),
        ),
        Gap(4.h),
        WnCopyableField(
          label: l10n.privateKey,
          value: nsec ?? '',
          obscurable: true,
          obscured: obscured,
          defaultTextColor: true,
          obscureDotCount: 14,
          onToggleVisibility: onToggleVisibility,
          onCopied: onCopied,
        ),
        Gap(4.h),
        Text(
          l10n.privateKeyDescription,
          style: typography.medium14.copyWith(color: descriptionColor),
        ),
      ],
    );
  }
}
