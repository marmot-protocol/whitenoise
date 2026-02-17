import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:whitenoise/hooks/use_delete_all_data.dart';
import 'package:whitenoise/hooks/use_system_notice.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_confirmation_slate.dart';
import 'package:whitenoise/widgets/wn_icon.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart';

class PrivacySecurityScreen extends HookConsumerWidget {
  const PrivacySecurityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final typography = context.typographyScaled;
    final (:state, :deleteAllData) = useDeleteAllData();
    final systemNotice = useSystemNotice();

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
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          child: WnSlate(
            header: WnSlateNavigationHeader(
              title: context.l10n.privacySecurityTitle,
              type: WnSlateNavigationType.back,
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
            child: Padding(
              padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.deleteAllAppData,
                    style: typography.semiBold16.copyWith(
                      color: colors.backgroundContentSecondary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  SizedBox(
                    width: double.infinity,
                    child: WnButton(
                      key: const Key('delete_all_data_button'),
                      text: context.l10n.deleteAppData,
                      onPressed: handleDeleteAllData,
                      type: WnButtonType.destructive,
                      size: WnButtonSize.medium,
                      loading: state.isDeleting,
                      disabled: state.isDeleting,
                      trailingIcon: WnIcons.trashCan,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    context.l10n.deleteAllAppDataDescription,
                    style: typography.medium12.copyWith(
                      color: colors.backgroundContentSecondary,
                    ),
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
