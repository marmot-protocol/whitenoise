import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/theme.dart';

class WnChatMessageInput extends StatelessWidget {
  const WnChatMessageInput({
    super.key,
    this.attachmentArea,
    required this.inputField,
    this.leadingAction,
    this.trailingAction,
    this.isFocused = false,
  });

  final Widget? attachmentArea;
  final Widget inputField;
  final Widget? leadingAction;
  final Widget? trailingAction;
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
          color: isFocused ? colors.borderPrimary : colors.borderTertiary,
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
            leadingAction: leadingAction,
            trailingAction: trailingAction,
          ),
        ],
      ),
    );
  }
}

class _InputRow extends StatelessWidget {
  const _InputRow({
    required this.inputField,
    this.leadingAction,
    this.trailingAction,
  });

  final Widget inputField;
  final Widget? leadingAction;
  final Widget? trailingAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(4.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (leadingAction != null)
            Padding(
              key: const Key('leading_action'),
              padding: EdgeInsets.only(left: 8.w, bottom: 16.h),
              child: leadingAction!,
            ),
          Expanded(
            child: inputField,
          ),
          if (trailingAction != null)
            Padding(
              key: const Key('trailing_action'),
              padding: EdgeInsets.only(right: 4.w, bottom: 6.h),
              child: trailingAction!,
            ),
        ],
      ),
    );
  }
}
