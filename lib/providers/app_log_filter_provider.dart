import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/providers/app_log_provider.dart';

class AppLogFilterState {
  const AppLogFilterState({
    this.searchQuery = '',
    this.includePatterns = const [],
    this.excludePatterns = const [],
    this.selectedLevels = const [Level.WARNING, Level.SEVERE, Level.SHOUT],
  });

  final String searchQuery;
  final List<String> includePatterns;
  final List<String> excludePatterns;
  final List<Level> selectedLevels;

  AppLogFilterState copyWith({
    String? searchQuery,
    List<String>? includePatterns,
    List<String>? excludePatterns,
    List<Level>? selectedLevels,
  }) => AppLogFilterState(
    searchQuery: searchQuery ?? this.searchQuery,
    includePatterns: includePatterns ?? this.includePatterns,
    excludePatterns: excludePatterns ?? this.excludePatterns,
    selectedLevels: selectedLevels ?? this.selectedLevels,
  );
}

class AppLogFilterNotifier extends Notifier<AppLogFilterState> {
  @override
  AppLogFilterState build() => const AppLogFilterState();

  void setSearch(String query) => state = state.copyWith(searchQuery: query);

  void toggleLevel(Level level) {
    final newLevels = Set<Level>.from(state.selectedLevels);
    final levelsToToggle = level == Level.SEVERE ? [Level.SEVERE, Level.SHOUT] : [level];

    final isSelected = newLevels.contains(level);

    for (final l in levelsToToggle) {
      if (isSelected) {
        newLevels.remove(l);
      } else {
        newLevels.add(l);
      }
    }
    state = state.copyWith(selectedLevels: newLevels.toList());
  }

  void addInclude(String pattern) {
    final trimmed = pattern.trim();
    if (trimmed.isEmpty) return;
    if (state.includePatterns.contains(trimmed)) return;
    state = state.copyWith(
      includePatterns: [...state.includePatterns, trimmed],
    );
  }

  void removeInclude(String pattern) => state = state.copyWith(
    includePatterns: state.includePatterns.where((p) => p != pattern).toList(),
  );

  void addExclude(String pattern) {
    final trimmed = pattern.trim();
    if (trimmed.isEmpty) return;
    if (state.excludePatterns.contains(trimmed)) return;
    state = state.copyWith(
      excludePatterns: [...state.excludePatterns, trimmed],
    );
  }

  void removeExclude(String pattern) => state = state.copyWith(
    excludePatterns: state.excludePatterns.where((p) => p != pattern).toList(),
  );

  void clearAll() => state = const AppLogFilterState();
}

final appLogFilterProvider = NotifierProvider<AppLogFilterNotifier, AppLogFilterState>(
  AppLogFilterNotifier.new,
);

String _entryText(AppLogEntry e) {
  final buf = StringBuffer();
  buf.write('${e.level.name} ${e.loggerName} ${e.message}');
  if (e.error != null) buf.write(' ${e.error}');
  if (e.stackTrace != null) buf.write(' ${e.stackTrace}');
  return buf.toString().toLowerCase();
}

bool _matches(String text, String pattern) => text.contains(pattern.toLowerCase());

final filteredAppLogProvider = Provider<List<AppLogEntry>>((ref) {
  final entries = ref.watch(appLogProvider);
  final filter = ref.watch(appLogFilterProvider);

  final levelFiltered = entries.where((e) => filter.selectedLevels.contains(e.level));

  if (filter.searchQuery.isEmpty &&
      filter.includePatterns.isEmpty &&
      filter.excludePatterns.isEmpty) {
    return levelFiltered.toList();
  }

  return levelFiltered.where((e) {
    final text = _entryText(e);

    if (filter.excludePatterns.any((p) => _matches(text, p))) return false;
    if (filter.includePatterns.isNotEmpty &&
        !filter.includePatterns.any((p) => _matches(text, p))) {
      return false;
    }
    if (filter.searchQuery.isNotEmpty && !_matches(text, filter.searchQuery)) {
      return false;
    }
    return true;
  }).toList();
});
