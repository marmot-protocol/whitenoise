import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/hooks/use_groups.dart';
import 'package:whitenoise/hooks/use_system_notice.dart';
import 'package:whitenoise/hooks/use_user_metadata.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/providers/account_pubkey_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/src/rust/api/groups.dart' as groups_api;
import 'package:whitenoise/src/rust/api/metadata.dart' show FlutterMetadata;
import 'package:whitenoise/src/rust/api/users.dart' show User;
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_confirmation_slate.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart';
import 'package:whitenoise/widgets/wn_user_item.dart';

final _logger = Logger('AddToGroupScreen');

class AddToGroupScreen extends HookConsumerWidget {
  const AddToGroupScreen({super.key, required this.userPubkey});

  final String userPubkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final accountPubkey = ref.watch(accountPubkeyProvider);

    final groupsState = useGroups(accountPubkey: accountPubkey);
    final adminGroups = groupsState.groups
        .where((g) => g.adminPubkeys.contains(accountPubkey))
        .toList();
    final userMetadata = useUserMetadata(context, userPubkey);
    final (
      :noticeMessage,
      :noticeType,
      :showErrorNotice,
      :showSuccessNotice,
      :dismissNotice,
    ) = useSystemNotice();

    useEffect(() {
      if (!groupsState.isLoading && adminGroups.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!context.mounted) return;
          final confirmed = await WnConfirmationSlate.show(
            context: context,
            title: context.l10n.addToGroup,
            message: context.l10n.noAdminGroupsAvailable,
            confirmText: context.l10n.createGroup,
            cancelText: context.l10n.cancel,
            onConfirmAsync: () async => true,
          );
          if (confirmed == true && context.mounted) {
            final metadata = userMetadata.data ?? const FlutterMetadata(custom: {});
            final user = User(
              pubkey: userPubkey,
              metadata: metadata,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            Routes.goBack(context);
            Routes.pushToUserSelection(context, initialUsers: [user]);
          } else if (confirmed == null && context.mounted) {
            Routes.goBack(context);
          }
        });
      }
      return null;
    }, [groupsState.isLoading, adminGroups.length]);

    Future<void> handleGroupTap(groups_api.Group group) async {
      final confirmed = await WnConfirmationSlate.show(
        context: context,
        title: context.l10n.addToGroup,
        message: context.l10n.addToGroupConfirmation(
          userMetadata.data?.displayName ?? userMetadata.data?.name ?? context.l10n.unknownUser,
          group.name.isEmpty ? context.l10n.unknownGroup : group.name,
        ),
        confirmText: context.l10n.addToGroup,
        cancelText: context.l10n.cancel,
        onConfirmAsync: () async {
          try {
            await groups_api.addMembersToGroup(
              pubkey: accountPubkey,
              groupId: group.mlsGroupId,
              memberPubkeys: [userPubkey],
            );
            return true;
          } catch (e) {
            _logger.severe('Failed to add user to group: $e');
            return false;
          }
        },
      );

      if (confirmed == true && context.mounted) {
        Routes.goToChat(context, group.mlsGroupId);
      } else if (confirmed == false && context.mounted) {
        showErrorNotice(context.l10n.failedToAddMembers);
      }
    }

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: SafeArea(
        child: WnSlate(
          header: WnSlateNavigationHeader(
            title: context.l10n.addToGroup,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (groupsState.isLoading || (!groupsState.isLoading && adminGroups.isEmpty))
                Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: colors.backgroundContentPrimary,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: adminGroups.length,
                    separatorBuilder: (context, index) => Gap(8.h),
                    itemBuilder: (context, index) {
                      final group = adminGroups[index];
                      return WnUserItem(
                        key: Key('group_${group.mlsGroupId}'),
                        displayName: group.name.isEmpty ? context.l10n.unknownGroup : group.name,
                        label: group.description.isNotEmpty ? group.description : null,
                        size: WnUserItemSize.big,
                        onTap: () => handleGroupTap(group),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
