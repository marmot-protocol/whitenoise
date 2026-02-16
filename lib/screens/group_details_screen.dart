import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:whitenoise/hooks/use_create_group.dart';
import 'package:whitenoise/hooks/use_image_picker.dart';
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
import 'package:whitenoise/widgets/wn_middle_ellipsis_text.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';

export 'package:whitenoise/hooks/use_create_group.dart' show CreateGroupError;

class GroupDetailsScreen extends HookConsumerWidget {
  const GroupDetailsScreen({
    required this.selectedUsers,
    super.key,
  });

  final List<User> selectedUsers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final typography = context.typographyScaled;
    final accountPubkey = ref.watch(accountPubkeyProvider);

    final groupNameController = useTextEditingController();
    final groupDescriptionController = useTextEditingController();
    final scrollController = useScrollController();

    final createGroupHook = useCreateGroup();
    final imagePickerHook = useImagePicker(
      onImageSelected: createGroupHook.actions.updateSelectedImagePath,
    );

    useEffect(() {
      createGroupHook.actions.updateSelectedUsers(selectedUsers);
      createGroupHook.actions.filterUsersByKeyPackage();
      return null;
    }, const []);

    useEffect(() {
      if (createGroupHook.state.error != null) {
        // coverage:ignore-start
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            final l10n = context.l10n;
            final errorMessage = switch (createGroupHook.state.error!) {
              CreateGroupError.groupNameRequired => l10n.groupNameRequired,
              CreateGroupError.noUsersWithKeyPackages => l10n.noUsersWithKeyPackages,
              CreateGroupError.createGroupFailed => l10n.createGroupFailed,
            };
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: colors.fillDestructive,
              ),
            );
            createGroupHook.actions.clearError();
          }
        });
      } // coverage:ignore-end
      return null;
    }, [createGroupHook.state.error]);

    Future<void> handleCreateGroup() async {
      final group = await createGroupHook.actions.createGroup(accountPubkey);
      if (group != null && context.mounted) {
        Routes.goToChat(context, group.mlsGroupId);
      }
    }

    Future<void> handlePickImage() async {
      await imagePickerHook.pickImage();
    }

    final canCreate =
        groupNameController.text.trim().isNotEmpty &&
        createGroupHook.state.usersWithKeyPackage.isNotEmpty &&
        !createGroupHook.state.isCreating &&
        !createGroupHook.state.isUploadingImage;

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          child: WnSlate(
            header: WnSlateNavigationHeader(
              title: context.l10n.groupDetails,
              onNavigate: () => Routes.goBack(context),
            ),
            footer: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              child: SizedBox(
                width: double.infinity,
                child: WnButton(
                  onPressed: canCreate ? handleCreateGroup : null,
                  text: context.l10n.createGroup,
                  loading:
                      createGroupHook.state.isCreating || createGroupHook.state.isUploadingImage,
                  size: WnButtonSize.medium,
                ),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w),
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
                          Gap(36.h),
                          Text(
                            context.l10n.groupName,
                            style: typography.medium14.copyWith(
                              color: colors.backgroundContentPrimary,
                            ),
                          ),
                          Gap(8.h),
                          WnInput(
                            controller: groupNameController,
                            placeholder: context.l10n.groupNamePlaceholder,
                            onChanged: createGroupHook.actions.updateGroupName,
                          ),
                          Gap(36.h),
                          Text(
                            context.l10n.groupDescription,
                            style: typography.medium14.copyWith(
                              color: colors.backgroundContentPrimary,
                            ),
                          ),
                          Gap(8.h),
                          WnInput(
                            controller: groupDescriptionController,
                            placeholder: context.l10n.groupDescriptionPlaceholder,
                            onChanged: createGroupHook.actions.updateGroupDescription,
                          ),
                          Gap(36.h),
                          // coverage:ignore-start
                          if (createGroupHook.state.isFilteringUsers)
                            Center(
                              child: CircularProgressIndicator(
                                color: colors.backgroundContentPrimary,
                                strokeCap: StrokeCap.round,
                              ),
                            )
                          // coverage:ignore-end
                          else if (createGroupHook.state.usersWithKeyPackage.isNotEmpty) ...[
                            Text(
                              context.l10n.members(
                                createGroupHook.state.usersWithKeyPackage.length,
                              ),
                              style: typography.medium14.copyWith(
                                color: colors.backgroundContentPrimary,
                              ),
                            ),
                            Gap(8.h),
                            ...createGroupHook.state.usersWithKeyPackage.map((user) {
                              final displayName = presentName(user.metadata);
                              final formattedPubKey = formatPublicKey(
                                npubFromHex(user.pubkey) ?? user.pubkey,
                              );
                              return Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.h),
                                child: Row(
                                  children: [
                                    WnAvatar(
                                      size: WnAvatarSize.medium,
                                      pictureUrl: user.metadata.picture,
                                      displayName: displayName,
                                      color: AvatarColor.fromPubkey(user.pubkey),
                                    ),
                                    Gap(12.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (displayName != null)
                                            Text(
                                              displayName,
                                              style: typography.medium16.copyWith(
                                                color: colors.backgroundContentPrimary,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            )
                                          else
                                            WnMiddleEllipsisText(
                                              // coverage:ignore-start
                                              text: formattedPubKey,
                                              style: typography.medium16.copyWith(
                                                color: colors.backgroundContentPrimary,
                                              ),
                                            ), // coverage:ignore-end
                                          Gap(4.h),
                                          WnMiddleEllipsisText(
                                            text: formattedPubKey,
                                            style: typography.medium12.copyWith(
                                              color: colors.backgroundContentSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                          if (createGroupHook.state.usersWithoutKeyPackage.isNotEmpty) ...[
                            Gap(24.h),
                            Text(
                              '${context.l10n.usersNotOnWhiteNoise(
                                createGroupHook.state.usersWithoutKeyPackage.length,
                              )}:',
                              style: typography.medium14.copyWith(
                                color: colors.backgroundContentTertiary,
                              ),
                            ),
                            Gap(16.h),
                            ...createGroupHook.state.usersWithoutKeyPackage.map((user) {
                              final displayName = presentName(user.metadata);
                              final formattedPubKey = formatPublicKey(
                                npubFromHex(user.pubkey) ?? user.pubkey,
                              );
                              return Opacity(
                                opacity: 0.5,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.h),
                                  child: Row(
                                    children: [
                                      WnAvatar(
                                        size: WnAvatarSize.medium,
                                        pictureUrl: user.metadata.picture,
                                        displayName: displayName,
                                        color: AvatarColor.fromPubkey(user.pubkey),
                                      ),
                                      Gap(12.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (displayName != null)
                                              Text(
                                                displayName,
                                                style: typography.medium16.copyWith(
                                                  color: colors.backgroundContentTertiary,
                                                  decoration: TextDecoration.lineThrough,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              )
                                            else
                                              WnMiddleEllipsisText(
                                                text: formattedPubKey,
                                                style: typography.medium16.copyWith(
                                                  color: colors.backgroundContentTertiary,
                                                  decoration: TextDecoration.lineThrough,
                                                ),
                                              ),
                                            Gap(4.h),
                                            WnMiddleEllipsisText(
                                              text: formattedPubKey,
                                              style: typography.medium12.copyWith(
                                                color: colors.backgroundContentTertiary,
                                                decoration: TextDecoration.lineThrough,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
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
        ),
      ),
    );
  }
}
