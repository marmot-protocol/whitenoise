import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/theme.dart';

class WnChatSystemMessage extends StatelessWidget {
  const WnChatSystemMessage({
    super.key,
    required this.text,
    this.isSticky = false,
    this.textSpan,
  });

  final String text;
  final bool isSticky;
  final InlineSpan? textSpan;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (isSticky) {
      final verticalPadding = 6.h;
      final borderRadius = (verticalPadding / 2).h;
      return Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 200.w),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: colors.backgroundPrimary,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(borderRadius),
              topRight: Radius.circular(borderRadius),
              bottomLeft: Radius.circular(borderRadius),
              bottomRight: Radius.circular(borderRadius),
            ),
            border: Border.all(color: colors.borderTertiary),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.1),
                offset: const Offset(0, 1),
                blurRadius: 3.r,
              ),
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.1),
                offset: const Offset(0, 1),
                blurRadius: 2.r,
                spreadRadius: -1.r,
              ),
            ],
          ),
          child: textSpan != null
              ? Text.rich(
                  textSpan!,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                )
              : Text(
                  text,
                  style: context.typographyScaled.medium14.copyWith(
                    color: colors.fillContentSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: textSpan != null
            ? Text.rich(
                textSpan!,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              )
            : Text(
                text,
                style: context.typographyScaled.medium14.copyWith(
                  color: colors.backgroundContentSecondary,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
      ),
    );
  }
}
