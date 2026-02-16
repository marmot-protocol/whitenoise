import 'package:flutter/material.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_avatar.dart';
import 'package:whitenoise/widgets/wn_user_item.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

const _sampleImageUrl = 'https://www.whitenoise.chat/images/mask-man.webp';

class WnUserItemStory extends StatelessWidget {
  const WnUserItemStory({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

@widgetbook.UseCase(name: 'User Item', type: WnUserItemStory)
Widget wnUserItemShowcase(BuildContext context) {
  final colors = context.colors;

  return Scaffold(
    backgroundColor: colors.backgroundPrimary,
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'User Item',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: colors.backgroundContentPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'A simple row used to display a user. It shows the user avatar, '
          'name, and an optional label when additional context is needed.',
          style: TextStyle(
            fontSize: 14,
            color: colors.backgroundContentSecondary,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Playground',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colors.backgroundContentPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Use the knobs panel to customize the user item.',
          style: TextStyle(
            fontSize: 14,
            color: colors.backgroundContentSecondary,
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 368),
            child: _InteractiveUserItem(context: context),
          ),
        ),
        const SizedBox(height: 32),
        Divider(color: colors.borderTertiary),
        const SizedBox(height: 24),
        _buildSection(
          context,
          'With Label',
          'User item with an optional label for additional context.',
          [
            _UserItemExample(
              label: 'With Label',
              child: WnUserItem(
                displayName: 'Fred Durst',
                label: 'Admin',
                avatarColor: AvatarColor.blue,
              ),
            ),
            _UserItemExample(
              label: 'Without Label',
              child: WnUserItem(
                displayName: 'Fred Durst',
                avatarColor: AvatarColor.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          context,
          'With Image',
          'User items with a profile picture instead of initials.',
          [
            _UserItemExample(
              label: 'Image with Label',
              child: WnUserItem(
                displayName: 'Fred Durst',
                label: 'Admin',
                pictureUrl: _sampleImageUrl,
              ),
            ),
            _UserItemExample(
              label: 'Image without Label',
              child: WnUserItem(
                displayName: 'Fred Durst',
                pictureUrl: _sampleImageUrl,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          context,
          'Avatar Colors',
          'User items with different avatar accent colors.',
          [
            _UserItemExample(
              label: 'Neutral',
              child: WnUserItem(displayName: 'Alice', label: 'Member'),
            ),
            _UserItemExample(
              label: 'Blue',
              child: WnUserItem(
                displayName: 'Bob',
                label: 'Moderator',
                avatarColor: AvatarColor.blue,
              ),
            ),
            _UserItemExample(
              label: 'Emerald',
              child: WnUserItem(
                displayName: 'Charlie',
                label: 'Owner',
                avatarColor: AvatarColor.emerald,
              ),
            ),
            _UserItemExample(
              label: 'Rose',
              child: WnUserItem(
                displayName: 'Diana',
                label: 'Guest',
                avatarColor: AvatarColor.rose,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          context,
          'Long Content',
          'User items with long names and labels that truncate with ellipsis.',
          [
            _UserItemExample(
              label: 'Long Name',
              child: WnUserItem(
                displayName:
                    'This Is A Very Long Display Name That Should Truncate',
                label: 'Member',
                avatarColor: AvatarColor.violet,
              ),
            ),
            _UserItemExample(
              label: 'Long Label',
              child: WnUserItem(
                displayName: 'Fred Durst',
                label:
                    'This is a very long label that should also truncate properly',
                avatarColor: AvatarColor.cyan,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _buildSection(
  BuildContext context,
  String title,
  String description,
  List<Widget> children,
) {
  final colors = context.colors;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: colors.backgroundContentPrimary,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        description,
        style: TextStyle(
          fontSize: 13,
          color: colors.backgroundContentSecondary,
        ),
      ),
      const SizedBox(height: 16),
      ...children.map(
        (child) =>
            Padding(padding: const EdgeInsets.only(bottom: 16), child: child),
      ),
    ],
  );
}

class _UserItemExample extends StatelessWidget {
  const _UserItemExample({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SizedBox(
      width: 368,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colors.backgroundContentSecondary,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _InteractiveUserItem extends StatelessWidget {
  const _InteractiveUserItem({required this.context});

  final BuildContext context;

  @override
  Widget build(BuildContext outerContext) {
    final displayName = context.knobs.string(
      label: 'Display Name',
      initialValue: 'Fred Durst',
    );
    final labelText = context.knobs.stringOrNull(
      label: 'Label',
      initialValue: 'Label',
    );
    final hasImage = context.knobs.boolean(
      label: 'Has Image',
      initialValue: false,
    );
    final color = context.knobs.object.dropdown<AvatarColor>(
      label: 'Avatar Color',
      options: AvatarColor.values,
      initialOption: AvatarColor.neutral,
      labelBuilder: (c) => c.name[0].toUpperCase() + c.name.substring(1),
    );

    return WnUserItem(
      displayName: displayName,
      label: labelText,
      pictureUrl: hasImage ? _sampleImageUrl : null,
      avatarColor: color,
    );
  }
}
