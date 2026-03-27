import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/src/rust/api/accounts.dart' as accounts_api;

final _logger = Logger('useFollowActions');

typedef FollowActionsState = ({
  bool isFollowing,
  bool isLoading,
  bool isActionLoading,
  String? error,
  void Function() clearError,
  Future<void> Function() follow,
  Future<void> Function() unfollow,
  Future<void> Function() toggleFollow,
});

FollowActionsState useFollowActions({
  required String accountPubkey,
  required String? userPubkey,
}) {
  final isFollowing = useState<bool?>(null);
  final isLoading = useState(true);
  final isActionLoading = useState(false);
  final error = useState<String?>(null);

  useEffect(() {
    Future<void> fetchIsFollowing() async {
      if (userPubkey == null) return;
      isLoading.value = true;
      try {
        final result = await accounts_api.isFollowingUser(
          accountPubkey: accountPubkey,
          userPubkey: userPubkey,
        );
        isFollowing.value = result;
      } catch (e) {
        _logger.severe('Failed to fetch follow status: $e');
        isFollowing.value = false;
      } finally {
        isLoading.value = false;
      }
    }

    fetchIsFollowing();
    return null;
  }, [accountPubkey, userPubkey]);

  void clearError() {
    error.value = null;
  }

  Future<void> follow() async {
    if (userPubkey == null) return;
    isActionLoading.value = true;
    error.value = null;
    try {
      await accounts_api.followUser(
        accountPubkey: accountPubkey,
        userToFollowPubkey: userPubkey,
      );
      isFollowing.value = true;
    } catch (e) {
      _logger.severe('Failed to follow user: $e');
      error.value = 'Failed to follow user';
      rethrow;
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<void> unfollow() async {
    if (userPubkey == null) return;
    isActionLoading.value = true;
    error.value = null;
    try {
      await accounts_api.unfollowUser(
        accountPubkey: accountPubkey,
        userToUnfollowPubkey: userPubkey,
      );
      isFollowing.value = false;
    } catch (e) {
      _logger.severe('Failed to unfollow user: $e');
      error.value = 'Failed to unfollow user';
      rethrow;
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<void> toggleFollow() async {
    if (userPubkey == null) return;
    if (isFollowing.value == true) {
      await unfollow();
    } else {
      await follow();
    }
  }

  return (
    isFollowing: isFollowing.value ?? false,
    isLoading: isLoading.value,
    isActionLoading: isActionLoading.value,
    error: error.value,
    clearError: clearError,
    follow: follow,
    unfollow: unfollow,
    toggleFollow: toggleFollow,
  );
}
