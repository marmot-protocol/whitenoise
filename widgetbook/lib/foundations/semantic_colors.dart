import 'package:flutter/material.dart';
import 'package:whitenoise/theme.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

class SemanticColorsStory extends StatelessWidget {
  const SemanticColorsStory({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

@widgetbook.UseCase(name: 'Semantic Colors', type: SemanticColorsStory)
Widget allColors(BuildContext context) {
  const light = SemanticColors.light;
  const dark = SemanticColors.dark;

  return Scaffold(
    backgroundColor: light.backgroundPrimary,
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildColorSection(
          'Background',
          [
            _ColorPairItem(
              semanticName: 'Background Primary',
              lightColor: light.backgroundPrimary,
              darkColor: dark.backgroundPrimary,
            ),
            _ColorPairItem(
              semanticName: 'Background Secondary',
              lightColor: light.backgroundSecondary,
              darkColor: dark.backgroundSecondary,
            ),
            _ColorPairItem(
              semanticName: 'Background Tertiary',
              lightColor: light.backgroundTertiary,
              darkColor: dark.backgroundTertiary,
            ),
          ],
          description:
              'Base surfaces the UI sits on. Use for page/app canvas, panels, cards, sheets, menus.',
        ),
        const SizedBox(height: 24),

        _buildColorSection(
          'Background Content',
          [
            _ColorPairItem(
              semanticName: 'Background Content Primary',
              lightColor: light.backgroundContentPrimary,
              darkColor: dark.backgroundContentPrimary,
            ),
            _ColorPairItem(
              semanticName: 'Background Content Secondary',
              lightColor: light.backgroundContentSecondary,
              darkColor: dark.backgroundContentSecondary,
            ),
            _ColorPairItem(
              semanticName: 'Background Content Tertiary',
              lightColor: light.backgroundContentTertiary,
              darkColor: dark.backgroundContentTertiary,
            ),
            _ColorPairItem(
              semanticName: 'Background Content Quaternary',
              lightColor: light.backgroundContentQuaternary,
              darkColor: dark.backgroundContentQuaternary,
            ),
            _ColorPairItem(
              semanticName: 'Background Content Destructive',
              lightColor: light.backgroundContentDestructive,
              darkColor: dark.backgroundContentDestructive,
            ),
            _ColorPairItem(
              semanticName: 'Background Content Destructive Secondary',
              lightColor: light.backgroundContentDestructiveSecondary,
              darkColor: dark.backgroundContentDestructiveSecondary,
            ),
          ],
          description:
              'Ink that sits on top of background. Use for text, icons, glyphs.',
        ),
        const SizedBox(height: 24),

        _buildColorSection(
          'Fill',
          [
            _ColorPairItem(
              semanticName: 'Fill Primary',
              lightColor: light.fillPrimary,
              darkColor: dark.fillPrimary,
            ),
            _ColorPairItem(
              semanticName: 'Fill Primary Hover',
              lightColor: light.fillPrimaryHover,
              darkColor: dark.fillPrimaryHover,
            ),
            _ColorPairItem(
              semanticName: 'Fill Primary Active',
              lightColor: light.fillPrimaryActive,
              darkColor: dark.fillPrimaryActive,
            ),
          ],
          description:
              'Emphasis surfaces meant to stand out from background. Use for primary buttons, selected states, toggles, progress fills, badges.',
        ),
        const SizedBox(height: 12),
        _buildColorSection('', [
          _ColorPairItem(
            semanticName: 'Fill Secondary',
            lightColor: light.fillSecondary,
            darkColor: dark.fillSecondary,
          ),
          _ColorPairItem(
            semanticName: 'Fill Secondary Hover',
            lightColor: light.fillSecondaryHover,
            darkColor: dark.fillSecondaryHover,
          ),
          _ColorPairItem(
            semanticName: 'Fill Secondary Active',
            lightColor: light.fillSecondaryActive,
            darkColor: dark.fillSecondaryActive,
          ),
        ]),
        const SizedBox(height: 12),
        _buildColorSection('', [
          _ColorPairItem(
            semanticName: 'Fill Tertiary',
            lightColor: light.fillTertiary,
            darkColor: dark.fillTertiary,
          ),
          _ColorPairItem(
            semanticName: 'Fill Tertiary Hover',
            lightColor: light.fillTertiaryHover,
            darkColor: dark.fillTertiaryHover,
          ),
          _ColorPairItem(
            semanticName: 'Fill Tertiary Active',
            lightColor: light.fillTertiaryActive,
            darkColor: dark.fillTertiaryActive,
          ),
        ]),
        const SizedBox(height: 12),
        _buildColorSection('', [
          _ColorPairItem(
            semanticName: 'Fill Quaternary',
            lightColor: light.fillQuaternary,
            darkColor: dark.fillQuaternary,
          ),
          _ColorPairItem(
            semanticName: 'Fill Quaternary Hover',
            lightColor: light.fillQuaternaryHover,
            darkColor: dark.fillQuaternaryHover,
          ),
          _ColorPairItem(
            semanticName: 'Fill Quaternary Active',
            lightColor: light.fillQuaternaryActive,
            darkColor: dark.fillQuaternaryActive,
          ),
        ]),
        const SizedBox(height: 12),
        _buildColorSection('', [
          _ColorPairItem(
            semanticName: 'Fill Destructive',
            lightColor: light.fillDestructive,
            darkColor: dark.fillDestructive,
          ),
          _ColorPairItem(
            semanticName: 'Fill Destructive Hover',
            lightColor: light.fillDestructiveHover,
            darkColor: dark.fillDestructiveHover,
          ),
          _ColorPairItem(
            semanticName: 'Fill Destructive Active',
            lightColor: light.fillDestructiveActive,
            darkColor: dark.fillDestructiveActive,
          ),
        ]),
        const SizedBox(height: 12),
        _buildColorSection('', [
          _ColorPairItem(
            semanticName: 'Fill Disabled',
            lightColor: light.fillDisabled,
            darkColor: dark.fillDisabled,
          ),
        ]),
        const SizedBox(height: 24),

        _buildColorSection(
          'Fill Content',
          [
            _ColorPairItem(
              semanticName: 'Fill Content Primary',
              lightColor: light.fillContentPrimary,
              darkColor: dark.fillContentPrimary,
            ),
            _ColorPairItem(
              semanticName: 'Fill Content Secondary',
              lightColor: light.fillContentSecondary,
              darkColor: dark.fillContentSecondary,
            ),
            _ColorPairItem(
              semanticName: 'Fill Content Tertiary',
              lightColor: light.fillContentTertiary,
              darkColor: dark.fillContentTertiary,
            ),
            _ColorPairItem(
              semanticName: 'Fill Content Quaternary',
              lightColor: light.fillContentQuaternary,
              darkColor: dark.fillContentQuaternary,
            ),
            _ColorPairItem(
              semanticName: 'Fill Content Disabled',
              lightColor: light.fillContentDisabled,
              darkColor: dark.fillContentDisabled,
            ),
          ],
          description:
              'Ink that sits on top of fill. Use for text, icons, glyphs.',
        ),
        const SizedBox(height: 24),

        _buildColorSection(
          'Border',
          [
            _ColorPairItem(
              semanticName: 'Border Primary',
              lightColor: light.borderPrimary,
              darkColor: dark.borderPrimary,
            ),
            _ColorPairItem(
              semanticName: 'Border Secondary',
              lightColor: light.borderSecondary,
              darkColor: dark.borderSecondary,
            ),
            _ColorPairItem(
              semanticName: 'Border Tertiary',
              lightColor: light.borderTertiary,
              darkColor: dark.borderTertiary,
            ),
            _ColorPairItem(
              semanticName: 'Border Destructive Primary',
              lightColor: light.borderDestructivePrimary,
              darkColor: dark.borderDestructivePrimary,
            ),
            _ColorPairItem(
              semanticName: 'Border Destructive Secondary',
              lightColor: light.borderDestructiveSecondary,
              darkColor: dark.borderDestructiveSecondary,
            ),
          ],
          description:
              'Edges and separators. Use for component outlines (inputs, cards), dividers, strokes around fills, and focus rings.',
        ),
        const SizedBox(height: 24),

        _buildColorSection(
          'Intention',
          [
            _ColorPairItem(
              semanticName: 'Intention Info Background',
              lightColor: light.intentionInfoBackground,
              darkColor: dark.intentionInfoBackground,
            ),
            _ColorPairItem(
              semanticName: 'Intention Info Content',
              lightColor: light.intentionInfoContent,
              darkColor: dark.intentionInfoContent,
            ),
            _ColorPairItem(
              semanticName: 'Intention Success Background',
              lightColor: light.intentionSuccessBackground,
              darkColor: dark.intentionSuccessBackground,
            ),
            _ColorPairItem(
              semanticName: 'Intention Success Content',
              lightColor: light.intentionSuccessContent,
              darkColor: dark.intentionSuccessContent,
            ),
            _ColorPairItem(
              semanticName: 'Intention Warning Background',
              lightColor: light.intentionWarningBackground,
              darkColor: dark.intentionWarningBackground,
            ),
            _ColorPairItem(
              semanticName: 'Intention Warning Content',
              lightColor: light.intentionWarningContent,
              darkColor: dark.intentionWarningContent,
            ),
            _ColorPairItem(
              semanticName: 'Intention Error Background',
              lightColor: light.intentionErrorBackground,
              darkColor: dark.intentionErrorBackground,
            ),
            _ColorPairItem(
              semanticName: 'Intention Error Content',
              lightColor: light.intentionErrorContent,
              darkColor: dark.intentionErrorContent,
            ),
          ],
          description:
              'Intent colors. Use to communicate meaning and urgency across the UI (info, success, warning, error) in elements like callouts, banners, toasts, and status indicators.',
        ),
        const SizedBox(height: 24),
        _buildColorSection(
          'Overlay',
          [
            _ColorPairItem(
              semanticName: 'Overlay Primary',
              lightColor: light.overlayPrimary,
              darkColor: dark.overlayPrimary,
            ),
            _ColorPairItem(
              semanticName: 'Overlay Secondary',
              lightColor: light.overlaySecondary,
              darkColor: dark.overlaySecondary,
            ),
            _ColorPairItem(
              semanticName: 'Overlay Tertiary',
              lightColor: light.overlayTertiary,
              darkColor: dark.overlayTertiary,
            ),
          ],
          description:
              'Overlay colors. Use for backdrops and overlay surfaces to separate Slate '
              'from background content and keep focus on it.',
        ),
        const SizedBox(height: 24),
        _buildColorSection('Reaction', [
          _ColorPairItem(
            semanticName: 'Reaction Fill Incoming',
            lightColor: light.reaction.incoming.fill,
            darkColor: dark.reaction.incoming.fill,
          ),
          _ColorPairItem(
            semanticName: 'Reaction Fill Incoming Hover',
            lightColor: light.reaction.incoming.fillHover,
            darkColor: dark.reaction.incoming.fillHover,
          ),
          _ColorPairItem(
            semanticName: 'Reaction Fill Incoming Selected',
            lightColor: light.reaction.incoming.fillSelected,
            darkColor: dark.reaction.incoming.fillSelected,
          ),
          _ColorPairItem(
            semanticName: 'Reaction Fill Outgoing',
            lightColor: light.reaction.outgoing.fill,
            darkColor: dark.reaction.outgoing.fill,
          ),
          _ColorPairItem(
            semanticName: 'Reaction Fill Outgoing Hover',
            lightColor: light.reaction.outgoing.fillHover,
            darkColor: dark.reaction.outgoing.fillHover,
          ),
          _ColorPairItem(
            semanticName: 'Reaction Fill Outgoing Selected',
            lightColor: light.reaction.outgoing.fillSelected,
            darkColor: dark.reaction.outgoing.fillSelected,
          ),
          _ColorPairItem(
            semanticName: 'Reaction Content Incoming',
            lightColor: light.reaction.incoming.content,
            darkColor: dark.reaction.incoming.content,
          ),
          _ColorPairItem(
            semanticName: 'Reaction Content Incoming Hover',
            lightColor: light.reaction.incoming.contentHover,
            darkColor: dark.reaction.incoming.contentHover,
          ),
          _ColorPairItem(
            semanticName: 'Reaction Content Incoming Selected',
            lightColor: light.reaction.incoming.contentSelected,
            darkColor: dark.reaction.incoming.contentSelected,
          ),
          _ColorPairItem(
            semanticName: 'Reaction Content Outgoing',
            lightColor: light.reaction.outgoing.content,
            darkColor: dark.reaction.outgoing.content,
          ),
          _ColorPairItem(
            semanticName: 'Reaction Content Outgoing Hover',
            lightColor: light.reaction.outgoing.contentHover,
            darkColor: dark.reaction.outgoing.contentHover,
          ),
          _ColorPairItem(
            semanticName: 'Reaction Content Outgoing Selected',
            lightColor: light.reaction.outgoing.contentSelected,
            darkColor: dark.reaction.outgoing.contentSelected,
          ),
        ], description: 'Use for reaction fills and content.'),
        const SizedBox(height: 24),
        _buildColorSection(
          'Accent',
          [
            ..._accentColorItems('Blue', light.accent.blue, dark.accent.blue),
            ..._accentColorItems('Cyan', light.accent.cyan, dark.accent.cyan),
            ..._accentColorItems(
              'Emerald',
              light.accent.emerald,
              dark.accent.emerald,
            ),
            ..._accentColorItems(
              'Fuchsia',
              light.accent.fuchsia,
              dark.accent.fuchsia,
            ),
            ..._accentColorItems(
              'Indigo',
              light.accent.indigo,
              dark.accent.indigo,
            ),
            ..._accentColorItems('Lime', light.accent.lime, dark.accent.lime),
            ..._accentColorItems(
              'Orange',
              light.accent.orange,
              dark.accent.orange,
            ),
            ..._accentColorItems('Rose', light.accent.rose, dark.accent.rose),
            ..._accentColorItems('Sky', light.accent.sky, dark.accent.sky),
            ..._accentColorItems('Teal', light.accent.teal, dark.accent.teal),
            ..._accentColorItems(
              'Violet',
              light.accent.violet,
              dark.accent.violet,
            ),
            ..._accentColorItems(
              'Amber',
              light.accent.amber,
              dark.accent.amber,
            ),
          ],
          description:
              'Avatar colors are preset color combos for avatars without a user image. Each set includes a fill, content color, and border. Use them for initials or fallback avatars when no photo is available.',
        ),
        const SizedBox(height: 24),
        _buildColorSection('Shadow', [
          _ColorPairItem(
            semanticName: 'Shadow',
            lightColor: light.shadow,
            darkColor: dark.shadow,
          ),
        ]),
      ],
    ),
  );
}

Widget _buildColorSection(
  String title,
  List<_ColorPairItem> items, {
  String? description,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      if (description != null) ...[
        const SizedBox(height: 4),
        Text(
          description,
          style: const TextStyle(fontSize: 13, color: Color(0xFF757575)),
        ),
        const SizedBox(height: 12),
      ],
      Wrap(
        spacing: 24,
        runSpacing: 16,
        children: items.map((item) => _ColorPair(item: item)).toList(),
      ),
    ],
  );
}

