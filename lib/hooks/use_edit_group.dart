import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/src/rust/api/groups.dart' as groups_api;
import 'package:whitenoise/src/rust/api/utils.dart' as utils_api;

final _logger = Logger('useEditGroup');

enum EditGroupLoadingState {
  idle,
  loading,
  saving,
}

class EditGroupState {
  final EditGroupLoadingState loadingState;
  final String? error;
  final groups_api.Group? currentGroup;
  final String? currentImagePath;
  final String? name;
  final String? description;
  final String? selectedImagePath;

  const EditGroupState({
    this.loadingState = EditGroupLoadingState.idle,
    this.error,
    this.currentGroup,
    this.currentImagePath,
    this.name,
    this.description,
    this.selectedImagePath,
  });

  bool get hasUnsavedChanges {
    if (currentGroup == null) return false;
    return name != currentGroup?.name ||
        description != currentGroup?.description ||
        selectedImagePath != null;
  }

  String? get pictureUrl {
    if (selectedImagePath != null && selectedImagePath!.isNotEmpty) {
      return selectedImagePath;
    }
    return currentImagePath;
  }

  EditGroupState copyWith({
    EditGroupLoadingState? loadingState,
    String? error,
    groups_api.Group? currentGroup,
    String? currentImagePath,
    String? name,
    String? description,
    String? selectedImagePath,
    bool clearError = false,
    bool clearSelectedImagePath = false,
  }) {
    return EditGroupState(
      loadingState: loadingState ?? this.loadingState,
      error: clearError ? null : (error ?? this.error),
      currentGroup: currentGroup ?? this.currentGroup,
      currentImagePath: currentImagePath ?? this.currentImagePath,
      name: name ?? this.name,
      description: description ?? this.description,
      selectedImagePath: clearSelectedImagePath
          ? null
          : (selectedImagePath ?? this.selectedImagePath),
    );
  }
}

({
  EditGroupState state,
  TextEditingController nameController,
  TextEditingController descriptionController,
  Future<void> Function() loadGroup,
  void Function(String imagePath) onImageSelected,
  Future<bool> Function() saveGroup,
  void Function() discardChanges,
})
useEditGroup({
  required String accountPubkey,
  required String groupId,
}) {
  final state = useState(const EditGroupState());
  final nameController = useTextEditingController();
  final descriptionController = useTextEditingController();

  Future<void> loadGroup() async {
    state.value = state.value.copyWith(
      loadingState: EditGroupLoadingState.loading,
      clearError: true,
    );
    try {
      final (group, imagePath) = await (
        groups_api.getGroup(accountPubkey: accountPubkey, groupId: groupId),
        groups_api.getGroupImagePath(accountPubkey: accountPubkey, groupId: groupId),
      ).wait;
      final name = group.name;
      final description = group.description;
      nameController.text = name;
      descriptionController.text = description;
      state.value = state.value.copyWith(
        loadingState: EditGroupLoadingState.idle,
        currentGroup: group,
        currentImagePath: imagePath ?? '',
        name: name,
        description: description,
      );
    } catch (e) {
      _logger.severe('Failed to load group: $e');
      state.value = state.value.copyWith(
        loadingState: EditGroupLoadingState.idle,
        error: e.toString(),
      );
    }
  }

  useEffect(() {
    void onNameChanged() {
      state.value = state.value.copyWith(name: nameController.text);
    }

    void onDescriptionChanged() {
      state.value = state.value.copyWith(description: descriptionController.text);
    }

    nameController.addListener(onNameChanged);
    descriptionController.addListener(onDescriptionChanged);

    return () {
      nameController.removeListener(onNameChanged);
      descriptionController.removeListener(onDescriptionChanged);
    };
  }, []);

  void onImageSelected(String imagePath) {
    state.value = state.value.copyWith(
      selectedImagePath: imagePath,
      clearError: true,
    );
  }

  Future<bool> saveGroup() async {
    if (!state.value.hasUnsavedChanges) return true;

    state.value = state.value.copyWith(
      loadingState: EditGroupLoadingState.saving,
      clearError: true,
    );
    try {
      groups_api.UploadGroupImageResult? imageResult;
      if (state.value.selectedImagePath != null && state.value.selectedImagePath!.isNotEmpty) {
        final serverUrl = await utils_api.getDefaultBlossomServerUrl();
        imageResult = await groups_api.uploadGroupImage(
          accountPubkey: accountPubkey,
          groupId: groupId,
          filePath: state.value.selectedImagePath!,
          serverUrl: serverUrl,
        );
      }

      final currentGroup = state.value.currentGroup;
      if (currentGroup == null) {
        throw Exception('Cannot update group: group not loaded');
      }

      await currentGroup.updateGroupData(
        accountPubkey: accountPubkey,
        groupData: groups_api.FlutterGroupDataUpdate(
          name: nameController.text.trim(),
          description: descriptionController.text.trim(),
          imageKey: imageResult?.imageKey,
          imageHash: imageResult?.encryptedHash,
          imageNonce: imageResult?.imageNonce,
        ),
      );

      final name = nameController.text.trim();
      final description = descriptionController.text.trim();
      nameController.text = name;
      descriptionController.text = description;

      final updatedGroup = await groups_api.getGroup(
        accountPubkey: accountPubkey,
        groupId: groupId,
      );
      final updatedImagePath = await groups_api.getGroupImagePath(
        accountPubkey: accountPubkey,
        groupId: groupId,
      );

      state.value = state.value.copyWith(
        loadingState: EditGroupLoadingState.idle,
        currentGroup: updatedGroup,
        currentImagePath: updatedImagePath ?? '',
        name: name,
        description: description,
        clearSelectedImagePath: true,
      );
      return true;
    } catch (e) {
      _logger.severe('Failed to save group: $e');
      state.value = state.value.copyWith(
        loadingState: EditGroupLoadingState.idle,
        error: e.toString(),
      );
      return false;
    }
  }

  void discardChanges() {
    if (state.value.currentGroup == null) return;
    final name = state.value.currentGroup!.name;
    final description = state.value.currentGroup!.description;
    nameController.text = name;
    descriptionController.text = description;
    state.value = state.value.copyWith(
      name: name,
      description: description,
      clearError: true,
      clearSelectedImagePath: true,
    );
  }

  return (
    state: state.value,
    nameController: nameController,
    descriptionController: descriptionController,
    loadGroup: loadGroup,
    onImageSelected: onImageSelected,
    saveGroup: saveGroup,
    discardChanges: discardChanges,
  );
}
