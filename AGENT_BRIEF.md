# Agent Brief (Whitenoise UI Lab)

## Mission
Support UI inspection and vibecoding for Whitenoise without adding unrelated app features.

## Repo + Branch
- Repo: `/Users/vladimirkrstic/dev/whitenoise-work/repo/whitenoise`
- Local branch: `codex/ui_lab`
- Push target: `origin/ui_lab`

## Primary Goal
- Inspect UI with Flutter DevTools Inspector.
- Apply focused UI tweaks screen-by-screen and component-by-component.

## In Scope
- Spacing, sizing, typography, colors, alignment, layout, visual states.
- Small UX polish directly tied to requested UI work.

## Out of Scope (unless explicitly asked)
- New product features.
- New debug screens/tools in app.
- Backend/data model changes unrelated to UI.

## Hard Rules
1. Work only on `codex/ui_lab`.
2. Push only to `origin/ui_lab`.
3. No force-push.
4. Keep changes minimal and focused.
5. Do not modify unrelated files.

## Required Delivery Flow
1. `git status -sb`
2. Implement requested UI change.
3. Run relevant checks.
4. `git add -A`
5. Commit with clear message.
6. `git push origin HEAD:ui_lab`
7. Summarize files changed + checks run + caveats.
