import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:whitenoise/hooks/use_create_group.dart';
import 'package:whitenoise/hooks/use_image_picker.dart';
import 'package:whitenoise/hooks/use_system_notice.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/providers/account_pubkey_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/src/rust/api/users.dart' show User;
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/utils/formatting.dart' show formatPublicKey, npubFromHex;
import 'package:whitenoise/utils/metadata.dart' show presentName;
import 'package:whitenoise/widgets/wn_avatar.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_input.dart';
import 'package:whitenoise/widgets/wn_input_text_area.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart' show WnSystemNotice;
import 'package:whitenoise/widgets/wn_user_item.dart';

class SetUpGroupScreen extends HookConsumerWidget {
  const SetUpGroupScreen({
    required this.selectedUsers,
    super.key,
  });

  final List<User> selectedUsers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final typography = context.typographyScaled;
    final accountPubkey = ref.watch(accountPubkeyProvider);

    final scrollController = useScrollController();

    final createGroupHook = useCreateGroup(selectedUsers);
    final groupNameController = createGroupHook.state.groupNameController;
    final groupDescriptionController = createGroupHook.state.groupDescriptionController;
    final imagePickerHook = useImagePicker(
      onImageSelected: createGroupHook.actions.updateSelectedImagePath,
    );

    final (:noticeMessage, :noticeType, :showErrorNotice, :showSuccessNotice, :dismissNotice) =
        useSystemNotice();

    Future<void> handleCreateGroup() async {
      final (:group, :imageUploadFailed) = await createGroupHook.actions.createGroup(accountPubkey);
      if (!context.mounted) return;
      if (group != null) {
        if (imageUploadFailed) {
          showErrorNotice(context.l10n.groupImageUploadFailed);
          await Future<void>.delayed(const Duration(seconds: 2));
          if (!context.mounted) return;
        }
        Routes.goToChat(context, group.mlsGroupId);
      } else {
        showErrorNotice(context.l10n.createGroupFailed);
      }
    }

    Future<void> handlePickImage() async {
      await imagePickerHook.pickImage();
    }

    final canCreate =
        createGroupHook.state.groupName.trim().isNotEmpty &&
        createGroupHook.state.usersWithKeyPackage.isNotEmpty &&
        !createGroupHook.state.isCreating &&
        !createGroupHook.state.isUploadingImage;

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: SafeArea(
        child: WnSlate(
          header: WnSlateNavigationHeader(
            title: context.l10n.setUpGroup,
            onNavigate: () => Routes.goBack(context),
          ),
          systemNotice: noticeMessage != null
              ? WnSystemNotice(
                  key: ValueKey(noticeMessage),
                  title: noticeMessage,
                  type: noticeType,
                  onDismiss: dismissNotice,
                )
              : null,
          footer: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: SizedBox(
              width: double.infinity,
              child: WnButton(
                onPressed: canCreate ? handleCreateGroup : null,
                text: context.l10n.createGroup,
                loading: createGroupHook.state.isCreating || createGroupHook.state.isUploadingImage,
                size: WnButtonSize.medium,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Gap(16.h),
                      Center(
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            WnAvatar(
                              size: WnAvatarSize.large,
                              pictureUrl: createGroupHook.state.selectedImagePath,
                              displayName: groupNameController.text.trim(),
                              color: AvatarColor.violet,
                            ),
                            Positioned(
                              right: 4.w,
                              bottom: 4.h,
                              child: GestureDetector(
                                onTap: handlePickImage,
                                child: Container(
                                  width: 32.w,
                                  height: 32.h,
                                  decoration: BoxDecoration(
                                    color: colors.backgroundContentPrimary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: colors.backgroundSecondary,
                                      width: 2.w,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.edit,
                                    key: const Key('edit_group_image_icon'),
                                    size: 16.sp,
                                    color: colors.backgroundSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Gap(24.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14.w),
                        child: WnInput(
                          label: context.l10n.groupName,
                          controller: groupNameController,
                          placeholder: context.l10n.groupNamePlaceholder,
                        ),
                      ),
                      Gap(12.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14.w),
                        child: WnInputTextArea(
                          label: context.l10n.description,
                          controller: groupDescriptionController,
                          placeholder: context.l10n.groupDescriptionPlaceholder,
                          size: WnInputSize.size44,
                        ),
                      ),
                      Gap(12.h),
                      if (createGroupHook.state.usersWithKeyPackage.isNotEmpty) ...[
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14.w),
                          child: Text(
                            context.l10n.invitingMembers(
                              createGroupHook.state.usersWithKeyPackage.length,
                            ),
                            style: typography.medium16.copyWith(
                              color: colors.backgroundContentSecondary,
                            ),
                          ),
                        ),
                        Gap(16.h),
                        ...createGroupHook.state.usersWithKeyPackage.expand((user) {
                          final displayName = presentName(user.metadata);
                          final formattedPubKey = formatPublicKey(
                            npubFromHex(user.pubkey) ?? user.pubkey,
                          );
                          return [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 14.w),
                              child: WnUserItem(
                                key: Key('member_${user.pubkey}'),
                                displayName: displayName ?? formattedPubKey,
                                pictureUrl: user.metadata.picture,
                                avatarColor: AvatarColor.fromPubkey(user.pubkey),
                              ),
                            ),
                            Gap(12.h),
                          ];
                        }).toList()..removeLast(),
                      ],
                      if (createGroupHook.state.usersWithoutKeyPackage.isNotEmpty) ...[
                        Gap(12.h),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14.w),
                          child: Text(
                            '${context.l10n.usersNotOnWhiteNoise(
                              createGroupHook.state.usersWithoutKeyPackage.length,
                            )}:',
                            style: typography.medium16.copyWith(
                              color: colors.backgroundContentSecondary,
                            ),
                          ),
                        ),
                        Gap(16.h),
                        ...createGroupHook.state.usersWithoutKeyPackage.expand((user) {
                          final displayName = presentName(user.metadata);
                          final formattedPubKey = formatPublicKey(
                            npubFromHex(user.pubkey) ?? user.pubkey,
                          );
                          return [
                            Opacity(
                              opacity: 0.5,
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 14.w),
                                child: WnUserItem(
                                  key: Key('excluded_${user.pubkey}'),
                                  displayName: displayName ?? formattedPubKey,
                                  pictureUrl: user.metadata.picture,
                                  avatarColor: AvatarColor.fromPubkey(user.pubkey),
                                ),
                              ),
                            ),
                            Gap(12.h),
                          ];
                        }).toList()..removeLast(),
                      ],
                      Gap(16.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
