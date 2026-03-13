# Tunnel Inspection: zapstore-release (local changes)

## The Lay of the Land

This dig adds an in-app update banner that fetches the latest release version from the Zapstore relay (Nostr kind-32267) and surfaces it to the user on the chat list screen via a new `useZapstoreUpdate` hook and a `fetchLatestZapstoreVersion` Rust API call. The overall architecture is clean and follows established patterns well — the hook is thin, the Rust layer is focused, and the prioritization logic (update banner beats welcome notice) is clear. There are a few fault lines worth addressing before this opens to colony traffic.

---

## Hazards 🚫

### Testing: Mock API pattern violation in hook test

**`test/hooks/use_zapstore_update_test.dart`:18**

```dart
class _MockApi implements RustLibApi {
  ...
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
```

`AGENTS.md` is explicit: *"Always extend `MockWnApi` from `test/mocks/mock_wn_api.dart` instead of implementing `RustLibApi` directly."* This test rolls its own `_MockApi implements RustLibApi` instead of extending `MockWnApi`. That means `MockWnApi` itself is never updated to handle `crateApiZapstoreFetchLatestZapstoreVersion`, so any future test that mounts a widget calling this method via the shared mock will get an `UnimplementedError` thrown synchronously — currently silently swallowed by `useFuture`, but a ticking trap for the next digger.

Fix: extend `MockWnApi`, add `crateApiZapstoreFetchLatestZapstoreVersion` to `MockWnApi` with a sensible default (return `null`), and override it in the test as needed.

---

### Testing: Update banner UI path has zero widget-test coverage

**`test/screens/chat_list_screen_test.dart` (no relevant lines)**

The `chat_list_screen_test.dart` has no tests for the new update banner: no test that it appears when a newer version is available, no test that it is prioritised over the welcome notice, no test that dismissing it works, no test that tapping "Update now" fires the right action. The hook itself is covered, but the wiring into the screen — the `_buildSystemNotice` priority logic, the `isDismissed` short-circuit on line 220, the `ValueKey` keying — is untested at the screen level. Per the project's testing philosophy: *"Test all code — no untested code."*

Fix: add a group `'update banner'` to `chat_list_screen_test.dart`. You'll need to add `crateApiZapstoreFetchLatestZapstoreVersion` to `MockWnApi` (see above) and override it in `_MockApi` to return a newer version string. Cover at minimum: banner appears with newer version, banner dismissed hides it, banner priority over welcome notice.

---

### Correctness: `launchUrl` return value silently ignored

**`lib/screens/chat_list_screen.dart`:111**

```dart
onPressed: () => launchUrl(
  Uri.parse(_zapstoreUrl),
  mode: LaunchMode.externalApplication,
),
```

