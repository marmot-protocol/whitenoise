import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart' show HookConsumerWidget, WidgetRef;
import 'package:whitenoise/hooks/use_relay_resolution.dart' show useRelayResolution;
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/providers/auth_provider.dart' show authProvider;
import 'package:whitenoise/routes.dart' show Routes;
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_input.dart' show WnInput, WnInputTrailingButton;
import 'package:whitenoise/widgets/wn_onboarding_carousel.dart' show WnOnboardingCarousel;
import 'package:whitenoise/widgets/wn_overlay.dart' show WnOverlay;
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart'
    show WnSystemNotice, WnSystemNoticeType, WnSystemNoticeVariant;

String _resolveError(String errorKey, AppLocalizations l10n) {
  return switch (errorKey) {
    'relayResolutionNotFound' => l10n.relayResolutionNotFound,
    'loginErrorNoRelayConnections' => l10n.loginErrorNoRelayConnections,
    'loginErrorTimeout' => l10n.loginErrorTimeout,
    'loginErrorInternal' => l10n.loginErrorInternal,
    'invalidRelayUrlScheme' => l10n.invalidRelayUrlScheme,
    'invalidRelayUrl' => l10n.invalidRelayUrl,
    _ => l10n.loginErrorGeneric,
  };
}

class RelayResolutionScreen extends HookConsumerWidget {
  final String pubkey;
  final bool isExternalSigner;

  const RelayResolutionScreen({
    super.key,
    required this.pubkey,
    required this.isExternalSigner,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final typography = context.typographyScaled;
    final authNotifier = ref.read(authProvider.notifier);

    final (
      :relayUrlController,
      :relayResolutionState,
      :isRelayUrlValid,
      :validationError,
      :trailingIcon,
      :trailingKey,
      :handleTrailingAction,
      :publishDefaults,
      :tryCustomRelay,
      :cancel,
      :clearError,
    ) = useRelayResolution(
      pubkey: pubkey,
      publishDefaultRelays: isExternalSigner
          ? (p) => authNotifier.loginExternalSignerPublishDefaultRelays(p)
          : (p) => authNotifier.loginPublishDefaultRelays(p),
      customRelay: isExternalSigner
          ? (p, r) => authNotifier.loginExternalSignerWithCustomRelay(p, r)
          : (p, r) => authNotifier.loginWithCustomRelay(p, r),
      cancelLogin: (p) => authNotifier.loginCancel(p),
    );

    Future<void> onPublishDefaults() async {
      final success = await publishDefaults();
      if (success && context.mounted) {
        Routes.goToChatList(context);
      }
    }

    Future<void> onTryCustomRelay() async {
      final success = await tryCustomRelay();
      if (success && context.mounted) {
        Routes.goToChatList(context);
      }
    }

    Future<void> onCancel() async {
      await cancel();
      if (context.mounted) {
        Routes.goBack(context);
      }
    }

    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    final isKeyboardOpen = keyboardHeight > 0;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: colors.backgroundPrimary,
      body: Stack(
        fit: StackFit.expand,
        children: [
          SafeArea(
            child: Padding(
              padding: EdgeInsets.only(bottom: 160.h),
              child: const WnOnboardingCarousel(),
            ),
          ),
          if (isKeyboardOpen) const WnOverlay(key: Key('relay_resolution_keyboard_overlay')),
          Positioned(
            left: 0,
            right: 0,
            bottom: isKeyboardOpen ? keyboardHeight + 10.h : 0,
            child: SafeArea(
              top: false,
              bottom: !isKeyboardOpen,
              child: WnSlate(
                header: WnSlateNavigationHeader(
                  title: context.l10n.relayResolutionTitle,
                  onNavigate: onCancel,
                ),
                systemNotice: relayResolutionState.error != null
                    ? WnSystemNotice(
                        key: ValueKey(relayResolutionState.error),
                        title: _resolveError(relayResolutionState.error!, context.l10n),
                        type: WnSystemNoticeType.error,
                        variant: WnSystemNoticeVariant.dismissible,
                        onDismiss: clearError,
                      )
                    : null,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
                  child: Column(
                    spacing: 12.h,
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        child: Text(
                          context.l10n.relayResolutionDescription,
                          style: typography.medium14.copyWith(
                            color: colors.fillContentSecondary,
                          ),
                        ),
                      ),
                      WnInput(
                        key: const Key('relay_url_input'),
                        label: context.l10n.relayResolutionRelayLabel,
                        placeholder: context.l10n.relayResolutionRelayPlaceholder,
                        controller: relayUrlController,
                        errorText: validationError != null
                            ? _resolveError(validationError, context.l10n)
                            : null,
                        onChanged: (_) => clearError(),
                        textInputAction: TextInputAction.done,
                        trailingAction: WnInputTrailingButton(
                          key: Key(trailingKey),
                          icon: trailingIcon,
                          onPressed: handleTrailingAction,
                        ),
                      ),
                      Column(
                        spacing: 8.h,
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          WnButton(
                            key: const Key('try_custom_relay_button'),
                            text: context.l10n.relayResolutionTryRelay,
                            onPressed: onTryCustomRelay,
                            loading: relayResolutionState.isSearchingRelay,
                            disabled: !isRelayUrlValid || relayResolutionState.isLoading,
                          ),
                          WnButton(
                            key: const Key('use_default_relays_button'),
                            text: context.l10n.relayResolutionUseDefaults,
                            type: WnButtonType.outline,
                            onPressed: onPublishDefaults,
                            loading: relayResolutionState.isPublishingDefaults,
                            disabled: relayResolutionState.isLoading,
                          ),
                        ],
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
