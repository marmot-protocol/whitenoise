import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise_frb/src/rust/api/accounts.dart' as accounts_api;
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/routes.dart';

final _logger = Logger('useAccounts');

class AccountsState {
  final bool isSwitching;
  final String? error;

  const AccountsState({
    this.isSwitching = false,
    this.error,
  });

  AccountsState copyWith({
    bool? isSwitching,
    String? error,
    bool clearError = false,
  }) {
    return AccountsState(
      isSwitching: isSwitching ?? this.isSwitching,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

({
  AsyncSnapshot<List<accounts_api.Account>> accounts,
  AccountsState state,
  Future<void> Function(String pubkey) switchTo,
})
useAccounts(BuildContext context, WidgetRef ref, String? currentPubkey) {
  final accountsFuture = useMemoized(() => accounts_api.getAccounts());
  final accountsSnapshot = useFuture(accountsFuture);
  final state = useState(const AccountsState());

  Future<void> switchTo(String pubkey) async {
    if (pubkey == currentPubkey) {
      Routes.goBack(context);
      return;
    }

    state.value = state.value.copyWith(isSwitching: true, clearError: true);
    try {
      await ref.read(authProvider.notifier).switchProfile(pubkey);
      if (context.mounted) {
        state.value = state.value.copyWith(isSwitching: false);
        Routes.goBack(context);
      }
    } catch (e, stackTrace) {
      _logger.severe('Failed to switch profile', e, stackTrace);
      state.value = state.value.copyWith(
        isSwitching: false,
        error: 'Failed to switch profile. Please try again.',
      );
    }
  }

  return (
    accounts: accountsSnapshot,
    state: state.value,
    switchTo: switchTo,
  );
}
