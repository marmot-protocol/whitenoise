# Code Review: PR #517 — Start Chat Flow Improvements

## Summary

This PR improves the start-chat UX in several meaningful ways: the loading skeleton for `StartChatScreen` now shows the user avatar immediately while the key-package check runs; metadata is fetched freshly rather than passed through router `extra`; "Chat with support" moves from the search screen to settings; and the app-logs screen gains level-filter toggles. Performance timing is added throughout using a new `logDuration` utility. The changes are well-structured and test coverage is solid. There are a handful of issues worth addressing before merging, mostly around a subtle semantic inconsistency in the filtered-count display and a dead `AnimatedOpacity`.

---

## Issues

### Logic: `hasFilters` doesn't account for level filtering — filtered count never shows for level-only filters

**`lib/screens/app_logs_screen.dart:105–108`**

```dart
final hasFilters =
    filter.searchQuery.isNotEmpty ||
    filter.includePatterns.isNotEmpty ||
    filter.excludePatterns.isNotEmpty;
```

`hasFilters` drives the "showing X of Y" count label. The PR adds level-filter toggles that actively hide entries, but since level selection isn't included in `hasFilters`, when the user filters by level only, the count text never appears — they get no feedback that entries are being hidden.

The fix is straightforward:

```dart
final defaultLevels = {Level.WARNING, Level.SEVERE, Level.SHOUT};
final hasFilters =
    filter.searchQuery.isNotEmpty ||
    filter.includePatterns.isNotEmpty ||
    filter.excludePatterns.isNotEmpty ||
    !defaultLevels.containsAll(filter.selectedLevels) ||
    filter.selectedLevels.length != defaultLevels.length;
```

Or simpler: expose an `isDefaultLevels` getter on `AppLogFilterState`.

---

### Bug: `AnimatedOpacity` with hardcoded `opacity: 1` is a no-op

**`lib/screens/start_chat_screen.dart` (inside `isKeyPackageLoading` branch)**

```dart
AnimatedOpacity(
  opacity: 1,
  duration: const Duration(milliseconds: 200),
  child: CircularProgressIndicator(...),
),
```

The opacity is permanently `1` and never changes — `AnimatedOpacity` has no effect here. The widget goes from not existing (when not loading) to existing at full opacity. Either:
- Remove `AnimatedOpacity` and use a plain widget (current behavior, simpler), or
- Animate it properly by tracking an opacity state variable that starts at 0 and transitions to 1.

This is pure noise in the widget tree as written.

---

### Semantic inconsistency: `totalEntries` in app logs screen now counts pre-level-filter entries

**`lib/screens/app_logs_screen.dart:74–76`**

```dart
final rawEntries = paused.value ? frozenRawEntries.value : liveRawEntries;
final entries = applyFilter(rawEntries);
final totalEntries = rawEntries.length;
```

`totalEntries` is used in the "X of Y" filtered count label. Previously it was `liveRawEntries.length` (always live). Now it's `rawEntries.length`, which is correct for the paused case, but the label now reads as "X of Y" where Y is raw-unfiltered-by-level entries, even when INFO is toggled on and increases entry count. The filtered-count label intends to show "how many entries match your text/pattern search out of how many are visible given your log level", but `totalEntries` is still the fully unfiltered count. This is a mild inconsistency — consider whether `totalEntries` should be post-level-filter.

---

### Behavior change: `followState.isLoading` added to the button loading indicator

**`lib/screens/start_chat_screen.dart` (inside `validActionsColumn`)**

```dart
loading: showLoadingStates && (followState.isLoading || followState.isActionLoading),
```

The old code only showed loading on `followState.isActionLoading`. Adding `followState.isLoading` means the follow button spins during the initial data fetch — which could feel jarring if the fetch is fast (a spinner flash). Confirm this is intentional. If `followState.isLoading` means "initial fetch is in progress", the button probably shouldn't exist at all yet, or should be disabled, rather than showing a spinner.

---

### Missing test: settings screen "Chat with support" doesn't test the `isLoading` guard

**`test/screens/settings_screen_test.dart`**

The new `WnMenuItem` in `SettingsScreen` has an early-return guard:

```dart
onTap: () {
  if (helpState.isLoading) return;
  ...
}
```

There's no test for the loading state scenario — i.e., that tapping while `helpState.isLoading` is true does nothing and doesn't navigate. This is a covered branch in the code but untested.

---

## Suggestions

### Style: Inconsistent naming — `stopWatch` vs `sw`

Performance is instrumented in `use_start_dm.dart`, `use_user_has_key_package.dart`, and `start_chat_screen.dart` using `stopWatch`, while `user_service.dart` uses `sw`. Pick one convention and apply it consistently. Given the project emphasises self-documenting code, `stopwatch` (or `sw` uniformly) is fine — just keep it consistent.

