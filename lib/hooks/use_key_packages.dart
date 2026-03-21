import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/src/rust/api/accounts.dart' as accounts_api;

final _logger = Logger('useKeyPackages');

sealed class KeyPackagesStatus {
  const KeyPackagesStatus();
}

class KeyPackagesIdle extends KeyPackagesStatus {
  const KeyPackagesIdle();
}

class KeyPackagesLoading extends KeyPackagesStatus {
  final KeyPackageAction action;
  const KeyPackagesLoading(this.action);
}

class KeyPackagesError extends KeyPackagesStatus {
  const KeyPackagesError();
}

class KeyPackagesState {
  final KeyPackagesStatus status;
  final List<accounts_api.FlutterEvent> packages;
  final String? deletingId;

  const KeyPackagesState({
    this.status = const KeyPackagesIdle(),
    this.packages = const [],
    this.deletingId,
  });

  KeyPackagesState copyWith({
    KeyPackagesStatus? status,
    List<accounts_api.FlutterEvent>? packages,
    String? deletingId,
    bool clearDeletingId = false,
  }) {
    return KeyPackagesState(
      status: status ?? this.status,
      packages: packages ?? this.packages,
      deletingId: clearDeletingId ? null : (deletingId ?? this.deletingId),
    );
  }

  bool get isLoading => status is KeyPackagesLoading;
  bool get hasError => status is KeyPackagesError;
  KeyPackageAction? get activeAction =>
      status is KeyPackagesLoading ? (status as KeyPackagesLoading).action : null;
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
  final isMountedRef = useRef(true);
  final refreshKey = useRef(0);

  useEffect(() {
    return () {
      isMountedRef.value = false;
    };
  }, const []);

  useEffect(() {
    state.value = const KeyPackagesState();
    refreshKey.value++;
    return null;
  }, [pubkey]);

  Future<KeyPackageResult> fetch() async {
    if (state.value.isLoading) {
      return (success: false, action: KeyPackageAction.fetch);
    }
    final currentRefreshKey = refreshKey.value;
    state.value = state.value.copyWith(
      status: const KeyPackagesLoading(KeyPackageAction.fetch),
    );
    try {
      final packages = await accounts_api.accountKeyPackages(accountPubkey: pubkey);
      if (!isMountedRef.value || refreshKey.value != currentRefreshKey) {
        return (success: true, action: KeyPackageAction.fetch);
      }
      state.value = state.value.copyWith(status: const KeyPackagesIdle(), packages: packages);
      return (success: true, action: KeyPackageAction.fetch);
    } catch (e) {
      _logger.severe('Failed to fetch key packages', e);
      if (!isMountedRef.value || refreshKey.value != currentRefreshKey) {
        return (success: false, action: KeyPackageAction.fetch);
      }
      state.value = state.value.copyWith(status: const KeyPackagesError());
      return (success: false, action: KeyPackageAction.fetch);
    }
  }

  Future<KeyPackageResult> publish() async {
    if (state.value.isLoading) {
      return (success: false, action: KeyPackageAction.publish);
    }
    final currentRefreshKey = refreshKey.value;
    state.value = state.value.copyWith(
      status: const KeyPackagesLoading(KeyPackageAction.publish),
    );
    try {
      await accounts_api.publishAccountKeyPackage(accountPubkey: pubkey);
    } catch (e) {
      _logger.severe('Failed to publish key package', e);
      if (!isMountedRef.value || refreshKey.value != currentRefreshKey) {
        return (success: false, action: KeyPackageAction.publish);
      }
      state.value = state.value.copyWith(status: const KeyPackagesError());
      return (success: false, action: KeyPackageAction.publish);
    }
    try {
      if (!isMountedRef.value || refreshKey.value != currentRefreshKey) {
        return (success: true, action: KeyPackageAction.publish);
      }
      final packages = await accounts_api.accountKeyPackages(accountPubkey: pubkey);
      if (!isMountedRef.value || refreshKey.value != currentRefreshKey) {
        return (success: true, action: KeyPackageAction.publish);
      }
      state.value = state.value.copyWith(status: const KeyPackagesIdle(), packages: packages);
    } catch (e) {
      _logger.severe('Failed to refresh key packages after publish', e);
      if (isMountedRef.value && refreshKey.value == currentRefreshKey) {
        state.value = state.value.copyWith(status: const KeyPackagesIdle());
      }
    }
    return (success: true, action: KeyPackageAction.publish);
  }

  Future<KeyPackageResult> delete(String id) async {
    if (state.value.isLoading) {
      return (success: false, action: KeyPackageAction.delete);
    }
    final currentRefreshKey = refreshKey.value;
    state.value = state.value.copyWith(
      status: const KeyPackagesLoading(KeyPackageAction.delete),
      deletingId: id,
    );
    try {
      await accounts_api.deleteAccountKeyPackage(accountPubkey: pubkey, keyPackageId: id);
    } catch (e) {
      _logger.severe('Failed to delete key package', e);
      if (!isMountedRef.value || refreshKey.value != currentRefreshKey) {
        return (success: false, action: KeyPackageAction.delete);
      }
      state.value = state.value.copyWith(
        status: const KeyPackagesError(),
        clearDeletingId: true,
      );
      return (success: false, action: KeyPackageAction.delete);
    }
    try {
      if (!isMountedRef.value || refreshKey.value != currentRefreshKey) {
        return (success: true, action: KeyPackageAction.delete);
      }
      final packages = await accounts_api.accountKeyPackages(accountPubkey: pubkey);
      if (!isMountedRef.value || refreshKey.value != currentRefreshKey) {
        return (success: true, action: KeyPackageAction.delete);
      }
      state.value = state.value.copyWith(
        status: const KeyPackagesIdle(),
        packages: packages,
        clearDeletingId: true,
      );
      return (success: true, action: KeyPackageAction.delete);
    } catch (e) {
      _logger.severe('Failed to refresh key packages after delete', e);
      if (isMountedRef.value && refreshKey.value == currentRefreshKey) {
        state.value = state.value.copyWith(
          status: const KeyPackagesIdle(),
          clearDeletingId: true,
        );
      }
      return (success: false, action: KeyPackageAction.delete);
    }
  }

  Future<KeyPackageResult> deleteAll() async {
    if (state.value.isLoading) {
      return (success: false, action: KeyPackageAction.deleteAll);
    }
    final currentRefreshKey = refreshKey.value;
    state.value = state.value.copyWith(
      status: const KeyPackagesLoading(KeyPackageAction.deleteAll),
    );
    try {
      await accounts_api.deleteAccountKeyPackages(accountPubkey: pubkey);
      if (!isMountedRef.value || refreshKey.value != currentRefreshKey) {
        return (success: true, action: KeyPackageAction.deleteAll);
      }
      state.value = state.value.copyWith(status: const KeyPackagesIdle(), packages: []);
      return (success: true, action: KeyPackageAction.deleteAll);
    } catch (e) {
      _logger.severe('Failed to delete all key packages', e);
      if (!isMountedRef.value || refreshKey.value != currentRefreshKey) {
        return (success: false, action: KeyPackageAction.deleteAll);
      }
      state.value = state.value.copyWith(status: const KeyPackagesError());
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
