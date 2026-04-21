import 'package:flutter/material.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_pill.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

class WnPillStory extends StatelessWidget {
  const WnPillStory({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

@widgetbook.UseCase(name: 'Pill', type: WnPillStory)
Widget wnPillShowcase(BuildContext context) {
  final colors = context.colors;

  final label = context.knobs.string(
    label: 'Label',
    initialValue: 'I am a pill!',
  );

  return Scaffold(
    backgroundColor: colors.backgroundPrimary,
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pill',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: colors.backgroundContentPrimary,
            ),
          ),
          const SizedBox(height: 32),
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
            'Use the knobs panel to customize this pill.',
            style: TextStyle(
              fontSize: 14,
              color: colors.backgroundContentSecondary,
            ),
          ),
          const SizedBox(height: 16),
          WnPill(label: label),
          const SizedBox(height: 32),
          Divider(color: colors.borderTertiary),
          const SizedBox(height: 24),
          Text(
            'Examples',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colors.backgroundContentPrimary,
            ),
          ),
          const SizedBox(height: 16),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              WnPill(label: 'I am a pill!'),
              WnPill(label: 'Am I pilly?'),
            ],
          ),
        ],
      ),
    ),
  );
}
