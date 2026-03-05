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
  });

  final VoidCallback? onLogin;
  final VoidCallback? onSignup;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WnButton(
          text: context.l10n.login,
          type: WnButtonType.outline,
          onPressed: onLogin ?? () => Routes.pushToLogin(context),
        ),
        Gap(12.h),
        WnButton(
          text: context.l10n.signUp,
          onPressed: onSignup ?? () => Routes.pushToSignup(context),
        ),
      ],
    );
  }
}
