import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/src/rust/api/accounts.dart' show LoginResult, LoginStatus;

final _logger = Logger('useRelayResolution');

class RelayResolutionState {
  final bool isLoading;
  final String? error;

  const RelayResolutionState({
    this.isLoading = false,
    this.error,
  });

  RelayResolutionState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return RelayResolutionState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

typedef PublishDefaultRelaysCallback = Future<LoginResult> Function(String pubkey);
typedef CustomRelayCallback = Future<LoginResult> Function(String pubkey, String relayUrl);
typedef CancelLoginCallback = Future<void> Function(String pubkey);

({
  TextEditingController relayUrlController,
  RelayResolutionState relayResolutionState,
  Future<bool> Function() publishDefaults,
  Future<bool> Function() tryCustomRelay,
  Future<void> Function() cancel,
  void Function() clearError,
})
useRelayResolution({
  required String pubkey,
  required bool isExternalSigner,
  required PublishDefaultRelaysCallback publishDefaultRelays,
  required CustomRelayCallback customRelay,
  required CancelLoginCallback cancelLogin,
}) {
  final controller = useTextEditingController();
  final state = useState(const RelayResolutionState());

  Future<bool> publishDefaults() async {
    state.value = state.value.copyWith(isLoading: true, clearError: true);

    try {
      final result = await publishDefaultRelays(pubkey);
      state.value = state.value.copyWith(isLoading: false);
      return result.status == LoginStatus.complete;
    } catch (e, stackTrace) {
      _logger.severe('Failed to publish default relays', e, stackTrace);
      state.value = state.value.copyWith(
        isLoading: false,
        error: 'relayResolutionPublishFailed',
      );
      return false;
    }
  }

  Future<bool> tryCustomRelay() async {
    final relayUrl = controller.text.trim();
    if (relayUrl.isEmpty) return false;

    state.value = state.value.copyWith(isLoading: true, clearError: true);

    try {
      final result = await customRelay(pubkey, relayUrl);
      state.value = state.value.copyWith(isLoading: false);

      if (result.status == LoginStatus.needsRelayLists) {
        state.value = state.value.copyWith(error: 'relayResolutionNotFound');
        return false;
      }

      return true;
    } catch (e, stackTrace) {
      _logger.severe('Failed to search custom relay', e, stackTrace);
      state.value = state.value.copyWith(
        isLoading: false,
        error: 'loginErrorGeneric',
      );
      return false;
    }
  }

  Future<void> cancel() async {
    try {
      await cancelLogin(pubkey);
    } catch (e, stackTrace) {
      _logger.warning('Failed to cancel login', e, stackTrace);
    }
  }

  void clearError() {
    if (state.value.error != null) {
      state.value = state.value.copyWith(clearError: true);
    }
  }

  return (
    relayUrlController: controller,
    relayResolutionState: state.value,
    publishDefaults: publishDefaults,
    tryCustomRelay: tryCustomRelay,
    cancel: cancel,
    clearError: clearError,
  );
}