---

### Style: Inner function `validActionsColumn` defined in `build`

**`lib/screens/start_chat_screen.dart:101`**

```dart
Widget validActionsColumn({bool showLoadingStates = true}) { ... }
```

Defining `Widget`-returning functions inside `build` is a pattern the Flutter team discounts — it bypasses element diffing and rebuilds the entire subtree unconditionally. Prefer extracting as a private `StatelessWidget` (screen-scoped, named `_StartChatActionsColumn` per AGENTS.md convention). The `showLoadingStates` flag and the data it needs can be constructor params.

---

### Style: `calloutTitleAndDescription` is also a build-scoped function

**`lib/screens/start_chat_screen.dart`**

Same concern as above — `calloutTitleAndDescription()` is a local function that returns a record. It's only called once. Extract it or inline it; the current indirection adds a layer without clarity.

---

### Suggestion: `logDuration` threshold (50ms) is hardcoded and undocumented

**`lib/utils/logging.dart:3`**

```dart
void logDuration(Logger logger, String message, int milliseconds) {
  if (milliseconds >= 50) {
    logger.warning('$message ${milliseconds}ms');
  }
```

The 50ms threshold is arbitrary and has no comment explaining why. Either name it as a constant (`_slowThresholdMs`) or add a brief comment. Also: the function doesn't accept an optional threshold, so callers can't tune it for fast vs slow operations. Not blocking, but the magic number will prompt questions later.

---

### Suggestion: `use_start_dm.dart` — stopwatch isn't reset before `createGroup`, total and create times overlap

**`lib/hooks/use_start_dm.dart:51`**

```dart
final createGroupStopWatch = Stopwatch()..start();
final group = await groups_api.createGroup(...);
logDuration(_logger, 'createGroup took', createGroupStopWatch.elapsedMilliseconds);
logDuration(_logger, 'Total DM creation', totalStopWatch.elapsedMilliseconds);
```

This is fine — two stopwatches, one measures createGroup only, one is the end-to-end total. The naming (`totalStopWatch` vs `createGroupStopWatch`) is clear. Minor note: `createGroupStopWatch` is never stopped before reading; Dart stopwatch semantics make this correct, but it's worth a comment to signal intent.

---

### Suggestion: `use_user_search.dart` — `follows` variable can be removed

**`lib/hooks/use_user_search.dart:87–105`**

```dart
() async {
  final stopWatch = Stopwatch()..start();
  try {
    final follows = await accounts_api.accountFollows(pubkey: accountPubkey);
    return follows;
  } finally {
    logDuration(...);
  }
},
```

`follows` can be returned directly: `return accounts_api.accountFollows(...)`. The intermediate variable serves no purpose.

---

### Design: Duplicate level-filter logic in screen vs provider

**`lib/screens/app_logs_screen.dart:48–74`** and **`lib/providers/app_log_filter_provider.dart`**

`AppLogsScreen` re-implements level filtering in its local `applyFilter` function, which mirrors the logic already in `filteredAppLogProvider`. The screen already watches `filteredAppLogProvider` indirectly through `filter` — but it applies the filter again on the raw entries for the paused state. This duplication means any future change to filter logic needs to be applied in two places. Consider whether `frozenRawEntries` could be filtered through the same provider mechanism, or extract the filter logic into a standalone function both can call.

---

## What's Done Well

- **The loading-skeleton UX approach is clever.** Using `Visibility(maintainSize: true)` to hold space for buttons while showing a spinner prevents layout jank without the complexity of explicit size constraints. The test that validates this (`keeps button layout stable while key package loads`) directly verifies the intent.

- **`useSupportChat` null-pubkey guard is clean.** Changing `accountPubkey` to `String?` and short-circuiting with `Future.value()` is idiomatic and eliminates a crash path. The test covers it.

- **`logDuration` utility is a good abstraction.** A small, single-responsibility utility tested with clear threshold boundaries (`>=50ms` → warning, `<50ms` → info). No over-engineering.

- **Removing `initialMetadata` from `StartChatScreen`** simplifies the component contract. The old pattern of passing stale router `extra` metadata then overwriting it with fresh data was a source of bugs (noted in the PR description). Removing it and always fetching fresh is the right call.

- **Test updates are thorough.** Tests for the `use_chat_profile` blocking-metadata fallback, the `use_support_chat` null-pubkey case, and the level-toggle provider behaviour all represent genuine regression coverage, not just padding.

- **Moving "Chat with support" to Settings** is a good UX decision. The search screen is for finding people; putting a support shortcut there was conceptually out of place.
