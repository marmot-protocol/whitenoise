import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/hooks/use_relay_input.dart';
import 'package:whitenoise/src/rust/api/accounts.dart' show LoginResult, LoginStatus;
import 'package:whitenoise/src/rust/api/error.dart';
import 'package:whitenoise/utils/relay_url_validation.dart' show isRelayUrlEmpty;
import 'package:whitenoise/widgets/wn_icon.dart' show WnIcons;

final _logger = Logger('useRelayResolution');

class RelayResolutionState {
  final bool isPublishingDefaults;
  final bool isSearchingRelay;
  final String? error;

  const RelayResolutionState({
    this.isPublishingDefaults = false,
    this.isSearchingRelay = false,
    this.error,
  });

  bool get isLoading => isPublishingDefaults || isSearchingRelay;

  RelayResolutionState copyWith({
    bool? isPublishingDefaults,
    bool? isSearchingRelay,
    String? error,
    bool clearError = false,
  }) {
    return RelayResolutionState(
      isPublishingDefaults: isPublishingDefaults ?? this.isPublishingDefaults,
      isSearchingRelay: isSearchingRelay ?? this.isSearchingRelay,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

typedef PublishDefaultRelaysCallback = Future<LoginResult> Function(String pubkey);
typedef CustomRelayCallback = Future<LoginResult> Function(String pubkey, String relayUrl);
typedef CancelLoginCallback = Future<void> Function(String pubkey);

String _relayResolutionErrorMessage(Object error) {
  return switch (error) {
    ApiError_LoginNoRelayConnections() => 'loginErrorNoRelayConnections',
    ApiError_LoginTimeout() => 'loginErrorTimeout',
    ApiError_LoginInternal() => 'loginErrorInternal',
    _ => 'loginErrorGeneric',
  };
}

({
  TextEditingController relayUrlController,
  RelayResolutionState relayResolutionState,
  bool isRelayUrlValid,
  String? validationError,
  WnIcons trailingIcon,
  String trailingKey,
  void Function() handleTrailingAction,
  Future<bool> Function() publishDefaults,
  Future<bool> Function() tryCustomRelay,
  Future<void> Function() cancel,
  void Function() clearError,
})
useRelayResolution({
  required String pubkey,
  required PublishDefaultRelaysCallback publishDefaultRelays,
  required CustomRelayCallback customRelay,
  required CancelLoginCallback cancelLogin,
}) {
  final relayInput = useRelayInput();
  final state = useState(const RelayResolutionState());
  final isMounted = useRef(true);

  useEffect(() {
    return () {
      isMounted.value = false;
    };
  }, const []);

  Future<bool> publishDefaults() async {
    state.value = state.value.copyWith(isPublishingDefaults: true, clearError: true);

    try {
      final result = await publishDefaultRelays(pubkey);
      if (!isMounted.value) return false;
      state.value = state.value.copyWith(isPublishingDefaults: false);
      return result.status == LoginStatus.complete;
    } catch (e, stackTrace) {
      _logger.severe('Failed to publish default relays', e, stackTrace);
      if (!isMounted.value) return false;
      state.value = state.value.copyWith(
        isPublishingDefaults: false,
        error: _relayResolutionErrorMessage(e),
      );
      return false;
    }
  }

  Future<bool> tryCustomRelay() async {
    final relayUrl = relayInput.controller.text.trim();
    if (isRelayUrlEmpty(relayUrl)) return false;

    state.value = state.value.copyWith(isSearchingRelay: true, clearError: true);

    try {
      final result = await customRelay(pubkey, relayUrl);
      if (!isMounted.value) return false;
      state.value = state.value.copyWith(isSearchingRelay: false);

      if (result.status == LoginStatus.needsRelayLists) {
        state.value = state.value.copyWith(error: 'relayResolutionNotFound');
        return false;
      }

      return result.status == LoginStatus.complete;
    } catch (e, stackTrace) {
      _logger.severe('Failed to search custom relay', e, stackTrace);
      if (!isMounted.value) return false;
      state.value = state.value.copyWith(
        isSearchingRelay: false,
        error: _relayResolutionErrorMessage(e),
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
    relayUrlController: relayInput.controller,
    relayResolutionState: state.value,
    isRelayUrlValid: relayInput.isValid,
    validationError: relayInput.validationError,
    trailingIcon: relayInput.trailingIcon,
    trailingKey: relayInput.trailingKey,
    handleTrailingAction: relayInput.handleTrailingAction,
    publishDefaults: publishDefaults,
    tryCustomRelay: tryCustomRelay,
    cancel: cancel,
    clearError: clearError,
  );
}
