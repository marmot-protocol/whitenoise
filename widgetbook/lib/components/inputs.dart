import 'package:flutter/material.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_icon.dart';
import 'package:whitenoise/widgets/wn_input.dart';
import 'package:whitenoise/widgets/wn_input_field_button.dart';
import 'package:whitenoise/widgets/wn_input_password.dart';
import 'package:whitenoise/widgets/wn_input_text_area.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

class WnInputStory extends StatelessWidget {
  const WnInputStory({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

@widgetbook.UseCase(name: 'Text Input', type: WnInputStory)
Widget wnInputShowcase(BuildContext context) {
  return Scaffold(
    backgroundColor: context.colors.backgroundPrimary,
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Playground',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: context.colors.backgroundContentPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Use the knobs panel to customize this input field.',
          style: TextStyle(
            fontSize: 14,
            color: context.colors.backgroundContentSecondary,
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 375),
            child: _InteractiveInput(context: context),
          ),
        ),
        const SizedBox(height: 32),
        Divider(color: context.colors.borderTertiary),
        const SizedBox(height: 24),
        _buildSection(
          context,
          'Size Variants',
          'Input fields come in two sizes: 56px (default) and 44px (compact).',
          [
            _InputExample(
              label: 'Size 56 (Default)',
              child: _StaticInput(
                placeholder: 'Enter text...',
                size: WnInputSize.size56,
              ),
            ),
            _InputExample(
              label: 'Size 44 (Compact)',
              child: _StaticInput(
                placeholder: 'Enter text...',
                size: WnInputSize.size44,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          context,
          'States',
          'Input fields can be in different states: enabled, disabled, read-only, or error.',
          [
            _InputExample(
              label: 'Enabled (Default)',
              child: _StaticInput(placeholder: 'Enter text...'),
            ),
            _InputExample(
              label: 'Disabled',
              child: _StaticInput(placeholder: 'Enter text...', enabled: false),
            ),
            _InputExample(
              label: 'Read Only',
              child: _StaticInput(
                placeholder: 'Enter text...',
                readOnly: true,
                initialValue: 'Read only content',
              ),
            ),
            _InputExample(
              label: 'Error State',
              child: _StaticInput(
                placeholder: 'Enter text...',
                errorText: 'This field has an error',
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          context,
          'With Label',
          'Labels help identify the purpose of the input field.',
          [
            _InputExample(
              label: 'With Label',
              child: _StaticInput(
                placeholder: 'Enter your name...',
                inputLabel: 'Full Name',
              ),
            ),
            _InputExample(
              label: 'With Label + Help Icon',
              child: _StaticInput(
                placeholder: 'Enter your name...',
                inputLabel: 'Full Name',
                showLabelHelpIcon: true,
              ),
            ),
            _InputExample(
              label: 'Label + Error',
              child: _StaticInput(
                placeholder: 'Enter email...',
                inputLabel: 'Email',
                errorText: 'Invalid email format',
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          context,
          'Helper & Error Text',
          'Additional text below the input provides guidance or error feedback.',
          [
            _InputExample(
              label: 'With Helper Text',
              child: _StaticInput(
                placeholder: 'Enter password...',
                helperText: 'Must be at least 8 characters',
              ),
            ),
            _InputExample(
              label: 'With Error Text',
              child: _StaticInput(
                placeholder: 'Enter password...',
                errorText: 'Password is too short',
              ),
            ),
            _InputExample(
              label: 'Label + Helper Text',
              child: _StaticInput(
                placeholder: 'Enter username...',
                inputLabel: 'Username',
                helperText: 'Letters and numbers only',
              ),
            ),
            _InputExample(
              label: 'Label + Error Text',
              child: _StaticInput(
                placeholder: 'Enter username...',
                inputLabel: 'Username',
                errorText: 'Username already taken',
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          context,
          'With Content',
          'Inputs with pre-filled content in various states.',
          [
            _InputExample(
              label: 'With Value',
              child: _StaticInput(
                placeholder: 'Enter text...',
                initialValue: 'Hello World',
              ),
            ),
            _InputExample(
              label: 'With Value + Label',
              child: _StaticInput(
                placeholder: 'Enter text...',
                inputLabel: 'Message',
                initialValue: 'Hello World',
              ),
            ),
            _InputExample(
              label: 'With Value + Error',
              child: _StaticInput(
                placeholder: 'Enter text...',
                initialValue: 'invalid@',
                errorText: 'Invalid format',
              ),
            ),
            _InputExample(
              label: 'Disabled with Value',
              child: _StaticInput(
                placeholder: 'Enter text...',
                initialValue: 'Cannot edit this',
                enabled: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          context,
          'With Leading Icon',
          'Input fields can display an optional leading icon on the left side.',
          [
            _InputExample(
              label: 'With Leading Icon',
              child: _StaticInput(
                placeholder: 'Search...',
                showLeadingIcon: true,
              ),
            ),
            _InputExample(
              label: 'Leading Icon + Label',
              child: _StaticInput(
                placeholder: 'Search...',
                inputLabel: 'Search',
                showLeadingIcon: true,
              ),
            ),
            _InputExample(
              label: 'Leading Icon Compact',
              child: _StaticInput(
                placeholder: 'Search...',
                size: WnInputSize.size44,
                showLeadingIcon: true,
              ),
            ),
            _InputExample(
              label: 'Leading + Inline Action',
              child: _StaticInput(
                placeholder: 'Search...',
                showLeadingIcon: true,
                showInlineAction: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          context,
          'With Actions',
          'Input fields can have inline or trailing action buttons.',
          [
            _InputExample(
              label: 'With Inline Action',
              child: _StaticInput(
                placeholder: 'Search...',
                showInlineAction: true,
              ),
            ),
            _InputExample(
              label: 'With Trailing Action',
              child: _StaticInput(
                placeholder: 'Enter text...',
                showTrailingAction: true,
              ),
            ),
            _InputExample(
              label: 'Both Actions',
              child: _StaticInput(
                placeholder: 'Enter text...',
                showInlineAction: true,
                showTrailingAction: true,
              ),
            ),
            _InputExample(
              label: 'Compact with Actions',
              child: _StaticInput(
                placeholder: 'Search...',
                size: WnInputSize.size44,
                showInlineAction: true,
                showTrailingAction: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          context,
          'Inline Action Buttons',
          'Inline action buttons auto-size based on the input size. '
              'Size 56 inputs use 48px buttons, size 44 inputs use 36px buttons.',
          [
            _InputExample(
              label: 'Size 56 (48px button)',
              child: _StaticInput(
                placeholder: 'Enter text...',
                showInlineAction: true,
              ),
            ),
            _InputExample(
              label: 'Size 44 (36px button)',
              child: _StaticInput(
                placeholder: 'Enter text...',
                size: WnInputSize.size44,
                showInlineAction: true,
              ),
            ),
            _InputExample(
              label: 'Unfilled (transparent)',
              child: _StaticInput(
                placeholder: 'Enter text...',
                showInlineAction: true,
                inlineActionFilled: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          context,
          'Standalone Button Sizes',
          'WnInputFieldButton comes in 48px, 40px, and 36px, '
              'each in filled or unfilled style.',
          [
            _InputExample(
              label: 'Filled (48, 40, 36)',
              child: Row(
                children: [
                  WnInputFieldButton(
                    icon: WnIcons.closeSmall,
                    onPressed: () {},
                    buttonSize: WnInputFieldButtonSize.size48,
                  ),
                  const SizedBox(width: 8),
                  WnInputFieldButton(
                    icon: WnIcons.closeSmall,
                    onPressed: () {},
                    buttonSize: WnInputFieldButtonSize.size40,
                  ),
                  const SizedBox(width: 8),
                  WnInputFieldButton(
                    icon: WnIcons.closeSmall,
                    onPressed: () {},
                    buttonSize: WnInputFieldButtonSize.size36,
                  ),
                ],
              ),
            ),
            _InputExample(
              label: 'Unfilled (48, 40, 36)',
              child: Row(
                children: [
                  WnInputFieldButton(
                    icon: WnIcons.closeSmall,
                    onPressed: () {},
                    buttonSize: WnInputFieldButtonSize.size48,
                    filled: false,
                  ),
                  const SizedBox(width: 8),
                  WnInputFieldButton(
                    icon: WnIcons.closeSmall,
                    onPressed: () {},
                    buttonSize: WnInputFieldButtonSize.size40,
                    filled: false,
                  ),
                  const SizedBox(width: 8),
                  WnInputFieldButton(
                    icon: WnIcons.closeSmall,
                    onPressed: () {},
                    buttonSize: WnInputFieldButtonSize.size36,
                    filled: false,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          context,
          'Complete Examples',
          'Full configurations combining multiple features.',
          [
            _InputExample(
              label: 'Full Configuration',
              child: _StaticInput(
                placeholder: 'Enter your email...',
                inputLabel: 'Email Address',
                helperText: 'We will never share your email',
                showLeadingIcon: true,
                leadingIconData: WnIcons.message,
                showInlineAction: true,
              ),
            ),
            _InputExample(
              label: 'Error with All Features',
              child: _StaticInput(
                placeholder: 'Enter your email...',
                inputLabel: 'Email Address',
                initialValue: 'invalid-email',
                errorText: 'Please enter a valid email address',
                showInlineAction: true,
              ),
            ),
            _InputExample(
              label: 'Search Field',
              child: _StaticInput(
                placeholder: 'Search messages...',
                size: WnInputSize.size44,
                showLeadingIcon: true,
                showInlineAction: true,
                showTrailingAction: true,
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
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: context.colors.backgroundContentPrimary,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        description,
        style: TextStyle(
          fontSize: 13,
          color: context.colors.backgroundContentSecondary,
        ),
      ),
      const SizedBox(height: 16),
      Wrap(spacing: 24, runSpacing: 24, children: children),
    ],
  );
}

class _InputExample extends StatelessWidget {
  const _InputExample({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: context.colors.backgroundContentSecondary,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _StaticInput extends StatelessWidget {
  const _StaticInput({
    required this.placeholder,
    this.inputLabel,
    this.helperText,
    this.errorText,
    this.initialValue,
    this.enabled = true,
    this.readOnly = false,
    this.size = WnInputSize.size56,
    this.showLabelHelpIcon = false,
    this.showLeadingIcon = false,
    this.leadingIconData,
    this.showInlineAction = false,
    this.inlineActionFilled = true,
    this.showTrailingAction = false,
  });

  final String placeholder;
  final String? inputLabel;
  final String? helperText;
  final String? errorText;
  final String? initialValue;
  final bool enabled;
  final bool readOnly;
  final WnInputSize size;
  final bool showLabelHelpIcon;
  final bool showLeadingIcon;
  final WnIcons? leadingIconData;
  final bool showInlineAction;
  final bool inlineActionFilled;
  final bool showTrailingAction;

  @override
  Widget build(BuildContext context) {
    return WnInput(
      placeholder: placeholder,
      label: inputLabel,
      labelHelpIcon: showLabelHelpIcon ? () {} : null,
      helperText: helperText,
      errorText: errorText,
      controller: initialValue != null
          ? TextEditingController(text: initialValue)
          : null,
      enabled: enabled,
      readOnly: readOnly,
      size: size,
      leadingIcon: showLeadingIcon
          ? WnIcon(
              leadingIconData ?? WnIcons.search,
              size: 16,
              color: context.colors.backgroundContentSecondary,
            )
          : null,
      inlineActionIcon: showInlineAction ? WnIcons.closeSmall : null,
      inlineActionOnPressed: showInlineAction ? () {} : null,
      inlineActionFilled: inlineActionFilled,
      trailingAction: showTrailingAction
          ? WnInputTrailingButton(
              icon: WnIcons.scan,
              onPressed: () {},
              size: size,
            )
          : null,
    );
  }
}

class _InteractiveInput extends StatelessWidget {
  const _InteractiveInput({required this.context});

  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final size = this.context.knobs.object.dropdown<WnInputSize>(
      label: 'Size',
      options: WnInputSize.values,
      initialOption: WnInputSize.size56,
      labelBuilder: (value) => value == WnInputSize.size56 ? '56px' : '44px',
    );
    final showInlineAction = this.context.knobs.boolean(
      label: 'Show Inline Action',
      initialValue: false,
    );
    final inlineActionFilled = this.context.knobs.boolean(
      label: 'Inline Action Filled',
      initialValue: true,
    );

    return WnInput(
      placeholder: this.context.knobs.string(
        label: 'Placeholder',
        initialValue: 'Enter text...',
      ),
      label: this.context.knobs.stringOrNull(
        label: 'Label',
        initialValue: 'Label',
      ),
      labelHelpIcon:
          this.context.knobs.boolean(
            label: 'Show Label Help Icon',
            initialValue: false,
          )
          ? () {}
          : null,
      helperText: this.context.knobs.stringOrNull(
        label: 'Helper Text',
        initialValue: null,
      ),
      errorText: this.context.knobs.stringOrNull(
        label: 'Error Text',
        initialValue: null,
      ),
      enabled: this.context.knobs.boolean(label: 'Enabled', initialValue: true),
      readOnly: this.context.knobs.boolean(
        label: 'Read Only',
        initialValue: false,
      ),
      size: size,
      leadingIcon:
          this.context.knobs.boolean(
            label: 'Show Leading Icon',
            initialValue: false,
          )
          ? WnIcon(
              WnIcons.search,
              size: 16,
              color: colors.backgroundContentSecondary,
            )
          : null,
      inlineActionIcon: showInlineAction ? WnIcons.closeSmall : null,
      inlineActionOnPressed: showInlineAction ? () {} : null,
      inlineActionFilled: inlineActionFilled,
      trailingAction:
          this.context.knobs.boolean(
            label: 'Show Trailing Action',
            initialValue: false,
          )
          ? WnInputTrailingButton(
              icon: WnIcons.scan,
              onPressed: () {},
              size: size,
            )
          : null,
    );
  }
}

class WnInputPasswordStory extends StatelessWidget {
  const WnInputPasswordStory({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

@widgetbook.UseCase(name: 'Password Input', type: WnInputPasswordStory)
Widget wnInputPasswordShowcase(BuildContext context) {
  return Scaffold(
    backgroundColor: context.colors.backgroundPrimary,
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Playground',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: context.colors.backgroundContentPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Use the knobs panel to customize this password input field.',
          style: TextStyle(
            fontSize: 14,
            color: context.colors.backgroundContentSecondary,
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 375),
            child: _InteractivePasswordInput(context: context),
          ),
        ),
        const SizedBox(height: 32),
        Divider(color: context.colors.borderTertiary),
        const SizedBox(height: 24),
        _buildSection(
          context,
          'Size Variants',
          'Password input fields come in two sizes.',
          [
            _PasswordExample(
              label: 'Size 56 (Default)',
              child: _StaticPasswordInput(
                placeholder: 'Enter password...',
                size: WnInputSize.size56,
              ),
            ),
            _PasswordExample(
              label: 'Size 44 (Compact)',
              child: _StaticPasswordInput(
                placeholder: 'Enter password...',
                size: WnInputSize.size44,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          context,
          'States',
          'Password inputs can be enabled, disabled, or show errors.',
          [
            _PasswordExample(
              label: 'Enabled (Default)',
              child: _StaticPasswordInput(placeholder: 'Enter password...'),
            ),
            _PasswordExample(
              label: 'Disabled',
              child: _StaticPasswordInput(
                placeholder: 'Enter password...',
                enabled: false,
              ),
            ),
            _PasswordExample(
              label: 'Error State',
              child: _StaticPasswordInput(
                placeholder: 'Enter password...',
                errorText: 'Password is incorrect',
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          context,
          'With Label & Helper',
          'Labels and helper text provide context for the password field.',
          [
            _PasswordExample(
              label: 'With Label',
              child: _StaticPasswordInput(
                placeholder: 'Enter password...',
                inputLabel: 'Password',
              ),
            ),
            _PasswordExample(
              label: 'With Helper Text',
              child: _StaticPasswordInput(
                placeholder: 'Enter password...',
                inputLabel: 'Password',
                helperText: 'Must be at least 8 characters',
              ),
            ),
            _PasswordExample(
              label: 'With Error',
              child: _StaticPasswordInput(
                placeholder: 'Enter password...',
                inputLabel: 'Password',
                errorText: 'Password does not meet requirements',
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _PasswordExample extends StatelessWidget {
  const _PasswordExample({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: context.colors.backgroundContentSecondary,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _StaticPasswordInput extends StatelessWidget {
  const _StaticPasswordInput({
    required this.placeholder,
    this.inputLabel,
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.size = WnInputSize.size56,
  });

  final String placeholder;
  final String? inputLabel;
  final String? helperText;
  final String? errorText;
  final bool enabled;
  final WnInputSize size;

  @override
  Widget build(BuildContext context) {
    return WnInputPassword(
      placeholder: placeholder,
      label: inputLabel,
      helperText: helperText,
      errorText: errorText,
      enabled: enabled,
      size: size,
    );
  }
}

class _InteractivePasswordInput extends StatelessWidget {
  const _InteractivePasswordInput({required this.context});

  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return WnInputPassword(
      placeholder: this.context.knobs.string(
        label: 'Placeholder',
        initialValue: 'Enter password...',
      ),
      label: this.context.knobs.stringOrNull(
        label: 'Label',
        initialValue: 'Password',
      ),
      helperText: this.context.knobs.stringOrNull(
        label: 'Helper Text',
        initialValue: null,
      ),
      errorText: this.context.knobs.stringOrNull(
        label: 'Error Text',
        initialValue: null,
      ),
      enabled: this.context.knobs.boolean(label: 'Enabled', initialValue: true),
      size: this.context.knobs.object.dropdown<WnInputSize>(
        label: 'Size',
        options: WnInputSize.values,
        initialOption: WnInputSize.size56,
        labelBuilder: (value) => value == WnInputSize.size56 ? '56px' : '44px',
      ),
    );
  }
}

class WnInputTextAreaStory extends StatelessWidget {
  const WnInputTextAreaStory({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

@widgetbook.UseCase(name: 'Text Area', type: WnInputTextAreaStory)
Widget wnInputTextAreaShowcase(BuildContext context) {
  return Scaffold(
    backgroundColor: context.colors.backgroundPrimary,
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Playground',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: context.colors.backgroundContentPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Use the knobs panel to customize this text area.',
          style: TextStyle(
            fontSize: 14,
            color: context.colors.backgroundContentSecondary,
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 375),
            child: _InteractiveTextArea(context: context),
          ),
        ),
        const SizedBox(height: 32),
        Divider(color: context.colors.borderTertiary),
        const SizedBox(height: 24),
        _buildSection(
          context,
          'Size Variants',
          'Text areas come in two sizes with configurable line count.',
          [
            _TextAreaExample(
              label: 'Size 56 (Default)',
              child: _StaticTextArea(
                placeholder: 'Enter text...',
                size: WnInputSize.size56,
              ),
            ),
            _TextAreaExample(
              label: 'Size 44 (Compact)',
              child: _StaticTextArea(
                placeholder: 'Enter text...',
                size: WnInputSize.size44,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          context,
          'States',
          'Text areas can be enabled, disabled, read-only, or show errors.',
          [
            _TextAreaExample(
              label: 'Enabled (Default)',
              child: _StaticTextArea(placeholder: 'Enter text...'),
            ),
            _TextAreaExample(
              label: 'Disabled',
              child: _StaticTextArea(
                placeholder: 'Enter text...',
                enabled: false,
              ),
            ),
            _TextAreaExample(
              label: 'Read Only',
              child: _StaticTextArea(
                placeholder: 'Enter text...',
                readOnly: true,
                initialValue: 'This content is read-only and cannot be edited.',
              ),
            ),
            _TextAreaExample(
              label: 'Error State',
              child: _StaticTextArea(
                placeholder: 'Enter text...',
                errorText: 'This field has an error',
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          context,
          'With Label & Helper',
          'Labels and helper text provide context.',
          [
            _TextAreaExample(
              label: 'With Label',
              child: _StaticTextArea(
                placeholder: 'Enter your message...',
                inputLabel: 'Message',
              ),
            ),
            _TextAreaExample(
              label: 'With Helper Text',
              child: _StaticTextArea(
                placeholder: 'Enter your bio...',
                inputLabel: 'Bio',
                helperText: 'Max 500 characters',
              ),
            ),
            _TextAreaExample(
              label: 'With Error',
              child: _StaticTextArea(
                placeholder: 'Enter description...',
                inputLabel: 'Description',
                errorText: 'Description is required',
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          context,
          'Max Lines',
          'Control the height by setting max lines.',
          [
            _TextAreaExample(
              label: '3 Lines',
              child: _StaticTextArea(placeholder: 'Enter text...', maxLines: 3),
            ),
            _TextAreaExample(
              label: '5 Lines (Default)',
              child: _StaticTextArea(placeholder: 'Enter text...', maxLines: 5),
            ),
            _TextAreaExample(
              label: '8 Lines',
              child: _StaticTextArea(placeholder: 'Enter text...', maxLines: 8),
            ),
          ],
        ),
      ],
    ),
  );
}

class _TextAreaExample extends StatelessWidget {
  const _TextAreaExample({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: context.colors.backgroundContentSecondary,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _StaticTextArea extends StatelessWidget {
  const _StaticTextArea({
    required this.placeholder,
    this.inputLabel,
    this.helperText,
    this.errorText,
    this.initialValue,
    this.enabled = true,
    this.readOnly = false,
    this.size = WnInputSize.size56,
    this.maxLines = 5,
  });

  final String placeholder;
  final String? inputLabel;
  final String? helperText;
  final String? errorText;
  final String? initialValue;
  final bool enabled;
  final bool readOnly;
  final WnInputSize size;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return WnInputTextArea(
      placeholder: placeholder,
      label: inputLabel,
      helperText: helperText,
      errorText: errorText,
      controller: initialValue != null
          ? TextEditingController(text: initialValue)
          : null,
      enabled: enabled,
      readOnly: readOnly,
      size: size,
      maxLines: maxLines,
    );
  }
}

class _InteractiveTextArea extends StatelessWidget {
  const _InteractiveTextArea({required this.context});

  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return WnInputTextArea(
      placeholder: this.context.knobs.string(
        label: 'Placeholder',
        initialValue: 'Enter multiline text...',
      ),
      label: this.context.knobs.stringOrNull(
        label: 'Label',
        initialValue: 'Comments',
      ),
      helperText: this.context.knobs.stringOrNull(
        label: 'Helper Text',
        initialValue: null,
      ),
      errorText: this.context.knobs.stringOrNull(
        label: 'Error Text',
        initialValue: null,
      ),
      enabled: this.context.knobs.boolean(label: 'Enabled', initialValue: true),
      readOnly: this.context.knobs.boolean(
        label: 'Read Only',
        initialValue: false,
      ),
      size: this.context.knobs.object.dropdown<WnInputSize>(
        label: 'Size',
        options: WnInputSize.values,
        initialOption: WnInputSize.size56,
        labelBuilder: (value) => value == WnInputSize.size56 ? '56px' : '44px',
      ),
      maxLines: this.context.knobs.int
          .slider(label: 'Max Lines', initialValue: 5, min: 1, max: 10)
          .toInt(),
    );
  }
}
