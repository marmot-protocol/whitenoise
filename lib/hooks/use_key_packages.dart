import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/src/rust/api/accounts.dart' as accounts_api;

final _logger = Logger('useKeyPackages');

class KeyPackagesState {
  final bool isLoading;
  final List<accounts_api.FlutterEvent> packages;
  final bool hasError;

  const KeyPackagesState({
    this.isLoading = false,
    this.packages = const [],
    this.hasError = false,
  });

  KeyPackagesState copyWith({
    bool? isLoading,
    List<accounts_api.FlutterEvent>? packages,
    bool? hasError,
  }) {
    return KeyPackagesState(
      isLoading: isLoading ?? this.isLoading,
      packages: packages ?? this.packages,
      hasError: hasError ?? this.hasError,
    );
  }
}

enum KeyPackageAction { fetch, publish, delete, deleteAll }

typedef KeyPackageResult = ({bool success, KeyPackageAction action});

({
  KeyPackagesState state,
  Future<KeyPackageResult> Function() fetch,
  Future<KeyPackageResult> Function() publish,
  Future<KeyPackageResult> Function(String id) delete,
  Future<KeyPackageResult> Function() deleteAll,
})
useKeyPackages(String pubkey) {
  final state = useState(const KeyPackagesState());

  Future<KeyPackageResult> fetch() async {
    if (state.value.isLoading) {
      return (success: false, action: KeyPackageAction.fetch);
    }
    state.value = state.value.copyWith(isLoading: true, hasError: false);
    try {
      final packages = await accounts_api.accountKeyPackages(accountPubkey: pubkey);
      state.value = state.value.copyWith(isLoading: false, packages: packages);
      return (success: true, action: KeyPackageAction.fetch);
    } catch (e) {
      _logger.severe('Failed to fetch key packages', e);
      state.value = state.value.copyWith(isLoading: false, hasError: true);
      return (success: false, action: KeyPackageAction.fetch);
    }
  }

  Future<KeyPackageResult> publish() async {
    if (state.value.isLoading) {
      return (success: false, action: KeyPackageAction.publish);
    }
    state.value = state.value.copyWith(isLoading: true, hasError: false);
    try {
      await accounts_api.publishAccountKeyPackage(accountPubkey: pubkey);
      final packages = await accounts_api.accountKeyPackages(accountPubkey: pubkey);
      state.value = state.value.copyWith(isLoading: false, packages: packages);
      return (success: true, action: KeyPackageAction.publish);
    } catch (e) {
      _logger.severe('Failed to publish key package', e);
      state.value = state.value.copyWith(isLoading: false, hasError: true);
      return (success: false, action: KeyPackageAction.publish);
    }
  }

  Future<KeyPackageResult> delete(String id) async {
    if (state.value.isLoading) {
      return (success: false, action: KeyPackageAction.delete);
    }
    state.value = state.value.copyWith(isLoading: true, hasError: false);
    try {
      await accounts_api.deleteAccountKeyPackage(accountPubkey: pubkey, keyPackageId: id);
      final packages = await accounts_api.accountKeyPackages(accountPubkey: pubkey);
      state.value = state.value.copyWith(isLoading: false, packages: packages);
      return (success: true, action: KeyPackageAction.delete);
    } catch (e) {
      _logger.severe('Failed to delete key package', e);
      state.value = state.value.copyWith(isLoading: false, hasError: true);
      return (success: false, action: KeyPackageAction.delete);
    }
  }

  Future<KeyPackageResult> deleteAll() async {
    if (state.value.isLoading) {
      return (success: false, action: KeyPackageAction.deleteAll);
    }
    state.value = state.value.copyWith(isLoading: true, hasError: false);
    try {
      await accounts_api.deleteAccountKeyPackages(accountPubkey: pubkey);
      state.value = state.value.copyWith(isLoading: false, packages: []);
      return (success: true, action: KeyPackageAction.deleteAll);
    } catch (e) {
      _logger.severe('Failed to delete all key packages', e);
      state.value = state.value.copyWith(isLoading: false, hasError: true);
      return (success: false, action: KeyPackageAction.deleteAll);
    }
  }

  return (
    state: state.value,
    fetch: fetch,
    publish: publish,
    delete: delete,
    deleteAll: deleteAll,
  );
}
