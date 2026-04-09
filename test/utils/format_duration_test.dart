import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/utils/format_duration.dart';

import '../test_helpers.dart';

void main() {
  late AppLocalizations l10n;

  Future<void> loadL10n(WidgetTester tester) async {
    await mountWidget(const SizedBox(), tester);
    final context = tester.element(find.byType(SizedBox));
    l10n = AppLocalizations.of(context);
  }

  group('formatDurationSeconds', () {
    group('seconds (< 60)', () {
      testWidgets('formats 0 seconds', (tester) async {
        await loadL10n(tester);
        expect(formatDurationSeconds(l10n, 0), l10n.durationSeconds(0));
      });

      testWidgets('formats 1 second', (tester) async {
        await loadL10n(tester);
        expect(formatDurationSeconds(l10n, 1), l10n.durationSeconds(1));
      });

      testWidgets('formats 30 seconds', (tester) async {
        await loadL10n(tester);
        expect(formatDurationSeconds(l10n, 30), l10n.durationSeconds(30));
      });

      testWidgets('formats 59 seconds (upper boundary)', (tester) async {
        await loadL10n(tester);
        expect(formatDurationSeconds(l10n, 59), l10n.durationSeconds(59));
      });
    });

    group('minutes (60..3599)', () {
      testWidgets('formats 60 seconds as 1 minute', (tester) async {
        await loadL10n(tester);
        expect(formatDurationSeconds(l10n, 60), l10n.durationMinutes(1));
      });

      testWidgets('formats 300 seconds as 5 minutes', (tester) async {
        await loadL10n(tester);
        expect(formatDurationSeconds(l10n, 300), l10n.durationMinutes(5));
      });

      testWidgets('formats 3599 seconds as 59 minutes (upper boundary)', (tester) async {
        await loadL10n(tester);
        expect(formatDurationSeconds(l10n, 3599), l10n.durationMinutes(59));
      });

      testWidgets('truncates partial minutes', (tester) async {
        await loadL10n(tester);
        expect(formatDurationSeconds(l10n, 90), l10n.durationMinutes(1));
      });
    });

    group('hours (3600..86399)', () {
      testWidgets('formats 3600 seconds as 1 hour', (tester) async {
        await loadL10n(tester);
        expect(formatDurationSeconds(l10n, 3600), l10n.durationHours(1));
      });

      testWidgets('formats 7200 seconds as 2 hours', (tester) async {
        await loadL10n(tester);
        expect(formatDurationSeconds(l10n, 7200), l10n.durationHours(2));
      });

      testWidgets('formats 86399 seconds as 23 hours (upper boundary)', (tester) async {
        await loadL10n(tester);
        expect(formatDurationSeconds(l10n, 86399), l10n.durationHours(23));
      });

      testWidgets('truncates partial hours', (tester) async {
        await loadL10n(tester);
        expect(formatDurationSeconds(l10n, 5400), l10n.durationHours(1));
      });
    });

    group('days (86400..604799)', () {
      testWidgets('formats 86400 seconds as 1 day', (tester) async {
        await loadL10n(tester);
        expect(formatDurationSeconds(l10n, 86400), l10n.durationDays(1));
      });

      testWidgets('formats 172800 seconds as 2 days', (tester) async {
        await loadL10n(tester);
        expect(formatDurationSeconds(l10n, 172800), l10n.durationDays(2));
      });

      testWidgets('formats 604799 seconds as 6 days (upper boundary)', (tester) async {
        await loadL10n(tester);
        expect(formatDurationSeconds(l10n, 604799), l10n.durationDays(6));
      });

      testWidgets('truncates partial days', (tester) async {
        await loadL10n(tester);
        expect(formatDurationSeconds(l10n, 100000), l10n.durationDays(1));
      });
    });

    group('weeks (>= 604800)', () {
      testWidgets('formats 604800 seconds as 1 week', (tester) async {
        await loadL10n(tester);
        expect(formatDurationSeconds(l10n, 604800), l10n.durationWeeks(1));
      });

      testWidgets('formats 1209600 seconds as 2 weeks', (tester) async {
        await loadL10n(tester);
        expect(formatDurationSeconds(l10n, 1209600), l10n.durationWeeks(2));
      });

      testWidgets('truncates partial weeks', (tester) async {
        await loadL10n(tester);
        expect(formatDurationSeconds(l10n, 700000), l10n.durationWeeks(1));
      });

      testWidgets('handles large values', (tester) async {
        await loadL10n(tester);
        expect(formatDurationSeconds(l10n, 6048000), l10n.durationWeeks(10));
      });
    });

    group('exact boundary transitions', () {
      testWidgets('59 -> seconds, 60 -> minutes', (tester) async {
        await loadL10n(tester);
        expect(formatDurationSeconds(l10n, 59), l10n.durationSeconds(59));
        expect(formatDurationSeconds(l10n, 60), l10n.durationMinutes(1));
      });

      testWidgets('3599 -> minutes, 3600 -> hours', (tester) async {
        await loadL10n(tester);
        expect(formatDurationSeconds(l10n, 3599), l10n.durationMinutes(59));
        expect(formatDurationSeconds(l10n, 3600), l10n.durationHours(1));
      });

      testWidgets('86399 -> hours, 86400 -> days', (tester) async {
        await loadL10n(tester);
        expect(formatDurationSeconds(l10n, 86399), l10n.durationHours(23));
        expect(formatDurationSeconds(l10n, 86400), l10n.durationDays(1));
      });

      testWidgets('604799 -> days, 604800 -> weeks', (tester) async {
        await loadL10n(tester);
        expect(formatDurationSeconds(l10n, 604799), l10n.durationDays(6));
        expect(formatDurationSeconds(l10n, 604800), l10n.durationWeeks(1));
      });
    });
  });
}
