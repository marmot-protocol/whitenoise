import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/hooks/use_network_relays.dart' show RelayCategory;
import 'package:whitenoise/hooks/use_relay_input.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_input.dart' show WnInput, WnInputSize, WnInputTrailingButton;
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';

String _resolveValidationError(String errorKey, AppLocalizations l10n) {
  return switch (errorKey) {
    'invalidRelayUrlScheme' => l10n.invalidRelayUrlScheme,
    _ => l10n.invalidRelayUrl,
  };
}

class AddRelayScreen extends HookWidget {
  const AddRelayScreen({
    super.key,
    required this.category,
    required this.onRelayAdded,
  });

  final RelayCategory category;
  final Future<void> Function(String) onRelayAdded;

  String _title(BuildContext context) {
    return switch (category) {
      RelayCategory.normal => context.l10n.addMyRelay,
      RelayCategory.inbox => context.l10n.addInboxRelay,
      RelayCategory.keyPackage => context.l10n.addKeyPackageRelay,
    };
  }

  @override
  Widget build(BuildContext context) {
    final (
      :controller,
      :isValid,
      :validationError,
      :handleTrailingAction,
      :trailingIcon,
      :trailingKey,
    ) = useRelayInput();

    Future<void> addRelay() async {
      final relayUrl = controller.text.trim();
      if (relayUrl.isEmpty) return;

      await onRelayAdded(relayUrl);
      if (context.mounted) Routes.goBack(context);
    }

    return Scaffold(
      backgroundColor: context.colors.backgroundPrimary,
      body: SafeArea(
        child: WnSlate(
          shrinkWrapContent: true,
          header: WnSlateNavigationHeader(
            title: _title(context),
            onNavigate: () => Routes.goBack(context),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                WnInput(
                  label: context.l10n.enterRelayAddress,
                  placeholder: 'wss://relay.example.com',
                  controller: controller,
                  size: WnInputSize.size44,
                  errorText: validationError != null
                      ? _resolveValidationError(validationError, context.l10n)
                      : null,
                  trailingAction: WnInputTrailingButton(
                    key: Key(trailingKey),
                    icon: trailingIcon,
                    size: WnInputSize.size44,
                    onPressed: handleTrailingAction,
                  ),
                ),
                Gap(12.h),
                WnButton(
                  key: const Key('add_relay_submit_button'),
                  onPressed: isValid ? addRelay : null,
                  text: context.l10n.addRelay,
                  size: WnButtonSize.medium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
