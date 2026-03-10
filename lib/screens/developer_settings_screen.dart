import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/providers/debug_view_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/utils/app_flavor.dart';
import 'package:whitenoise/widgets/wn_separator.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';

class DeveloperSettingsScreen extends HookConsumerWidget {
  const DeveloperSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final debugViewEnabled = ref.watch(debugViewProvider).value ?? false;

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          child: WnSlate(
            header: WnSlateNavigationHeader(
              title: context.l10n.developerSettingsTitle,
              type: WnSlateNavigationType.back,
              onNavigate: () => Routes.goBack(context),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16.h),
                  if (isStaging) ...[
                    _DeveloperSettingsDebugViewToggle(
                      label: context.l10n.rawDebugView,
                      description: context.l10n.rawDebugViewDescription,
                      enabled: debugViewEnabled,
                      onChanged: (value) => ref.read(debugViewProvider.notifier).setEnabled(value),
                    ),
                    const WnSeparator(),
                    SizedBox(height: 8.h),
                    _DeveloperSettingsViewLogsRow(
                      rowKey: const Key('view_logs_row'),
                      label: context.l10n.appLogsViewLogs,
                      description: context.l10n.appLogsViewLogsDescription,
                      onTap: () => Routes.pushToAppLogs(context),
                    ),
                    const WnSeparator(),
                    SizedBox(height: 8.h),
                  ],
                  _DeveloperSettingsViewLogsRow(
                    rowKey: const Key('key_package_management_row'),
                    label: context.l10n.keyPackageManagementTitle,
                    description: context.l10n.keyPackageManagementDescription,
                    onTap: () => Routes.pushToKeyPackageManagement(context),
                  ),
                  const WnSeparator(),
                  if (isStaging) ...[
                    SizedBox(height: 8.h),
                    _DeveloperSettingsViewLogsRow(
                      rowKey: const Key('relay_state_row'),
                      label: context.l10n.relayStateTitle,
                      description: context.l10n.relayStateDescription,
                      onTap: () => Routes.pushToRelayControlState(context),
                    ),
                    const WnSeparator(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeveloperSettingsViewLogsRow extends StatelessWidget {
  const _DeveloperSettingsViewLogsRow({
    required this.rowKey,
    required this.label,
    required this.description,
    required this.onTap,
  });

  final Key rowKey;
  final String label;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typographyScaled;

    return InkWell(
      key: rowKey,
      onTap: onTap,
      child: SizedBox(
        height: 56.h,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: typography.medium16.copyWith(
                  color: colors.backgroundContentPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                description,
                style: typography.medium12.copyWith(
                  color: colors.backgroundContentSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeveloperSettingsDebugViewToggle extends StatelessWidget {
  const _DeveloperSettingsDebugViewToggle({
    required this.label,
    required this.description,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final String description;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typographyScaled;

    return InkWell(
      key: const Key('debug_view_toggle_row'),
      onTap: () => onChanged(!enabled),
      child: SizedBox(
        height: 56.h,
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: typography.medium16.copyWith(
                        color: colors.backgroundContentPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      description,
                      style: typography.medium12.copyWith(
                        color: colors.backgroundContentSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(right: 10.w),
              child: Switch(
                key: const Key('debug_view_switch'),
                value: enabled,
                onChanged: onChanged,
                activeThumbColor: colors.backgroundContentPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
