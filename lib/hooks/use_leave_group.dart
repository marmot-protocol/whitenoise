import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/src/rust/api/groups.dart' show GroupType, RequiredProposal;
import 'package:whitenoise/src/rust/api/groups.dart' as groups_api;

typedef LeaveGroupState = ({
  bool canLeave,
  bool isLoading,
  Future<void> Function() leaveGroup,
});

final _logger = Logger('useLeaveGroup');

LeaveGroupState useLeaveGroup({
  required String accountPubkey,
  required String groupId,
  required bool featureEnabled,
  required GroupType groupType,
  required bool pendingConfirmation,
  required bool selfRemoved,
}) {
  final hasNostrCapabilities = useState(false);
  final isLoading = useState(false);
  final isDisposed = useRef(false);
  useEffect(
    () =>
        () => isDisposed.value = true,
    const [],
  );

  useEffect(() {
    if (!featureEnabled ||
        groupType == GroupType.directMessage ||
        pendingConfirmation ||
        selfRemoved) {
      hasNostrCapabilities.value = false;
      return null;
    }

    var isStale = false;
    hasNostrCapabilities.value = false;
    Future<void> fetch() async {
      try {
        final proposals = await groups_api.groupRequiredProposals(
          accountPubkey: accountPubkey,
          groupId: groupId,
        );
        if (!isStale) {
          hasNostrCapabilities.value = proposals.contains(RequiredProposal.selfRemove);
        }
      } catch (e, st) {
        _logger.severe('Failed to fetch required proposals', e, st);
        if (!isStale) hasNostrCapabilities.value = false;
      }
    }

    fetch();
    return () => isStale = true;
  }, [accountPubkey, groupId, featureEnabled, groupType, pendingConfirmation, selfRemoved]);

  final isEligibleToLeave =
      featureEnabled &&
      groupType != GroupType.directMessage &&
      !pendingConfirmation &&
      !selfRemoved &&
      hasNostrCapabilities.value;

  Future<void> leaveGroup() async {
    if (!isEligibleToLeave) return;
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      await groups_api.leaveGroup(pubkey: accountPubkey, groupId: groupId);
    } catch (e, st) {
      _logger.severe('Failed to leave group', e, st);
      rethrow;
    } finally {
      if (!isDisposed.value) isLoading.value = false;
    }
  }

  return (
    canLeave: isEligibleToLeave && !isLoading.value,
    isLoading: isLoading.value,
    leaveGroup: leaveGroup,
  );
}
