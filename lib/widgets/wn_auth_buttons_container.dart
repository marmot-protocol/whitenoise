import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/widgets/wn_button.dart';

class WnAuthButtonsContainer extends StatelessWidget {
  const WnAuthButtonsContainer({
    super.key,
    this.onLogin,
    this.onSignup,
    this.disabled = false,
  });

  final VoidCallback? onLogin;
  final VoidCallback? onSignup;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WnButton(
          text: context.l10n.login,
          type: WnButtonType.outline,
          onPressed: disabled ? null : (onLogin ?? () => Routes.pushToLogin(context)),
          disabled: disabled,
        ),
        Gap(12.h),
        WnButton(
          text: context.l10n.signUp,
          onPressed: disabled ? null : (onSignup ?? () => Routes.pushToSignup(context)),
          disabled: disabled,
        ),
      ],
    );
  }
}
