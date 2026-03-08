import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart' show Gap;
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_icon.dart';
import 'package:whitenoise/widgets/wn_icon_button.dart';
import 'package:whitenoise/widgets/wn_input.dart';
import 'package:whitenoise/widgets/wn_input_field_button.dart';

class WnInputPassword extends HookWidget {
  const WnInputPassword({
    super.key,
    required this.placeholder,
    this.label,
    this.labelHelpIcon,
    this.helperText,
    this.errorText,
    this.controller,
    this.autofocus = false,
    this.enabled = true,
    this.size = WnInputSize.size56,
    this.onChanged,
    this.textInputAction,
    this.onScan,
    this.onPaste,
    this.focusNode,
  });

  final String placeholder;
  final String? label;
  final VoidCallback? labelHelpIcon;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final bool autofocus;
  final bool enabled;
  final WnInputSize size;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final VoidCallback? onScan;
  final VoidCallback? onPaste;
  final FocusNode? focusNode;

  bool get _hasError => errorText != null;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isVisible = useState(false);
    final internalController = useTextEditingController();
    final effectiveController = controller ?? internalController;
    final isEmpty = useListenableSelector(
      effectiveController,
      () => effectiveController.text.isEmpty,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) _buildLabel(context, colors),
        _buildInputRow(context, colors, isVisible, isEmpty, effectiveController),
        if (_hasError)
          _buildErrorText(context, colors)
        else if (helperText != null)
          _buildHelperText(context, colors),
      ],
    );
  }

  Widget _buildLabel(BuildContext context, SemanticColors colors) {
    final typography = context.typographyScaled;
    return Padding(
      padding: EdgeInsets.only(left: 2.w),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 4.h),
            child: Text(
              label!,
              style: typography.medium14.copyWith(color: colors.backgroundContentPrimary),
            ),
          ),
          if (labelHelpIcon != null)
            WnIconButton(
              key: const Key('label_help_icon'),
              icon: WnIcons.help,
              onPressed: labelHelpIcon,
            ),
        ],
      ),
    );
  }

  Widget _buildInputRow(
    BuildContext context,
    SemanticColors colors,
    ValueNotifier<bool> isVisible,
    bool isEmpty,
    TextEditingController effectiveController,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildInputField(context, colors, isVisible, isEmpty, effectiveController),
        ),
        Gap(6.w),
        _buildTrailingAction(colors, isEmpty, effectiveController),
      ],
    );
  }

  Widget _buildInputField(
    BuildContext context,
    SemanticColors colors,
    ValueNotifier<bool> isVisible,
    bool isEmpty,
    TextEditingController effectiveController,
  ) {
    final typography = context.typographyScaled;
    final fieldHeight = size.height.h;
    final borderColor = _hasError ? colors.borderDestructivePrimary : colors.borderTertiary;

    return Container(
      key: const Key('password_field_container'),
      height: fieldHeight,
      decoration: BoxDecoration(
        color: colors.backgroundPrimary,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: TextField(
                key: const Key('password_field'),
                controller: effectiveController,
                focusNode: focusNode,
                autofocus: autofocus,
                enabled: enabled,
                obscureText: !isVisible.value,
                obscuringCharacter: '●',
                onChanged: onChanged,
                textInputAction: textInputAction,
                style: typography.medium14.copyWith(
                  color: enabled
                      ? colors.backgroundContentPrimary
                      : colors.backgroundContentTertiary,
                ),
                decoration: InputDecoration(
                  hintText: placeholder,
                  hintStyle: typography.medium14.copyWith(
                    color: colors.backgroundContentSecondary,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
              ),
            ),
          ),
          _buildInlineAction(colors, isVisible, isEmpty),
          Gap(4.w),
        ],
      ),
    );
  }

  Widget _buildInlineAction(
    SemanticColors colors,
    ValueNotifier<bool> isVisible,
    bool isEmpty,
  ) {
    final btnSize = size.inlineActionButtonSize;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onScan != null)
          IgnorePointer(
            ignoring: !enabled,
            child: WnInputFieldButton(
              key: const Key('scan_button'),
              icon: WnIcons.scan,
              onPressed: onScan!,
              buttonSize: btnSize,
              filled: false,
            ),
          ),
        if (!isEmpty)
          IgnorePointer(
            ignoring: !enabled,
            child: WnInputFieldButton(
              key: const Key('visibility_toggle'),
              icon: isVisible.value ? WnIcons.viewOff : WnIcons.view,
              onPressed: () => isVisible.value = !isVisible.value,
              buttonSize: btnSize,
              filled: false,
            ),
          ),
      ],
    );
  }

  Widget _buildTrailingAction(
    SemanticColors colors,
    bool isEmpty,
    TextEditingController effectiveController,
  ) {
    if (isEmpty && onPaste != null) {
      return WnInputTrailingButton(
        key: const Key('paste_button'),
        icon: WnIcons.paste,
        onPressed: onPaste!,
        size: size,
      );
    }

    return WnInputTrailingButton(
      key: const Key('clear_button'),
      icon: WnIcons.closeSmall,
      onPressed: () {
        effectiveController.clear();
        onChanged?.call('');
      },
      size: size,
    );
  }

  Widget _buildHelperText(BuildContext context, SemanticColors colors) {
    final typography = context.typographyScaled;
    return Padding(
      padding: EdgeInsets.only(left: 2.w, top: 4.h),
      child: Text(
        helperText!,
        style: typography.medium14.copyWith(color: colors.backgroundContentSecondary),
      ),
    );
  }

  Widget _buildErrorText(BuildContext context, SemanticColors colors) {
    final typography = context.typographyScaled;
    return Padding(
      padding: EdgeInsets.only(left: 2.w, top: 4.h),
      child: Text(
        errorText!,
        style: typography.medium14.copyWith(color: colors.backgroundContentDestructive),
      ),
    );
  }
}
