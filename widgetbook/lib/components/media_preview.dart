import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_media_preview.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

const _sampleImages = [
  'https://www.whitenoise.chat/images/mask-man.webp',
  'https://picsum.photos/seed/mp1/400/400',
  'https://picsum.photos/seed/mp2/400/400',
  'https://picsum.photos/seed/mp3/400/400',
  'https://picsum.photos/seed/mp4/400/400',
  'https://picsum.photos/seed/mp5/400/400',
];

Widget _imageTile(int index) {
  return Image.network(
    _sampleImages[index % _sampleImages.length],
    fit: BoxFit.cover,
    errorBuilder: (_, _, _) => Container(color: Colors.grey.shade300),
  );
}

class WnMediaPreviewStory extends StatelessWidget {
  const WnMediaPreviewStory({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

@widgetbook.UseCase(name: 'Media Preview', type: WnMediaPreviewStory)
Widget wnMediaPreviewShowcase(BuildContext context) {
  final colors = context.colors;
  final imageCount = context.knobs.int.slider(
    label: 'Number of images',
    initialValue: 4,
    min: 1,
    max: 6,
  );

  final showDeleteButton = context.knobs.boolean(
    label: 'Show delete button',
    initialValue: true,
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
          'Interactive media preview with thumbnails for navigation.',
          style: TextStyle(
            fontSize: 14,
            color: colors.backgroundContentSecondary,
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 384),
            child: _InteractiveMediaPreview(
              imageCount: imageCount,
              showDeleteButton: showDeleteButton,
            ),
          ),
        ),
        const SizedBox(height: 32),
        Divider(color: colors.borderTertiary),
        const SizedBox(height: 24),
        Text(
          'Examples',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colors.backgroundContentPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Preview adapts to different image counts.',
          style: TextStyle(
            fontSize: 13,
            color: colors.backgroundContentSecondary,
          ),
        ),
        const SizedBox(height: 16),
        _buildExample(context, '1 image (no thumbnails)', 1),
        _buildExample(context, '3 images', 3),
        _buildExample(context, '6 images', 6),
      ],
    ),
  );
}

class _InteractiveMediaPreview extends HookWidget {
  const _InteractiveMediaPreview({
    required this.imageCount,
    required this.showDeleteButton,
  });

  final int imageCount;
  final bool showDeleteButton;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = useState(0);

    useEffect(() {
      if (selectedIndex.value >= imageCount) {
        selectedIndex.value = imageCount > 0 ? imageCount - 1 : 0;
      }
      return null;
    }, [imageCount]);

    return WnMediaPreview(
      selectedIndex: selectedIndex.value,
      onSelectedChanged: (index) => selectedIndex.value = index,
      onDelete: showDeleteButton ? () {} : null,
      children: List.generate(imageCount, _imageTile),
    );
  }
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
          constraints: const BoxConstraints(maxWidth: 384),
          child: _StaticExample(imageCount: count),
        ),
      ],
    ),
  );
}

class _StaticExample extends HookWidget {
  const _StaticExample({required this.imageCount});

  final int imageCount;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = useState(0);

    return WnMediaPreview(
      selectedIndex: selectedIndex.value,
      onSelectedChanged: (index) => selectedIndex.value = index,
      onDelete: () {},
      children: List.generate(imageCount, _imageTile),
    );
  }
}
