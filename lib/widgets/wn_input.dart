import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart' show Gap;
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_icon.dart';
import 'package:whitenoise/widgets/wn_input_field_button.dart';

enum WnInputSize {
  size44(44),
  size56(56)
  ;

  const WnInputSize(this.height);
  final int height;

  WnInputFieldButtonSize get inlineActionButtonSize =>
      this == WnInputSize.size44 ? WnInputFieldButtonSize.size36 : WnInputFieldButtonSize.size48;
}

class WnInput extends HookWidget {
  const WnInput({
    super.key,
    required this.placeholder,
    this.label,
    this.labelHelpIcon,
    this.helperText,
    this.errorText,
    this.controller,
    this.autofocus = false,
    this.enabled = true,
    this.readOnly = false,
    this.size = WnInputSize.size56,
    this.onChanged,
    this.textInputAction,
    this.leadingIcon,
    this.inlineActionIcon,
    this.inlineActionOnPressed,
    this.inlineActionFilled = true,
    this.inlineActionKey,
    this.trailingAction,
    this.focusNode,
    this.onSubmitted,
  });

  final String placeholder;
  final String? label;
  final VoidCallback? labelHelpIcon;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final bool autofocus;
  final bool enabled;
  final bool readOnly;
  final WnInputSize size;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final Widget? leadingIcon;
  final WnIcons? inlineActionIcon;
  final VoidCallback? inlineActionOnPressed;
  final bool inlineActionFilled;
  final Key? inlineActionKey;
  final Widget? trailingAction;
  final FocusNode? focusNode;
  final void Function(String)? onSubmitted;

  bool get _hasInlineAction => inlineActionIcon != null;

  bool get _hasError => errorText != null;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isFocused = useState(false);
    final isHovered = useState(false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) _buildLabel(context, colors),
        _buildInputRow(context, colors, isFocused, isHovered),
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
            GestureDetector(
              key: const Key('label_help_icon'),
              behavior: HitTestBehavior.opaque,
              onTap: labelHelpIcon,
              child: SizedBox(
                width: 18.w,
                height: 18.h,
                child: Center(
                  child: WnIcon(
                    WnIcons.help,
                    size: 14.w,
                    color: colors.backgroundContentPrimary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputRow(
    BuildContext context,
    SemanticColors colors,
    ValueNotifier<bool> isFocused,
    ValueNotifier<bool> isHovered,
  ) {
    return Row(
      children: [
        Expanded(child: _buildInputField(context, colors, isFocused, isHovered)),
        if (trailingAction != null) ...[
          Gap(6.w),
          IgnorePointer(
            ignoring: !enabled,
            child: trailingAction!,
          ),
        ],
      ],
    );
  }

  Color _getBorderColor(SemanticColors colors, bool isFocused, bool isHovered) {
    if (!enabled) return colors.borderTertiary;
    if (_hasError) {
      return (isFocused || isHovered)
          ? colors.borderDestructiveSecondary
          : colors.borderDestructivePrimary;
    }
    if (isFocused) return colors.borderPrimary;
    if (isHovered) return colors.borderSecondary;
    return colors.borderTertiary;
  }

  Widget _buildInputField(
    BuildContext context,
    SemanticColors colors,
    ValueNotifier<bool> isFocused,
    ValueNotifier<bool> isHovered,
  ) {
    final typography = context.typographyScaled;
    final fieldHeight = size.height.h;
    final borderColor = _getBorderColor(colors, isFocused.value, isHovered.value);

    return MouseRegion(
      onEnter: (_) {
        if (enabled) isHovered.value = true;
      },
      onExit: (_) => isHovered.value = false,
      child: Container(
        key: const Key('input_field_container'),
        height: fieldHeight,
        decoration: BoxDecoration(
          color: colors.backgroundPrimary,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            if (leadingIcon != null)
              Padding(
                key: const Key('leading_icon_wrapper'),
                padding: EdgeInsets.only(left: 16.r),
                child: IgnorePointer(
                  ignoring: !enabled,
                  child: SizedBox(
                    width: 16.r,
                    height: 16.r,
                    child: leadingIcon,
                  ),
                ),
              ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: Focus(
                  onFocusChange: (focused) => isFocused.value = focused,
                  child: TextField(
                    key: const Key('input_field'),
                    controller: controller,
                    focusNode: focusNode,
                    autofocus: autofocus,
                    enabled: enabled,
                    readOnly: readOnly,
                    onChanged: onChanged,
                    onSubmitted: onSubmitted,
                    textInputAction: textInputAction,
                    style: typography.medium14.copyWith(
                      color: enabled
                          ? (_hasError
                                ? colors.backgroundContentDestructive
                                : colors.backgroundContentPrimary)
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
            ),
            if (_hasInlineAction) ...[
              IgnorePointer(
                ignoring: !enabled || inlineActionOnPressed == null,
                child: WnInputFieldButton(
                  key: inlineActionKey,
                  icon: inlineActionIcon!,
                  onPressed: inlineActionOnPressed ?? () {},
                  buttonSize: size.inlineActionButtonSize,
                  filled: inlineActionFilled,
                ),
              ),
              Gap(4.w),
            ],
          ],
        ),
      ),
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

class WnInputTrailingButton extends StatelessWidget {
  const WnInputTrailingButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = WnInputSize.size56,
    this.filled = true,
  });

  final WnIcons icon;
  final VoidCallback onPressed;
  final WnInputSize size;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final buttonWidth = size.height.w;
    final buttonHeight = size.height.h;
    final iconSize = 18.w;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: buttonWidth,
        height: buttonHeight,
        decoration: BoxDecoration(
          color: filled ? colors.fillSecondary : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
          border: filled ? Border.all(color: colors.borderTertiary) : null,
        ),
        child: Center(
          child: WnIcon(
            icon,
            size: iconSize,
            color: colors.backgroundContentPrimary,
          ),
        ),
      ),
    );
  }
}
