import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart' show useEffect, useState;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/hooks/use_edit_group.dart' show EditGroupLoadingState, useEditGroup;
import 'package:whitenoise/hooks/use_image_picker.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/providers/account_pubkey_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/utils/avatar_color.dart';
import 'package:whitenoise/widgets/wn_avatar.dart' show WnAvatar, WnAvatarSize;
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_input.dart' show WnInput;
import 'package:whitenoise/widgets/wn_input_text_area.dart' show WnInputTextArea;
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart';

final _logger = Logger('EditGroupScreen');

class EditGroupScreen extends HookConsumerWidget {
  const EditGroupScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final accountPubkey = ref.watch(accountPubkeyProvider);
    final (
      :state,
      :nameController,
      :descriptionController,
      :loadGroup,
      :onImageSelected,
      :saveGroup,
      :discardChanges,
    ) = useEditGroup(
      accountPubkey: accountPubkey,
      groupId: groupId,
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
      loadGroup();
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
            title: context.l10n.editGroup,
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
          footer: state.loadingState != EditGroupLoadingState.loading && state.currentGroup != null
              ? Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
                  child: Column(
                    spacing: 8.h,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      WnButton(
                        text: context.l10n.cancel,
                        type: WnButtonType.outline,
                        size: WnButtonSize.medium,
                        onPressed: state.loadingState == EditGroupLoadingState.saving
                            ? null
                            : () {
                                discardChanges();
                                Routes.goBack(context);
                              },
                      ),
                      WnButton(
                        text: context.l10n.save,
                        size: WnButtonSize.medium,
                        onPressed:
                            state.hasUnsavedChanges &&
                                state.loadingState != EditGroupLoadingState.saving
                            ? () async {
                                final success = await saveGroup();
                                if (context.mounted) {
                                  if (success) {
                                    showNotice(context.l10n.groupUpdatedSuccessfully);
                                  } else {
                                    showNotice(
                                      context.l10n.groupSaveError,
                                      type: WnSystemNoticeType.error,
                                    );
                                  }
                                }
                              }
                            : null,
                        loading: state.loadingState == EditGroupLoadingState.saving,
                      ),
                    ],
                  ),
                )
              : null,
          child: state.error != null && state.currentGroup == null
              ? Builder(
                  builder: (context) {
                    _logger.warning('Group load error: ${state.error}');
                    return Center(
                      child: Text(
                        context.l10n.groupLoadError,
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
                          displayName: state.name ?? '',
                          size: WnAvatarSize.large,
                          color: AvatarColor.fromPubkey(groupId),
                          onEditTap: state.loadingState == EditGroupLoadingState.saving
                              ? null
                              : pickImage,
                        ),
                      ),
                      Gap(36.h),
                      WnInput(
                        label: context.l10n.groupNameLabel,
                        placeholder: '',
                        controller: nameController,
                      ),
                      Gap(36.h),
                      WnInputTextArea(
                        label: context.l10n.groupDescriptionLabel,
                        placeholder: '',
                        controller: descriptionController,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
