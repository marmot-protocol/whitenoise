import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart' show useEffect, useState;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/hooks/use_edit_profile.dart'
    show EditProfileLoadingState, useEditProfile;
import 'package:whitenoise/hooks/use_image_picker.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/providers/account_pubkey_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/utils/avatar_color.dart';
import 'package:whitenoise/widgets/wn_avatar.dart' show WnAvatar, WnAvatarSize;
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_callout.dart';
import 'package:whitenoise/widgets/wn_input.dart' show WnInput;
import 'package:whitenoise/widgets/wn_input_text_area.dart' show WnInputTextArea;
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart';

final _logger = Logger('EditProfileScreen');

class EditProfileScreen extends HookConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final pubkey = ref.watch(accountPubkeyProvider);
    final (
      :state,
      :displayNameController,
      :aboutController,
      :nip05Controller,
      :loadProfile,
      :onImageSelected,
      :updateProfileData,
      :discardChanges,
    ) = useEditProfile(
      pubkey,
    );
    final (:pickImage, error: imagePickerError, clearError: clearImagePickerError) = useImagePicker(
      onImageSelected: onImageSelected,
    );
    final noticeMessage = useState<String?>(null);
    final noticeType = useState(WnSystemNoticeType.success);

    void showNotice(String message, {WnSystemNoticeType type = WnSystemNoticeType.success}) {
      noticeMessage.value = message;
      noticeType.value = type;
    }

    void dismissNotice() {
      noticeMessage.value = null;
    }

    useEffect(() {
      loadProfile();
      return null;
    }, []);

    useEffect(() {
      if (imagePickerError != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            showNotice(context.l10n.imagePickerError, type: WnSystemNoticeType.error);
          }
        });
        clearImagePickerError();
      }
      return null;
    }, [imagePickerError]);

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: SafeArea(
        child: WnSlate(
          showTopScrollEffect: true,
          showBottomScrollEffect: true,
          header: WnSlateNavigationHeader(
            title: context.l10n.editProfile,
            onNavigate: () => Routes.goBack(context),
          ),
          systemNotice: noticeMessage.value != null
              ? WnSystemNotice(
                  key: ValueKey(noticeMessage.value),
                  title: noticeMessage.value!,
                  type: noticeType.value,
                  onDismiss: dismissNotice,
                )
              : null,
          footer: state.loadingState != EditProfileLoadingState.loading && state.error == null
              ? Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                  child: Column(
                    spacing: 8.h,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (state.hasUnsavedChanges)
                        WnButton(
                          text: context.l10n.discard,
                          type: WnButtonType.outline,
                          size: WnButtonSize.medium,
                          onPressed: () {
                            discardChanges();
                          },
                          disabled: state.loadingState == EditProfileLoadingState.saving,
                        ),
                      WnButton(
                        text: context.l10n.save,
                        size: WnButtonSize.medium,
                        onPressed:
                            state.hasUnsavedChanges &&
                                state.loadingState != EditProfileLoadingState.saving
                            ? () async {
                                final success = await updateProfileData();
                                if (context.mounted && success) {
                                  showNotice(context.l10n.profileUpdatedSuccessfully);
                                }
                              }
                            : null,
                        loading: state.loadingState == EditProfileLoadingState.saving,
                      ),
                    ],
                  ),
                )
              : null,
          child: state.error != null
              ? Builder(
                  builder: (context) {
                    _logger.warning('Profile error: ${state.error}');
                    final message = state.currentMetadata == null
                        ? context.l10n.profileLoadError
                        : context.l10n.profileSaveError;
                    return Center(
                      child: Text(
                        message,
                        style: context.typographyScaled.medium14.copyWith(
                          color: colors.fillDestructive,
                        ),
                      ),
                    );
                  },
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Gap(16.h),
                      Center(
                        child: WnAvatar(
                          pictureUrl: state.pictureUrl,
                          displayName: state.displayName ?? '',
                          size: WnAvatarSize.large,
                          color: AvatarColor.fromPubkey(pubkey),
                          onEditTap: state.loadingState == EditProfileLoadingState.saving
                              ? null
                              : pickImage,
                        ),
                      ),
                      Gap(36.h),
                      WnInput(
                        label: context.l10n.profileName,
                        placeholder: context.l10n.enterYourName,
                        controller: displayNameController,
                      ),
                      Gap(36.h),
                      WnInput(
                        label: context.l10n.nostrAddress,
                        placeholder: 'example@whitenoise.chat',
                        controller: nip05Controller,
                      ),
                      Gap(36.h),
                      WnInputTextArea(
                        label: context.l10n.aboutYou,
                        placeholder: context.l10n.writeSomethingAboutYourself,
                        controller: aboutController,
                      ),
                      Gap(36.h),
                      WnCallout(
                        title: context.l10n.profileIsPublic,
                        description: context.l10n.profilePublicDescription,
                      ),
                      Gap(16.h),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
