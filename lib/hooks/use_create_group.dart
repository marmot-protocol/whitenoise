import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/src/rust/api/groups.dart' as groups_api;
import 'package:whitenoise/src/rust/api/users.dart' show User, userHasKeyPackage;
import 'package:whitenoise/src/rust/api/utils.dart' as rust_utils;

final _logger = Logger('useCreateGroup');

enum CreateGroupError {
  groupNameRequired,
  noUsersWithKeyPackages,
  createGroupFailed,
}

typedef CreateGroupState = ({
  String groupName,
  String groupDescription,
  String? selectedImagePath,
  List<User> selectedUsers,
  List<User> usersWithKeyPackage,
  List<User> usersWithoutKeyPackage,
  bool isCreating,
  bool isUploadingImage,
  CreateGroupError? error,
  bool isFilteringUsers,
});

typedef CreateGroupActions = ({
  void Function(String) updateGroupName,
  void Function(String) updateGroupDescription,
  void Function(String?) updateSelectedImagePath,
  void Function(List<User>) updateSelectedUsers,
  Future<void> Function() filterUsersByKeyPackage,
  Future<groups_api.Group?> Function(String accountPubkey) createGroup,
  void Function() clearError,
  void Function() reset,
});

({CreateGroupState state, CreateGroupActions actions}) useCreateGroup() {
  final groupName = useState('');
  final groupDescription = useState('');
  final selectedImagePath = useState<String?>(null);
  final selectedUsers = useState<List<User>>([]);
  final usersWithKeyPackage = useState<List<User>>([]);
  final usersWithoutKeyPackage = useState<List<User>>([]);
  final isCreating = useState(false);
  final isUploadingImage = useState(false);
  final error = useState<CreateGroupError?>(null);
  final isFilteringUsers = useState(false);
  final isMountedRef = useRef(true);

  useEffect(() {
    isMountedRef.value = true;
    return () {
      isMountedRef.value = false;
    };
  }, []);

  Future<void> filterUsersByKeyPackage() async {
    if (selectedUsers.value.isEmpty) {
      usersWithKeyPackage.value = [];
      usersWithoutKeyPackage.value = [];
      return;
    }

    isFilteringUsers.value = true;
    error.value = null;

    final withKeyPackage = <User>[];
    final withoutKeyPackage = <User>[];

    for (final user in selectedUsers.value) {
      try {
        final hasKeyPackage = await userHasKeyPackage(
          pubkey: user.pubkey,
          blockingDataSync: true,
        );

        if (hasKeyPackage) {
          withKeyPackage.add(user);
        } else {
          withoutKeyPackage.add(user);
        }
      } catch (e) {
        _logger.warning(
          'Failed to check key package for ${user.pubkey}: $e',
        );
        withoutKeyPackage.add(user);
      }
    }

    if (!isMountedRef.value) return;

    usersWithKeyPackage.value = withKeyPackage;
    usersWithoutKeyPackage.value = withoutKeyPackage;

    if (isMountedRef.value) {
      isFilteringUsers.value = false;
    }
  }

  Future<groups_api.Group?> createGroup(String accountPubkey) async {
    if (groupName.value.trim().isEmpty) {
      error.value = CreateGroupError.groupNameRequired;
      return null;
    }

    if (usersWithKeyPackage.value.isEmpty) {
      error.value = CreateGroupError.noUsersWithKeyPackages;
      return null;
    }

    isCreating.value = true;
    error.value = null;

    try {
      final memberPubkeys = usersWithKeyPackage.value.map((u) => u.pubkey).toList();

      final group = await groups_api.createGroup(
        creatorPubkey: accountPubkey,
        memberPubkeys: memberPubkeys,
        adminPubkeys: [accountPubkey],
        groupName: groupName.value.trim(),
        groupDescription: groupDescription.value.trim(),
        groupType: groups_api.GroupType.group,
      );

      if (selectedImagePath.value != null && selectedImagePath.value!.isNotEmpty) {
        if (!isMountedRef.value) return group;
        isUploadingImage.value = true;
        try {
          final serverUrl = await rust_utils.getDefaultBlossomServerUrl();
          final uploadResult = await groups_api.uploadGroupImage(
            accountPubkey: accountPubkey,
            groupId: group.mlsGroupId,
            filePath: selectedImagePath.value!,
            serverUrl: serverUrl,
          );

          await group.updateGroupData(
            accountPubkey: accountPubkey,
            groupData: groups_api.FlutterGroupDataUpdate(
              imageKey: uploadResult.imageKey,
              imageHash: uploadResult.encryptedHash,
              imageNonce: uploadResult.imageNonce,
            ),
          );
        } catch (e, st) {
          _logger.warning('Failed to upload group image', e, st);
        } finally {
          if (isMountedRef.value) {
            isUploadingImage.value = false;
          }
        }
      }

      return group;
    } catch (e, st) {
      _logger.severe('createGroup failed', e, st);
      if (!isMountedRef.value) return null;
      error.value = CreateGroupError.createGroupFailed;
      return null;
    } finally {
      if (isMountedRef.value) {
        isCreating.value = false;
      }
    }
  }

  void updateGroupName(String name) {
    groupName.value = name;
    error.value = null;
  }

  void updateGroupDescription(String description) {
    groupDescription.value = description;
    error.value = null;
  }

  void updateSelectedImagePath(String? path) {
    selectedImagePath.value = path;
    error.value = null;
  }

  void updateSelectedUsers(List<User> users) {
    selectedUsers.value = users;
    error.value = null;
  }

  void clearError() {
    error.value = null;
  }

  void reset() {
    groupName.value = '';
    groupDescription.value = '';
    selectedImagePath.value = null;
    selectedUsers.value = [];
    usersWithKeyPackage.value = [];
    usersWithoutKeyPackage.value = [];
    isCreating.value = false;
    isUploadingImage.value = false;
    error.value = null;
    isFilteringUsers.value = false;
  }

  return (
    state: (
      groupName: groupName.value,
      groupDescription: groupDescription.value,
      selectedImagePath: selectedImagePath.value,
      selectedUsers: selectedUsers.value,
      usersWithKeyPackage: usersWithKeyPackage.value,
      usersWithoutKeyPackage: usersWithoutKeyPackage.value,
      isCreating: isCreating.value,
      isUploadingImage: isUploadingImage.value,
      error: error.value,
      isFilteringUsers: isFilteringUsers.value,
    ),
    actions: (
      updateGroupName: updateGroupName,
      updateGroupDescription: updateGroupDescription,
      updateSelectedImagePath: updateSelectedImagePath,
      updateSelectedUsers: updateSelectedUsers,
      filterUsersByKeyPackage: filterUsersByKeyPackage,
      createGroup: createGroup,
      clearError: clearError,
      reset: reset,
    ),
  );
}
