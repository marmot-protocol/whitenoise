import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart' show useState;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart' show HookConsumerWidget, WidgetRef;
import 'package:whitenoise/hooks/use_login_with_android_signer.dart' show useLoginWithAndroidSigner;
import 'package:whitenoise/hooks/use_login_with_nsec.dart' show useLoginWithNsec;
import 'package:whitenoise/hooks/use_onboarding_carousel.dart' show onboardingCarouselSlideCount;
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/providers/auth_provider.dart' show authProvider;
import 'package:whitenoise/routes.dart' show Routes;
import 'package:whitenoise/src/rust/api/accounts.dart' show LoginResult, LoginStatus;
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_carousel_indicator.dart' show WnCarouselIndicator;
import 'package:whitenoise/widgets/wn_input_password.dart' show WnInputPassword;
import 'package:whitenoise/widgets/wn_onboarding_carousel.dart' show WnOnboardingCarousel;
import 'package:whitenoise/widgets/wn_overlay.dart' show WnOverlay;
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart'
    show WnSystemNotice, WnSystemNoticeType, WnSystemNoticeVariant;

String _signerErrorL10n(String code, AppLocalizations l10n) {
  switch (code) {
    case 'USER_REJECTED':
      return l10n.signerErrorUserRejected;
    case 'NOT_CONNECTED':
      return l10n.signerErrorNotConnected;
    case 'NO_SIGNER':
      return l10n.signerErrorNoSigner;
    case 'NO_RESPONSE':
      return l10n.signerErrorNoResponse;
    case 'NO_PUBKEY':
      return l10n.signerErrorNoPubkey;
    case 'NO_RESULT':
      return l10n.signerErrorNoResult;
    case 'NO_EVENT':
      return l10n.signerErrorNoEvent;
    case 'REQUEST_IN_PROGRESS':
      return l10n.signerErrorRequestInProgress;
    case 'NO_ACTIVITY':
      return l10n.signerErrorNoActivity;
    case 'LAUNCH_ERROR':
      return l10n.signerErrorLaunchError;
    case 'CONNECTION_ERROR':
      return l10n.signerConnectionError;
    default:
      return l10n.signerErrorUnknown;
  }
}

String _loginErrorL10n(String errorKey, AppLocalizations l10n) {
  return switch (errorKey) {
    'loginErrorInvalidKey' => l10n.loginErrorInvalidKey,
    'loginErrorNoRelayConnections' => l10n.loginErrorNoRelayConnections,
    'loginErrorTimeout' => l10n.loginErrorTimeout,
    'loginErrorNoLoginInProgress' => l10n.loginErrorNoLoginInProgress,
    'loginErrorInternal' => l10n.loginErrorInternal,
    'loginPasteNothingToPaste' => l10n.loginPasteNothingToPaste,
    'loginPasteFailed' => l10n.loginPasteFailed,
    _ => l10n.loginErrorGeneric,
  };
}

void _handleLoginResult(
  BuildContext context,
  LoginResult result, {
  required bool isExternalSigner,
}) {
  if (!context.mounted) return;

  if (result.status == LoginStatus.complete) {
    Routes.goToChatList(context);
  } else if (result.status == LoginStatus.needsRelayLists) {
    Routes.pushToRelayResolution(
      context,
      pubkey: result.account.pubkey,
      isExternalSigner: isExternalSigner,
    );
  }
}

