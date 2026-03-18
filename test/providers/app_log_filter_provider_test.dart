import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/providers/app_log_filter_provider.dart';
import 'package:whitenoise/providers/app_log_provider.dart';

final _testEntries = [
  AppLogEntry(
    timestamp: DateTime(2025, 1, 1, 12),
    level: Level.INFO,
    loggerName: 'foo',
    message: 'hello world',
  ),
  AppLogEntry(
    timestamp: DateTime(2025, 1, 1, 12),
    level: Level.WARNING,
    loggerName: 'bar',
    message: 'error occurred',
  ),
  AppLogEntry(
    timestamp: DateTime(2025, 1, 1, 12),
    level: Level.SEVERE,
    loggerName: 'baz',
    message: 'connection timeout',
  ),
];

class _TestAppLogNotifier extends AppLogNotifier {
  @override
  List<AppLogEntry> build() => List.unmodifiable(_testEntries);
}

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        appLogProvider.overrideWith(() => _TestAppLogNotifier()),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('filteredAppLogProvider', () {
    test('returns filtered entries when no patterns but default levels applied', () {
      final filtered = container.read(filteredAppLogProvider);
      expect(filtered.length, 2);
      expect(filtered.map((e) => e.message), containsAll(['error occurred', 'connection timeout']));
    });

    test('returns all entries when all levels are applied', () {
      container.read(appLogFilterProvider.notifier).toggleLevel(Level.INFO);
      final filtered = container.read(filteredAppLogProvider);
      expect(filtered.length, 3);
      expect(
        filtered.map((e) => e.message),
        containsAll(['hello world', 'error occurred', 'connection timeout']),
      );
    });

    test('search filters by substring', () {
      container.read(appLogFilterProvider.notifier).setSearch('error');
      final filtered = container.read(filteredAppLogProvider);
      expect(filtered.length, 1);
      expect(filtered.single.message, 'error occurred');
    });

    test('search is case insensitive', () {
      container.read(appLogFilterProvider.notifier).toggleLevel(Level.INFO);
      container.read(appLogFilterProvider.notifier).setSearch('HELLO');
      final filtered = container.read(filteredAppLogProvider);
      expect(filtered.length, 1);
      expect(filtered.single.message, 'hello world');
    });

    test('exclude hides matching entries', () {
      container.read(appLogFilterProvider.notifier).toggleLevel(Level.INFO);
      container.read(appLogFilterProvider.notifier).addExclude('timeout');
      final filtered = container.read(filteredAppLogProvider);
      expect(filtered.length, 2);
      expect(filtered.map((e) => e.message).toList(), contains('hello world'));
      expect(filtered.map((e) => e.message).toList(), contains('error occurred'));
    });

    test('include shows only matching entries', () {
      container.read(appLogFilterProvider.notifier).toggleLevel(Level.INFO);
      container.read(appLogFilterProvider.notifier).addInclude('world');
      final filtered = container.read(filteredAppLogProvider);
      expect(filtered.length, 1);
      expect(filtered.single.message, 'hello world');
    });

    test('include with multiple patterns shows entries matching any', () {
      container.read(appLogFilterProvider.notifier).toggleLevel(Level.INFO);
      container.read(appLogFilterProvider.notifier).addInclude('world');
      container.read(appLogFilterProvider.notifier).addInclude('timeout');
      final filtered = container.read(filteredAppLogProvider);
      expect(filtered.length, 2);
    });

    test('exclude takes precedence over include', () {
      container.read(appLogFilterProvider.notifier).addInclude('error');
      container.read(appLogFilterProvider.notifier).addExclude('occurred');
      final filtered = container.read(filteredAppLogProvider);
      expect(filtered.length, 0);
    });

    test('clearAll resets all filters including levels', () {
      container.read(appLogFilterProvider.notifier).setSearch('x');
      container.read(appLogFilterProvider.notifier).addExclude('y');
      container.read(appLogFilterProvider.notifier).addInclude('z');
      container.read(appLogFilterProvider.notifier).toggleLevel(Level.INFO);
      container.read(appLogFilterProvider.notifier).clearAll();

      final filter = container.read(appLogFilterProvider);
      expect(filter.searchQuery, '');
      expect(filter.excludePatterns, isEmpty);
      expect(filter.includePatterns, isEmpty);
      expect(filter.selectedLevels, [Level.WARNING, Level.SEVERE, Level.SHOUT]);

      final filtered = container.read(filteredAppLogProvider);
      expect(filtered.length, 2);
    });
  });

  group('AppLogFilterNotifier levels', () {
    test('toggleLevel toggles individual level', () {
      final notifier = container.read(appLogFilterProvider.notifier);
      expect(container.read(appLogFilterProvider).selectedLevels, isNot(contains(Level.INFO)));

      notifier.toggleLevel(Level.INFO);
      expect(container.read(appLogFilterProvider).selectedLevels, contains(Level.INFO));

      notifier.toggleLevel(Level.INFO);
      expect(container.read(appLogFilterProvider).selectedLevels, isNot(contains(Level.INFO)));
    });

    test('toggleLevel on SEVERE toggles both SEVERE and SHOUT', () {
      final notifier = container.read(appLogFilterProvider.notifier);
      expect(
        container.read(appLogFilterProvider).selectedLevels,
        containsAll([Level.SEVERE, Level.SHOUT]),
      );

      notifier.toggleLevel(Level.SEVERE);
      expect(container.read(appLogFilterProvider).selectedLevels, isNot(contains(Level.SEVERE)));
      expect(container.read(appLogFilterProvider).selectedLevels, isNot(contains(Level.SHOUT)));

      notifier.toggleLevel(Level.SEVERE);
      expect(
        container.read(appLogFilterProvider).selectedLevels,
        containsAll([Level.SEVERE, Level.SHOUT]),
      );
    });
  });

  group('AppLogFilterNotifier', () {
    test('addExclude ignores empty and duplicates', () {
      final notifier = container.read(appLogFilterProvider.notifier);
      notifier.addExclude('');
      notifier.addExclude('   ');
      expect(container.read(appLogFilterProvider).excludePatterns, isEmpty);
      notifier.addExclude('foo');
      notifier.addExclude('foo');
      expect(container.read(appLogFilterProvider).excludePatterns, ['foo']);
    });

    test('addInclude ignores empty and duplicates', () {
      final notifier = container.read(appLogFilterProvider.notifier);
      notifier.addInclude('');
      expect(container.read(appLogFilterProvider).includePatterns, isEmpty);
      notifier.addInclude('bar');
      notifier.addInclude('bar');
      expect(container.read(appLogFilterProvider).includePatterns, ['bar']);
    });

    test('removeExclude removes pattern', () {
      container.read(appLogFilterProvider.notifier).addExclude('a');
      container.read(appLogFilterProvider.notifier).addExclude('b');
      container.read(appLogFilterProvider.notifier).removeExclude('a');
      expect(container.read(appLogFilterProvider).excludePatterns, ['b']);
    });

    test('removeInclude removes pattern', () {
      container.read(appLogFilterProvider.notifier).addInclude('x');
      container.read(appLogFilterProvider.notifier).addInclude('y');
      container.read(appLogFilterProvider.notifier).removeInclude('x');
      expect(container.read(appLogFilterProvider).includePatterns, ['y']);
    });
  });
}