`launchUrl` returns `Future<bool>` — `false` means the URL could not be launched (no handler, sandboxed env, etc.). The result is discarded: the user taps "Update now" and nothing happens, with no feedback. On some platforms (particularly iOS when the zapstore app isn't installed) this silently fails.

Fix: await the result and show an error notice via the existing `notice.showErrorNotice` mechanism when `launchUrl` returns `false`, or at minimum add `unawaited(...)` from `dart:async` with a comment explaining the intentional no-op. Silently ignoring a bool return that signals failure is a real hazard, not a style nit.

---

## Suggestions 🪨

### Rust: Redundant double-timeout in `fetch_latest_zapstore_version`

**`rust/src/api/zapstore.rs`:38-48**

```rust
let events = tokio::time::timeout(
    Duration::from_secs(FETCH_TIMEOUT_SECS),
    client.fetch_events(filter, Duration::from_secs(FETCH_TIMEOUT_SECS)),
)
```

`client.fetch_events` already accepts an internal timeout `Duration`. Wrapping that in a `tokio::time::timeout` with the same duration adds no protection: if the inner `fetch_events` timeout fires and returns normally, the outer never triggers; if `fetch_events` hangs past its own timeout for some reason, the outer adds an additional 10s delay before the user notices. The outer `tokio::time::timeout` was likely added defensively, but with identical durations it only adds complexity. Consider removing the outer wrapper and trusting `fetch_events`'s built-in timeout, or — if you genuinely distrust it — set the outer to a shorter guard (e.g., `FETCH_TIMEOUT_SECS + 2`).

---

### Rust: `a`-tag identifier not validated during version extraction

**`rust/src/api/zapstore.rs`:69-81**

```rust
.find_map(|coord| {
    let parts: Vec<&str> = coord.splitn(3, ':').collect();
    if parts.first() == Some(&"30063") {
        parts.get(2).and_then(|id_at_ver| {
            id_at_ver.split_once('@').map(|(_, version)| version.to_string())
        })
    } else {
        None
    }
})
```

The relay filter already constrains the event to the correct author and identifier, which makes this low-risk in practice. But the `a`-tag parsing extracts the version from *any* kind-30063 `a` tag without checking whether the identifier segment (`org.parres.whitenoise`) matches `ZAPSTORE_APP_IDENTIFIER`. If the app event ever gains multiple `a` tags pointing to releases for different apps, the first 30063 match wins — and that might be the wrong one. A one-line guard before extracting the version would make the intent explicit and the code self-documenting:

```rust
id_at_ver.split_once('@').and_then(|(ident, version)| {
    if ident == ZAPSTORE_APP_IDENTIFIER { Some(version.to_string()) } else { None }
})
```

---

### Dart: `useZapstoreUpdate` errors swallowed without logging

**`lib/hooks/use_zapstore_update.dart`:17-20**

```dart
final snapshot = useFuture(future);
return (
  availableVersion: snapshot.data,
  ...
```

When the Zapstore relay is unreachable or returns an error, `snapshot.hasError` is true but `snapshot.data` is `null`. The hook silently returns `null` and the banner doesn't appear — which is the correct user-facing behaviour. But the error is never logged, making it invisible during debugging. Consider adding a `useEffect` that logs `snapshot.error` at debug level when it's non-null. This costs nothing in production and saves future diggers significant time.

---

### Dart: `_buildSystemNotice` is an instance method rebuilding on every `build`

**`lib/screens/chat_list_screen.dart`:85**

```dart
WnSystemNotice? _buildSystemNotice(
  BuildContext context,
  AppTypography typography,
  SemanticColors colors, { ... }
) {
```

This is a non-`const` instance method on a `HookConsumerWidget` that is called on every `build`. It's not expensive (no allocations beyond widget construction), and Flutter rebuilds are cheap, so this isn't a performance hazard. But as a private helper that only uses its arguments (no `this` state), it would be clearer as a top-level or `static` function — consistent with `_buildWelcomeDescription` which has the same shape and the same issue. Not blocking, but worth noting for read consistency.

---

## Solid Work ✅

**The Rust layer is well-structured.** `zapstore.rs` is focused, the constants are clearly named, the error mapping is consistent with the rest of the API surface, and the relay connection lifecycle (connect → fetch → disconnect) is properly bounded. The doc comment accurately describes the event structure queried.

**The version comparison logic is correct and well-tested.** `_isNewer` handles CalVer segments properly, degrades gracefully on non-numeric segments, and the test file covers the key cases: loading, exact match, older Zapstore, newer Zapstore, null from relay, error, and cross-year/minor/patch boundary bumps. That's thorough work.

**The hook's return type is clean.** Returning a named record `({String? availableVersion, bool isDismissed, void Function() dismiss})` keeps the API surface explicit and easy to consume without a separate state class.

**The `_buildSystemNotice` extraction is a genuine improvement.** The old inline `WnSystemNotice` in `build()` was already long; pulling it into a named method and adding the update-vs-welcome priority logic in one place is cleaner than it was before. The `ValueKey('update_notice_$updateVersion')` keying means Flutter correctly animates between different update versions rather than reusing a stale widget.

**All 8 languages got the new strings.** No language was left with missing keys, and the translations look idiomatic (not literal word-for-word).

**The `url_launcher` dependency promotion is correct.** Promoting it from transitive to direct main is the right call when it's now used explicitly in application code.
