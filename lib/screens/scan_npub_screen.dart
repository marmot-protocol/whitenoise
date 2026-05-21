import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart' show Gap;
import 'package:go_router/go_router.dart' show GoRouter;
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/routes.dart' show Routes;
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/utils/deep_links.dart' show DeepLinks;
import 'package:whitenoise/utils/encoding.dart' show hexFromNpub;
import 'package:whitenoise/widgets/qr_scanner.dart' show QrScanner;
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';

class ScanNpubScreen extends HookWidget {
  const ScanNpubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final showInvalidNpubError = useState(false);

    void onBarcodeDetected(String value) {
      final deepLinkTarget = DeepLinks.parseString(value);
      if (deepLinkTarget != null) {
        Routes.goBack(context);
        GoRouter.of(context).push(deepLinkTarget.location);
        return;
      }

      final hexPubkey = hexFromNpub(value);
      if (hexPubkey != null) {
        Routes.goBack(context);
        Routes.pushToUserProfile(context, hexPubkey, topAligned: true);
      } else if (value.startsWith('npub1')) {
        showInvalidNpubError.value = true;
      }
    }

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: SafeArea(
        child: WnSlate(
          header: WnSlateNavigationHeader(
            title: l10n.scanNpub,
            onNavigate: () => Routes.goBack(context),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: QrScanner(
                    onBarcodeDetected: onBarcodeDetected,
                  ),
                ),
                Gap(12.h),
                Text(
                  showInvalidNpubError.value ? l10n.invalidNpub : l10n.scanNpubHint,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: showInvalidNpubError.value
                        ? colors.backgroundContentDestructive
                        : colors.backgroundContentSecondary,
                  ),
                ),
                Gap(12.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