List<_ColorPairItem> _accentColorItems(
  String colorName,
  AccentColorSet lightAccent,
  AccentColorSet darkAccent,
) {
  return [
    _ColorPairItem(
      semanticName: '$colorName Fill',
      lightColor: lightAccent.fill,
      darkColor: darkAccent.fill,
    ),
    _ColorPairItem(
      semanticName: '$colorName Content Primary',
      lightColor: lightAccent.contentPrimary,
      darkColor: darkAccent.contentPrimary,
    ),
    _ColorPairItem(
      semanticName: '$colorName Content Secondary',
      lightColor: lightAccent.contentSecondary,
      darkColor: darkAccent.contentSecondary,
    ),
    _ColorPairItem(
      semanticName: '$colorName Border',
      lightColor: lightAccent.border,
      darkColor: darkAccent.border,
    ),
  ];
}

class _ColorPairItem {
  final String semanticName;
  final Color lightColor;
  final Color darkColor;

  const _ColorPairItem({
    required this.semanticName,
    required this.lightColor,
    required this.darkColor,
  });
}

class _ColorPair extends StatelessWidget {
  final _ColorPairItem item;

  const _ColorPair({required this.item});

  static const _grey = Color(0xFF9E9E9E);
  static final _greyBorder = _grey.withValues(alpha: 0.3);
  static const _neutral100 = Color(0xFFF5F5F5);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Column(
        children: [
          Container(
            height: 60,
            decoration: BoxDecoration(border: Border.all(color: _greyBorder)),
            child: ClipRect(
              child: Row(
                children: [
                  Expanded(
                    child: CustomPaint(
                      painter: const _CheckerboardPainter(),
                      child: Container(color: item.lightColor),
                    ),
                  ),
                  Expanded(
                    child: CustomPaint(
                      painter: const _CheckerboardPainter(),
                      child: Container(color: item.darkColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _neutral100,
              border: Border(
                left: BorderSide(color: _greyBorder),
                right: BorderSide(color: _greyBorder),
                bottom: BorderSide(color: _greyBorder),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Light',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: _grey,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Text(
                          'Dark',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: _grey,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  item.semanticName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.left,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckerboardPainter extends CustomPainter {
  const _CheckerboardPainter();

  static const _squareSize = 8.0;
  static const _lightColor = Color(0xFFFFFFFF);
  static const _darkColor = Color(0xFFCCCCCC);

  @override
  void paint(Canvas canvas, Size size) {
    final lightPaint = Paint()..color = _lightColor;
    final darkPaint = Paint()..color = _darkColor;

    canvas.drawRect(Offset.zero & size, lightPaint);

    for (var y = 0.0; y < size.height; y += _squareSize) {
      for (var x = 0.0; x < size.width; x += _squareSize) {
        final isEvenRow = (y ~/ _squareSize) % 2 == 0;
        final isEvenCol = (x ~/ _squareSize) % 2 == 0;
        if (isEvenRow != isEvenCol) {
          canvas.drawRect(
            Rect.fromLTWH(x, y, _squareSize, _squareSize),
            darkPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
