import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/l10n/generated/app_localizations.dart';
import 'package:whitenoise/providers/app_log_provider.dart'
    show AppLogEntry, AppLogNotifier, appLogProvider;
import 'package:whitenoise/screens/app_logs_screen.dart';

import '../test_helpers.dart';

class _TestAppLogNotifier extends AppLogNotifier {
  @override
  List<AppLogEntry> build() => List.unmodifiable(_entries);

  @override
  void clear() {
    _entries = [];
    state = List.unmodifiable(_entries);
  }
}

List<AppLogEntry> _entries = [];

AppLogEntry _entry(
  String message, {
  Level level = Level.INFO,
  String logger = 'test_logger',
  Object? error,
  StackTrace? stackTrace,
  DateTime? time,
}) {
  return AppLogEntry(
    timestamp: time ?? DateTime.now(),
    level: level,
    loggerName: logger,
    message: message,
    error: error,
    stackTrace: stackTrace,
  );
}

Finder _excludeChipClose(String pattern) {
  return find.descendant(
    of: find.byKey(Key('exclude_$pattern')),
    matching: find.byIcon(Icons.close),
  );
}

Finder _includeChipClose(String pattern) {
  return find.descendant(
    of: find.byKey(Key('include_$pattern')),
    matching: find.byIcon(Icons.close),
  );
}