class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final (
      :nsecInputController,
      :loginWithNsecState,
      :pasteNsec,
      :submitLoginWithNsec,
      :clearLoginWithNsecError,
    ) = useLoginWithNsec(
      (nsec) => ref.read(authProvider.notifier).loginStart(nsec),
    );
    final (
      :isAndroidSignerAvailable,
      :loginWithAndroidSignerState,
      :submitLoginWithAndroidSigner,
      :clearLoginWithAndroidSignerError,
    ) = useLoginWithAndroidSigner(
      ({required pubkey}) =>
          ref.read(authProvider.notifier).loginExternalSignerStart(pubkey: pubkey),
    );

    final carouselIndex = useState(0);
    final carouselAccentColor = useState<Color>(colors.accent.cyan.contentSecondary);

    Future<void> onSubmit() async {
      final result = await submitLoginWithNsec();
      if (result != null && context.mounted) {
        _handleLoginResult(context, result, isExternalSigner: false);
      }
    }

    Future<void> onScan() async {
      final scannedValue = await Routes.pushToScanNsec(context);
      if (scannedValue != null && scannedValue.isNotEmpty) {
        nsecInputController.text = scannedValue;
        clearLoginWithNsecError();
      }
    }

    Future<void> onAndroidSignerSubmit() async {
      clearLoginWithNsecError();
      final result = await submitLoginWithAndroidSigner();
      if (result != null && context.mounted) {
        _handleLoginResult(context, result, isExternalSigner: true);
      }
    }

    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    final bottomSafeArea = MediaQuery.paddingOf(context).bottom;
    final isKeyboardOpen = keyboardHeight > 0;
    final slateBottomPadding = ((keyboardHeight - bottomSafeArea) + (isKeyboardOpen ? 10.h : 0.0))
        .clamp(0.0, double.infinity);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: colors.backgroundPrimary,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              key: const Key('login_background'),
              onTap: () => Routes.goBack(context),
              behavior: HitTestBehavior.translucent,
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const carouselMaxHeight = 260.0;
                      final carouselIndicatorSpacing = 16.h;
                      final carouselIndicatorHeight = 8.h;
                      final keyboardOpenBottomSpacing = 20.h;
                      final carouselHeight = isKeyboardOpen
                          ? (constraints.maxHeight -
                                    carouselIndicatorSpacing -
                                    carouselIndicatorHeight -
                                    keyboardOpenBottomSpacing)
                                .clamp(0.0, carouselMaxHeight.h)
                          : carouselMaxHeight.h;
                      return Stack(
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              WnOnboardingCarousel(
                                key: const Key('login_onboarding_carousel'),
                                height: carouselHeight,
                                onSlideChanged: (index, accentColor) {
                                  carouselIndex.value = index;
                                  carouselAccentColor.value = accentColor;
                                },
                              ),
                              SizedBox(height: 16.h),
                              WnCarouselIndicator(
                                key: const Key('login_carousel_indicator'),
                                itemCount: onboardingCarouselSlideCount,
                                activeIndex: carouselIndex.value,
                                activeColor: carouselAccentColor.value,
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                curve: Curves.easeOut,
                                height: isKeyboardOpen
                                    ? 20.h
                                    : isAndroidSignerAvailable
                                    ? 157.h
                                    : 205.h,
                              ),
                            ],
                          ),
                          if (isKeyboardOpen) const WnOverlay(key: Key('login_keyboard_overlay')),
                        ],
                      );
                    },
                  ),
                ),
                AnimatedPadding(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.only(bottom: slateBottomPadding),
                  child: WnSlate(
                    header: WnSlateNavigationHeader(
                      title: context.l10n.loginTitle,
                      type: WnSlateNavigationType.back,
                      onNavigate: () => Routes.goBack(context),
                    ),
                    systemNotice: loginWithAndroidSignerState.error != null
                        ? WnSystemNotice(
                            key: ValueKey(loginWithAndroidSignerState.error),
                            title: _signerErrorL10n(
                              loginWithAndroidSignerState.error!,
                              context.l10n,
                            ),
                            type: WnSystemNoticeType.error,
                            variant: WnSystemNoticeVariant.dismissible,
                            onDismiss: clearLoginWithAndroidSignerError,
                          )
                        : null,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
                      child: Column(
                        spacing: 12.h,
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          WnInputPassword(
                            placeholder: context.l10n.nsecPlaceholder,
                            controller: nsecInputController,
                            errorText: loginWithNsecState.error != null
                                ? _loginErrorL10n(loginWithNsecState.error!, context.l10n)
                                : null,
                            onChanged: (_) => clearLoginWithNsecError(),
                            onPaste: pasteNsec,
                            onScan: onScan,
                          ),
                          ListenableBuilder(
                            listenable: nsecInputController,
                            builder: (context, _) {
                              final nsecEmpty = nsecInputController.text.trim().isEmpty;
                              return Column(
                                spacing: 12.h,
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  WnButton(
                                    key: const Key('login_button'),
                                    text: context.l10n.login,
                                    onPressed: onSubmit,
                                    loading: loginWithNsecState.isLoading,
                                    disabled: nsecEmpty || loginWithAndroidSignerState.isLoading,
                                  ),
                                  if (isAndroidSignerAvailable)
                                    WnButton(
                                      key: const Key('android_signer_login_button'),
                                      text: context.l10n.loginWithAmber,
                                      type: WnButtonType.outline,
                                      onPressed: onAndroidSignerSubmit,
                                      loading: loginWithAndroidSignerState.isLoading,
                                      disabled: loginWithNsecState.isLoading,
                                    ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
