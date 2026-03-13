import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_checkbox.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

class WnCheckboxStory extends StatelessWidget {
  const WnCheckboxStory({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

@widgetbook.UseCase(name: 'Checkbox', type: WnCheckboxStory)
Widget wnCheckboxShowcase(BuildContext context) {
  final colors = context.colors;

  return Scaffold(
    backgroundColor: colors.backgroundPrimary,
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Checkbox',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: colors.backgroundContentPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'A checkbox with a label and optional description, using the same visual style as '
          'user selection checkboxes.',
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
          'Use the knobs panel to customize the checkbox.',
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
            child: _InteractiveCheckbox(context: context),
          ),
        ),
        const SizedBox(height: 32),
        Divider(color: colors.borderTertiary),
        const SizedBox(height: 24),
        _buildSection(
          context,
          'States',
          'Common checkbox configurations.',
          const [
            _CheckboxExample(
              label: 'Unchecked',
              child: WnCheckbox(
                label: 'Include your npub',
                value: false,
                onChanged: _noopOnChanged,
              ),
            ),
            _CheckboxExample(
              label: 'Checked',
              child: WnCheckbox(
                label: 'Include your npub',
                value: true,
                onChanged: _noopOnChanged,
              ),
            ),
            _CheckboxExample(
              label: 'With description',
              child: WnCheckbox(
                label: 'Include your npub',
                description: 'Share your public key with the recipient.',
                value: true,
                onChanged: _noopOnChanged,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

void _noopOnChanged(bool _) {}

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

class _CheckboxExample extends StatelessWidget {
  const _CheckboxExample({required this.label, required this.child});

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

class _InteractiveCheckbox extends HookWidget {
  const _InteractiveCheckbox({required this.context});

  final BuildContext context;

  @override
  Widget build(BuildContext _) {
    final value = useState(false);
    final label = context.knobs.string(
      label: 'Label',
      initialValue: 'Include your npub',
    );
    final description = context.knobs.stringOrNull(
      label: 'Description',
      initialValue: 'Share your public key with the recipient.',
    );

    return WnCheckbox(
      label: label,
      description: description,
      value: value.value,
      onChanged: (v) {
        value.value = v;
      },
    );
  }
}
