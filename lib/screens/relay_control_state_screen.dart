import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/hooks/use_system_notice.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/providers/offline_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/src/rust/api/relays.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/offline_system_notice.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart';

final _logger = Logger('RelayControlStateScreen');

class RelayControlStateScreen extends HookConsumerWidget {
  const RelayControlStateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final typography = context.typographyScaled;
    final isOffline = ref.watch(offlineProvider).value ?? false;
    final isLoading = useState(false);
    final result = useState<String?>(null);

    final (
      :noticeMessage,
      :noticeType,
      :showErrorNotice,
      :dismissNotice,
      :showSuccessNotice,
    ) = useSystemNotice();

    Future<void> loadState() async {
      if (isOffline) return;
      isLoading.value = true;
      dismissNotice();

      try {
        final dump = await debugRelayControlState();
        if (!context.mounted) {
          return;
        }
        result.value = dump;
      } catch (e, stackTrace) {
        _logger.severe('Failed to load relay control state dump', e, stackTrace);
        if (!context.mounted) {
          return;
        }
        showErrorNotice(context.l10n.relayControlStateLoadError);
        result.value = null;
      } finally {
        if (context.mounted) {
          isLoading.value = false;
        }
      }
    }

    Future<void> copyDump() async {
      final dump = result.value;
      if (dump == null || dump.isEmpty) {
        return;
      }

      await Clipboard.setData(ClipboardData(text: dump));
      if (context.mounted) {
        showSuccessNotice(context.l10n.rawDebugViewCopied);
      }
    }

    useEffect(() {
      if (!isOffline) {
        loadState();
      }
      return null;
    }, [isOffline]);

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          child: WnSlate(
            header: WnSlateNavigationHeader(
              title: context.l10n.relayStateTitle,
              onNavigate: () => Routes.goBack(context),
            ),
            systemNotice: isOffline
                ? const OfflineSystemNotice()
                : (noticeMessage != null
                      ? WnSystemNotice(
                          key: ValueKey(noticeMessage),
                          title: noticeMessage,
                          type: noticeType,
                          onDismiss: dismissNotice,
                        )
                      : null),
            child: ListView(
              padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 14.h),
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: colors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.relayControlStateSnapshotDescription,
                        style: typography.medium10.copyWith(
                          color: colors.backgroundContentSecondary,
                          fontFamily: 'monospace',
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: [
                          WnButton(
                            key: const Key('relay_control_state_refresh_button'),
                            text: isLoading.value
                                ? context.l10n.relayControlStateLoading
                                : context.l10n.relayControlStateRefreshButton,
                            onPressed: isLoading.value || isOffline ? null : loadState,
                            loading: isLoading.value,
                            type: WnButtonType.outline,
                            size: WnButtonSize.small,
                          ),
                          WnButton(
                            key: const Key('relay_control_state_copy_button'),
                            text: context.l10n.relayControlStateCopyButton,
                            onPressed: (result.value?.trim().isEmpty ?? true) ? null : copyDump,
                            type: WnButtonType.outline,
                            size: WnButtonSize.small,
                          ),
                        ],
                      ),
                      if (result.value != null) ...[
                        SizedBox(height: 6.h),
                        SelectableText(
                          key: const Key('relay_control_state_result'),
                          result.value!,
                          style: typography.medium10.copyWith(
                            color: colors.backgroundContentPrimary,
                            fontFamily: 'monospace',
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
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
