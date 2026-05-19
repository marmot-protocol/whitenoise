import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/src/rust/api/markdown.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/markdown_text.dart';
import 'package:whitenoise/widgets/wn_icon.dart';

class WnMessageQuote extends StatelessWidget {
  const WnMessageQuote({
    super.key,
    required this.author,
    required this.text,
    this.document,
    this.mentionDisplayName,
    this.onCancel,
    this.onTap,
    this.image,
    this.mediaThumbnail,
    this.authorColor,
  });

  final String author;
  final String text;

  /// Parsed markdown of the quoted message. When present, the preview renders
  /// formatted (bold, links, mentions, …) instead of leaking raw markdown
  /// characters. Falls back to [text] for "message not found", empty content,
  /// or callers that don't have access to the document.
  final MarkdownDocument? document;

  /// Resolves a hex pubkey to a display name for npub mentions inside
  /// [document]. Without this, mentions render as truncated `npub1…` strings.
  final String? Function(String hexPubkey)? mentionDisplayName;
  final VoidCallback? onCancel;
  final VoidCallback? onTap;
  final ImageProvider? image;
  final Widget? mediaThumbnail;
  final Color? authorColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typographyScaled;

    return GestureDetector(
      key: onTap != null ? const Key('message_quote_tap_area') : null,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: onCancel != null ? colors.backgroundTertiary : colors.backgroundPrimary,
          borderRadius: BorderRadius.circular(4.r),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                key: const Key('quote_bar'),
                width: 2.w,
                decoration: BoxDecoration(
                  color: colors.borderTertiary,
                  borderRadius: BorderRadius.circular(1.w),
                ),
              ),
              Gap(4.w),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: 6.w, top: 2.h, bottom: 2.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        author,
                        style: typography.semiBold12.copyWith(
                          color: authorColor ?? colors.backgroundContentTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Gap(4.h),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_buildPreview(context) case final preview?) Flexible(child: preview),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (image != null || mediaThumbnail != null) ...[
                Gap(10.w),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4.r),
                  child: SizedBox(
                    key: const Key('quote_thumbnail'),
                    width: 40.w,
                    height: 40.h,
                    child: image != null
                        ? Image(
                            image: image!,
                            fit: BoxFit.cover,
                          )
                        : mediaThumbnail!,
                  ),
                ),
              ],
              if (onCancel != null) ...[
                Gap(4.w),
                IconButton(
                  key: const Key('cancel_quote_button'),
                  onPressed: onCancel,
                  icon: WnIcon(
                    WnIcons.closeSmall,
                    color: colors.backgroundContentTertiary,
                    size: 18.w,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildPreview(BuildContext context) {
    final colors = context.colors;
    final baseStyle = context.typographyScaled.medium14Compact.copyWith(
      color: colors.backgroundContentSecondary,
    );

    if (document != null) {
      final inlines = firstParagraphInlines(document!);
      if (inlines != null) {
        return MarkdownText(
          key: const Key('quote_markdown_preview'),
          document: MarkdownDocument(
            blocks: [MarkdownBlock.paragraph(inlines: inlines)],
          ),
          baseStyle: baseStyle,
          mentionDisplayName: mentionDisplayName,
          maxLines: 2,
        );
      }
    }

    if (text.isEmpty) return null;
    return Text(
      text,
      style: baseStyle,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
