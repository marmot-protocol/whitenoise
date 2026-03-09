import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart' show SvgPicture;
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/utils/app_flavor.dart';
import 'package:whitenoise/widgets/wn_icon.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart';

class FatalErrorScreen extends StatelessWidget {
  const FatalErrorScreen({
    super.key,
    required this.error,
    this.stackTrace,
    this.showDiagnostics = isStaging,
    this.frbBindingsMismatch = false,
  });

  final Object error;
  final StackTrace? stackTrace;
  final bool showDiagnostics;
  final bool frbBindingsMismatch;

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(420, 912),
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: darkTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _FatalErrorBody(
            error: error,
            stackTrace: stackTrace,
            showDiagnostics: showDiagnostics,
            frbBindingsMismatch: frbBindingsMismatch,
          ),
        );
      },
    );
  }
}

class _FatalErrorBody extends StatelessWidget {
  const _FatalErrorBody({
    required this.error,
    this.stackTrace,
    required this.showDiagnostics,
    required this.frbBindingsMismatch,
  });

  final Object error;
  final StackTrace? stackTrace;
  final bool showDiagnostics;
  final bool frbBindingsMismatch;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final typography = context.typographyScaled;

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 40.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SvgPicture.asset(
                'assets/svgs/whitenoise.svg',
                width: 80.w,
                height: 62.h,
                colorFilter: ColorFilter.mode(
                  colors.backgroundContentPrimary,
                  BlendMode.srcIn,
                ),
              ),
              const Spacer(),
              WnIcon(
                WnIcons.warningFilled,
                key: const Key('fatal_error_icon'),
                size: 32.w,
                color: colors.backgroundContentPrimary,
              ),
              SizedBox(height: 16.h),
              Text(
                frbBindingsMismatch ? l10n.fatalErrorBindingsMismatchTitle : l10n.fatalErrorTitle,
                key: const Key('fatal_error_title'),
                style: typography.bold24.copyWith(color: colors.backgroundContentPrimary),
              ),
              SizedBox(height: 12.h),
              Text(
                frbBindingsMismatch
                    ? l10n.fatalErrorBindingsMismatchMessage
                    : l10n.fatalErrorMessage,
                key: const Key('fatal_error_message'),
                style: typography.medium16.copyWith(color: colors.backgroundContentSecondary),
              ),
              if (showDiagnostics) ...[
                SizedBox(height: 24.h),
                _ErrorDetailBox(error: error, stackTrace: stackTrace),
              ],
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorDetailBox extends HookWidget {
  const _ErrorDetailBox({required this.error, this.stackTrace});

  final Object error;
  final StackTrace? stackTrace;

  String get _errorText {
    final buf = StringBuffer(error.toString());
    if (stackTrace != null) {
      buf.writeln();
      buf.writeln();
      buf.write(stackTrace.toString());
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final typography = context.typographyScaled;
    final copied = useState(false);

    Future<void> handleCopy() async {
      await Clipboard.setData(ClipboardData(text: _errorText));
      copied.value = true;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (copied.value)
          WnSystemNotice(
            key: const Key('fatal_error_copied_notice'),
            title: l10n.fatalErrorErrorCopied,
            variant: WnSystemNoticeVariant.dismissible,
            onDismiss: () => copied.value = false,
          ),
        Container(
          key: const Key('fatal_error_detail_box'),
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: colors.backgroundSecondary,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: colors.borderPrimary),
          ),
          constraints: BoxConstraints(maxHeight: 160.h),
          child: SingleChildScrollView(
            child: Text(
              _errorText,
              style: typography.medium12.copyWith(
                color: colors.intentionErrorContent,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        TextButton.icon(
          key: const Key('fatal_error_copy_button'),
          onPressed: handleCopy,
          icon: WnIcon(WnIcons.copy, size: 16.r, color: colors.backgroundContentSecondary),
          label: Text(
            l10n.fatalErrorCopyError,
            style: typography.medium12.copyWith(color: colors.backgroundContentSecondary),
          ),
        ),
      ],
    );
  }
}
