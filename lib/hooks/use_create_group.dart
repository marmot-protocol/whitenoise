import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/src/rust/api/groups.dart' as groups_api;
import 'package:whitenoise/src/rust/api/users.dart' show KeyPackageStatus, User, userHasKeyPackage;
import 'package:whitenoise/src/rust/api/utils.dart' as rust_utils;

final _logger = Logger('useCreateGroup');

enum CreateGroupError {
  groupNameRequired,
  noUsersWithKeyPackages,
  createGroupFailed,
}

typedef CreateGroupState = ({
  TextEditingController groupNameController,
  TextEditingController groupDescriptionController,
  String groupName,
  String groupDescription,
  String? selectedImagePath,
  List<User> usersWithKeyPackage,
  List<User> usersWithoutKeyPackage,
  bool isCreating,
  bool isUploadingImage,
  CreateGroupError? error,
  bool isFilteringUsers,
});

typedef CreateGroupActions = ({
  void Function(String?) updateSelectedImagePath,
  Future<groups_api.Group?> Function(String accountPubkey) createGroup,
  void Function() clearError,
  void Function() reset,
});

({CreateGroupState state, CreateGroupActions actions}) useCreateGroup(
  List<User> selectedUsers,
) {
  final groupNameController = useTextEditingController();
  final groupDescriptionController = useTextEditingController();
  final groupName = useState('');
  final groupDescription = useState('');
  final selectedImagePath = useState<String?>(null);
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

  useEffect(() {
    void onNameChanged() {
      groupName.value = groupNameController.text;
      error.value = null;
    }

    void onDescriptionChanged() {
      groupDescription.value = groupDescriptionController.text;
      error.value = null;
    }

    groupNameController.addListener(onNameChanged);
    groupDescriptionController.addListener(onDescriptionChanged);
    return () {
      groupNameController.removeListener(onNameChanged);
      groupDescriptionController.removeListener(onDescriptionChanged);
    };
  }, [groupNameController, groupDescriptionController]);

  useEffect(() {
    Future<void> filterUsers() async {
      if (selectedUsers.isEmpty) {
        usersWithKeyPackage.value = [];
        usersWithoutKeyPackage.value = [];
        return;
      }

      isFilteringUsers.value = true;
      error.value = null;

      final withKeyPackage = <User>[];
      final withoutKeyPackage = <User>[];

      for (final user in selectedUsers) {
        try {
          final hasKp = await userHasKeyPackage(
            pubkey: user.pubkey,
            blockingDataSync: true,
          );

          if (hasKp == KeyPackageStatus.valid) {
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
      isFilteringUsers.value = false;
    }

    filterUsers();
    return null;
  }, [selectedUsers]);

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

          if (!isMountedRef.value) return group;

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

  void updateSelectedImagePath(String? path) {
    selectedImagePath.value = path;
    error.value = null;
  }

  void clearError() {
    error.value = null;
  }

  void reset() {
    groupNameController.clear();
    groupDescriptionController.clear();
    selectedImagePath.value = null;
    usersWithKeyPackage.value = [];
    usersWithoutKeyPackage.value = [];
    isCreating.value = false;
    isUploadingImage.value = false;
    error.value = null;
    isFilteringUsers.value = false;
  }

  return (
    state: (
      groupNameController: groupNameController,
      groupDescriptionController: groupDescriptionController,
      groupName: groupName.value,
      groupDescription: groupDescription.value,
      selectedImagePath: selectedImagePath.value,
      usersWithKeyPackage: usersWithKeyPackage.value,
      usersWithoutKeyPackage: usersWithoutKeyPackage.value,
      isCreating: isCreating.value,
      isUploadingImage: isUploadingImage.value,
      error: error.value,
      isFilteringUsers: isFilteringUsers.value,
    ),
    actions: (
      updateSelectedImagePath: updateSelectedImagePath,
      createGroup: createGroup,
      clearError: clearError,
      reset: reset,
    ),
  );
}
