import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/src/rust/api/relays.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';

final _logger = Logger('RelayControlStateScreen');

class RelayControlStateScreen extends HookWidget {
  const RelayControlStateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typographyScaled;
    final isLoading = useState(false);
    final result = useState<String?>(null);
    final error = useState<String?>(null);

    Future<void> loadState() async {
      isLoading.value = true;
      error.value = null;

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
        error.value = context.l10n.relayControlStateLoadError;
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.rawDebugViewCopied),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }

    useEffect(() {
      loadState();
      return null;
    }, const []);

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
                        context.l10n.relayControlStateDumpLabel,
                        style: typography.semiBold10.copyWith(
                          color: colors.backgroundContentSecondary,
                          fontFamily: 'monospace',
                        ),
                      ),
                      SizedBox(height: 8.h),
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
                          TextButton(
                            key: const Key('relay_control_state_refresh_button'),
                            onPressed: isLoading.value ? null : loadState,
                            child: Text(
                              isLoading.value
                                  ? context.l10n.relayControlStateLoading
                                  : context.l10n.relayControlStateRefreshButton,
                            ),
                          ),
                          TextButton(
                            key: const Key('relay_control_state_copy_button'),
                            onPressed: result.value == null ? null : copyDump,
                            child: Text(context.l10n.relayControlStateCopyButton),
                          ),
                        ],
                      ),
                      if (error.value != null) ...[
                        SizedBox(height: 6.h),
                        SelectableText(
                          key: const Key('relay_control_state_error'),
                          error.value!,
                          style: typography.medium10.copyWith(
                            color: colors.fillDestructive,
                            fontFamily: 'monospace',
                            height: 1.4,
                          ),
                        ),
                      ],
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
