import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/providers/is_adding_account_provider.dart';
import 'package:whitenoise/providers/offline_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/offline_system_notice.dart';
import 'package:whitenoise/widgets/wn_auth_buttons_container.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';

class AddProfileScreen extends ConsumerWidget {
  const AddProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final isOffline = ref.watch(offlineProvider).value ?? false;

    void navigateToLogin() {
      if (isOffline) return;
      ref.read(isAddingAccountProvider.notifier).set(true);
      Routes.pushToLogin(context);
    }

    void navigateToSignup() {
      if (isOffline) return;
      ref.read(isAddingAccountProvider.notifier).set(true);
      Routes.pushToSignup(context);
    }

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: WnSlate(
            shrinkWrapContent: true,
            header: WnSlateNavigationHeader(
              title: context.l10n.addNewProfile,
              onNavigate: () => Routes.goBack(context),
            ),
            systemNotice: isOffline ? const OfflineSystemNotice() : null,
            child: Padding(
              padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  WnAuthButtonsContainer(
                    onLogin: navigateToLogin,
                    onSignup: navigateToSignup,
                    disabled: isOffline,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
