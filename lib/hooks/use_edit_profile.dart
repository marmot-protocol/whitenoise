import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/services/profile_service.dart';
import 'package:whitenoise/services/user_service.dart';
import 'package:whitenoise/src/rust/api/accounts.dart' as accounts_api;
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/utils/metadata.dart';

final _logger = Logger('useEditProfile');

enum EditProfileLoadingState {
  idle,
  loading,
  saving,
}

class EditProfileState {
  final EditProfileLoadingState loadingState;
  final String? error;
  final FlutterMetadata? currentMetadata;
  final String? displayName;
  final String? about;
  final String? nip05;
  final String? selectedImagePath;

  const EditProfileState({
    this.loadingState = EditProfileLoadingState.idle,
    this.error,
    this.currentMetadata,
    this.displayName,
    this.about,
    this.nip05,
    this.selectedImagePath,
  });

  bool get hasUnsavedChanges {
    if (currentMetadata == null) return false;
    return displayName != currentMetadata?.displayName ||
        about != currentMetadata?.about ||
        nip05 != currentMetadata?.nip05 ||
        selectedImagePath != null;
  }

  String? get pictureUrl {
    if (selectedImagePath != null && selectedImagePath!.isNotEmpty) {
      return selectedImagePath;
    }
    return currentMetadata?.picture;
  }

  EditProfileState copyWith({
    EditProfileLoadingState? loadingState,
    String? error,
    FlutterMetadata? currentMetadata,
    String? displayName,
    String? about,
    String? nip05,
    String? selectedImagePath,
    bool clearError = false,
    bool clearCurrentMetadata = false,
    bool clearSelectedImagePath = false,
  }) {
    return EditProfileState(
      loadingState: loadingState ?? this.loadingState,
      error: clearError ? null : (error ?? this.error),
      currentMetadata: clearCurrentMetadata ? null : (currentMetadata ?? this.currentMetadata),
      displayName: displayName ?? this.displayName,
      about: about ?? this.about,
      nip05: nip05 ?? this.nip05,
      selectedImagePath: clearSelectedImagePath
          ? null
          : (selectedImagePath ?? this.selectedImagePath),
    );
  }
}

({
  EditProfileState state,
  TextEditingController displayNameController,
  TextEditingController aboutController,
  TextEditingController nip05Controller,
  Future<void> Function() loadProfile,
  void Function(String imagePath) onImageSelected,
  Future<bool> Function() updateProfileData,
  void Function() discardChanges,
})
useEditProfile(String pubkey) {
  final state = useState(const EditProfileState());
  final displayNameController = useTextEditingController();
  final aboutController = useTextEditingController();
  final nip05Controller = useTextEditingController();

  Future<void> loadProfile() async {
    state.value = state.value.copyWith(
      loadingState: EditProfileLoadingState.loading,
      clearError: true,
    );
    try {
      final metadata = await UserService(pubkey).getInitialMetadata();
      final displayName = presentName(metadata) ?? '';
      final about = metadata.about ?? '';
      final nip05 = metadata.nip05 ?? '';
      displayNameController.text = displayName;
      aboutController.text = about;
      nip05Controller.text = nip05;
      state.value = state.value.copyWith(
        loadingState: EditProfileLoadingState.idle,
        currentMetadata: metadata,
        displayName: displayName,
        about: about,
        nip05: nip05,
      );
    } catch (e) {
      _logger.severe('Failed to load profile', e);
      state.value = state.value.copyWith(
        loadingState: EditProfileLoadingState.idle,
        error: e.toString(),
      );
    }
  }

  useEffect(() {
    void onDisplayNameChanged() {
      state.value = state.value.copyWith(displayName: displayNameController.text);
    }

    void onAboutChanged() {
      state.value = state.value.copyWith(about: aboutController.text);
    }

    void onNip05Changed() {
      state.value = state.value.copyWith(nip05: nip05Controller.text);
    }

    displayNameController.addListener(onDisplayNameChanged);
    aboutController.addListener(onAboutChanged);
    nip05Controller.addListener(onNip05Changed);

    return () {
      displayNameController.removeListener(onDisplayNameChanged);
      aboutController.removeListener(onAboutChanged);
      nip05Controller.removeListener(onNip05Changed);
    };
  }, []);

  void onImageSelected(String imagePath) {
    state.value = state.value.copyWith(
      selectedImagePath: imagePath,
      clearError: true,
    );
  }

  Future<bool> updateProfileData() async {
    if (!state.value.hasUnsavedChanges) return true;

    state.value = state.value.copyWith(
      loadingState: EditProfileLoadingState.saving,
      clearError: true,
    );
    try {
      final profileService = ProfileService(pubkey);

      String? pictureUrl = state.value.currentMetadata?.picture;
      if (state.value.selectedImagePath != null && state.value.selectedImagePath!.isNotEmpty) {
        pictureUrl = await profileService.uploadProfilePicture(
          filePath: state.value.selectedImagePath!,
        );
      }

      final currentMetadata = state.value.currentMetadata;
      if (currentMetadata == null) {
        throw Exception('Cannot update profile: metadata not loaded');
      }

      final updatedMetadata = FlutterMetadata(
        name: currentMetadata.name,
        displayName: displayNameController.text.trim(),
        about: aboutController.text.isNotEmpty ? aboutController.text : null,
        picture: pictureUrl,
        banner: currentMetadata.banner,
        website: currentMetadata.website,
        nip05: nip05Controller.text.isNotEmpty ? nip05Controller.text : null,
        lud06: currentMetadata.lud06,
        lud16: currentMetadata.lud16,
        custom: Map<String, String>.from(currentMetadata.custom),
      );

      await accounts_api.updateAccountMetadata(
        pubkey: pubkey,
        metadata: updatedMetadata,
      );

      final displayName = presentName(updatedMetadata) ?? '';
      final about = updatedMetadata.about ?? '';
      final nip05 = updatedMetadata.nip05 ?? '';
      displayNameController.text = displayName;
      aboutController.text = about;
      nip05Controller.text = nip05;
      state.value = state.value.copyWith(
        loadingState: EditProfileLoadingState.idle,
        currentMetadata: updatedMetadata,
        displayName: displayName,
        about: about,
        nip05: nip05,
        clearSelectedImagePath: true,
      );
      return true;
    } catch (e) {
      _logger.severe('Failed to update profile', e);
      state.value = state.value.copyWith(
        loadingState: EditProfileLoadingState.idle,
        error: e.toString(),
      );
      return false;
    }
  }

  void discardChanges() {
    if (state.value.currentMetadata == null) return;
    final displayName = presentName(state.value.currentMetadata) ?? '';
    final about = state.value.currentMetadata?.about ?? '';
    final nip05 = state.value.currentMetadata?.nip05 ?? '';
    displayNameController.text = displayName;
    aboutController.text = about;
    nip05Controller.text = nip05;
    state.value = state.value.copyWith(
      displayName: displayName,
      about: about,
      nip05: nip05,
      clearError: true,
      clearSelectedImagePath: true,
    );
  }

  return (
    state: state.value,
    displayNameController: displayNameController,
    aboutController: aboutController,
    nip05Controller: nip05Controller,
    loadProfile: loadProfile,
    onImageSelected: onImageSelected,
    updateProfileData: updateProfileData,
    discardChanges: discardChanges,
  );
}
