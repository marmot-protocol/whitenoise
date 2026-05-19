import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/src/rust/api/users.dart' show User;
import 'package:whitenoise/widgets/user_picker_screen.dart';
import 'package:whitenoise/widgets/wn_icon.dart';

class UserSelectionScreen extends HookConsumerWidget {
  const UserSelectionScreen({super.key, this.initialUsers = const []});

  final List<User> initialUsers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return UserPickerScreen(
      title: context.l10n.newGroupChat,
      submitText: context.l10n.continueButton,
      submitIcon: WnIcons.arrowRight,
      initialUsers: initialUsers,
      onSubmit: (ctx, selected) async {
        Routes.pushToSetUpGroup(ctx, selected);
      },
    );
  }
}
