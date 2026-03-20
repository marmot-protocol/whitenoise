# Background Stream Bug Investigation

**Date:** 2026-03-20
**Branch:** `investigate-background-bug`
**Scope:** Commits `d8332b15` through `HEAD` on `master`

---

## Problem

Streams between Rust (via flutter_rust_bridge) and Dart stop working or behave incorrectly after the app goes to background and returns to foreground. Observed on both Android and iOS.

---

## Investigation Summary

Analyzed the full dependency and code change surface between the last known-good state and current `master`. The investigation covered:

- Flutter SDK upgrade (3.38.4 → 3.41.4) and Dart SDK (3.10.3 → 3.11.1)
- Riverpod/hooks_riverpod upgrade (3.2.1 → 3.3.1)
- flutter_foreground_task (9.2.0 → 9.2.1)
- flutter_local_notifications (20.1.0 → 21.0.0)
- Three whitenoise-rs crate bumps
- All application code changes in the commit range

---

## Findings by Layer

### 1. Dart SDK: Cleared

`stream_impl.dart` and `stream_controller.dart` are byte-identical between Dart 3.10.3 and 3.11.1. The `Dart_PostCObject` / `NativePort` API that FRB uses for Rust-to-Dart communication is unchanged. Three GC thread-safety fixes landed (data race in `SemiSpace::Contains`, growth policy safepoint, service zone null check) — these are more likely to help than hurt.

**Verdict:** Not the cause.

### 2. FRB StreamSink Delivery Path: Cleared

FRB 2.11.1 (unchanged across the commit range) uses this delivery chain:

```
Rust tokio thread → StreamSink::add() → SSE encode → allo-isolate::Isolate::post()
  → Dart_PostCObject(port_id, msg)     [C FFI, thread-safe, callable from any thread]
    → Dart isolate message queue
      → ReceivePort → listenAndBuffer() → Stream<T>
```

`Dart_PostCObject` posts from tokio worker threads, not from Flutter's UI or platform thread. The Flutter thread merge (PR [#174408](https://github.com/flutter/flutter/pull/174408)) only merged the UI and platform threads — tokio threads were never involved. Messages enqueue successfully even when the app is backgrounded; they queue up and deliver on resume.

**Verdict:** Not the cause. The delivery mechanism is orthogonal to Flutter's threading model.

### 3. Flutter 3.38.4 → 3.41.4: Contributing Factor

The Flutter SDK upgrade spans two major stable releases (no 3.39 or 3.40 exist in stable). Key changes:

