import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/widgets/wn_icon.dart';
import 'package:whitenoise/widgets/wn_input.dart';

class WnCopyableField extends HookWidget {
  const WnCopyableField({
    super.key,
    required this.label,
    required this.value,
    this.obscurable = false,
    this.obscured = true,
    this.onToggleVisibility,
    this.onCopied,
  });

  final String label;
  final String value;
  final bool obscurable;
  final bool obscured;
  final VoidCallback? onToggleVisibility;
  final VoidCallback? onCopied;

  void _handleCopy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    onCopied?.call();
  }

  String _getDisplayValue() {
    if (!obscurable || !obscured) {
      return value;
    }
    final maskedLength = value.length.clamp(8, 24).toInt();
    return '●' * maskedLength;
  }

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController(text: _getDisplayValue());

    useEffect(() {
      controller.text = _getDisplayValue();
      return null;
    }, [value, obscured, obscurable]);

    return WnInput(
      label: label,
      placeholder: '',
      controller: controller,
      readOnly: true,
      size: WnInputSize.size44,
      inlineActionIcon: obscurable ? (obscured ? WnIcons.view : WnIcons.viewOff) : null,
      inlineActionOnPressed: obscurable ? onToggleVisibility : null,
      inlineActionFilled: false,
      inlineActionKey: obscurable ? const Key('visibility_toggle') : null,
      trailingAction: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Gap(2.w),
          WnInputTrailingButton(
            key: const Key('copy_button'),
            icon: WnIcons.copy,
            onPressed: () => _handleCopy(value),
            size: WnInputSize.size44,
          ),
        ],
      ),
    );
  }
}
