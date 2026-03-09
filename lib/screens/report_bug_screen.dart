import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/providers/app_log_provider.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/src/rust/api/bug_report.dart';
import 'package:whitenoise/src/rust/api/utils.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_callout.dart';
import 'package:whitenoise/widgets/wn_dropdown_selector.dart';
import 'package:whitenoise/widgets/wn_input_text_area.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart';

class ReportBugScreen extends HookConsumerWidget {
  const ReportBugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final typography = context.typographyScaled;
    final l10n = context.l10n;

    final whatWentWrong = useTextEditingController();
    final expectedBehavior = useTextEditingController();
    final stepsToReproduce = useTextEditingController();
    final frequency = useState<String?>(null);
    final includeNpub = useState(false);
    final includeLogs = useState(false);
    final isSending = useState(false);
    final noticeMessage = useState<String?>(null);
    final noticeIsError = useState(false);
    final whatWentWrongError = useState<String?>(null);

    final logs = ref.watch(appLogProvider);
    final pubkey = ref.watch(authProvider).value;

    final frequencyOptions = [
      WnDropdownOption(value: 'always', label: l10n.reportBugFrequencyAlways),
      WnDropdownOption(value: 'often', label: l10n.reportBugFrequencyOften),
      WnDropdownOption(
        value: 'sometimes',
        label: l10n.reportBugFrequencySometimes,
      ),
      WnDropdownOption(value: 'rarely', label: l10n.reportBugFrequencyRarely),
    ];

