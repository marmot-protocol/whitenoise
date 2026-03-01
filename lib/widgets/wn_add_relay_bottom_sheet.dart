import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/hooks/use_add_relay.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/utils/relay_url_validation.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_icon.dart' show WnIcons;
import 'package:whitenoise/widgets/wn_input.dart' show WnInput, WnInputTrailingButton;

class WnAddRelayBottomSheet extends HookWidget {
  final Future<void> Function(String) onRelayAdded;

  const WnAddRelayBottomSheet({
    super.key,
    required this.onRelayAdded,
  });

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
    final (:controller, :isValid, :validationError, :paste) = useAddRelay();

    final validationErrorText = validationError == null
        ? null
        : switch (validationError) {
            RelayValidationError.invalidScheme => context.l10n.invalidRelayUrlScheme,
            RelayValidationError.invalidUrl => context.l10n.invalidRelayUrl,
          };

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
              errorText: validationErrorText,
              trailingAction: WnInputTrailingButton(
                key: const Key('paste_button'),
                icon: WnIcons.paste,
                onPressed: paste,
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
