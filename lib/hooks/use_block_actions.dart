import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/src/rust/api/mute_list.dart' as mute_list_api;

final _logger = Logger('useBlockActions');

typedef BlockActionsState = ({
  bool isBlocked,
  bool isLoading,
  bool isActionLoading,
  String? error,
  void Function() clearError,
  Future<void> Function() toggleBlock,
});

BlockActionsState useBlockActions({
  required String accountPubkey,
  required String? userPubkey,
  int refreshKey = 0,
}) {
  final isBlocked = useState<bool?>(null);
  final isLoading = useState(true);
  final isActionLoading = useState(false);
  final error = useState<String?>(null);

  useEffect(() {
    if (userPubkey == null) {
      isBlocked.value = null;
      isLoading.value = false;
      return null;
    }

    var cancelled = false;
    isLoading.value = true;

    Future<void> fetchIsBlocked() async {
      try {
        final result = await mute_list_api.isUserBlocked(
          accountPubkey: accountPubkey,
          targetPubkey: userPubkey,
        );
        if (cancelled) return;
        isBlocked.value = result;
      } catch (e) {
        if (cancelled) return;
        _logger.severe('Failed to fetch block status: $e');
        isBlocked.value = false;
      } finally {
        if (!cancelled) isLoading.value = false;
      }
    }

    fetchIsBlocked();
    return () => cancelled = true;
  }, [accountPubkey, userPubkey, refreshKey]);

  void clearError() {
    error.value = null;
  }

  Future<void> block() async {
    if (userPubkey == null) return;
    isActionLoading.value = true;
    error.value = null;
    try {
      await mute_list_api.blockUser(
        accountPubkey: accountPubkey,
        targetPubkey: userPubkey,
      );
      isBlocked.value = true;
    } catch (e) {
      _logger.severe('Failed to block user: $e');
      error.value = 'Failed to block user';
      rethrow;
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<void> unblock() async {
    if (userPubkey == null) return;
    isActionLoading.value = true;
    error.value = null;
    try {
      await mute_list_api.unblockUser(
        accountPubkey: accountPubkey,
        targetPubkey: userPubkey,
      );
      isBlocked.value = false;
    } catch (e) {
      _logger.severe('Failed to unblock user: $e');
      error.value = 'Failed to unblock user';
      rethrow;
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<void> toggleBlock() async {
    if (userPubkey == null || isLoading.value) return;
    if (isBlocked.value == true) {
      await unblock();
    } else {
      await block();
    }
  }

  return (
    isBlocked: isBlocked.value ?? false,
    isLoading: isLoading.value,
    isActionLoading: isActionLoading.value,
    error: error.value,
    clearError: clearError,
    toggleBlock: toggleBlock,
  );
}
