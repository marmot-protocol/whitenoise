import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';

class WnConfirmationSlate extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final bool isDestructive;
  final bool loading;

  const WnConfirmationSlate({
    super.key,
    required this.title,
    required this.message,
    required this.confirmText,
    required this.cancelText,
    required this.onConfirm,
    required this.onCancel,
    this.isDestructive = false,
    this.loading = false,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmText,
    required String cancelText,
    bool isDestructive = false,
    required Future<bool> Function() onConfirmAsync,
  }) async {
    final colors = context.colors;

    return await Navigator.of(context).push<bool>(
      PageRouteBuilder(
        opaque: false,
        barrierColor: colors.backgroundPrimary.withValues(alpha: 0.8),
        pageBuilder: (context, _, _) {
          return _AsyncConfirmationOverlay(
            title: title,
            message: message,
            confirmText: confirmText,
            cancelText: cancelText,
            isDestructive: isDestructive,
            onConfirmAsync: onConfirmAsync,
          );
        },
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return WnSlate(
      header: WnSlateNavigationHeader(
        title: title,
        type: WnSlateNavigationType.back,
        onNavigate: loading ? null : onCancel,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Gap(12.h),
            Text(
              message,
              style: context.typographyScaled.medium14.copyWith(
                color: colors.backgroundContentSecondary,
              ),
            ),
            Gap(24.h),
            Column(
              spacing: 8.h,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                WnButton(
                  key: const Key('cancel_button'),
                  onPressed: onCancel,
                  text: cancelText,
                  type: WnButtonType.outline,
                  disabled: loading,
                ),
                WnButton(
                  key: const Key('confirm_button'),
                  onPressed: onConfirm,
                  text: confirmText,
                  type: isDestructive ? WnButtonType.destructive : WnButtonType.primary,
                  loading: loading,
                  disabled: loading,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AsyncConfirmationOverlay extends HookWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final bool isDestructive;
  final Future<bool> Function() onConfirmAsync;

  const _AsyncConfirmationOverlay({
    required this.title,
    required this.message,
    required this.confirmText,
    required this.cancelText,
    required this.isDestructive,
    required this.onConfirmAsync,
  });

  @override
  Widget build(BuildContext context) {
    final isLoading = useState(false);

    Future<void> handleConfirm() async {
      isLoading.value = true;
      final result = await onConfirmAsync();
      if (context.mounted) {
        Navigator.of(context).pop(result);
      }
    }

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        child: Column(
          children: [
            WnConfirmationSlate(
              title: title,
              message: message,
              confirmText: confirmText,
              cancelText: cancelText,
              onConfirm: handleConfirm,
              onCancel: () => Navigator.of(context).pop(),
              isDestructive: isDestructive,
              loading: isLoading.value,
            ),
            Expanded(
              child: GestureDetector(
                onTap: isLoading.value ? null : () => Navigator.of(context).pop(),
                behavior: HitTestBehavior.opaque,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
