import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:whitenoise/hooks/use_notifications_settings.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_checkbox.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart';

String? _localizeError(String? code, AppLocalizations l10n) {
  return switch (code) {
    settingsLoadFailed => l10n.notificationsSettingsLoadError,
    settingsUpdateFailed => l10n.notificationsSettingsUpdateError,
    _ => null,
  };
}

class NotificationSettingsScreen extends HookConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pubkey = ref.watch(authProvider).value;

    if (pubkey == null) {
      return const SizedBox.shrink();
    }

    final (:settings, :isUpdating, :error, :updateNotifications, :clearError) =
        useNotificationsSettings(pubkey);

    return Scaffold(
      backgroundColor: context.colors.backgroundPrimary,
      body: SafeArea(
        child: WnSlate(
          shrinkWrapContent: true,
          header: WnSlateNavigationHeader(
            title: context.l10n.notificationSettingsTitle,
            onNavigate: () => Routes.goBack(context),
          ),
          systemNotice: _localizeError(error, context.l10n) != null
              ? WnSystemNotice(
                  title: _localizeError(error, context.l10n)!,
                  type: WnSystemNoticeType.error,
                  onDismiss: clearError,
                )
              : null,
          child: Padding(
            padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
            child: WnCheckbox(
              label: context.l10n.notifications,
              description: context.l10n.notificationsDescription,
              value: settings.data?.notificationsEnabled ?? true,
              enabled: !isUpdating && settings.hasData,
              checkboxKey: const Key('notifications_checkbox'),
              onChanged: updateNotifications,
            ),
          ),
        ),
      ),
    );
  }
}
