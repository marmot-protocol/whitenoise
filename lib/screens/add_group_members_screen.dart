import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:whitenoise/hooks/use_group_members.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/providers/account_pubkey_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/src/rust/api/groups.dart' as groups_api;
import 'package:whitenoise/widgets/user_picker_screen.dart';
import 'package:whitenoise/widgets/wn_icon.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart';

class AddGroupMembersScreen extends HookConsumerWidget {
  const AddGroupMembersScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountPubkey = ref.watch(accountPubkeyProvider);
    final membersState = useGroupMembers(
      accountPubkey: accountPubkey,
      groupId: groupId,
    );
    final fetchErrorMessage = useState<String?>(null);
    final fetchErrorLabel = context.l10n.failedToFetchGroupMembers;

    useEffect(() {
      if (membersState.error != null) {
        fetchErrorMessage.value = fetchErrorLabel;
        membersState.clearError();
      }
      return null;
    }, [membersState.error]);

    final existingMembersSet = useMemoized(
      () => membersState.members.toSet(),
      [membersState.members],
    );

    final fetchNotice = fetchErrorMessage.value != null
        ? WnSystemNotice(
            key: ValueKey(fetchErrorMessage.value),
            title: fetchErrorMessage.value!,
            type: WnSystemNoticeType.error,
            onDismiss: () => fetchErrorMessage.value = null,
          )
        : null;

    return UserPickerScreen(
      title: context.l10n.addMembers,
      submitText: context.l10n.addMembers,
      submitIcon: WnIcons.userFollow,
      submitErrorMessage: context.l10n.failedToAddMembers,
      additionalLoading: membersState.isLoading,
      additionalNotice: fetchNotice,
      candidateFilter: (user) => !existingMembersSet.contains(user.pubkey),
      onSubmit: (ctx, selected) async {
        await groups_api.addMembersToGroup(
          pubkey: accountPubkey,
          groupId: groupId,
          memberPubkeys: selected.map((u) => u.pubkey).toList(),
        );
        if (ctx.mounted) {
          Routes.goBack(ctx);
        }
      },
    );
  }
}
