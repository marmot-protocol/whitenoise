import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_auth_buttons_container.dart' show WnAuthButtonsContainer;
import 'package:whitenoise/widgets/wn_logo_slogan.dart';
import 'package:whitenoise/widgets/wn_slate.dart' show WnSlate;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        WnLogoSlogan(
                          texts: [
                            l10n.sloganDecentralized,
                            l10n.sloganUncensorable,
                            l10n.sloganSecureMessaging,
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            WnSlate(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 14.w),
                child: const WnAuthButtonsContainer(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