    Future<void> handleSend() async {
      if (whatWentWrong.text.trim().isEmpty) {
        whatWentWrongError.value = l10n.reportBugWhatWentWrongRequired;
        return;
      }
      whatWentWrongError.value = null;
      isSending.value = true;

      try {
        final packageInfo = await PackageInfo.fromPlatform();

        if (!context.mounted) return;

        await sendBugReport(
          whatWentWrong: whatWentWrong.text.trim(),
          expectedBehavior: expectedBehavior.text.trim().isNotEmpty
              ? expectedBehavior.text.trim()
              : null,
          stepsToReproduce: stepsToReproduce.text.trim().isNotEmpty
              ? stepsToReproduce.text.trim()
              : null,
          frequency: frequency.value,
          npub: includeNpub.value && pubkey != null ? npubFromHexPubkey(hexPubkey: pubkey) : null,
          logs: includeLogs.value
              ? logs
                    .take(200)
                    .map(
                      (e) =>
                          '${e.timestamp.toIso8601String()} ${e.level.name} ${e.loggerName}: ${e.message}',
                    )
                    .join('\n')
              : null,
          appVersion: '${packageInfo.version}+${packageInfo.buildNumber}',
          platform: Platform.operatingSystem,
          osVersion: Platform.operatingSystemVersion,
          relayUrls: [],
        );

        if (!context.mounted) return;
        noticeIsError.value = false;
        noticeMessage.value = l10n.reportBugSuccess;
      } catch (e) {
        debugPrint('send_bug_report failed: $e');
        if (!context.mounted) return;
        noticeIsError.value = true;
        noticeMessage.value = l10n.reportBugError;
      } finally {
        if (context.mounted) isSending.value = false;
      }
    }

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          child: WnSlate(
            showTopScrollEffect: true,
            showBottomScrollEffect: true,
            header: WnSlateNavigationHeader(
              title: l10n.reportBug,
              type: WnSlateNavigationType.back,
              onNavigate: () => Routes.goBack(context),
            ),
            systemNotice: noticeMessage.value != null
                ? WnSystemNotice(
                    key: ValueKey(noticeMessage.value),
                    title: noticeMessage.value!,
                    type: noticeIsError.value
                        ? WnSystemNoticeType.error
                        : WnSystemNoticeType.success,
                    onDismiss: () => noticeMessage.value = null,
                  )
                : null,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
              child: Column(
                spacing: 20.h,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.reportBugDescription,
                    style: typography.medium14.copyWith(
                      color: colors.backgroundContentTertiary,
                    ),
                  ),
                  WnInputTextArea(
                    key: const Key('report_bug_what_went_wrong'),
                    label: l10n.reportBugWhatWentWrong,
                    placeholder: l10n.reportBugWhatWentWrongPlaceholder,
                    controller: whatWentWrong,
                    errorText: whatWentWrongError.value,
                    onChanged: (_) {
                      if (whatWentWrongError.value != null) {
                        whatWentWrongError.value = null;
                      }
                    },
                  ),
                  WnInputTextArea(
                    key: const Key('report_bug_expected_behavior'),
                    label: l10n.reportBugExpectedBehavior,
                    placeholder: l10n.reportBugExpectedBehaviorPlaceholder,
                    controller: expectedBehavior,
                  ),
                  WnInputTextArea(
                    key: const Key('report_bug_steps_to_reproduce'),
                    label: l10n.reportBugStepsToReproduce,
                    placeholder: l10n.reportBugStepsToReproducePlaceholder,
                    controller: stepsToReproduce,
                  ),
                  WnDropdownSelector<String?>(
                    key: const Key('report_bug_frequency'),
                    label: l10n.reportBugFrequency,
                    options: frequencyOptions,
                    value: frequency.value,
                    onChanged: (v) => frequency.value = v,
                  ),
                  _ReportBugToggleRow(
                    switchKey: const Key('include_npub_toggle'),
                    label: l10n.reportBugIncludeNpub,
                    description: l10n.reportBugIncludeNpubDescription,
                    value: includeNpub.value,
                    onChanged: (v) => includeNpub.value = v,
                  ),
                  _ReportBugToggleRow(
                    switchKey: const Key('include_logs_toggle'),
                    label: l10n.reportBugIncludeLogs,
                    description: l10n.reportBugIncludeLogsDescription,
                    value: includeLogs.value,
                    onChanged: (v) => includeLogs.value = v,
                  ),
                  if (includeLogs.value) ...[
                    WnCallout(
                      type: CalloutType.warning,
                      title: l10n.reportBugIncludeLogsDescription,
                    ),
                    _LogPreview(logs: logs),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: WnButton(
                      text: isSending.value ? l10n.reportBugSending : l10n.reportBugSend,
                      onPressed: isSending.value ? null : handleSend,
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

class _ReportBugToggleRow extends StatelessWidget {
  const _ReportBugToggleRow({
    required this.switchKey,
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final Key switchKey;
  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typographyScaled;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: typography.medium14.copyWith(
                  color: colors.backgroundContentPrimary,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                description,
                style: typography.medium12.copyWith(
                  color: colors.backgroundContentTertiary,
                ),
              ),
            ],
          ),
        ),
        Switch(key: switchKey, value: value, onChanged: onChanged),
      ],
    );
  }
}

class _LogPreview extends StatelessWidget {
  const _LogPreview({required this.logs});

  final List<AppLogEntry> logs;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typographyScaled;
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.reportBugLogsPreviewTitle,
          style: typography.medium14.copyWith(
            color: colors.backgroundContentPrimary,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          width: double.infinity,
          height: 180.h,
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: colors.backgroundSecondary,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: colors.borderTertiary),
          ),
          child: logs.isEmpty
              ? Center(
                  child: Text(
                    l10n.reportBugLogsEmpty,
                    style: typography.medium14.copyWith(
                      color: colors.backgroundContentTertiary,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: logs.take(200).length,
                  itemBuilder: (context, index) {
                    final entry = logs[index];
                    return Text(
                      '${entry.timestamp.toIso8601String()} ${entry.level.name} ${entry.loggerName}: ${entry.message}',
                      style: typography.medium10.copyWith(
                        color: colors.backgroundContentSecondary,
                        fontFamily: 'monospace',
                        height: 1.4,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
