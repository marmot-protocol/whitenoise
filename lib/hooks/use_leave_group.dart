import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/src/rust/api/groups.dart' show GroupType, RequiredProposal;
import 'package:whitenoise/src/rust/api/groups.dart' as groups_api;

enum LeaveGroupVisibility { visible, hidden, disabled }

enum LeaveGroupMessage { defaultWarning, lastAdminWarning, noCapabilities, fetchError }

typedef LeaveGroupState = ({
  LeaveGroupVisibility visibility,
  LeaveGroupMessage? message,
  bool isLoading,
  Future<void> Function() leaveGroup,
});

final _logger = Logger('useLeaveGroup');

LeaveGroupState useLeaveGroup({
  required String accountPubkey,
  required String groupId,
  required GroupType groupType,
  required bool pendingConfirmation,
  required bool selfRemoved,
}) {
  final hasNostrCapabilities = useState(false);
  final proposalsFetchFailed = useState(false);
  final adminPubkeys = useState<List<String>>([]);
  final isLoading = useState(false);
  final isDisposed = useRef(false);
  useEffect(
    () =>
        () => isDisposed.value = true,
    const [],
  );

  useEffect(() {
    if (groupType == GroupType.directMessage || pendingConfirmation || selfRemoved) {
      hasNostrCapabilities.value = false;
      proposalsFetchFailed.value = false;
      adminPubkeys.value = [];
      return null;
    }

    var isStale = false;
    hasNostrCapabilities.value = false;
    proposalsFetchFailed.value = false;
    adminPubkeys.value = [];

    Future<void> fetch() async {
      await Future.wait([
        groups_api
            .groupRequiredProposals(accountPubkey: accountPubkey, groupId: groupId)
            .then((proposals) {
              if (!isStale) {
                hasNostrCapabilities.value = proposals.contains(RequiredProposal.selfRemove);
              }
            })
            .catchError((Object e, StackTrace st) {
              _logger.severe('Failed to fetch required proposals', e, st);
              if (!isStale) {
                proposalsFetchFailed.value = true;
              }
            }),
        groups_api
            .groupAdmins(pubkey: accountPubkey, groupId: groupId)
            .then((admins) {
              if (!isStale) {
                adminPubkeys.value = admins;
              }
            })
            .catchError((Object e, StackTrace st) {
              _logger.severe('Failed to fetch group admins', e, st);
              if (!isStale) {
                adminPubkeys.value = [];
              }
            }),
      ]);
    }

    fetch();
    return () => isStale = true;
  }, [accountPubkey, groupId, groupType, pendingConfirmation, selfRemoved]);

  final isAdmin = adminPubkeys.value.contains(accountPubkey);
  final isLastAdmin = isAdmin && adminPubkeys.value.length == 1;

  final LeaveGroupVisibility visibility;
  final LeaveGroupMessage? message;

  if (groupType == GroupType.directMessage || pendingConfirmation || selfRemoved) {
    visibility = LeaveGroupVisibility.hidden;
    message = null;
  } else if (proposalsFetchFailed.value) {
    visibility = LeaveGroupVisibility.disabled;
    message = LeaveGroupMessage.fetchError;
  } else if (!hasNostrCapabilities.value) {
    visibility = LeaveGroupVisibility.disabled;
    message = LeaveGroupMessage.noCapabilities;
  } else if (isLastAdmin) {
    visibility = LeaveGroupVisibility.disabled;
    message = LeaveGroupMessage.lastAdminWarning;
  } else {
    visibility = LeaveGroupVisibility.visible;
    message = LeaveGroupMessage.defaultWarning;
  }

  Future<void> leaveGroup() async {
    if (visibility != LeaveGroupVisibility.visible) return;
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      if (isAdmin) {
        await groups_api.selfDemote(pubkey: accountPubkey, groupId: groupId);
      }
      await groups_api.leaveGroup(pubkey: accountPubkey, groupId: groupId);
    } catch (e, st) {
      _logger.severe('Failed to leave group', e, st);
      rethrow;
    } finally {
      if (!isDisposed.value) isLoading.value = false;
    }
  }

  return (
    visibility: visibility,
    message: message,
    isLoading: isLoading.value,
    leaveGroup: leaveGroup,
  );
}
