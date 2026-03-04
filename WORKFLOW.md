# Workflow (Inspect + Vibecode)

## Track A: Inspect
Use Ghostty command palette (`WN:`):

1. `WN: Open Repo`
2. `WN: Bootstrap Widgetbook` (first run / after pulls)
3. `WN: Run Widgetbook` (component/foundation inspection)
4. `WN: Run App On iPhone Air (Staging)` (runtime screen inspection)
5. `WN: Run Inspector (DevTools 9100)`
6. In DevTools: connect to app VM URL, open Flutter Inspector, use Select Widget Mode.

Use cases:
- Widgetbook = isolated components and design system.
- App + Inspector = real screen hierarchy and runtime layout values.

## Track B: Vibecode
1. `WN: Open Repo`
2. Make UI edits
3. `WN: Commit Changes`
4. `WN: Push Branch`

Branch safety:
- Stay on `codex/ui_lab`.
- Push target is `origin/ui_lab`.

## Troubleshooting
- Simulator issue: `WN: Open iPhone Air Simulator`
- iOS build issue: `WN: Build iOS Dependencies`
- Inspector attach issue: rerun `WN: Run Inspector (DevTools 9100)` and reconnect with fresh VM URL
- Behind remote: `WN: Sync Branch`
- Too many processes: `WN: Stop App And Inspector` and/or `WN: Stop Widgetbook And DevTools`
