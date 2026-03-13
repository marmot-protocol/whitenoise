import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/hooks/use_system_notice.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_callout.dart';
import 'package:whitenoise/widgets/wn_icon.dart';
import 'package:whitenoise/widgets/wn_logo_slogan.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart';

class FatalErrorScreen extends StatelessWidget {
  const FatalErrorScreen({
    super.key,
    required this.errorMessage,
    this.stackTrace,
  });

  final String errorMessage;
  final StackTrace? stackTrace;

  @override
  Widget build(BuildContext context) {
    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    return ScreenUtilInit(
      designSize: const Size(420, 912),
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: brightness == Brightness.dark ? darkTheme : lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _FatalErrorBody(
            errorMessage: errorMessage,
            stackTrace: stackTrace,
          ),
        );
      },
    );
  }
}

class _FatalErrorBody extends HookWidget {
  const _FatalErrorBody({
    required this.errorMessage,
    this.stackTrace,
  });

  final String errorMessage;
  final StackTrace? stackTrace;

  String get _errorText {
    final buf = StringBuffer(errorMessage);
    if (stackTrace != null) {
      buf.writeln();
      buf.writeln();
      buf.write(stackTrace.toString());
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final (
      :noticeMessage,
      :noticeType,
      :showSuccessNotice,
      showErrorNotice: _,
      :dismissNotice,
    ) = useSystemNotice();

    Future<void> handleCopy() async {
      await Clipboard.setData(ClipboardData(text: _errorText));
      showSuccessNotice(l10n.fatalErrorErrorCopied);
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: colors.backgroundPrimary,
      body: Stack(
        fit: StackFit.expand,
        children: [
          SafeArea(
            child: Column(
              children: [
                Gap(216.5.h),
                WnLogoSlogan(
                  texts: [
                    l10n.sloganDecentralized,
                    l10n.sloganUncensorable,
                    l10n.sloganSecureMessaging,
                  ],
                ),
                const Spacer(),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: WnSlate(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (noticeMessage != null) ...[
                        WnSystemNotice(
                          key: const Key('fatal_error_notice'),
                          title: noticeMessage,
                          type: noticeType,
                          variant: noticeType == WnSystemNoticeType.success
                              ? WnSystemNoticeVariant.temporary
                              : WnSystemNoticeVariant.dismissible,
                          onDismiss: dismissNotice,
                        ),
                        Gap(12.h),
                      ],
                      WnCallout(
                        key: const Key('fatal_error_callout'),
                        title: l10n.fatalErrorTitle,
                        description: l10n.fatalErrorDescription,
                        type: CalloutType.error,
                      ),
                      Gap(12.h),
                      SizedBox(
                        width: double.infinity,
                        child: WnButton(
                          key: const Key('fatal_error_copy_button'),
                          text: l10n.fatalErrorCopyError,
                          onPressed: handleCopy,
                          type: WnButtonType.outline,
                          size: WnButtonSize.medium,
                          trailingIcon: WnIcons.copy,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
