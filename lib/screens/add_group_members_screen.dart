import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:whitenoise/hooks/use_group_members.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/providers/account_pubkey_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/screens/user_picker_screen.dart';
import 'package:whitenoise/widgets/wn_icon.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart';

String _localizeMembersError(String errorKey, AppLocalizations l10n) {
  return switch (errorKey) {
    'failedToFetchGroupMembers' => l10n.failedToFetchGroupMembers,
    'failedToAddMembers' => l10n.failedToAddMembers,
    _ => l10n.somethingWentWrong,
  };
}

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
    final errorMessage = useState<String?>(null);
    final l10n = context.l10n;

    useEffect(() {
      final key = membersState.error;
      if (key != null) {
        errorMessage.value = _localizeMembersError(key, l10n);
        membersState.clearError();
      }
      return null;
    }, [membersState.error]);

    final existingMembersSet = useMemoized(
      () => membersState.members.toSet(),
      [membersState.members],
    );

    final notice = errorMessage.value != null
        ? WnSystemNotice(
            key: ValueKey(errorMessage.value),
            title: errorMessage.value!,
            type: WnSystemNoticeType.error,
            onDismiss: () => errorMessage.value = null,
          )
        : null;

    return UserPickerScreen(
      title: l10n.addMembers,
      submitText: l10n.addMembers,
      submitIcon: WnIcons.userFollow,
      additionalLoading: membersState.isLoading,
      additionalNotice: notice,
      candidateFilter: (user) => !existingMembersSet.contains(user.pubkey),
      onSubmit: (ctx, selected) async {
        final ok = await membersState.addMembers(selected.map((u) => u.pubkey).toList());
        if (ok && ctx.mounted) {
          Routes.goBack(ctx);
        }
      },
    );
  }
}
