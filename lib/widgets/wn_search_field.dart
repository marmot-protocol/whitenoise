import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_icon.dart';
import 'package:whitenoise/widgets/wn_input_field_button.dart';

class WnSearchField extends StatelessWidget {
  const WnSearchField({
    super.key,
    required this.placeholder,
    this.controller,
    this.onChanged,
    this.autofocus = false,
    this.onScan,
    this.isLoading = false,
  });

  final String placeholder;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final VoidCallback? onScan;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typographyScaled;

    final Widget? suffixWidget;
    if (isLoading) {
      suffixWidget = Padding(
        padding: EdgeInsets.only(right: 14.w),
        child: SizedBox(
          key: const Key('search_loading_indicator'),
          width: 16.w,
          height: 16.h,
          child: CircularProgressIndicator(
            strokeWidth: 2.w,
            color: colors.backgroundContentTertiary,
            strokeCap: StrokeCap.round,
          ),
        ),
      );
    } else if (onScan != null) {
      suffixWidget = Padding(
        padding: EdgeInsets.only(right: 14.w),
        child: WnInputFieldButton(
          key: const Key('scan_button'),
          icon: WnIcons.scan,
          onPressed: onScan!,
          buttonSize: WnInputFieldButtonSize.size36,
          filled: false,
        ),
      );
    } else {
      suffixWidget = null;
    }

    return TextField(
      controller: controller,
      autofocus: autofocus,
      onChanged: onChanged,
      style: typography.medium14.copyWith(color: colors.backgroundContentPrimary),
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: typography.medium14.copyWith(color: colors.backgroundContentTertiary),
        prefixIcon: Padding(
          padding: EdgeInsets.only(left: 14.w, right: 10.w),
          child: WnIcon(
            WnIcons.search,
            key: const Key('search_icon'),
            size: 20.sp,
            color: colors.backgroundContentTertiary,
          ),
        ),
        prefixIconConstraints: const BoxConstraints(),
        suffixIcon: suffixWidget,
        suffixIconConstraints: const BoxConstraints(),
        filled: true,
        fillColor: colors.backgroundPrimary,
        contentPadding: EdgeInsets.symmetric(
          vertical: 12.h,
          horizontal: 14.w,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: colors.borderTertiary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: colors.borderPrimary),
        ),
      ),
    );
  }
}
