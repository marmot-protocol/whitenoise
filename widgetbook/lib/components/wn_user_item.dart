import 'package:flutter/material.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_avatar.dart';
import 'package:whitenoise/widgets/wn_user_item.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

const _sampleImageUrl = 'https://www.whitenoise.chat/images/mask-man.webp';
const _sampleNpub =
    'npub 1zuu ajd7 u3sx 8xu9 2yav 9jwx pr83 9cs0 kc3q 6t56 vd5u 9q03 3xmh sk6c 2uc';

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
          'A row used to display a user. Comes in three sizes: small (name + label), '
          'medium (name + npub + checkbox), and big (larger avatar + npub + checkbox).',
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
            constraints: const BoxConstraints(maxWidth: 400),
            child: _InteractiveUserItem(context: context),
          ),
        ),
        const SizedBox(height: 32),
        Divider(color: colors.borderTertiary),
        const SizedBox(height: 24),
        _buildSection(
          context,
          'Small',
          'Compact row with name and optional label. No checkbox.',
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
            _UserItemExample(
              label: 'With Image',
              child: WnUserItem(
                displayName: 'Fred Durst',
                label: 'Admin',
                pictureUrl: _sampleImageUrl,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          context,
          'Medium',
          'Row with name, npub (middle-ellipsis, 2 lines), and optional checkbox.',
          [
            _UserItemExample(
              label: 'With Checkbox (Unselected)',
              child: WnUserItem(
                displayName: 'Fred Durst',
                npub: _sampleNpub,
                pictureUrl: _sampleImageUrl,
                size: WnUserItemSize.medium,
                showCheckbox: true,
              ),
            ),
            _UserItemExample(
              label: 'With Checkbox (Selected)',
              child: WnUserItem(
                displayName: 'Fred Durst',
                npub: _sampleNpub,
                pictureUrl: _sampleImageUrl,
                size: WnUserItemSize.medium,
                showCheckbox: true,
                isSelected: true,
              ),
            ),
            _UserItemExample(
              label: 'Without Checkbox',
              child: WnUserItem(
                displayName: 'Fred Durst',
                npub: _sampleNpub,
                pictureUrl: _sampleImageUrl,
                size: WnUserItemSize.medium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          context,
          'Big',
          'Larger avatar, fixed height, name, npub, and optional checkbox.',
          [
            _UserItemExample(
              label: 'With Checkbox (Unselected)',
              child: WnUserItem(
                displayName: 'Fred Durst',
                npub: _sampleNpub,
                pictureUrl: _sampleImageUrl,
                size: WnUserItemSize.big,
                showCheckbox: true,
              ),
            ),
            _UserItemExample(
              label: 'With Checkbox (Selected)',
              child: WnUserItem(
                displayName: 'Fred Durst',
                npub: _sampleNpub,
                pictureUrl: _sampleImageUrl,
                size: WnUserItemSize.big,
                showCheckbox: true,
                isSelected: true,
              ),
            ),
            _UserItemExample(
              label: 'Initials Avatar',
              child: WnUserItem(
                displayName: 'Fred Durst',
                npub: _sampleNpub,
                avatarColor: AvatarColor.emerald,
                size: WnUserItemSize.big,
                showCheckbox: true,
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
      width: 400,
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
    final size = context.knobs.object.dropdown<WnUserItemSize>(
      label: 'Size',
      options: WnUserItemSize.values,
      initialOption: WnUserItemSize.small,
      labelBuilder: (s) => s.name[0].toUpperCase() + s.name.substring(1),
    );
    final isSmall = size == WnUserItemSize.small;
    final labelText = isSmall
        ? context.knobs.stringOrNull(label: 'Label', initialValue: 'Label')
        : null;
    final npubText = !isSmall
        ? context.knobs.stringOrNull(label: 'Npub', initialValue: _sampleNpub)
        : null;
    final hasImage = context.knobs.boolean(
      label: 'Has Image',
      initialValue: false,
    );
    final showCheckbox = !isSmall
        ? context.knobs.boolean(label: 'Show Checkbox', initialValue: true)
        : false;
    final isSelected = showCheckbox
        ? context.knobs.boolean(label: 'Selected', initialValue: false)
        : false;
    final color = context.knobs.object.dropdown<AvatarColor>(
      label: 'Avatar Color',
      options: AvatarColor.values,
      initialOption: AvatarColor.neutral,
      labelBuilder: (c) => c.name[0].toUpperCase() + c.name.substring(1),
    );

    return WnUserItem(
      displayName: displayName,
      label: labelText,
      npub: npubText,
      pictureUrl: hasImage ? _sampleImageUrl : null,
      avatarColor: color,
      size: size,
      showCheckbox: showCheckbox,
      isSelected: isSelected,
    );
  }
}
