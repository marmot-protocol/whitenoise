# Bug: New group messages missing after background invite

After an invite is received while the app is backgrounded, the newly created group is never added to the group plane subscription. Messages for that group are only partially received (via inbox giftwraps) and the group plane never picks up its relay-level messages.

**Severity:** Medium. All messages eventually arrive via the inbox giftwrap channel — no permanent message loss. The impact is a timing-dependent UX gap (missing messages on first open) and loss of delivery redundancy (group plane relay path inactive for this group).

## Reproduction

1. Open the app, leave it on the chat list
2. Background the app
3. From another phone, send an invite then send several messages to the new group
4. Reopen the app
5. The invite appears in the chat list
6. Open the chat: most or all messages are missing
7. Send a new message from the other phone: it arrives normally
8. Force-close and reopen the app: all messages now appear

Observed on both Android and iOS. Not reproducible via CLI/TUI (desktop has stable network so the welcome finalization always succeeds).

## Root Cause

`git bisect` identified commit `9c7ea26` — "Cut over long-lived subscriptions to relay planes (#582)".

### The welcome path uses the wrong subscription mechanism

There are two code paths for updating the group plane. The welcome path uses the destructive one.

**Group creation** (groups.rs:340):

```
background_refresh_account_group_subscriptions
  → refresh_account_group_subscriptions_with_cancel (setup.rs:686)
    → extract_group_subscription_specs (reads all active groups from MDK)
    → relay_control.sync_account_group_subscriptions (mod.rs:368)
      → group_plane.update_account(pubkey, specs, since)
```

Only touches the group plane. Inbox subscriptions are untouched. Existing relay connections stay healthy.

**Welcome receive** (handle_giftwrap.rs:421):

```
setup_group_subscriptions
  → whitenoise.refresh_account_subscriptions (setup.rs:861)
    → relay_control.deactivate_account_subscriptions  ← TEARS DOWN EVERYTHING
    → relay_control.activate_account_subscriptions    ← REBUILDS EVERYTHING
```

Tears down BOTH inbox AND group planes, then tries to rebuild both from scratch. This requires fresh relay connections.

### The cascade failure on mobile

When the welcome path runs on mobile after backgrounding:

1. `deactivate_account_subscriptions` (mod.rs:380) removes the inbox plane (disconnects relays), removes the account from the group plane, removes ephemeral scope. The 3 healthy existing groups are gone. The working inbox subscription is gone.

2. `activate_account_subscriptions` (mod.rs:300) tries to rebuild:
   - Saves `previous_group_state` — but it's `None` because step 1 just removed it
   - Updates group plane with new specs (4 groups including the new one)
   - Creates new inbox plane and connects to relays

3. If inbox relay connection fails (likely on mobile — network still recovering):
   - Deactivates the new inbox plane
   - Rolls back group plane. Since `previous_group_state` is `None`, it calls `group_plane.remove_account()`
   - **Result: account has ZERO subscriptions — no inbox, no groups, nothing**

The bug report originally said "the new group is missing from the group plane." The reality is worse: the entire account's subscription state can get wiped — all existing groups AND the inbox.

### Why group creation doesn't have this problem

`sync_account_group_subscriptions` (mod.rs:368) calls `group_plane.update_account()` directly. No teardown, no inbox involvement, no cascade risk. It only touches the group plane.

### Why `ensure_all_subscriptions` recovers the situation (partially)

After the cascade wipe, `ensure_all_subscriptions` (called on app resume from Flutter) detects that the account has no operational subscriptions and triggers a full rebuild. This rebuilds the inbox and group planes from scratch — but by this time, some messages may have already been missed.

### Why app restart shows all messages

On full restart, `setup_subscriptions` rebuilds everything from MDK state. All messages that arrived via giftwrap during the broken window are already in the DB. The fresh initial snapshot includes them.

## Evidence

### Diagnostic logs from reproduction (2026-03-20)

```
16:28    App backgrounds (2 existing chats)
16:41:06 App resumes
16:41:22 Chat list receives newGroup for cf5e9b.. (invite processed)
16:41:49 Chat list receives newLastMessage for cf5e9b..
16:41:50 Chat list receives newLastMessage for cf5e9b..
16:41:51 User opens chat -> initial DB snapshot: count=2
16:42:09 User opens chat again -> initial DB snapshot: count=2 (no change)
```

Only 2 of 7 sent messages made it to the DB at the time the user opened the chat. After force-close and reopen, all 7 messages appear (count=7).

### Relay control state snapshot (taken during reproduction)

Group plane lists 3 groups, **none of which is the newly invited group** `cf5e9b1a620d47a459203ca8de4c016d`:

```json
"group": {
  "group_count": 3,
  "groups": [
    { "group_id": "bb5c64cd...", "subscription_id": "5ae0808c8a85_mls_messages_0" },
    { "group_id": "cd0d4b0d...", "subscription_id": "5ae0808c8a85_mls_messages_0" },
    { "group_id": "fdea5219...", "subscription_id": "5ae0808c8a85_mls_messages_0" }
  ]
}
```

After force-close and reopen, the group plane still does not include the new group. Same 3 groups. All 7 messages arrived via the inbox giftwrap channel.

## Fix

### Primary: Welcome path should use the group creation mechanism

`setup_group_subscriptions` in `handle_giftwrap.rs:400` should call `sync_account_group_subscriptions` (the same path that group creation uses) instead of `refresh_account_subscriptions`. It only needs to add one group to the group plane — there's no reason to tear down and rebuild the entire subscription stack.

### Safety net: Group count parity check

Add a group count parity check to `is_account_subscriptions_operational()`:

1. Count active groups in MDK (`mdk.get_groups()`)
2. Count groups in the group plane
3. If counts differ → return `false` → triggers refresh

This catches any cause of group/plane divergence. The check belongs at the Whitenoise layer (not relay_control) since MDK access is needed.

### Prerequisite: Wire `ensure_all_subscriptions` into app resume

Currently only called from `register_external_signer`. The Flutter app has already added a `WidgetsBindingObserver` that calls `ensureAllSubscriptions()` on `AppLifecycleState.resumed`. Once the parity check is in place, this call becomes the self-healing trigger.

## Key Files

| File | What to look at |
|---|---|
| `src/whitenoise/event_processor/event_handlers/handle_giftwrap.rs:400` | `setup_group_subscriptions` — should use `sync_account_group_subscriptions` instead of `refresh_account_subscriptions` |
| `src/whitenoise/accounts/setup.rs:686` | `refresh_account_group_subscriptions_with_cancel` — the correct group-only path |
| `src/whitenoise/accounts/setup.rs:861` | `refresh_account_subscriptions` — the destructive full-teardown path |
| `src/relay_control/mod.rs:300` | `activate_account_subscriptions` — rollback logic that wipes group plane on failure |
| `src/relay_control/mod.rs:368` | `sync_account_group_subscriptions` — the incremental group-only path |
| `src/relay_control/groups.rs` | `GroupPlane::update_account` — already accepts full set of specs and reconciles |
| `src/whitenoise/mod.rs` | `ensure_all_subscriptions` — needs the parity check addition |
