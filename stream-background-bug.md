# Stream Background Bug

Scratchpad for tracking the investigation, findings, and fixes for the background stream issue.

---

## Problem

After the app goes to background and returns to foreground, streams between Rust and Dart stop delivering events. Observed on both Android and iOS.

## Root Cause (Bisected)

`git bisect` on whitenoise-rs identified commit `9c7ea26` — "Cut over long-lived subscriptions to relay planes (#582)".

This commit replaced the old single-`Client` `nostr_manager` with a multi-session relay plane architecture. Each plane (discovery, account inbox, group, ephemeral) now has its own `Client` instance with independent relay connections and notification handlers.

**Why this breaks background:** The old architecture had ONE set of relay connections. nostr-sdk's auto-reconnect restored them reliably on resume. The new architecture has MULTIPLE independent `Client` instances, each needing to reconnect independently. This makes recovery after background more fragile — if any session's relay connections or notification handler fails to recover, events for that plane's subscriptions stop flowing.

**Why CLI doesn't reproduce:** Desktop never has network suspension. The CLI's `dispatch_streaming()` subscribes to the same broadcast channels and works fine because relay connections never die.

**The missing link:** `ensure_all_subscriptions()` was built in the same commit as a recovery mechanism — it checks if each plane's subscriptions are operational and refreshes broken ones. It's exposed to Flutter via FRB as `ensureAllSubscriptions()`. But it was never wired up to be called on app resume.

## What We've Tried

### Investigation (2026-03-20)

1. Analyzed all commits from `d8332b15` to `HEAD` on master
2. Cleared the Dart SDK, FRB StreamSink delivery path, and flutter_foreground_task as causes
3. Verified FRB streams survive normal background/foreground (traced `useStream` → `ReceivePort` → `Dart_PostCObject` end-to-end)
4. Analyzed whitenoise-rs crate changes: notification handler backoff, pending relay fix, orphaned subscriptions, inbox drain fix
5. Confirmed broadcast channel architecture is sound (buffer=100, auto-cleanup, lazy creation)
6. `git bisect` identified `9c7ea26` as the introducing commit

### Diagnostic Changes (Flutter app)

Added lifecycle logging to `use_chat_list.dart` and `use_chat_messages.dart`:

- `useOnAppLifecycleStateChange` logs transitions with `secsSinceLastEvent`
- `lastEventAt` ref timestamps each stream event
- Enabled `hierarchicalLoggingEnabled` in `main.dart` for `useChatList`, `useChatMessages`, and `WnApp` loggers (root level is WARNING, these are set to INFO)

### Fix Attempt: Wire up `ensureAllSubscriptions()` on resume

Added `WidgetsBindingObserver` to `_WnAppState` in `main.dart`:

- On `AppLifecycleState.resumed`, calls `relays_api.ensureAllSubscriptions()`
- This checks all relay planes and refreshes any broken subscriptions
- Logs success/failure via `_logger`

## Files Modified (Flutter app)

- `lib/main.dart` — Added `WidgetsBindingObserver`, `ensureAllSubscriptions()` on resume, hierarchical logging
- `lib/hooks/use_chat_list.dart` — Added lifecycle logging + lastEventAt tracking
- `lib/hooks/use_chat_messages.dart` — Added lifecycle logging + lastEventAt tracking

## What to Test

1. Build with `just when-apk`, install on device
2. Open app, navigate to a chat
3. Background the app for 30-60 seconds
4. Send a message from another device while backgrounded
5. Bring app to foreground
6. Check: does the message appear? How quickly?
7. Check logs (in-app log viewer) for:
   - `LIFECYCLE` entries showing background/resume transitions
   - `App resumed, ensuring relay subscriptions are operational`
   - `Relay subscriptions ensured after resume`
   - Any `stream DONE` entries (would indicate stream death)

## What to Try Next (if fix doesn't work)

- Add `refreshKey` to `useChatMessages` and bump it on resume (forces fresh snapshot from local DB)
- Investigate whether the multi-Client architecture causes relay rate limiting on reconnection
- Check if nostr-sdk's auto-reconnect behaves differently with multiple Client instances
- Add `notification_handler_restart_count` and `current_backoff_secs` to the relay state snapshot for visibility

## For the whitenoise-rs Team

The `ensure_all_subscriptions()` method is the designed recovery mechanism but was never called by any consumer. If the fix works, consider:

1. Whether `ensure_all_subscriptions()` should be called automatically on some trigger (e.g., after detecting relay reconnections)
2. Whether the notification handler restart with backoff (1s → 30s cap) needs a reset-on-demand mechanism for app resume scenarios
3. Whether the multi-Client architecture could share a single relay pool to reduce connection count on mobile
4. Adding `receiver_count()` for each stream manager to the debug snapshot so consumers can verify broadcast health

Key whitenoise-rs files:

- `src/relay_control/sessions/session.rs` — notification handler, subscribe_with_id_to, router context management
- `src/relay_control/mod.rs` — relay control plane, ensure_account_subscriptions
- `src/relay_control/router.rs` — event routing by (relay_url, subscription_id) → context
- `src/whitenoise/mod.rs` — ensure_all_subscriptions, setup_subscriptions
- `src/whitenoise/event_processor/mod.rs` — event routing by EventSource
