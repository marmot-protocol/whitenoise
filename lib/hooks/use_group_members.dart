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
  Future<void> Function(List<String> pubkeys) addMembers,
  Future<void> Function(List<String> pubkeys) removeMembers,
  Future<void> Function(String pubkey) makeAdmin,
  Future<void> Function(String pubkey) removeAdmin,
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
        final results = await Future.wait([
          groups_api.groupMembers(pubkey: accountPubkey, groupId: groupId),
          groups_api.groupAdmins(pubkey: accountPubkey, groupId: groupId),
          groups_api.getGroup(accountPubkey: accountPubkey, groupId: groupId),
        ]);
        members.value = results[0] as List<String>;
        admins.value = results[1] as List<String>;
        groupRef.value = results[2] as groups_api.Group;
      } catch (e) {
        _logger.severe('Failed to fetch group members: $e');
        error.value = 'Failed to fetch group members';
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

  Future<void> addMembers(List<String> pubkeys) async {
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
    } catch (e) {
      _logger.severe('Failed to add members: $e');
      error.value = 'Failed to add members';
      rethrow;
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<void> removeMembers(List<String> pubkeys) async {
    isActionLoading.value = true;
    error.value = null;
    try {
      await groups_api.removeMembersFromGroup(
        pubkey: accountPubkey,
        groupId: groupId,
        memberPubkeys: pubkeys,
      );
      members.value = members.value.where((m) => !pubkeys.contains(m)).toList();
    } catch (e) {
      _logger.severe('Failed to remove members: $e');
      error.value = 'Failed to remove members';
      rethrow;
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<void> makeAdmin(String pubkey) async {
    final group = groupRef.value;
    if (group == null) return;

    isActionLoading.value = true;
    error.value = null;
    try {
      final updatedAdmins = {...admins.value, pubkey}.toList();
      await group.updateGroupData(
        accountPubkey: accountPubkey,
        groupData: groups_api.FlutterGroupDataUpdate(admins: updatedAdmins),
      );
      admins.value = updatedAdmins;
    } catch (e) {
      _logger.severe('Failed to make admin: $e');
      error.value = 'Failed to make admin';
      rethrow;
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<void> removeAdmin(String pubkey) async {
    final group = groupRef.value;
    if (group == null) return;

    isActionLoading.value = true;
    error.value = null;
    try {
      final updatedAdmins = admins.value.where((a) => a != pubkey).toList();
      await group.updateGroupData(
        accountPubkey: accountPubkey,
        groupData: groups_api.FlutterGroupDataUpdate(admins: updatedAdmins),
      );
      admins.value = updatedAdmins;
    } catch (e) {
      _logger.severe('Failed to remove admin: $e');
      error.value = 'Failed to remove admin';
      rethrow;
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
