import 'package:whitenoise/l10n/l10n.dart';

String formatDurationSeconds(AppLocalizations l10n, int seconds) {
  if (seconds < 60) {
    return l10n.durationSeconds(seconds);
  } else if (seconds < 3600) {
    final minutes = seconds ~/ 60;
    return l10n.durationMinutes(minutes);
  } else if (seconds < 86400) {
    final hours = seconds ~/ 3600;
    return l10n.durationHours(hours);
  } else if (seconds < 604800) {
    final days = seconds ~/ 86400;
    return l10n.durationDays(days);
  } else {
    final weeks = seconds ~/ 604800;
    return l10n.durationWeeks(weeks);
  }
}
