import 'package:flutter/material.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_chat_info_actions.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

class WnChatInfoActionsStory extends StatelessWidget {
  const WnChatInfoActionsStory({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

@widgetbook.UseCase(name: 'Chat Info Actions', type: WnChatInfoActionsStory)
Widget wnChatInfoActionsShowcase(BuildContext context) {
  final isOwnProfile = context.knobs.boolean(
    label: 'Is own profile',
    initialValue: false,
  );
  final isFollowing = context.knobs.boolean(
    label: 'Is following',
    initialValue: false,
  );
  final isFollowLoading = context.knobs.boolean(
    label: 'Follow loading',
    initialValue: false,
  );

  return Scaffold(
    backgroundColor: context.colors.backgroundPrimary,
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 375),
          child: WnChatInfoActions(
            isOwnProfile: isOwnProfile,
            isFollowing: isFollowing,
            isFollowLoading: isFollowLoading,
            onFollowTap: () {},
            onSearchTap: () {},
            onAddToGroupTap: () {},
          ),
        ),
      ),
    ),
  );
}
