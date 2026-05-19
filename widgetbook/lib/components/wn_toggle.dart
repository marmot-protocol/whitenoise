import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_toggle.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

class WnToggleStory extends StatelessWidget {
  const WnToggleStory({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

@widgetbook.UseCase(name: 'Toggle', type: WnToggleStory)
Widget wnToggleShowcase(BuildContext context) {
  final colors = context.colors;

  return Scaffold(
    backgroundColor: colors.backgroundPrimary,
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Toggle',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: colors.backgroundContentPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'A compact on/off control for settings rows.',
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
        const SizedBox(height: 16),
        _InteractiveToggle(context: context),
        const SizedBox(height: 32),
        Divider(color: colors.borderTertiary),
        const SizedBox(height: 24),
        Wrap(
          spacing: 32,
          runSpacing: 24,
          children: const [
            _ToggleExample(
              label: 'Off',
              child: WnToggle(value: false, onChanged: _noopOnChanged),
            ),
            _ToggleExample(
              label: 'On',
              child: WnToggle(value: true, onChanged: _noopOnChanged),
            ),
            _ToggleExample(
              label: 'Disabled',
              child: WnToggle(
                value: true,
                enabled: false,
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

class _InteractiveToggle extends HookWidget {
  const _InteractiveToggle({required this.context});

  final BuildContext context;

  @override
  Widget build(BuildContext _) {
    final value = useState(false);
    final enabled = context.knobs.boolean(label: 'Enabled', initialValue: true);

    return WnToggle(
      value: value.value,
      enabled: enabled,
      onChanged: (v) {
        value.value = v;
      },
    );
  }
}

class _ToggleExample extends StatelessWidget {
  const _ToggleExample({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      mainAxisSize: MainAxisSize.min,
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
    );
  }
}
