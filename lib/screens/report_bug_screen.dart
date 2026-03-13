import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/hooks/use_system_notice.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/providers/app_version_provider.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/src/rust/api/bug_report.dart';
import 'package:whitenoise/src/rust/api/utils.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/keyboard_dismiss_on_tap.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_checkbox.dart';
import 'package:whitenoise/widgets/wn_dropdown_selector.dart';
import 'package:whitenoise/widgets/wn_input_text_area.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart';

final _logger = Logger('ReportBugScreen');

class ReportBugScreen extends HookConsumerWidget {
  const ReportBugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final typography = context.typographyScaled;
    final l10n = context.l10n;

    final description = useTextEditingController();
    final stepsToReproduce = useTextEditingController();
    final frequency = useState<String?>(null);
    final includeNpub = useState(false);
    final isSending = useState(false);
    final notice = useSystemNotice();
    final descriptionError = useState<String?>(null);

    final pubkey = ref.watch(authProvider).value;
    final appVersionAsync = ref.watch(appVersionProvider);

    final frequencyOptions = [
      WnDropdownOption(value: 'once', label: l10n.reportBugFrequencyOnce),
      WnDropdownOption(
        value: 'sometimes',
        label: l10n.reportBugFrequencySometimes,
      ),
      WnDropdownOption(value: 'always', label: l10n.reportBugFrequencyAlways),
    ];

    Future<void> handleSend() async {
      if (description.text.trim().isEmpty) {
        descriptionError.value = l10n.reportBugWhatWentWrongRequired;
        return;
      }
      descriptionError.value = null;
      FocusScope.of(context).unfocus();
      final appVersion = appVersionAsync.value;

      if (appVersion == null) {
        notice.showErrorNotice(l10n.reportBugError);
        return;
      }

      isSending.value = true;

      try {
        await sendBugReport(
          whatWentWrong: description.text.trim(),
          stepsToReproduce: stepsToReproduce.text.trim().isNotEmpty
              ? stepsToReproduce.text.trim()
              : null,
          frequency: frequency.value,
          npub: includeNpub.value && pubkey != null ? npubFromHexPubkey(hexPubkey: pubkey) : null,
          appVersion: appVersion,
          platform: Platform.operatingSystem,
          osVersion: Platform.operatingSystemVersion,
        );

        if (!context.mounted) return;
        notice.showSuccessNotice(l10n.reportBugSuccess);
      } catch (e) {
        _logger.severe('send_bug_report failed', e);
        if (!context.mounted) return;
        notice.showErrorNotice(l10n.reportBugError);
      } finally {
        if (context.mounted) isSending.value = false;
      }
    }

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: SafeArea(
        child: WnSlate(
          showTopScrollEffect: true,
          showBottomScrollEffect: true,
          header: WnSlateNavigationHeader(
            title: l10n.reportBug,
            onNavigate: () => Routes.goBack(context),
          ),
          systemNotice: notice.noticeMessage != null
              ? WnSystemNotice(
                  key: ValueKey(notice.noticeMessage),
                  title: notice.noticeMessage!,
                  type: notice.noticeType,
                  onDismiss: notice.dismissNotice,
                )
              : null,
          child: KeyboardDismissOnTap(
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
                    key: const Key('report_bug_description'),
                    label: l10n.reportBugWhatWentWrong,
                    placeholder: l10n.reportBugWhatWentWrongPlaceholder,
                    controller: description,
                    errorText: descriptionError.value,
                    onChanged: (_) {
                      if (descriptionError.value != null) {
                        descriptionError.value = null;
                      }
                    },
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
                    onChanged: (frequencyValue) => frequency.value = frequencyValue,
                  ),
                  WnCheckbox(
                    key: const Key('include_npub_checkbox'),
                    label: l10n.reportBugIncludeNpub,
                    description: l10n.reportBugIncludeNpubDescription,
                    value: includeNpub.value,
                    onChanged: (v) => includeNpub.value = v,
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: WnButton(
                      text: l10n.reportBugSend,
                      loading: isSending.value,
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
