import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/hooks/use_relay_input.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_input.dart' show WnInput, WnInputTrailingButton;

String _resolveValidationError(String errorKey, AppLocalizations l10n) {
  return switch (errorKey) {
    'invalidRelayUrlScheme' => l10n.invalidRelayUrlScheme,
    'invalidRelayUrl' => l10n.invalidRelayUrl,
    _ => l10n.invalidRelayUrl,
  };
}

class WnAddRelayBottomSheet extends HookWidget {
  final Future<void> Function(String) onRelayAdded;

  const WnAddRelayBottomSheet({super.key, required this.onRelayAdded});

  static Future<void> show({
    required BuildContext context,
    required Future<void> Function(String) onRelayAdded,
  }) async {
    final colors = context.colors;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.backgroundTertiary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: WnAddRelayBottomSheet(onRelayAdded: onRelayAdded),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
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

      Navigator.of(context).pop();
      await onRelayAdded(relayUrl);
    }

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: colors.borderTertiary,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            Gap(16.h),
            Text(
              context.l10n.addRelay,
              style: context.typographyScaled.semiBold18.copyWith(
                color: colors.backgroundContentPrimary,
              ),
            ),
            Gap(16.h),
            WnInput(
              label: context.l10n.enterRelayAddress,
              placeholder: 'wss://relay.example.com',
              controller: controller,
              errorText: validationError != null
                  ? _resolveValidationError(validationError, context.l10n)
                  : null,
              trailingAction: WnInputTrailingButton(
                key: Key(trailingKey),
                icon: trailingIcon,
                onPressed: handleTrailingAction,
              ),
            ),
            Gap(16.h),
            SizedBox(
              width: double.infinity,
              child: WnButton(
                key: const Key('add_relay_submit_button'),
                onPressed: isValid ? addRelay : null,
                text: context.l10n.addRelay,
                disabled: !isValid,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
