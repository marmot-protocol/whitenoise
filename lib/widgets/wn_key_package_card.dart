import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_icon.dart';

class WnKeyPackageCard extends StatelessWidget {
  const WnKeyPackageCard({
    super.key,
    required this.title,
    required this.packageId,
    required this.createdAt,
    required this.onDelete,
    required this.deleteLabel,
    this.disabled = false,
    this.loading = false,
    this.deleteButtonKey,
  });

  final String title;
  final String packageId;
  final String createdAt;
  final VoidCallback onDelete;
  final String deleteLabel;
  final bool disabled;
  final bool loading;
  final Key? deleteButtonKey;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 16.h),
      decoration: BoxDecoration(
        color: colors.fillSecondary,
        borderRadius: BorderRadius.circular(8.r),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitleRow(context),
          _buildContent(context),
        ],
      ),
    );
  }

  Widget _buildTitleRow(BuildContext context) {
    final colors = context.colors;

    return SizedBox(
      height: 44.h,
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: WnIcon(
              WnIcons.key,
              size: 20.w,
              color: colors.backgroundContentSecondary,
              key: const Key('key_package_icon'),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Text(
                title,
                style: context.typographyScaled.semiBold14.copyWith(
                  color: colors.fillContentSecondary,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildIdField(context),
        _buildCreatedAtField(context),
        SizedBox(
          height: 44.h,
          child: WnButton(
            key: deleteButtonKey ?? const Key('delete_button'),
            text: deleteLabel,
            onPressed: onDelete,
            type: WnButtonType.destructive,
            size: WnButtonSize.medium,
            disabled: disabled,
            loading: loading,
            trailingIcon: WnIcons.trashCan,
          ),
        ),
      ],
    );
  }

  Widget _buildIdField(BuildContext context) {
    final colors = context.colors;
    final textStyle = context.typographyScaled.medium14.copyWith(
      color: colors.backgroundContentSecondary,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(0, 4.h, 8.w, 13.h),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: 'ID: ', style: textStyle),
            TextSpan(text: packageId, style: textStyle),
          ],
        ),
        key: const Key('package_id_text'),
      ),
    );
  }

  Widget _buildCreatedAtField(BuildContext context) {
    final colors = context.colors;
    final textStyle = context.typographyScaled.medium14.copyWith(
      color: colors.backgroundContentPrimary,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(0, 4.h, 8.w, 13.h),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: 'Created at: ', style: textStyle),
            TextSpan(text: createdAt, style: textStyle),
          ],
        ),
        key: const Key('created_at_text'),
      ),
    );
  }
}
