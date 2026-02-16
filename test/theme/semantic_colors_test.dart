import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/theme/semantic_colors.dart';

void main() {
  group('AccentColorSet', () {
    const accent = AccentColorSet(
      fill: Colors.blue,
      contentPrimary: Colors.white,
      contentSecondary: Colors.grey,
      border: Colors.blueGrey,
    );

    test('copyWith returns new instance with updated values', () {
      final updated = accent.copyWith(fill: Colors.red);

      expect(updated.fill, Colors.red);
      expect(updated.contentPrimary, Colors.white);
      expect(updated.contentSecondary, Colors.grey);
      expect(updated.border, Colors.blueGrey);
    });

    test('copyWith with no arguments returns equivalent instance', () {
      final updated = accent.copyWith();

      expect(updated.fill, accent.fill);
      expect(updated.contentPrimary, accent.contentPrimary);
      expect(updated.contentSecondary, accent.contentSecondary);
      expect(updated.border, accent.border);
    });

    test('lerp interpolates between two AccentColorSets', () {
      const other = AccentColorSet(
        fill: Colors.red,
        contentPrimary: Colors.black,
        contentSecondary: Colors.white,
        border: Colors.orange,
      );

      final result = AccentColorSet.lerp(accent, other, 0.5);

      expect(result.fill, Color.lerp(Colors.blue, Colors.red, 0.5));
      expect(result.contentPrimary, Color.lerp(Colors.white, Colors.black, 0.5));
      expect(result.contentSecondary, Color.lerp(Colors.grey, Colors.white, 0.5));
      expect(result.border, Color.lerp(Colors.blueGrey, Colors.orange, 0.5));
    });

    test('lerp at 0 returns first AccentColorSet colors', () {
      const other = AccentColorSet(
        fill: Colors.red,
        contentPrimary: Colors.black,
        contentSecondary: Colors.white,
        border: Colors.orange,
      );

      final result = AccentColorSet.lerp(accent, other, 0);

      expect(result.fill.toARGB32(), accent.fill.toARGB32());
      expect(result.contentPrimary.toARGB32(), accent.contentPrimary.toARGB32());
    });

    test('lerp at 1 returns second AccentColorSet colors', () {
      const other = AccentColorSet(
        fill: Colors.red,
        contentPrimary: Colors.black,
        contentSecondary: Colors.white,
        border: Colors.orange,
      );

      final result = AccentColorSet.lerp(accent, other, 1);

      expect(result.fill.toARGB32(), other.fill.toARGB32());
      expect(result.contentPrimary.toARGB32(), other.contentPrimary.toARGB32());
    });
  });

  group('ReactionColorSet', () {
    const reaction = ReactionColorSet(
      fill: Colors.white,
      fillHover: Colors.grey,
      fillSelected: Colors.black,
      content: Colors.blue,
      contentHover: Colors.blue,
      contentSelected: Colors.red,
    );

    test('copyWith returns new instance with updated values', () {
      final updated = reaction.copyWith(fill: Colors.red);

      expect(updated.fill, Colors.red);
      expect(updated.fillHover, Colors.grey);
      expect(updated.fillSelected, Colors.black);
      expect(updated.content, Colors.blue);
      expect(updated.contentHover, Colors.blue);
      expect(updated.contentSelected, Colors.red);
    });

    test('copyWith with no arguments returns equivalent instance', () {
      final updated = reaction.copyWith();

      expect(updated.fill, reaction.fill);
      expect(updated.fillHover, reaction.fillHover);
      expect(updated.fillSelected, reaction.fillSelected);
      expect(updated.content, reaction.content);
      expect(updated.contentHover, reaction.contentHover);
      expect(updated.contentSelected, reaction.contentSelected);
    });

    test('lerp interpolates between two ReactionColorSets', () {
      const other = ReactionColorSet(
        fill: Colors.black,
        fillHover: Colors.white,
        fillSelected: Colors.red,
        content: Colors.green,
        contentHover: Colors.green,
        contentSelected: Colors.blue,
      );

      final result = ReactionColorSet.lerp(reaction, other, 0.5);

      expect(result.fill, Color.lerp(Colors.white, Colors.black, 0.5));
      expect(result.fillHover, Color.lerp(Colors.grey, Colors.white, 0.5));
      expect(result.fillSelected, Color.lerp(Colors.black, Colors.red, 0.5));
      expect(result.content, Color.lerp(Colors.blue, Colors.green, 0.5));
      expect(result.contentHover, Color.lerp(Colors.blue, Colors.green, 0.5));
      expect(result.contentSelected, Color.lerp(Colors.red, Colors.blue, 0.5));
    });

    test('lerp at 0 returns first ReactionColorSet colors', () {
      const other = ReactionColorSet(
        fill: Colors.black,
        fillHover: Colors.white,
        fillSelected: Colors.red,
        content: Colors.green,
        contentHover: Colors.green,
        contentSelected: Colors.blue,
      );

      final result = ReactionColorSet.lerp(reaction, other, 0);

      expect(result.fill.toARGB32(), reaction.fill.toARGB32());
      expect(result.content.toARGB32(), reaction.content.toARGB32());
    });

    test('lerp at 1 returns second ReactionColorSet colors', () {
      const other = ReactionColorSet(
        fill: Colors.black,
        fillHover: Colors.white,
        fillSelected: Colors.red,
        content: Colors.green,
        contentHover: Colors.green,
        contentSelected: Colors.blue,
      );

      final result = ReactionColorSet.lerp(reaction, other, 1);

      expect(result.fill.toARGB32(), other.fill.toARGB32());
      expect(result.content.toARGB32(), other.content.toARGB32());
    });
  });

  group('SemanticReactionColors', () {
    test('lerp interpolates incoming and outgoing', () {
      final light = SemanticColors.light.reaction;
      final dark = SemanticColors.dark.reaction;

      final result = SemanticReactionColors.lerp(light, dark, 0.5);

      expect(
        result.incoming.fill,
        Color.lerp(light.incoming.fill, dark.incoming.fill, 0.5),
      );
      expect(
        result.outgoing.fill,
        Color.lerp(light.outgoing.fill, dark.outgoing.fill, 0.5),
      );
      expect(
        result.incoming.content,
        Color.lerp(light.incoming.content, dark.incoming.content, 0.5),
      );
      expect(
        result.outgoing.content,
        Color.lerp(light.outgoing.content, dark.outgoing.content, 0.5),
      );
    });
  });

  group('SemanticAccentColors', () {
    test('lerp interpolates all accent color sets', () {
      final light = SemanticColors.light.accent;
      final dark = SemanticColors.dark.accent;

      final result = SemanticAccentColors.lerp(light, dark, 0.5);

      expect(result.blue.fill, Color.lerp(light.blue.fill, dark.blue.fill, 0.5));
      expect(result.cyan.fill, Color.lerp(light.cyan.fill, dark.cyan.fill, 0.5));
      expect(
        result.emerald.fill,
        Color.lerp(light.emerald.fill, dark.emerald.fill, 0.5),
      );
      expect(
        result.fuchsia.fill,
        Color.lerp(light.fuchsia.fill, dark.fuchsia.fill, 0.5),
      );
      expect(
        result.indigo.fill,
        Color.lerp(light.indigo.fill, dark.indigo.fill, 0.5),
      );
      expect(result.lime.fill, Color.lerp(light.lime.fill, dark.lime.fill, 0.5));
      expect(
        result.orange.fill,
        Color.lerp(light.orange.fill, dark.orange.fill, 0.5),
      );
      expect(result.rose.fill, Color.lerp(light.rose.fill, dark.rose.fill, 0.5));
      expect(result.sky.fill, Color.lerp(light.sky.fill, dark.sky.fill, 0.5));
      expect(result.teal.fill, Color.lerp(light.teal.fill, dark.teal.fill, 0.5));
      expect(
        result.violet.fill,
        Color.lerp(light.violet.fill, dark.violet.fill, 0.5),
      );
      expect(
        result.amber.fill,
        Color.lerp(light.amber.fill, dark.amber.fill, 0.5),
      );
    });
  });

  group('SemanticColors', () {
    group('light theme', () {
      test('has expected background colors', () {
        expect(SemanticColors.light.backgroundPrimary, const Color(0xFFFFFFFF));
        expect(SemanticColors.light.backgroundSecondary, const Color(0xFFFAFAFA));
        expect(SemanticColors.light.backgroundTertiary, const Color(0xFFF5F5F5));
      });

      test('has expected content colors', () {
        expect(
          SemanticColors.light.backgroundContentPrimary,
          const Color(0xFF0A0A0A),
        );
        expect(
          SemanticColors.light.backgroundContentSecondary,
          const Color(0xFF737373),
        );
        expect(
          SemanticColors.light.backgroundContentTertiary,
          const Color(0xFFA3A3A3),
        );
      });

      test('has accent colors', () {
        expect(SemanticColors.light.accent, isNotNull);
        expect(SemanticColors.light.accent.blue, isNotNull);
      });

      test('has reaction colors', () {
        expect(SemanticColors.light.reaction, isNotNull);
        expect(SemanticColors.light.reaction.incoming.fill, const Color(0xFFFFFFFF));
        expect(SemanticColors.light.reaction.outgoing.fill, const Color(0xFF262626));
      });
    });

    group('dark theme', () {
      test('has expected background colors', () {
        expect(SemanticColors.dark.backgroundPrimary, const Color(0xFF000000));
        expect(SemanticColors.dark.backgroundSecondary, const Color(0xFF0A0A0A));
        expect(SemanticColors.dark.backgroundTertiary, const Color(0xFF171717));
      });

      test('has expected content colors', () {
        expect(
          SemanticColors.dark.backgroundContentPrimary,
          const Color(0xFFFFFFFF),
        );
        expect(
          SemanticColors.dark.backgroundContentSecondary,
          const Color(0xFFA3A3A3),
        );
        expect(
          SemanticColors.dark.backgroundContentTertiary,
          const Color(0xFF737373),
        );
      });

      test('has accent colors', () {
        expect(SemanticColors.dark.accent, isNotNull);
        expect(SemanticColors.dark.accent.blue, isNotNull);
      });

      test('has reaction colors', () {
        expect(SemanticColors.dark.reaction, isNotNull);
        expect(SemanticColors.dark.reaction.incoming.fill, const Color(0xFF262626));
        expect(SemanticColors.dark.reaction.outgoing.fill, const Color(0xFFF5F5F5));
      });
    });

    group('copyWith', () {
      test('returns new instance with updated background colors', () {
        final updated = SemanticColors.light.copyWith(
          backgroundPrimary: Colors.red,
          backgroundSecondary: Colors.green,
          backgroundTertiary: Colors.blue,
        );

        expect(updated.backgroundPrimary, Colors.red);
        expect(updated.backgroundSecondary, Colors.green);
        expect(updated.backgroundTertiary, Colors.blue);
        expect(
          updated.backgroundContentPrimary,
          SemanticColors.light.backgroundContentPrimary,
        );
      });

      test('returns new instance with updated content colors', () {
        final updated = SemanticColors.light.copyWith(
          backgroundContentPrimary: Colors.red,
          backgroundContentSecondary: Colors.green,
          backgroundContentTertiary: Colors.blue,
          backgroundContentDestructive: Colors.orange,
          backgroundContentDestructiveSecondary: Colors.purple,
        );

        expect(updated.backgroundContentPrimary, Colors.red);
        expect(updated.backgroundContentSecondary, Colors.green);
        expect(updated.backgroundContentTertiary, Colors.blue);
        expect(updated.backgroundContentDestructive, Colors.orange);
        expect(updated.backgroundContentDestructiveSecondary, Colors.purple);
      });

      test('returns new instance with updated fill colors', () {
        final updated = SemanticColors.light.copyWith(
          fillPrimary: Colors.red,
          fillPrimaryHover: Colors.green,
          fillPrimaryActive: Colors.blue,
          fillSecondary: Colors.orange,
          fillSecondaryHover: Colors.purple,
          fillSecondaryActive: Colors.pink,
          fillTertiary: Colors.cyan,
          fillTertiaryHover: Colors.teal,
          fillTertiaryActive: Colors.indigo,
          fillDestructive: Colors.amber,
          fillDestructiveHover: Colors.lime,
          fillDestructiveActive: Colors.brown,
        );

        expect(updated.fillPrimary, Colors.red);
        expect(updated.fillPrimaryHover, Colors.green);
        expect(updated.fillPrimaryActive, Colors.blue);
        expect(updated.fillSecondary, Colors.orange);
        expect(updated.fillSecondaryHover, Colors.purple);
        expect(updated.fillSecondaryActive, Colors.pink);
        expect(updated.fillTertiary, Colors.cyan);
        expect(updated.fillTertiaryHover, Colors.teal);
        expect(updated.fillTertiaryActive, Colors.indigo);
        expect(updated.fillDestructive, Colors.amber);
        expect(updated.fillDestructiveHover, Colors.lime);
        expect(updated.fillDestructiveActive, Colors.brown);
      });

      test('returns new instance with updated fill content colors', () {
        final updated = SemanticColors.light.copyWith(
          fillContentPrimary: Colors.red,
          fillContentSecondary: Colors.green,
          fillContentQuaternary: Colors.blue,
        );

        expect(updated.fillContentPrimary, Colors.red);
        expect(updated.fillContentSecondary, Colors.green);
        expect(updated.fillContentQuaternary, Colors.blue);
      });

      test('returns new instance with updated border colors', () {
        final updated = SemanticColors.light.copyWith(
          borderPrimary: Colors.red,
          borderSecondary: Colors.green,
          borderTertiary: Colors.blue,
          borderDestructivePrimary: Colors.orange,
          borderDestructiveSecondary: Colors.purple,
        );

        expect(updated.borderPrimary, Colors.red);
        expect(updated.borderSecondary, Colors.green);
        expect(updated.borderTertiary, Colors.blue);
        expect(updated.borderDestructivePrimary, Colors.orange);
        expect(updated.borderDestructiveSecondary, Colors.purple);
      });

      test('returns new instance with updated intention colors', () {
        final updated = SemanticColors.light.copyWith(
          intentionInfoBackground: Colors.cyan,
          intentionInfoContent: Colors.blue,
          intentionSuccessBackground: Colors.teal,
          intentionSuccessContent: Colors.green,
          intentionWarningBackground: Colors.amber,
          intentionWarningContent: Colors.orange,
          intentionErrorBackground: Colors.pink,
          intentionErrorContent: Colors.red,
        );

        expect(updated.intentionInfoBackground, Colors.cyan);
        expect(updated.intentionInfoContent, Colors.blue);
        expect(updated.intentionSuccessBackground, Colors.teal);
        expect(updated.intentionSuccessContent, Colors.green);
        expect(updated.intentionWarningBackground, Colors.amber);
        expect(updated.intentionWarningContent, Colors.orange);
        expect(updated.intentionErrorBackground, Colors.pink);
        expect(updated.intentionErrorContent, Colors.red);
      });

      test('returns new instance with updated shadow', () {
        final updated = SemanticColors.light.copyWith(shadow: Colors.red);

        expect(updated.shadow, Colors.red);
      });

      test('returns new instance with updated overlay colors', () {
        final updated = SemanticColors.light.copyWith(
          overlayPrimary: Colors.red,
          overlaySecondary: Colors.green,
          overlayTertiary: Colors.blue,
        );

        expect(updated.overlayPrimary, Colors.red);
        expect(updated.overlaySecondary, Colors.green);
        expect(updated.overlayTertiary, Colors.blue);
      });

      test('returns new instance with updated accent colors', () {
        const newAccent = SemanticAccentColors(
          blue: AccentColorSet(
            fill: Colors.red,
            contentPrimary: Colors.white,
            contentSecondary: Colors.grey,
            border: Colors.black,
          ),
          cyan: AccentColorSet(
            fill: Colors.red,
            contentPrimary: Colors.white,
            contentSecondary: Colors.grey,
            border: Colors.black,
          ),
          emerald: AccentColorSet(
            fill: Colors.red,
            contentPrimary: Colors.white,
            contentSecondary: Colors.grey,
            border: Colors.black,
          ),
          fuchsia: AccentColorSet(
            fill: Colors.red,
            contentPrimary: Colors.white,
            contentSecondary: Colors.grey,
            border: Colors.black,
          ),
          indigo: AccentColorSet(
            fill: Colors.red,
            contentPrimary: Colors.white,
            contentSecondary: Colors.grey,
            border: Colors.black,
          ),
          lime: AccentColorSet(
            fill: Colors.red,
            contentPrimary: Colors.white,
            contentSecondary: Colors.grey,
            border: Colors.black,
          ),
          orange: AccentColorSet(
            fill: Colors.red,
            contentPrimary: Colors.white,
            contentSecondary: Colors.grey,
            border: Colors.black,
          ),
          rose: AccentColorSet(
            fill: Colors.red,
            contentPrimary: Colors.white,
            contentSecondary: Colors.grey,
            border: Colors.black,
          ),
          sky: AccentColorSet(
            fill: Colors.red,
            contentPrimary: Colors.white,
            contentSecondary: Colors.grey,
            border: Colors.black,
          ),
          teal: AccentColorSet(
            fill: Colors.red,
            contentPrimary: Colors.white,
            contentSecondary: Colors.grey,
            border: Colors.black,
          ),
          violet: AccentColorSet(
            fill: Colors.red,
            contentPrimary: Colors.white,
            contentSecondary: Colors.grey,
            border: Colors.black,
          ),
          amber: AccentColorSet(
            fill: Colors.red,
            contentPrimary: Colors.white,
            contentSecondary: Colors.grey,
            border: Colors.black,
          ),
        );

        final updated = SemanticColors.light.copyWith(accent: newAccent);

        expect(updated.accent.blue.fill, Colors.red);
      });

      test('returns new instance with updated reaction colors', () {
        const newReaction = SemanticReactionColors(
          incoming: ReactionColorSet(
            fill: Colors.red,
            fillHover: Colors.green,
            fillSelected: Colors.blue,
            content: Colors.orange,
            contentHover: Colors.purple,
            contentSelected: Colors.pink,
          ),
          outgoing: ReactionColorSet(
            fill: Colors.cyan,
            fillHover: Colors.teal,
            fillSelected: Colors.indigo,
            content: Colors.amber,
            contentHover: Colors.lime,
            contentSelected: Colors.brown,
          ),
        );

        final updated = SemanticColors.light.copyWith(reaction: newReaction);

        expect(updated.reaction.incoming.fill, Colors.red);
        expect(updated.reaction.outgoing.fill, Colors.cyan);
      });

      test('with no arguments returns equivalent instance', () {
        final updated = SemanticColors.light.copyWith();

        expect(updated.backgroundPrimary, SemanticColors.light.backgroundPrimary);
        expect(updated.fillPrimary, SemanticColors.light.fillPrimary);
        expect(updated.borderPrimary, SemanticColors.light.borderPrimary);
        expect(
          updated.reaction.incoming.fill,
          SemanticColors.light.reaction.incoming.fill,
        );
      });
    });

    group('lerp', () {
      test('interpolates between light and dark themes', () {
        final result = SemanticColors.light.lerp(SemanticColors.dark, 0.5);

        expect(
          result.backgroundPrimary,
          Color.lerp(
            SemanticColors.light.backgroundPrimary,
            SemanticColors.dark.backgroundPrimary,
            0.5,
          ),
        );
        expect(
          result.fillPrimary,
          Color.lerp(
            SemanticColors.light.fillPrimary,
            SemanticColors.dark.fillPrimary,
            0.5,
          ),
        );
      });

      test('at 0 returns first theme colors', () {
        final result = SemanticColors.light.lerp(SemanticColors.dark, 0);

        expect(result.backgroundPrimary, SemanticColors.light.backgroundPrimary);
        expect(result.fillPrimary, SemanticColors.light.fillPrimary);
      });

      test('at 1 returns second theme colors', () {
        final result = SemanticColors.light.lerp(SemanticColors.dark, 1);

        expect(result.backgroundPrimary, SemanticColors.dark.backgroundPrimary);
        expect(result.fillPrimary, SemanticColors.dark.fillPrimary);
      });

      test('returns this when other is not SemanticColors', () {
        final result = SemanticColors.light.lerp(null, 0.5);

        expect(result, SemanticColors.light);
      });

      test('interpolates all color properties', () {
        final result = SemanticColors.light.lerp(SemanticColors.dark, 0.5);

        expect(
          result.backgroundSecondary,
          Color.lerp(
            SemanticColors.light.backgroundSecondary,
            SemanticColors.dark.backgroundSecondary,
            0.5,
          ),
        );
        expect(
          result.backgroundTertiary,
          Color.lerp(
            SemanticColors.light.backgroundTertiary,
            SemanticColors.dark.backgroundTertiary,
            0.5,
          ),
        );
        expect(
          result.backgroundContentPrimary,
          Color.lerp(
            SemanticColors.light.backgroundContentPrimary,
            SemanticColors.dark.backgroundContentPrimary,
            0.5,
          ),
        );
        expect(
          result.backgroundContentSecondary,
          Color.lerp(
            SemanticColors.light.backgroundContentSecondary,
            SemanticColors.dark.backgroundContentSecondary,
            0.5,
          ),
        );
        expect(
          result.backgroundContentTertiary,
          Color.lerp(
            SemanticColors.light.backgroundContentTertiary,
            SemanticColors.dark.backgroundContentTertiary,
            0.5,
          ),
        );
        expect(
          result.backgroundContentDestructive,
          Color.lerp(
            SemanticColors.light.backgroundContentDestructive,
            SemanticColors.dark.backgroundContentDestructive,
            0.5,
          ),
        );
        expect(
          result.backgroundContentDestructiveSecondary,
          Color.lerp(
            SemanticColors.light.backgroundContentDestructiveSecondary,
            SemanticColors.dark.backgroundContentDestructiveSecondary,
            0.5,
          ),
        );

        expect(
          result.fillPrimaryHover,
          Color.lerp(
            SemanticColors.light.fillPrimaryHover,
            SemanticColors.dark.fillPrimaryHover,
            0.5,
          ),
        );
        expect(
          result.fillPrimaryActive,
          Color.lerp(
            SemanticColors.light.fillPrimaryActive,
            SemanticColors.dark.fillPrimaryActive,
            0.5,
          ),
        );
        expect(
          result.fillSecondary,
          Color.lerp(
            SemanticColors.light.fillSecondary,
            SemanticColors.dark.fillSecondary,
            0.5,
          ),
        );
        expect(
          result.fillSecondaryHover,
          Color.lerp(
            SemanticColors.light.fillSecondaryHover,
            SemanticColors.dark.fillSecondaryHover,
            0.5,
          ),
        );
        expect(
          result.fillSecondaryActive,
          Color.lerp(
            SemanticColors.light.fillSecondaryActive,
            SemanticColors.dark.fillSecondaryActive,
            0.5,
          ),
        );
        expect(
          result.fillTertiary,
          Color.lerp(
            SemanticColors.light.fillTertiary,
            SemanticColors.dark.fillTertiary,
            0.5,
          ),
        );
        expect(
          result.fillTertiaryHover,
          Color.lerp(
            SemanticColors.light.fillTertiaryHover,
            SemanticColors.dark.fillTertiaryHover,
            0.5,
          ),
        );
        expect(
          result.fillTertiaryActive,
          Color.lerp(
            SemanticColors.light.fillTertiaryActive,
            SemanticColors.dark.fillTertiaryActive,
            0.5,
          ),
        );
        expect(
          result.fillDestructive,
          Color.lerp(
            SemanticColors.light.fillDestructive,
            SemanticColors.dark.fillDestructive,
            0.5,
          ),
        );
        expect(
          result.fillDestructiveHover,
          Color.lerp(
            SemanticColors.light.fillDestructiveHover,
            SemanticColors.dark.fillDestructiveHover,
            0.5,
          ),
        );
        expect(
          result.fillDestructiveActive,
          Color.lerp(
            SemanticColors.light.fillDestructiveActive,
            SemanticColors.dark.fillDestructiveActive,
            0.5,
          ),
        );

        expect(
          result.fillContentPrimary,
          Color.lerp(
            SemanticColors.light.fillContentPrimary,
            SemanticColors.dark.fillContentPrimary,
            0.5,
          ),
        );
        expect(
          result.fillContentSecondary,
          Color.lerp(
            SemanticColors.light.fillContentSecondary,
            SemanticColors.dark.fillContentSecondary,
            0.5,
          ),
        );
        expect(
          result.fillContentQuaternary,
          Color.lerp(
            SemanticColors.light.fillContentQuaternary,
            SemanticColors.dark.fillContentQuaternary,
            0.5,
          ),
        );

        expect(
          result.borderPrimary,
          Color.lerp(
            SemanticColors.light.borderPrimary,
            SemanticColors.dark.borderPrimary,
            0.5,
          ),
        );
        expect(
          result.borderSecondary,
          Color.lerp(
            SemanticColors.light.borderSecondary,
            SemanticColors.dark.borderSecondary,
            0.5,
          ),
        );
        expect(
          result.borderTertiary,
          Color.lerp(
            SemanticColors.light.borderTertiary,
            SemanticColors.dark.borderTertiary,
            0.5,
          ),
        );
        expect(
          result.borderDestructivePrimary,
          Color.lerp(
            SemanticColors.light.borderDestructivePrimary,
            SemanticColors.dark.borderDestructivePrimary,
            0.5,
          ),
        );
        expect(
          result.borderDestructiveSecondary,
          Color.lerp(
            SemanticColors.light.borderDestructiveSecondary,
            SemanticColors.dark.borderDestructiveSecondary,
            0.5,
          ),
        );
        expect(
          result.intentionInfoBackground,
          Color.lerp(
            SemanticColors.light.intentionInfoBackground,
            SemanticColors.dark.intentionInfoBackground,
            0.5,
          ),
        );
        expect(
          result.intentionInfoContent,
          Color.lerp(
            SemanticColors.light.intentionInfoContent,
            SemanticColors.dark.intentionInfoContent,
            0.5,
          ),
        );
        expect(
          result.intentionSuccessBackground,
          Color.lerp(
            SemanticColors.light.intentionSuccessBackground,
            SemanticColors.dark.intentionSuccessBackground,
            0.5,
          ),
        );
        expect(
          result.intentionSuccessContent,
          Color.lerp(
            SemanticColors.light.intentionSuccessContent,
            SemanticColors.dark.intentionSuccessContent,
            0.5,
          ),
        );
        expect(
          result.intentionWarningBackground,
          Color.lerp(
            SemanticColors.light.intentionWarningBackground,
            SemanticColors.dark.intentionWarningBackground,
            0.5,
          ),
        );
        expect(
          result.intentionWarningContent,
          Color.lerp(
            SemanticColors.light.intentionWarningContent,
            SemanticColors.dark.intentionWarningContent,
            0.5,
          ),
        );
        expect(
          result.intentionErrorBackground,
          Color.lerp(
            SemanticColors.light.intentionErrorBackground,
            SemanticColors.dark.intentionErrorBackground,
            0.5,
          ),
        );
        expect(
          result.intentionErrorContent,
          Color.lerp(
            SemanticColors.light.intentionErrorContent,
            SemanticColors.dark.intentionErrorContent,
            0.5,
          ),
        );

        expect(
          result.shadow,
          Color.lerp(
            SemanticColors.light.shadow,
            SemanticColors.dark.shadow,
            0.5,
          ),
        );
        expect(
          result.overlayPrimary,
          Color.lerp(
            SemanticColors.light.overlayPrimary,
            SemanticColors.dark.overlayPrimary,
            0.5,
          ),
        );
        expect(
          result.overlaySecondary,
          Color.lerp(
            SemanticColors.light.overlaySecondary,
            SemanticColors.dark.overlaySecondary,
            0.5,
          ),
        );
        expect(
          result.overlayTertiary,
          Color.lerp(
            SemanticColors.light.overlayTertiary,
            SemanticColors.dark.overlayTertiary,
            0.5,
          ),
        );

        expect(
          result.reaction.incoming.fill,
          Color.lerp(
            SemanticColors.light.reaction.incoming.fill,
            SemanticColors.dark.reaction.incoming.fill,
            0.5,
          ),
        );
        expect(
          result.reaction.outgoing.fill,
          Color.lerp(
            SemanticColors.light.reaction.outgoing.fill,
            SemanticColors.dark.reaction.outgoing.fill,
            0.5,
          ),
        );
      });
    });
  });

  group('SemanticColorsExtension', () {
    testWidgets('returns SemanticColors from theme', (tester) async {
      late SemanticColors colors;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const [SemanticColors.light],
          ),
          home: Builder(
            builder: (context) {
              colors = context.colors;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(colors.backgroundPrimary, SemanticColors.light.backgroundPrimary);
    });

    testWidgets('returns light colors as fallback when extension is missing', (
      tester,
    ) async {
      late SemanticColors colors;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(),
          home: Builder(
            builder: (context) {
              colors = context.colors;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(colors.backgroundPrimary, SemanticColors.light.backgroundPrimary);
    });

    testWidgets('returns dark theme colors when dark theme is used', (
      tester,
    ) async {
      late SemanticColors colors;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const [SemanticColors.dark],
          ),
          home: Builder(
            builder: (context) {
              colors = context.colors;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(colors.backgroundPrimary, SemanticColors.dark.backgroundPrimary);
    });
  });
}
