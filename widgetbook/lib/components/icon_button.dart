import 'package:flutter/material.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_icon_button.dart';
import 'package:whitenoise/widgets/wn_icon.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Icon Button', type: WnIconButton)
Widget wnIconButtonShowcase(BuildContext context) {
  return Scaffold(
    backgroundColor: context.colors.backgroundPrimary,
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Icon Button Playground',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: context.colors.backgroundContentPrimary,
          ),
        ),
        const SizedBox(height: 24),
        const Center(child: _InteractiveIconButton()),
        const SizedBox(height: 32),
        Divider(color: context.colors.borderTertiary),
        const SizedBox(height: 24),
        Text(
          'Types',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.colors.backgroundContentPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 24,
          children: [
            _Variant(
              'Primary',
              WnIconButton(
                icon: WnIcons.addCircle,
                type: WnIconButtonType.primary,
                onPressed: () {},
              ),
            ),
            _Variant(
              'Outline',
              WnIconButton(
                icon: WnIcons.addCircle,
                type: WnIconButtonType.outline,
                onPressed: () {},
              ),
            ),
            _Variant(
              'Ghost',
              WnIconButton(
                icon: WnIcons.addCircle,
                type: WnIconButtonType.ghost,
                onPressed: () {},
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Sizes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.colors.backgroundContentPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 24,
          children: [
            _Variant(
              'Size 44',
              WnIconButton(
                icon: WnIcons.addCircle,
                size: WnIconButtonSize.size44,
                onPressed: () {},
              ),
            ),
            _Variant(
              'Size 56',
              WnIconButton(
                icon: WnIcons.addCircle,
                size: WnIconButtonSize.size56,
                onPressed: () {},
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _InteractiveIconButton extends StatelessWidget {
  const _InteractiveIconButton();

  @override
  Widget build(BuildContext context) {
    return WnIconButton(
      icon: context.knobs.object.dropdown<WnIcons>(
        label: 'Icon',
        options: [
          WnIcons.addCircle,
          WnIcons.newChat,
          WnIcons.settings,
          WnIcons.closeLarge,
        ],
        initialOption: WnIcons.addCircle,
        labelBuilder: (value) => value.toString().split('.').last,
      ),
      type: context.knobs.object.dropdown<WnIconButtonType>(
        label: 'Type',
        options: WnIconButtonType.values,
        initialOption: WnIconButtonType.ghost,
        labelBuilder: (value) => value.name,
      ),
      size: context.knobs.object.dropdown<WnIconButtonSize>(
        label: 'Size',
        options: WnIconButtonSize.values,
        initialOption: WnIconButtonSize.size44,
        labelBuilder: (value) => value.name,
      ),
      disabled: context.knobs.boolean(label: 'Disabled', initialValue: false),
      onPressed: () {},
    );
  }
}

class _Variant extends StatelessWidget {
  const _Variant(this.label, this.child);

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        child,
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: context.colors.backgroundContentSecondary,
          ),
        ),
      ],
    );
  }
}