| Change                          | PR/Issue                                                                                                                                                                        | Impact                                                                                                                                                                  |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Thread merge opt-out removed    | [#174408](https://github.com/flutter/flutter/pull/174408)                                                                                                                       | UI and platform threads permanently merged on iOS and Android. Changes execution context for platform channel callbacks and frame scheduling.                           |
| iOS UIScene lifecycle migration | [#174910](https://github.com/flutter/flutter/pull/174910), [#175866](https://github.com/flutter/flutter/pull/175866), [#176240](https://github.com/flutter/flutter/pull/176240) | App lifecycle events delivered via `UISceneDelegate` instead of `UIApplicationDelegate`. Plugin registration deferred to `didInitializeImplicitFlutterEngine`.          |
| iOS lifecycle crash fix         | [#182361](https://github.com/flutter/flutter/issues/182361)                                                                                                                     | `NSGenericException` in `FlutterPluginAppLifeCycleDelegate` during lifecycle callbacks. Fixed in 3.41.4 (the target version).                                           |
| Android Activity memory leak    | [#177121](https://github.com/flutter/flutter/pull/177121), [#173770](https://github.com/flutter/flutter/issues/173770)                                                          | Since Flutter 3.29: `StreamHandler.onCancel` not called when Activity destroyed by OS. Stream listeners could leak across Activity recreation. Cherry-picked to 3.38.x. |
| Granular frame forcing          | [#173862](https://github.com/flutter/flutter/pull/173862)                                                                                                                       | Refactored `SchedulerBinding` behavior for `AppLifecycleState.hidden`. Stream-driven UI updates could stall during background transitions.                              |

The iOS scene-based lifecycle is visible in commit `d8332b15` itself — `AppDelegate.swift` was migrated to `FlutterImplicitEngineDelegate` and `Info.plist` gained `UIApplicationSceneManifest`. This changes the timing of engine initialization and lifecycle event delivery. However, since the bug is on both platforms, the iOS-specific changes alone are insufficient to explain it.

**Verdict:** The Flutter engine changes altered background/foreground lifecycle timing on both platforms. This is a contributing factor that likely exposed a pre-existing vulnerability.

### 4. Riverpod 3.2.1 → 3.3.1 (commit b79681f9): Low Impact

The core `riverpod` package stays at 3.2.1. The 3.3.x wrapper changes add `ChangeNotifierProvider.disposeNotifier` — irrelevant to this app's stream patterns.

The riverpod 3.2.x line (already present before this commit range) introduced TickerMode-based provider pausing (PR [#4377](https://github.com/rrousselGit/riverpod/pull/4377)): when a widget is navigated away from, `ref.watch` subscriptions are paused. The 3.2.1 flush fix (PR [#4679](https://github.com/rrousselGit/riverpod/pull/4679)) ensures providers recompute on resume.

**This only affects `ref.watch`/`ref.listen` subscriptions. Hooks like `useMemoized` are not managed by riverpod's pause/resume mechanism.**

Open issue [#4709](https://github.com/rrousselGit/riverpod/issues/4709): TickerMode + chained provider mutation can trigger assertion errors — worth monitoring if chained providers are in use.

**Verdict:** Not the primary cause, but the pause/resume mechanism adds complexity to the lifecycle story.

### 5. flutter_foreground_task 9.2.0 → 9.2.1: Cleared

Single Android-only fix: guards a `lateinit` property access in `ForegroundService.onDestroy()`. Prevents `UninitializedPropertyAccessException` when Android kills the service before `onStartCommand()` runs. No Dart code, no iOS code, no stream changes.

**Verdict:** Not the cause. Crash prevention only.

### 6. Hook Stream Lifecycle: Pre-existing Architectural Gap

All FRB stream consumers lack app lifecycle handling. Verified against source:

| Hook              | File                                       | Pattern                                                 | Manual Refresh            | Lifecycle-Aware | Stream Death Detection                                                                |
| ----------------- | ------------------------------------------ | ------------------------------------------------------- | ------------------------- | --------------- | ------------------------------------------------------------------------------------- |
| `useChatList`     | `lib/hooks/use_chat_list.dart`             | `useMemoized([pubkey, refreshKey.value])` + `useStream` | Yes (`refreshKey`)        | No              | Basic (`connectionState == waiting`)                                                  |
| `useChatMessages` | `lib/hooks/use_chat_messages.dart`         | `useMemoized([groupId])` + `useStream`                  | **No**                    | No              | Good (`useEffect` tracks state changes, logs transitions)                             |
| `useUserSearch`   | `lib/hooks/use_user_search.dart`           | `useEffect` + manual `.listen()`                        | Periodic (5s for follows) | No              | Via `onError`/`onDone` callbacks                                                      |
| `useAppLogs`      | `lib/hooks/use_app_logs.dart`              | `useEffect(const [])` + `.listen()`                     | **No**                    | No              | Via `onDone` callback, `cancelOnError: false`                                         |
| Notifications     | `lib/providers/notification_provider.dart` | `Provider.autoDispose` + `.listen()`                    | **No**                    | No              | Via `onDone` callback. **Android-only** (line 32: `if (!Platform.isAndroid) return;`) |

Key findings from source verification:

- Only `useChatList` has a `refreshKey` mechanism — but it's **never triggered automatically** on resume. It's exposed as a manual `refresh()` callback.
- `useChatMessages` has **no refreshKey and no reconnection**. Its dependency is `[groupId]` only. Stream recreates only when `groupId` changes.
- `useChatMessages` has the best death detection: a `useEffect` monitors `snapshot.connectionState`, `hasData`, `hasError` and logs transitions. But it takes no recovery action.
- The notification listener is **completely absent on iOS** — `notificationListenerProvider` returns immediately if `!Platform.isAndroid`.
- Only `use_active_chat.dart` and `wn_scan_box.dart` use `useOnAppLifecycleStateChange`, and neither manages data streams.

**Verdict:** The streams assume connections stay alive indefinitely. No hook has automatic reconnection on resume. `useChatMessages` is the most vulnerable — no refresh mechanism at all.

### 7. "The Great Relay Restoration" (commit 2dd6a1ca): High Impact

This commit restructured relay handling:

- **Removed** `use_network_relays.dart` entirely, including its `isMountedRef` cleanup pattern and relay status polling
- **Changed** group creation from dynamic relay fetching to hardcoded `GROUP_CREATION_RELAY_URLS`
- **Added** `ChatListUpdateTrigger::ChatArchiveChanged` to the chat list stream
- **Added** message pagination to `fetch_aggregated_messages_for_group()`

The removal of relay status monitoring means the app no longer actively tracks relay connection state. If relays disconnect while backgrounded, there is no visibility into this.

**Verdict:** Significant restructuring of the relay layer. Could affect stream source reliability.

### 8. whitenoise-rs Crate Changes (aa2aafe1 → 809aa004)

The three crate bumps plus the relay restoration commit span 28 commits in whitenoise-rs. Six are directly relevant to stream behavior:

#### 8a. Relay Control Refactor — Warm Ephemeral Sessions (8a4ee4c4, PR #600)

Massive architectural change to relay session management:

- **New `RelaySessionState`** with `publish_lock: Mutex<()>` serializing all publishes and `subscription_relays: RwLock<HashMap>` tracking relay-to-subscription mappings
- **New `EphemeralExecutor`** caching sessions per scope (per-account + anonymous) instead of spawning per operation. Tracks pinned relays with ref-counting and ad-hoc relays with TTL.
- **New `prepare_relay_urls()`** replaces `ensure_relays_connected()` — partitions relays into usable vs failed, filters failed relays from queries/publishes instead of failing the entire operation
- **Per-session telemetry** broadcast receivers prevent cross-session interference

This changes the fundamental relay lifecycle model. Sessions are now long-lived and cached rather than ephemeral per-operation.

#### 8b. Group Subscription Structure Fix (e32f04aa, PR #597)

Refactored from single subscription per account (relays × group_ids) to per-relay-set subscriptions. Groups on different relays now get separate subscriptions with distinct indices. Previously, collapsed subscriptions could cause broadcast channel saturation or missed group messages.

#### 8c. TOCTOU Race and Orphaned Subscriptions (118e34b7, PR #594)

Two fixes:

1. `compute_global_since_timestamp()` re-queried accounts from DB, creating a race where logout could delete accounts between queries. Fixed by accepting `&[Account]` from caller.
2. `refresh_global_subscription_for_user` bypassed the empty-account guard, leaving orphaned discovery subscriptions that receive events but have no handlers — **silent event loss**.

#### 8d. Reconnect Pending Relays (afd911f0, PR #619)

Relays in `RelayStatus::Pending` state were stuck permanently — `relay.connect()` was a no-op because `can_connect()` returns false for Pending. Fix: disconnect first (transitions to Terminated), then connect (spawns fresh connection). Without this, relays could permanently stop delivering data.

#### 8e. Notification Handler Exponential Backoff (f6c4c89e, PR #645)

**Directly relevant to background behavior.** The notification handler is the long-lived task routing relay events to subscription streams. Previously used fixed 1-second restart delay. Now uses exponential backoff (1s → 2s → 4s → ... → 30s cap), resetting only after 30+ seconds of successful runtime.

Without backoff, rapid restarts during transient errors created tight loops with brief notification processing blackouts. High CPU usage from restart loops could trigger OS background process kills.

#### 8f. Early Return from Relay Setup (42269bb1, PR #636)

`prepare_relay_urls()` now accepts `min_connected_relays: Option<usize>`. Set to `Some(2)` for AccountInboxPlane, DiscoveryPlane, GroupPlane, and EphemeralExecutor sessions.

Startup no longer waits for all relays to connect — if 2 of N relays connect, setup proceeds immediately. Remaining relays connect in background with nostr-sdk auto-resubscribe. **This could cause subscriptions to start before all relays are ready**, potentially missing events from late-connecting relays.

#### 8g. Inbox Plane Drain Fix (c9d4b8a1, PR #646)

Changed `shutdown_all` from repeated read/write lock cycles per plane to a single write lock that drains all planes atomically, then deactivates sequentially. Prevents deadlock during concurrent stream deactivation.

### 9. Broadcast Channel Architecture

All stream managers use broadcast channels with **buffer size 100**:

| Stream        | Storage                                  | Lifecycle                   | Cleanup                                   |
| ------------- | ---------------------------------------- | --------------------------- | ----------------------------------------- |
| Chat List     | `DashMap<PublicKey, Sender>` per account | Lazy on first `subscribe()` | Auto-remove when `receiver_count() == 0`  |
| Messages      | `DashMap<GroupId, Sender>` per group     | Lazy on first `subscribe()` | Auto-remove when `receiver_count() == 0`  |
| Notifications | Single global `Sender`                   | Created once at init        | Never removed, skips emit if no receivers |
| User Search   | Local per-search                         | Fresh each search           | Dropped with search                       |

**Critical behavior:** When `send()` returns `Err` (all receivers dropped), chat list and message managers atomically remove the sender from the DashMap. On next `subscribe()`, a new channel is created. **Events emitted between cleanup and re-subscribe are lost** — there is no replay buffer beyond the initial snapshot.

**No channel restart mechanism exists.** Channels are created once and persist until all receivers drop. There is no reconnection or health-check protocol between the broadcast layer and Flutter.

---

## Root Cause Analysis

### Critical Correction: Streams Do NOT Die During Normal Background

Tracing the actual code paths end-to-end, the FRB stream mechanism is robust across normal background/foreground transitions. Here is the verified execution path:

1. **Widget stays mounted** during background (Android with foreground service, iOS with process suspension). `useStream`'s `_StreamHookState` keeps its `StreamSubscription` active. The subscription is only cancelled in `dispose()` (widget unmount) or `didUpdateHook()` (stream object identity changes). Neither happens during normal background.

2. **ReceivePort stays open.** FRB's `RustStreamSink._setup()` creates a `ReceivePort` wrapped in an `async*` generator, consumed by `listenAndBuffer()` which creates a `StreamController(sync: true)` that eagerly subscribes. The ReceivePort is only closed when the subscription is cancelled (via `onCancel = subscription.cancel` → generator exits → `finally { receivePort.close() }`). Since the subscription stays active, the port stays open.

3. **Rust tokio task keeps running.** The `loop { rx.recv().await ... sink.add(item) }` runs on tokio worker threads, independent of Flutter's thread model. `sink.add()` calls `Dart_PostCObject(port_id, msg)` which is non-blocking and thread-safe — it enqueues into the Dart isolate's message queue and returns `true` as long as the port is open (which it is).

4. **Broadcast channel does NOT lag.** The Rust FRB task consumes events from the broadcast channel as fast as they arrive (no bottleneck — `Dart_PostCObject` is non-blocking). Buffer overflow (Lagged) only occurs if 100+ events arrive before the FRB task can consume them, which is effectively impossible given non-blocking send.

5. **On resume, messages deliver.** The Dart event loop resumes and processes all queued messages from the isolate queue. Events flow through `ReceivePort` → `async*` generator → `listenAndBuffer` → `useStream` listener → widget rebuild.

**The stream layer itself works correctly. The previous analysis incorrectly focused on stream lifecycle as the primary issue.**

### The Actual Problem: Event Source Starvation

The streams are alive but **nothing is flowing through them** because the relay connections die during background:

1. **App goes to background** → OS suspends process (iOS) or throttles threads (Android)
2. **Relay WebSocket connections die** — TCP keepalives fail, server timeouts, network interface changes (WiFi↔cellular)
3. **No relay events arrive** → event processor has nothing to process → broadcast channels have nothing to emit → FRB stream task blocks on `rx.recv().await` indefinitely
4. **Stream appears frozen** — UI shows stale data, `snapshot.connectionState` stays `active` (not `done`), no errors
5. **App returns to foreground** → nostr-sdk auto-reconnect kicks in → relays reconnect → subscriptions re-established
6. **Notification handler may need to restart** — if it crashed during the disconnection, exponential backoff (1s → 2s → 4s → ... → 30s cap) delays event routing. This is the handler that routes `RelayPoolNotification` events to the event processor.
7. **Events eventually resume** — but the gap between resume and first event could be 5-30+ seconds depending on relay reconnection time and notification handler state.

### Why This Appears Worse After the Commits

Several changes in the commit range widened the starvation window:

1. **Notification handler exponential backoff** (f6c4c89e) — Previously retried every 1s. Now backs off to 30s max. If the handler crashes on resume (stale relay state), recovery takes longer.

2. **min_connected_relays=2 early return** (42269bb1) — After resume, `prepare_relay_urls()` proceeds as soon as 2 relays reconnect. Events from slower relays arrive late.

3. **iOS UIScene lifecycle** (d8332b15) — Scene-based lifecycle may deliver background/foreground transitions with different timing, potentially causing relay connections to drop more aggressively.

4. **Long-lived cached sessions** (8a4ee4c4) — Sessions persist across background. If their relay state becomes stale, they may not immediately detect that reconnection is needed.

### What Hooks Should Do (But Don't)

The streams don't die, but the UI shows stale data during the reconnection gap. The fix isn't "restart the stream" (it's alive) — it's "refresh the data." On `AppLifecycleState.resumed`:

- **Bump `refreshKey`** → `useMemoized` creates a new FRB stream → new subscription → **fresh initial snapshot from local database** → immediate data refresh
- This works because `subscribe_to_chat_list()` and `subscribe_to_group_messages()` read the initial snapshot from the **local SQLite database**, not from relays. Even when relays are disconnected, the DB has the most recent locally-known state.
- The old stream's Rust task exits cleanly (ReceivePort closes → `Dart_PostCObject` returns false → loop breaks). The new stream picks up live events once relays reconnect.

### Edge Case: Android Activity Destruction

Under memory pressure or "Don't keep activities," Android destroys the Activity. The entire Dart isolate dies and is recreated. In this case:

- All streams are destroyed and recreated from scratch on resume
- Fresh initial snapshots from DB provide current state — **this recovers correctly**
- The only gap is notifications: `NotificationSubscription` has no initial snapshot, so notifications during the dead window are lost. But the underlying messages are still in the DB and visible in chat.

This is a clean recovery path, not a bug. The "normal background" (stale data with live stream) is the problematic case.

---

## Recommended Next Steps

### Immediate: Confirm the Hypothesis

1. **Check existing logs on a real device.** `useChatMessages` already logs `snapshot.connectionState` transitions (lines 154-187). After background/resume, check:
   - Does `connectionState` transition to `done`? → Stream died (unexpected — investigate why)
   - Does `connectionState` stay `active` but no new events arrive? → **Confirms event source starvation** (relay disconnection)
   - How long between resume and first stream event? → Measures the reconnection gap
2. **Log relay connection events.** Add tracing to `prepare_relay_urls()` to log relay status on resume — how many relays are connected, how long reconnection takes.
3. **Log notification handler state.** Track when the handler crashes and restarts, and the current backoff delay. This reveals whether the handler's 30s max backoff is contributing to the gap.

### Short-term: Fix Data Freshness on Resume

1. **Add `refreshKey` to `useChatMessages`** — it currently has `[groupId]` as the only dependency. `useChatList` already has this pattern.
2. **Add `useOnAppLifecycleStateChange` to stream hooks** — on `AppLifecycleState.resumed`, bump `refreshKey`. This re-subscribes the stream, giving a **fresh initial snapshot from the local database** — immediate data refresh independent of relay state. The old Rust task exits cleanly; the new one picks up live events as relays reconnect.
3. **Consider debouncing.** Quick background→foreground cycles (e.g., switching apps briefly) shouldn't force a full re-subscribe. Only refresh if the app was backgrounded for more than a few seconds.

### Medium-term: Reduce the Reconnection Gap

1. **Review notification handler backoff for background recovery.** The 30s max backoff makes sense for persistent errors, but after app resume there's a good chance the network just came back. Consider resetting backoff to 1s when the app returns to foreground (signal from Flutter → Rust).
2. **Surface relay health to Flutter** — replace the removed `use_network_relays` with a lightweight health signal from the Rust layer so the UI can show connectivity status during reconnection.
3. **Evaluate notification handler's crash conditions after background.** If the handler reliably crashes on resume because of stale session state, fixing the crash is better than optimizing the backoff.
4. **Consider pre-emptive relay reconnection on resume.** Before waiting for nostr-sdk auto-reconnect, explicitly trigger reconnection from the Flutter lifecycle callback via a bridge function.

---

## Commits Analyzed

| Commit     | Description                                  | Stream Impact                                  |
| ---------- | -------------------------------------------- | ---------------------------------------------- |
| `d8332b15` | Flutter 3.38→3.41, Dart 3.10→3.11, dep bumps | High (engine lifecycle changes)                |
| `c330ff47` | Fix debug log view                           | None                                           |
| `d2400d78` | Eliminate N+1 query in useGroups             | None                                           |
| `3f04b9a1` | UI Polish: Login Screen                      | None                                           |
| `fb6d69a5` | Fix self profile start chat guard            | None                                           |
| `bd713850` | Implement NIP-C7 reply threading             | None                                           |
| `c924e6eb` | Deleted messages bubbles                     | None                                           |
| `2dd6a1ca` | The great relay restoration                  | High (relay restructuring)                     |
| `03696d57` | Debug and relay screen improvements          | Low                                            |
| `c3f7142e` | Error screen for bridge init failure         | Moderate (init timing)                         |
| `3d12bd56` | Bump flutter_svg                             | None                                           |
| `62048e5a` | Bump flutter_local_notifications 20→21       | Low                                            |
| `b2078826` | UI Polish: Slate & Settings                  | None                                           |
| `2bfec517` | Bug report screen with NIP-44                | None                                           |
| `9d34297b` | Update rust crate (→ afd911f0)               | High (pending relay fix, notification backoff) |
| `c798b997` | Chat with support                            | Low                                            |
| `b79681f9` | Riverpod 3.2→3.3, hooks_riverpod 3.2→3.3     | Low                                            |
| `a48f45b6` | Update rust crate (→ 6239aa58)               | Moderate (security caps, init perf)            |
| `4c4971a0` | Update rust crate (→ 809aa004)               | Moderate (inbox drain deadlock fix)            |
| `6baf93b1` | Fix translations                             | None                                           |
| `127ab1d9` | Fix deleted bubbles style                    | None                                           |
| `a82efb0a` | Start chat flow improvements                 | Moderate (blocking sync fallback)              |

---

## References

- Flutter thread merge: [PR #174408](https://github.com/flutter/flutter/pull/174408), [Issue #150525](https://github.com/flutter/flutter/issues/150525)
- iOS UIScene migration: [Breaking change docs](https://docs.flutter.dev/release/breaking-changes/uiscenedelegate)
- iOS lifecycle crash: [Issue #182361](https://github.com/flutter/flutter/issues/182361)
- Android Activity memory leak: [PR #177121](https://github.com/flutter/flutter/pull/177121), [Issue #173770](https://github.com/flutter/flutter/issues/173770)
- Riverpod flush fix: [PR #4679](https://github.com/rrousselGit/riverpod/pull/4679), [Issue #4669](https://github.com/rrousselGit/riverpod/issues/4669)
- Riverpod TickerMode change: [PR #4377](https://github.com/rrousselGit/riverpod/pull/4377)
- FRB StreamSink source: `flutter_rust_bridge-2.11.1/src/stream/stream_sink.rs`
- allo-isolate Dart_PostCObject: `allo-isolate-0.1.27/src/lib.rs`
- whitenoise-rs relay refactor: PR #600 (8a4ee4c4)
- whitenoise-rs group subscription fix: PR #597 (e32f04aa)
- whitenoise-rs TOCTOU race fix: PR #594 (118e34b7)
- whitenoise-rs pending relay fix: PR #619 (afd911f0)
- whitenoise-rs notification backoff: PR #645 (f6c4c89e)
- whitenoise-rs init performance: PR #636 (42269bb1)
- whitenoise-rs inbox drain fix: PR #646 (c9d4b8a1)
- Broadcast channel managers: `whitenoise-rs/src/whitenoise/{chat_list,message,notification}_streaming/manager.rs`

---

## Validation Log

All claims in this report verified against actual source code on 2026-03-20.

### Broadcast Channel Managers (whitenoise-rs) — All Confirmed

- `chat_list_streaming/manager.rs`: buffer=100, DashMap, lazy `or_insert_with`, auto-cleanup via `remove_if(|_, s| s.receiver_count() == 0)`
- `message_streaming/manager.rs`: identical pattern to chat list, DashMap per GroupId
- `notification_streaming/manager.rs`: single global sender, buffer=100, `has_subscribers()` check before emit, never removed
- `user_search/types.rs`: `SEARCH_CHANNEL_BUFFER_SIZE = 100`

### Dart Hook Patterns — Corrected from Initial Claims

- `use_chat_list.dart`: Confirmed `useMemoized([pubkey, refreshKey.value])` + `useStream`. Has `refreshKey` (line 16).
- `use_chat_messages.dart`: Confirmed `useMemoized([groupId])` + `useStream`. **No refreshKey.** Has `useEffect` monitoring connection state (lines 154-187). Has `StreamTransformer` logging stream done (lines 64-73).
- `use_user_search.dart`: Uses `useEffect` + manual `.listen()` for search streams, `useMemoized` + `useFuture` for follows. Not `useMemoized` + `useStream` as initially reported.
- `use_app_logs.dart`: Uses `useEffect(const [])` + `.listen()`. Not `useMemoized`. One-time setup.
- `notification_provider.dart`: `Provider.autoDispose` + `.listen()`. **Android-only** (line 32: `if (!Platform.isAndroid) return;`). Has `ref.mounted` checks and `onDone`/`onError` callbacks.

### Rust Stream Functions — All Confirmed

- All five functions use `loop { match rx.recv().await { ... } }` pattern
- All exit on `sink.add().is_err()` (sink closed) or `RecvError::Closed` (channel closed)
- All return `Ok(())` after loop exit
- `Lagged` handling: `continue` everywhere. `subscribe_to_group_messages` logs a warning; others are silent.
- `subscribe_to_rust_logs` is different: file-tail with 200ms polling, not broadcast channel

### Whitenoise-rs Subscribe Methods — Confirmed

- `subscribe_to_chat_list` and `subscribe_to_group_messages`: race-free snapshot via `subscribe()` → fetch → `try_recv()` drain loop → merge
- `subscribe_to_notifications`: returns `NotificationSubscription { updates }` only — **no initial snapshot**

### Relay Infrastructure — All Confirmed

- Notification handler backoff: 1s → 2s → 4s → 8s → 16s → 30s cap, resets after 30s successful runtime
- `min_connected_relays=2` set on AccountInboxPlane, DiscoveryPlane, GroupPlane, EphemeralExecutor
- Pending relay fix: `disconnect()` then `connect()` pattern, tested
- Orphaned subscription fix: `compute_global_since_timestamp` accepts `&[Account]`, empty-accounts guard present

### Stream Lifecycle During Background — Corrected Understanding

- **Streams survive normal background/foreground.** Verified by tracing: `useStream` → `_StreamHookState._subscription` stays active → `listenAndBuffer` stays subscribed → `ReceivePort` stays open → `Dart_PostCObject` succeeds → Rust loop keeps running.
- `useStream` subscription is only cancelled in `dispose()` (widget unmount) or `didUpdateHook()` (stream identity changes). Neither occurs during normal background.
- `listenAndBuffer()` (async package `StreamExtensions`) eagerly subscribes via `StreamController(sync: true)` and forwards `onCancel` to the upstream subscription. Only cancels when the downstream listener cancels.
- `Dart_PostCObject` is non-blocking — it enqueues into the isolate message queue and returns immediately. The Rust broadcast channel does NOT lag because the FRB task consumes at full speed.
- **The previous "broadcast channel buffer overflow" scenario is incorrect.** Lagging cannot occur from Dart being slow — the Rust FRB task is the consumer and it's never blocked.
