import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_icon.dart';
import 'package:whitenoise/widgets/wn_icon_button.dart';
import 'package:whitenoise/widgets/wn_input_field_button.dart';

class WnChatMessageInput extends StatelessWidget {
  const WnChatMessageInput({
    super.key,
    this.attachmentArea,
    required this.inputField,
    required this.controller,
    required this.inputStyle,
    required this.onAddTap,
    this.onSend,
    this.sendEnabled = false,
    this.isFocused = false,
  });

  final Widget? attachmentArea;
  final Widget inputField;
  final TextEditingController controller;
  final TextStyle inputStyle;
  final VoidCallback onAddTap;
  final VoidCallback? onSend;
  final bool sendEnabled;
  final bool isFocused;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      key: const Key('chat_message_input'),
      decoration: BoxDecoration(
        color: colors.backgroundPrimary,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: isFocused ? colors.borderPrimary : colors.borderSecondary,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (attachmentArea != null)
            Padding(
              key: const Key('attachment_area'),
              padding: EdgeInsets.fromLTRB(8.w, 8.h, 8.w, 0),
              child: attachmentArea!,
            ),
          _InputRow(
            inputField: inputField,
            controller: controller,
            inputStyle: inputStyle,
            onAddTap: onAddTap,
            onSend: onSend,
            sendEnabled: sendEnabled,
          ),
        ],
      ),
    );
  }
}

class _InputRow extends StatelessWidget {
  const _InputRow({
    required this.inputField,
    required this.controller,
    required this.inputStyle,
    required this.onAddTap,
    this.onSend,
    this.sendEnabled = false,
  });

  final Widget inputField;
  final TextEditingController controller;
  final TextStyle inputStyle;
  final VoidCallback onAddTap;
  final VoidCallback? onSend;
  final bool sendEnabled;

  static double get _inputContentPaddingH => 8.w;

  bool _isMultiline(BoxConstraints constraints) {
    final buttonWidth = 32.w + 8.w;
    final sendWidth = onSend != null ? 40.h + 8.w : 0.0;
    final horizontalPadding = 16.w;
    final inputPadding = _inputContentPaddingH * 2;
    final availableWidth =
        constraints.maxWidth - buttonWidth - sendWidth - horizontalPadding - inputPadding;

    final textPainter = TextPainter(
      text: TextSpan(text: controller.text, style: inputStyle),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    );
    try {
      textPainter.layout(maxWidth: availableWidth > 0 ? availableWidth : 0);
      return textPainter.didExceedMaxLines;
    } finally {
      textPainter.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final addButton = WnInputFieldButton(
      key: const Key('add_button'),
      icon: WnIcons.addLarge,
      onPressed: onAddTap,
      buttonSize: WnInputFieldButtonSize.size40,
      filled: false,
    );

    final sendButton = onSend != null
        ? WnIconButton(
            key: const Key('send_button'),
            icon: WnIcons.arrowUp,
            onPressed: sendEnabled ? onSend : null,
            type: WnIconButtonType.primary,
            disabled: !sendEnabled,
          )
        : null;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, _, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final multiline = _isMultiline(constraints);

            final row = Row(
              spacing: 8.w,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: multiline ? Alignment.topCenter : Alignment.center,
                  child: addButton,
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: _inputContentPaddingH),
                    child: inputField,
                  ),
                ),
                if (sendButton != null)
                  Align(
                    alignment: multiline ? Alignment.bottomCenter : Alignment.center,
                    child: sendButton,
                  ),
              ],
            );

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
              child: IntrinsicHeight(child: row),
            );
          },
        );
      },
    );
  }
}
