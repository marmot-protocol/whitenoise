import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/src/rust/api/accounts.dart' show LoginResult;
import 'package:whitenoise/src/rust/api/error.dart';

final _logger = Logger('useLoginWithNsec');

class LoginWithNsecState {
  final bool isLoading;
  final String? error;

  const LoginWithNsecState({
    this.isLoading = false,
    this.error,
  });

  LoginWithNsecState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return LoginWithNsecState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

typedef LoginStartCallback = Future<LoginResult> Function(String nsec);

String _loginErrorMessage(Object error) {
  return switch (error) {
    ApiError_LoginInvalidKeyFormat() => 'loginErrorInvalidKey',
    ApiError_LoginNoRelayConnections() => 'loginErrorNoRelayConnections',
    ApiError_LoginTimeout() => 'loginErrorTimeout',
    ApiError_LoginNoLoginInProgress() => 'loginErrorNoLoginInProgress',
    ApiError_LoginInternal() => 'loginErrorInternal',
    _ => 'loginErrorGeneric',
  };
}

({
  TextEditingController nsecInputController,
  LoginWithNsecState loginWithNsecState,
  Future<void> Function() pasteNsec,
  Future<LoginResult?> Function() submitLoginWithNsec,
  void Function() clearLoginWithNsecError,
})
useLoginWithNsec(LoginStartCallback loginStart) {
  final controller = useTextEditingController();
  final state = useState(const LoginWithNsecState());

  useEffect(() {
    return () => controller.clear();
  }, const []);

  Future<void> paste() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text == null) {
        return;
      }

      final trimmedText = clipboardData!.text!.trim();
      if (trimmedText.isEmpty) {
        state.value = state.value.copyWith(
          error: 'loginPasteNothingToPaste',
        );
        return;
      }

      controller.text = trimmedText;
      state.value = state.value.copyWith(clearError: true);
    } catch (e) {
      _logger.warning('Failed to paste from clipboard: $e');
      state.value = state.value.copyWith(
        error: 'loginPasteFailed',
      );
    }
  }

  Future<LoginResult?> submit() async {
    final nsec = controller.text.trim();
    if (nsec.isEmpty) return null;

    state.value = state.value.copyWith(isLoading: true, clearError: true);

    try {
      final result = await loginStart(nsec);
      state.value = state.value.copyWith(isLoading: false);
      return result;
    } catch (e, stackTrace) {
      _logger.severe('Login failed', e, stackTrace);
      state.value = state.value.copyWith(
        isLoading: false,
        error: _loginErrorMessage(e),
      );
      return null;
    }
  }

  void clearError() {
    if (state.value.error != null) {
      state.value = state.value.copyWith(clearError: true);
    }
  }

  return (
    nsecInputController: controller,
    loginWithNsecState: state.value,
    pasteNsec: paste,
    submitLoginWithNsec: submit,
    clearLoginWithNsecError: clearError,
  );
}
