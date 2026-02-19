import 'package:flutter/material.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_message_media.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

const _sampleImages = [
  'https://www.whitenoise.chat/images/mask-man.webp',
  'https://picsum.photos/seed/wn1/400/400',
  'https://picsum.photos/seed/wn2/400/400',
  'https://picsum.photos/seed/wn3/400/400',
  'https://picsum.photos/seed/wn4/400/400',
  'https://picsum.photos/seed/wn5/400/400',
  'https://picsum.photos/seed/wn6/400/400',
  'https://picsum.photos/seed/wn7/400/400',
];

Widget _imageTile(int index) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(4),
    child: Image.network(
      _sampleImages[index % _sampleImages.length],
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade300),
    ),
  );
}

class WnMessageMediaStory extends StatelessWidget {
  const WnMessageMediaStory({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

@widgetbook.UseCase(name: 'Message Media', type: WnMessageMediaStory)
Widget wnMessageMediaShowcase(BuildContext context) {
  final colors = context.colors;
  final tileCount = context.knobs.int.slider(
    label: 'Number of images',
    initialValue: 4,
    min: 1,
    max: 12,
  );

  return Scaffold(
    backgroundColor: colors.backgroundSecondary,
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Playground',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colors.backgroundContentPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Use the knobs panel to change the number of images.',
          style: TextStyle(
            fontSize: 14,
            color: colors.backgroundContentSecondary,
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: WnMessageMedia(tiles: List.generate(tileCount, _imageTile)),
          ),
        ),
        const SizedBox(height: 32),
        Divider(color: colors.borderTertiary),
        const SizedBox(height: 24),
        Text(
          'All Variants',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colors.backgroundContentPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Grid layouts adapt from 1 to 6+ images.',
          style: TextStyle(
            fontSize: 13,
            color: colors.backgroundContentSecondary,
          ),
        ),
        const SizedBox(height: 16),
        _buildExample(context, '1 image', 1),
        _buildExample(context, '2 images', 2),
        _buildExample(context, '3 images', 3),
        _buildExample(context, '4 images', 4),
        _buildExample(context, '5 images', 5),
        _buildExample(context, '6 images (no overflow)', 6),
        _buildExample(context, '8 images (+2 overflow)', 8),
      ],
    ),
  );
}

Widget _buildExample(BuildContext context, String label, int count) {
  final colors = context.colors;

  return Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colors.backgroundContentSecondary,
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: WnMessageMedia(tiles: List.generate(count, _imageTile)),
        ),
      ],
    ),
  );
}
