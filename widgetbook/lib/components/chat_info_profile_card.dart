import 'package:flutter/material.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_chat_info_profile_card.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

class WnChatInfoProfileCardStory extends StatelessWidget {
  const WnChatInfoProfileCardStory({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

@widgetbook.UseCase(
  name: 'Chat Info Profile Card',
  type: WnChatInfoProfileCardStory,
)
Widget wnChatInfoProfileCardShowcase(BuildContext context) {
  return Scaffold(
    backgroundColor: context.colors.backgroundPrimary,
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 375),
          child: WnChatInfoProfileCard(
            userPubkey:
                '30f6804a5d0580c6de2a2f8149f89ca92f60163ca87e1230298eb08f6de4def7',
          ),
        ),
      ),
    ),
  );
}
