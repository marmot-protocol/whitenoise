import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:whitenoise/hooks/use_delete_all_data.dart';
import 'package:whitenoise/hooks/use_system_notice.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/providers/product_analytics_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_confirmation_slate.dart';
import 'package:whitenoise/widgets/wn_icon.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart';
import 'package:whitenoise/widgets/wn_toggle.dart';

class PrivacySecurityScreen extends HookConsumerWidget {
  const PrivacySecurityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final (:state, :deleteAllData) = useDeleteAllData();
    final systemNotice = useSystemNotice();
    final analyticsSettings = ref.watch(productAnalyticsSettingsProvider);

    Future<void> handleDeleteAllData() async {
      final result = await WnConfirmationSlate.show(
        context: context,
        title: context.l10n.deleteAllAppDataConfirmation,
        message: context.l10n.deleteAllAppDataWarning,
        confirmText: context.l10n.deleteAppData,
        cancelText: context.l10n.cancel,
        isDestructive: true,
        onConfirmAsync: deleteAllData,
      );

      if (!context.mounted || result == null) return;

      if (result) {
        await ref.read(authProvider.notifier).resetAuth();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            Routes.goToHome(context);
          }
        });
      } else {
        systemNotice.showErrorNotice(context.l10n.deleteAllDataError);
      }
    }

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: SafeArea(
        child: WnSlate(
          header: WnSlateNavigationHeader(
            title: context.l10n.privacySecurityTitle,
            onNavigate: () => Routes.goBack(context),
          ),
          systemNotice: systemNotice.noticeMessage != null
              ? WnSystemNotice(
                  key: ValueKey(systemNotice.noticeMessage),
                  title: systemNotice.noticeMessage!,
                  type: systemNotice.noticeType,
                  variant: WnSystemNoticeVariant.dismissible,
                  onDismiss: systemNotice.dismissNotice,
                )
              : null,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AnalyticsActionBlock(
                  title: context.l10n.analyticsConsentTitle,
                  description: context.l10n.analyticsConsentSettingsDescription,
                  value: analyticsSettings.value?.enabled ?? false,
                  enabled: analyticsSettings.hasValue,
                  onChanged: (enabled) {
                    ref.read(productAnalyticsSettingsProvider.notifier).setEnabled(enabled);
                  },
                ),
                Gap(12.h),
                _DestructiveActionBlock(
                  title: context.l10n.deleteAllAppData,
                  buttonText: context.l10n.deleteAppData,
                  description: context.l10n.deleteAllAppDataDescription,
                  icon: WnIcons.trashCan,
                  buttonKey: const Key('delete_all_data_button'),
                  loading: state.isDeleting,
                  onPressed: state.isDeleting ? null : handleDeleteAllData,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnalyticsActionBlock extends StatelessWidget {
  const _AnalyticsActionBlock({
    required this.title,
    required this.description,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String title;
  final String description;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _ActionTextBlock(
            title: title,
            description: description,
            descriptionGap: 0,
          ),
        ),
        Gap(24.w),
        Padding(
          padding: EdgeInsets.only(top: 4.h),
          child: WnToggle(
            key: const Key('privacy_security_analytics_consent_toggle'),
            thumbKey: const Key('privacy_security_analytics_consent_toggle_thumb'),
            value: value,
            enabled: enabled,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _DestructiveActionBlock extends StatelessWidget {
  const _DestructiveActionBlock({
    required this.title,
    required this.buttonText,
    required this.description,
    required this.icon,
    required this.buttonKey,
    required this.loading,
    required this.onPressed,
  });

  final String title;
  final String buttonText;
  final String description;
  final WnIcons icon;
  final Key buttonKey;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return _ActionTextBlock(
      title: title,
      description: description,
      descriptionGap: 4.h,
      child: WnButton(
        key: buttonKey,
        text: buttonText,
        onPressed: onPressed,
        type: WnButtonType.destructive,
        size: WnButtonSize.medium,
        loading: loading,
        disabled: loading,
        trailingIcon: icon,
      ),
    );
  }
}

class _ActionTextBlock extends StatelessWidget {
  const _ActionTextBlock({
    required this.title,
    required this.description,
    required this.descriptionGap,
    this.child,
  });

  final String title;
  final String description;
  final double descriptionGap;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typographyScaled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 2.w, top: 4.h, bottom: 4.h),
          child: Text(
            title,
            style: typography.semiBold16.copyWith(
              color: colors.backgroundContentSecondary,
            ),
          ),
        ),
        if (child != null) ...[
          Gap(4.h),
          SizedBox(width: double.infinity, child: child),
        ],
        Gap(descriptionGap),
        Padding(
          padding: EdgeInsets.only(left: 2.w, top: 4.h, bottom: 4.h),
          child: Text(
            description,
            style: typography.medium14.copyWith(
              color: colors.backgroundContentSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
