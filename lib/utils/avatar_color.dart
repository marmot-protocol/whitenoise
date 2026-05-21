import 'dart:ui' show Color;

import 'package:flutter/foundation.dart' show immutable;
import 'package:logging/logging.dart';
import 'package:whitenoise/theme/semantic_colors.dart';

final _logger = Logger('AvatarColor');

@immutable
class AvatarColorSet {
  final Color background;
  final Color border;
  final Color content;
  final Color contentSecondary;

  const AvatarColorSet({
    required this.background,
    required this.border,
    required this.content,
    required this.contentSecondary,
  });
}

enum AvatarColor {
  neutral,
  blue,
  cyan,
  emerald,
  fuchsia,
  indigo,
  lime,
  orange,
  rose,
  sky,
  teal,
  violet,
  amber,
  ;

  static AvatarColor fromPubkey(String pubkey) {
    if (pubkey.isEmpty) {
      _logger.severe('AvatarColor.fromPubkey called with empty string');
      return AvatarColor.neutral;
    }

    final firstChar = pubkey[0].toLowerCase();
    final hexValue = int.tryParse(firstChar, radix: 16);

    if (hexValue == null) {
      _logger.severe('AvatarColor.fromPubkey called with invalid hex: $firstChar');
      return AvatarColor.neutral;
    }

    final accentColors = AvatarColor.values.sublist(1);
    return accentColors[hexValue % accentColors.length];
  }

  AvatarColorSet toColorSet(SemanticColors colors) {
    return switch (this) {
      neutral => AvatarColorSet(
        background: colors.fillSecondary,
        border: colors.borderSecondary,
        content: colors.fillContentSecondary,
        contentSecondary: colors.fillContentTertiary,
      ),
      blue => _fromAccent(colors.accent.blue),
      cyan => _fromAccent(colors.accent.cyan),
      emerald => _fromAccent(colors.accent.emerald),
      fuchsia => _fromAccent(colors.accent.fuchsia),
      indigo => _fromAccent(colors.accent.indigo),
      lime => _fromAccent(colors.accent.lime),
      orange => _fromAccent(colors.accent.orange),
      rose => _fromAccent(colors.accent.rose),
      sky => _fromAccent(colors.accent.sky),
      teal => _fromAccent(colors.accent.teal),
      violet => _fromAccent(colors.accent.violet),
      amber => _fromAccent(colors.accent.amber),
    };
  }
}

AvatarColorSet _fromAccent(AccentColorSet accent) => AvatarColorSet(
  background: accent.fill,
  border: accent.border,
  content: accent.contentPrimary,
  contentSecondary: accent.contentSecondary,
);
