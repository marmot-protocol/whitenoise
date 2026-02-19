import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/src/rust/api/groups.dart' as groups_api;

final _logger = Logger('useGroupMembers');

typedef GroupMembersState = ({
  List<String> members,
  List<String> admins,
  bool isLoading,
  bool isActionLoading,
  String? error,
  void Function() clearError,
  Future<bool> Function(List<String> pubkeys) addMembers,
  Future<bool> Function(List<String> pubkeys) removeMembers,
  Future<bool> Function(String pubkey) makeAdmin,
  Future<bool> Function(String pubkey) removeAdmin,
});

GroupMembersState useGroupMembers({
  required String accountPubkey,
  required String groupId,
  Object? refreshKey,
}) {
  final members = useState<List<String>>([]);
  final admins = useState<List<String>>([]);
  final isLoading = useState(true);
  final isActionLoading = useState(false);
  final error = useState<String?>(null);
  final groupRef = useRef<groups_api.Group?>(null);

  useEffect(() {
    Future<void> fetchMembersAndAdmins() async {
      isLoading.value = true;
      try {
        final (membersList, adminsList, group) = await (
          groups_api.groupMembers(pubkey: accountPubkey, groupId: groupId),
          groups_api.groupAdmins(pubkey: accountPubkey, groupId: groupId),
          groups_api.getGroup(accountPubkey: accountPubkey, groupId: groupId),
        ).wait;
        members.value = membersList;
        admins.value = adminsList;
        groupRef.value = group;
      } catch (e) {
        _logger.severe('Failed to fetch group members: $e');
        error.value = 'failedToFetchGroupMembers';
      } finally {
        isLoading.value = false;
      }
    }

    fetchMembersAndAdmins();
    return null;
  }, [accountPubkey, groupId, refreshKey]);

  void clearError() {
    error.value = null;
  }

  Future<bool> addMembers(List<String> pubkeys) async {
    isActionLoading.value = true;
    error.value = null;
    try {
      await groups_api.addMembersToGroup(
        pubkey: accountPubkey,
        groupId: groupId,
        memberPubkeys: pubkeys,
      );
      final updated = {...members.value, ...pubkeys}.toList();
      members.value = updated;
      return true;
    } catch (e) {
      _logger.severe('Failed to add members: $e');
      error.value = 'failedToAddMembers';
      return false;
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<bool> removeMembers(List<String> pubkeys) async {
    isActionLoading.value = true;
    error.value = null;
    try {
      await groups_api.removeMembersFromGroup(
        pubkey: accountPubkey,
        groupId: groupId,
        memberPubkeys: pubkeys,
      );
      members.value = members.value.where((m) => !pubkeys.contains(m)).toList();
      return true;
    } catch (e) {
      _logger.severe('Failed to remove members: $e');
      error.value = 'failedToRemoveFromGroup';
      return false;
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<bool> makeAdmin(String pubkey) async {
    final group = groupRef.value;
    if (group == null) return false;

    isActionLoading.value = true;
    error.value = null;
    try {
      final updatedAdmins = {...admins.value, pubkey}.toList();
      await group.updateGroupData(
        accountPubkey: accountPubkey,
        groupData: groups_api.FlutterGroupDataUpdate(admins: updatedAdmins),
      );
      admins.value = updatedAdmins;
      return true;
    } catch (e) {
      _logger.severe('Failed to make admin: $e');
      error.value = 'failedToMakeAdmin';
      return false;
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<bool> removeAdmin(String pubkey) async {
    final group = groupRef.value;
    if (group == null) return false;

    isActionLoading.value = true;
    error.value = null;
    try {
      final updatedAdmins = admins.value.where((a) => a != pubkey).toList();
      await group.updateGroupData(
        accountPubkey: accountPubkey,
        groupData: groups_api.FlutterGroupDataUpdate(admins: updatedAdmins),
      );
      admins.value = updatedAdmins;
      return true;
    } catch (e) {
      _logger.severe('Failed to remove admin: $e');
      error.value = 'failedToRemoveAdmin';
      return false;
    } finally {
      isActionLoading.value = false;
    }
  }

  return (
    members: members.value,
    admins: admins.value,
    isLoading: isLoading.value,
    isActionLoading: isActionLoading.value,
    error: error.value,
    clearError: clearError,
    addMembers: addMembers,
    removeMembers: removeMembers,
    makeAdmin: makeAdmin,
    removeAdmin: removeAdmin,
  );
}
