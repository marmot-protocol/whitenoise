import 'package:flutter/material.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_media_thumbnail.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

const _sampleImageUrl = 'https://www.whitenoise.chat/images/mask-man.webp';

class WnMediaThumbnailStory extends StatelessWidget {
  const WnMediaThumbnailStory({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

@widgetbook.UseCase(name: 'Media Thumbnail', type: WnMediaThumbnailStory)
Widget wnMediaThumbnailShowcase(BuildContext context) {
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
          'Use the knobs panel to customize this media thumbnail.',
          style: TextStyle(
            fontSize: 14,
            color: context.colors.backgroundContentSecondary,
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: _InteractiveMediaThumbnail(context: context),
        ),
        const SizedBox(height: 32),
        Divider(color: context.colors.borderTertiary),
        const SizedBox(height: 24),
        _buildSection(
          context,
          'Size Variants',
          'Media Thumbnail comes in 2 sizes: medium (44px, default) and large (56px).',
          [
            _ThumbnailExample(
              label: 'Medium (default)',
              child: WnMediaThumbnail(
                size: WnMediaThumbnailSize.medium,
                child: Image.network(_sampleImageUrl, fit: BoxFit.cover),
              ),
            ),
            _ThumbnailExample(
              label: 'Large',
              child: WnMediaThumbnail(
                size: WnMediaThumbnailSize.large,
                child: Image.network(_sampleImageUrl, fit: BoxFit.cover),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          context,
          'Selection States',
          'Media Thumbnail shows a border when selected.',
          [
            _ThumbnailExample(
              label: 'Unselected',
              child: WnMediaThumbnail(
                isSelected: false,
                child: Image.network(_sampleImageUrl, fit: BoxFit.cover),
              ),
            ),
            _ThumbnailExample(
              label: 'Selected',
              child: WnMediaThumbnail(
                isSelected: true,
                child: Image.network(_sampleImageUrl, fit: BoxFit.cover),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          context,
          'All Combinations',
          'Size and selection state combinations.',
          [
            _ThumbnailExample(
              label: 'Medium Unselected',
              child: WnMediaThumbnail(
                size: WnMediaThumbnailSize.medium,
                isSelected: false,
                child: Image.network(_sampleImageUrl, fit: BoxFit.cover),
              ),
            ),
            _ThumbnailExample(
              label: 'Medium Selected',
              child: WnMediaThumbnail(
                size: WnMediaThumbnailSize.medium,
                isSelected: true,
                child: Image.network(_sampleImageUrl, fit: BoxFit.cover),
              ),
            ),
            _ThumbnailExample(
              label: 'Large Unselected',
              child: WnMediaThumbnail(
                size: WnMediaThumbnailSize.large,
                isSelected: false,
                child: Image.network(_sampleImageUrl, fit: BoxFit.cover),
              ),
            ),
            _ThumbnailExample(
              label: 'Large Selected',
              child: WnMediaThumbnail(
                size: WnMediaThumbnailSize.large,
                isSelected: true,
                child: Image.network(_sampleImageUrl, fit: BoxFit.cover),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          context,
          'Placeholder States',
          'How the thumbnail looks with different content.',
          [
            _ThumbnailExample(
              label: 'With Image',
              child: WnMediaThumbnail(
                child: Image.network(_sampleImageUrl, fit: BoxFit.cover),
              ),
            ),
            _ThumbnailExample(
              label: 'Loading Placeholder',
              child: WnMediaThumbnail(
                child: Container(color: context.colors.fillSecondary),
              ),
            ),
            _ThumbnailExample(
              label: 'Error State',
              child: WnMediaThumbnail(
                child: Container(
                  color: context.colors.fillSecondary,
                  child: Icon(
                    Icons.broken_image,
                    color: context.colors.backgroundContentTertiary,
                    size: 20,
                  ),
                ),
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

class _ThumbnailExample extends StatelessWidget {
  const _ThumbnailExample({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
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
    );
  }
}

class _InteractiveMediaThumbnail extends StatelessWidget {
  const _InteractiveMediaThumbnail({required this.context});

  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    final size = this.context.knobs.object.dropdown<WnMediaThumbnailSize>(
      label: 'Size',
      options: WnMediaThumbnailSize.values,
      initialOption: WnMediaThumbnailSize.medium,
      labelBuilder: (value) => value.name,
    );

    final isSelected = this.context.knobs.boolean(
      label: 'Selected',
      initialValue: false,
    );

    return WnMediaThumbnail(
      size: size,
      isSelected: isSelected,
      onTap: () {},
      child: Image.network(_sampleImageUrl, fit: BoxFit.cover),
    );
  }
}
