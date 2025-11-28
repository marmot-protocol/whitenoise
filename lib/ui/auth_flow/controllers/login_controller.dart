import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/routing/routes.dart';
import 'package:whitenoise/ui/auth_flow/qr_scanner_screen.dart';
import 'package:whitenoise/utils/clipboard_utils.dart';
import 'package:whitenoise/utils/localization_extensions.dart';

class LoginController {
  final Ref ref;
  final BuildContext context;

  LoginController(this.ref, this.context);

  Future<void> onContinuePressed(String key) async {
    if (key.isEmpty) {
      ref.showErrorToast('auth.pleaseEnterPrivateKey'.tr());
      return;
    }

    final authNotifier = ref.read(authProvider.notifier);

    // Use the regular login method that shows loading state
    await authNotifier.loginWithKey(key);

    final authState = ref.read(authProvider);

    if (authState.isAuthenticated && authState.error == null) {
      if (!context.mounted) return;
      context.go(Routes.chats);
    } else if (authState.error != null) {
      // Error is already shown by the auth provider via toast
      // No need to show additional error here
    }
  }

  Future<String?> scanQRCode() async {
    return await QRScannerScreen.navigate(context);
  }

  Future<void> pasteFromClipboard(Function(String) onPaste) async {
    await ClipboardUtils.pasteWithToast(
      ref: ref,
      onPaste: onPaste,
    );
  }
}

final loginControllerProvider = Provider.autoDispose.family<LoginController, BuildContext>((
  ref,
  context,
) {
  return LoginController(ref, context);
});