void main() {
  Future<void> pumpScreen(WidgetTester tester) async {
    setUpTestView(tester);
    tester.view.physicalSize = const Size(1200, 844);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appLogProvider.overrideWith(_TestAppLogNotifier.new),
        ],
        child: ScreenUtilInit(
          designSize: testDesignSize,
          builder: (_, _) => const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: AppLogsScreen()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    _entries = [];
  });

  group('AppLogsScreen', () {
    testWidgets('shows empty state when there are no logs', (tester) async {
      await pumpScreen(tester);

      expect(find.byType(AppLogsScreen), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(find.byKey(const Key('app_logs_search')), findsOneWidget);
      expect(find.byKey(const Key('app_logs_pattern_input')), findsOneWidget);
      expect(find.byKey(const Key('app_logs_clear_filters')), findsNothing);
    });

    testWidgets('renders log rows with level, logger, message, error and stacktrace', (
      tester,
    ) async {
      _entries = [
        _entry(
          'failed to send message',
          level: Level.SEVERE,
          logger: 'rust',
          error: 'socket error',
          stackTrace: StackTrace.fromString('line_1\nline_2\nline_3'),
          time: DateTime(2026, 1, 1, 10, 11, 12, 123),
        ),
      ];

      await pumpScreen(tester);

      expect(find.text('SEVERE').last, findsOneWidget);
      expect(find.text('rust'), findsOneWidget);
      expect(find.text('failed to send message'), findsOneWidget);
      expect(find.textContaining('error: socket error'), findsOneWidget);
      expect(find.textContaining('line_1'), findsOneWidget);
    });

    testWidgets('search filters visible logs', (tester) async {
      _entries = [
        _entry('alpha event', level: Level.WARNING),
        _entry('beta event', level: Level.WARNING),
      ];
      await pumpScreen(tester);

      await tester.enterText(find.byKey(const Key('app_logs_search')), 'alpha');
      await tester.pumpAndSettle();

      expect(find.text('alpha event'), findsOneWidget);
      expect(find.text('beta event'), findsNothing);
      expect(find.byKey(const Key('app_logs_clear_filters')), findsOneWidget);
    });

    testWidgets('adds and removes exclude/include patterns', (tester) async {
      _entries = [
        _entry('network timeout warning', level: Level.WARNING),
        _entry('auth success', level: Level.WARNING),
      ];
      await pumpScreen(tester);

      await tester.enterText(find.byKey(const Key('app_logs_pattern_input')), 'timeout');
      await tester.tap(find.byKey(const Key('app_logs_add_ignore')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('exclude_timeout')), findsOneWidget);
      expect(find.text('network timeout warning'), findsNothing);
      expect(find.text('auth success'), findsOneWidget);

      await tester.tap(_excludeChipClose('timeout'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('exclude_timeout')), findsNothing);
      expect(find.text('network timeout warning'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('app_logs_pattern_input')), 'auth');
      await tester.tap(find.byKey(const Key('app_logs_add_show')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('include_auth')), findsOneWidget);
      expect(find.text('network timeout warning'), findsNothing);
      expect(find.text('auth success'), findsOneWidget);

      await tester.tap(_includeChipClose('auth'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('include_auth')), findsNothing);
    });

    testWidgets('submitting pattern input adds exclude filter', (tester) async {
      _entries = [_entry('alpha', level: Level.WARNING), _entry('beta', level: Level.WARNING)];
      await pumpScreen(tester);

      await tester.enterText(find.byKey(const Key('app_logs_pattern_input')), 'alpha');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('exclude_alpha')), findsOneWidget);
      expect(find.text('alpha'), findsNothing);
    });

    testWidgets('clear filters resets search and patterns', (tester) async {
      _entries = [
        _entry('foo event', level: Level.WARNING),
        _entry('bar event', level: Level.WARNING),
      ];
      await pumpScreen(tester);

      await tester.enterText(find.byKey(const Key('app_logs_search')), 'foo');
      await tester.enterText(find.byKey(const Key('app_logs_pattern_input')), 'bar');
      await tester.tap(find.byKey(const Key('app_logs_add_ignore')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('app_logs_clear_filters')), findsOneWidget);
      await tester.tap(find.byKey(const Key('app_logs_clear_filters')));
      await tester.pumpAndSettle();

      expect(find.text('foo event'), findsOneWidget);
      expect(find.text('bar event'), findsOneWidget);
      expect(find.byKey(const Key('exclude_bar')), findsNothing);
      expect(find.byKey(const Key('app_logs_clear_filters')), findsNothing);
    });

    testWidgets('shows filtered count when entries are filtered out', (tester) async {
      _entries = [
        _entry('alpha event', level: Level.WARNING),
        _entry('beta event', level: Level.WARNING),
      ];
      await pumpScreen(tester);

      await tester.enterText(find.byKey(const Key('app_logs_search')), 'nomatch');
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(AppLogsScreen));
      final l10n = AppLocalizations.of(context);
      expect(find.text(l10n.appLogsFilteredCount(0, 2)), findsWidgets);
    });

    testWidgets('clear logs button removes all entries', (tester) async {
      _entries = [_entry('first', level: Level.WARNING), _entry('second', level: Level.WARNING)];
      await pumpScreen(tester);

      expect(find.text('first'), findsOneWidget);
      expect(find.text('second'), findsOneWidget);

      await tester.tap(find.byKey(const Key('app_logs_clear')));
      await tester.pumpAndSettle();

      expect(find.text('first'), findsNothing);
      expect(find.text('second'), findsNothing);
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('resume-live button is hidden when list is at the bottom', (tester) async {
      _entries = [_entry('only entry', level: Level.WARNING)];
      await pumpScreen(tester);

      expect(find.byKey(const Key('app_logs_resume_live')), findsNothing);
    });

    testWidgets('scrolling up shows resume-live button and freezes the list', (tester) async {
      _entries = List.generate(
        50,
        (i) => _entry('log entry $i', level: Level.WARNING, time: DateTime(2026, 1, 1, 0, 0, i)),
      );
      await pumpScreen(tester);

      expect(find.byKey(const Key('app_logs_resume_live')), findsNothing);

      await tester.drag(find.byKey(const Key('app_logs_list')), const Offset(0, 300));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('app_logs_resume_live')), findsOneWidget);
    });

    testWidgets('tapping resume-live button hides the button', (tester) async {
      _entries = List.generate(
        50,
        (i) => _entry('log entry $i', level: Level.WARNING, time: DateTime(2026, 1, 1, 0, 0, i)),
      );
      await pumpScreen(tester);

      await tester.drag(find.byKey(const Key('app_logs_list')), const Offset(0, 300));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('app_logs_resume_live')), findsOneWidget);

      await tester.tap(find.byKey(const Key('app_logs_resume_live')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('app_logs_resume_live')), findsNothing);
    });

    testWidgets('tapping log entry copies formatted text and shows snackbar', (tester) async {
      String? clipboardText;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboardText = call.arguments['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });

      _entries = [
        _entry(
          'failed to send message',
          level: Level.SEVERE,
          logger: 'rust',
          error: 'socket error',
          stackTrace: StackTrace.fromString('line_1\nline_2\nline_3'),
          time: DateTime(2026, 1, 1, 10, 11, 12, 123),
        ),
      ];

      await pumpScreen(tester);
      final entryTile = find.ancestor(
        of: find.text('failed to send message'),
        matching: find.byType(GestureDetector),
      );
      expect(entryTile, findsOneWidget);
      final gesture = tester.widget<GestureDetector>(entryTile);
      gesture.onTap?.call();
      await tester.pumpAndSettle();

      expect(clipboardText, isNotNull);
      expect(clipboardText, contains('SEVERE rust'));
      expect(clipboardText, contains('failed to send message'));
      expect(clipboardText, contains('error: socket error'));
      expect(clipboardText, contains('stackTrace: line_1'));

      final context = tester.element(find.byType(AppLogsScreen));
      final l10n = AppLocalizations.of(context);
      expect(find.text(l10n.rawDebugViewCopied), findsOneWidget);
    });

    testWidgets('renders WARNING log entry', (tester) async {
      _entries = [_entry('low disk space', level: Level.WARNING)];
      await pumpScreen(tester);

      expect(find.text('WARNING'), findsOneWidget);
    });

    testWidgets('copy all button copies all visible entries to clipboard', (tester) async {
      String? clipboardText;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboardText = call.arguments['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });

      _entries = [
        _entry('first message', time: DateTime(2026, 1, 1, 10)),
        _entry('second message', time: DateTime(2026, 1, 1, 10, 0, 1)),
        _entry('third message', time: DateTime(2026, 1, 1, 10, 0, 2)),
      ];

      await pumpScreen(tester);

      await tester.tap(find.text('INFO').first);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('app_logs_copy_all')), findsOneWidget);

      await tester.tap(find.byKey(const Key('app_logs_copy_all')));
      await tester.pumpAndSettle();

      expect(clipboardText, isNotNull);
      expect(clipboardText, contains('first message'));
      expect(clipboardText, contains('second message'));
      expect(clipboardText, contains('third message'));

      final context = tester.element(find.byType(AppLogsScreen));
      final l10n = AppLocalizations.of(context);
      expect(find.text(l10n.rawDebugViewCopied), findsOneWidget);
    });

    testWidgets('copy all button is hidden when no entries', (tester) async {
      await pumpScreen(tester);

      expect(find.byKey(const Key('app_logs_copy_all')), findsNothing);
    });

    testWidgets('copy all button copies filtered entries only', (tester) async {
      String? clipboardText;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboardText = call.arguments['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });

      _entries = [
        _entry('alpha message', level: Level.WARNING),
        _entry('beta message', level: Level.WARNING),
        _entry('gamma message', level: Level.WARNING),
      ];

      await pumpScreen(tester);

      await tester.enterText(find.byKey(const Key('app_logs_search')), 'beta');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('app_logs_copy_all')));
      await tester.pumpAndSettle();

      expect(clipboardText, isNotNull);
      expect(clipboardText, contains('beta message'));
      expect(clipboardText, isNot(contains('alpha message')));
      expect(clipboardText, isNot(contains('gamma message')));
    });

    testWidgets('renders SHOUT level with destructive color styling', (tester) async {
      _entries = [_entry('critical error', level: Level.SHOUT)];
      await pumpScreen(tester);

      expect(find.text('SHOUT'), findsOneWidget);
    });

    testWidgets('renders INFO level entry', (tester) async {
      _entries = [_entry('info message')];
      await pumpScreen(tester);

      await tester.tap(find.text('INFO').first);
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: find.byKey(const Key('app_logs_list')), matching: find.text('INFO')),
        findsOneWidget,
      );
    });

    testWidgets('INFO logs are hidden by default and appear after enabling INFO level', (
      tester,
    ) async {
      _entries = [
        _entry('info only'),
        _entry('warning only', level: Level.WARNING),
      ];
      await pumpScreen(tester);

      expect(find.text('warning only'), findsOneWidget);
      expect(find.text('info only'), findsNothing);

      await tester.tap(find.text('INFO').first);
      await tester.pumpAndSettle();

      expect(find.text('info only'), findsOneWidget);
    });
  });
}
