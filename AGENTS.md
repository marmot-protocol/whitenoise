# AGENTS.md

## Project Overview

This is a secure messaging app that uses the [whitenoise Rust crate](https://github.com/marmot-protocol/whitenoise-rs), which implements secure messaging using the [Marmot Protocol](https://github.com/marmot-protocol/marmot) with MLS (Messaging Layer Security) and Nostr.


## Architecture

```text
┌─────────────────────────────────────────────────────────────┐
│                    Flutter UI Layer                         │
│  (screens/, widgets/, hooks/, providers/)                   │
├─────────────────────────────────────────────────────────────┤
│              Flutter-Rust Bridge Layer                      │
│  (lib/src/rust/ - auto-generated bindings)                  │
├─────────────────────────────────────────────────────────────┤
│                    Rust API Layer                           │
│  (rust/src/api/ - thin wrapper around whitenoise)           │
├─────────────────────────────────────────────────────────────┤
│                Whitenoise Rust Crate                        │
│  (external dependency - core messaging logic)               │
└─────────────────────────────────────────────────────────────┘
```

## Tech Stack

- **Flutter/Dart** - UI and application logic
- **Rust** - Core messaging/crypto functionality via FFI
- **flutter_rust_bridge** - Dart-Rust FFI bindings
- **Riverpod** - State management (shared state)
- **flutter_hooks** - Ephemeral widget state
- **go_router** - Navigation/routing

## Directory Structure

```text
whitenoise/
├── lib/                    # Flutter/Dart source code
│   ├── main.dart           # App entry point
│   ├── routes.dart         # Route definitions (go_router)
│   ├── theme.dart          # Theme colors and styles
│   ├── providers/          # Riverpod providers (shared state)
│   ├── hooks/              # Flutter hooks (ephemeral state)
│   ├── screens/            # Full-page UI components
│   ├── widgets/            # Reusable components (see Widget Naming)
│   ├── services/           # Stateless operations (API calls)
│   ├── extensions/         # Dart extensions
│   ├── utils/              # Utility functions
│   ├── constants/          # Shared constants (fixed, related sets or reused elsewhere only)
│   └── src/rust/           # Auto-generated Rust bridge code (DO NOT EDIT)
├── rust/                   # Rust source code
│   └── src/api/            # API modules exposed to Flutter
├── test/                   # Flutter tests (mirrors lib/ structure)
├── trees/                  # Git worktrees for parallel development
├── assets/                 # Images, SVGs, fonts
└── scripts/                # Build/CI scripts
```

Use `constants/` only for fixed, related sets (e.g. NIP kinds) or constants repeated in multiple places; otherwise keep constants next to the code that uses them.

## Setup Commands

```bash
# Install all dependencies
just deps

# Install Flutter dependencies only
just deps-flutter

# Install Rust dependencies only
just deps-rust
```

## Development Commands

```bash
# Format all code (Rust + Dart)
just format

# Lint all code
just lint

# Run all tests (verbose output)
just test-flutter
just test-rust

# Run tests with coverage (99% minimum)
just coverage

# Generate coverage HTML report
just coverage-report

# Pre-commit checks (REQUIRED before every commit)
just precommit

# Pre-commit with verbose output (for debugging failures)
just precommit-verbose

# Regenerate flutter_rust_bridge code
just generate

# Rebuild Android native libraries (after Rust code/dependency changes)
just build-android-quiet
```

## Quiet Commands for Agents

**IMPORTANT:** When verifying that code works, agents should ALWAYS use the quiet variants. These produce minimal output that is easy to parse while still showing errors on failure.

```bash
# Quiet test commands - USE THESE for verification
just test-flutter-quiet    # Output: "+1093: All tests passed!" or error details
just test-rust-quiet       # Output: "....... test result: ok" or error details
just build-android-quiet   # Output: "✅ Android build complete" or error details

# Quiet pre-commit - USE THIS before committing
just precommit             # Shows step names + ✓/✗, errors only on failure
```

**Why quiet variants?**
- Minimal output reduces context window usage
- Clear pass/fail indicators are easy to parse
- Full error details are still shown when something fails
- No noisy progress indicators or dependency resolution messages

**Example quiet precommit output:**

```text
flutter deps...     ✓
rust deps...        ✓
l10n generation...  ✓
l10n validation...  ✓
auto-fix...         ✓
formatting...       ✓
linting...          ✓
flutter tests...    ✓
rust tests...       ✓
✅ PRECOMMIT PASSED
```

## Code Style

### Dart/Flutter

- Single quotes for strings
- `prefer_const_constructors` enabled
- `prefer_final_locals` enabled
- Line width: 100 characters
- Trailing commas: preserve

### Widget Naming

There are three categories of widgets with different naming rules:

1. **Design system widgets** — Simple, presentational widgets that match the Figma design system. They have Widgetbook stories, no translations, and no Rust API calls.
   - File prefixed with `wn_` (e.g., `wn_filled_button.dart`)
   - Class prefixed with `Wn` (e.g., `WnFilledButton`)

2. **Complex reusable widgets** — Used across multiple screens but contain translations, hooks with Rust API calls, or other complex logic.
   - No `wn_`/`Wn` prefix (e.g., `onboarding_carousel.dart` / `OnboardingCarousel`)

3. **Screen-scoped widgets** — Extracted from a single screen for simplicity, only used in that one screen.
   - Prefixed with the screen name (e.g., `ChatListTile` for a widget only used in the chat list screen)

### Hook Naming

- Hook files prefixed with `use_` (e.g., `use_chat_list.dart`)
- Hook functions start with `use` (e.g., `useChatList()`)

### Provider Naming

- Files end with `_provider.dart`
- Provider variables end with `Provider` (e.g., `authProvider`)

### Comments

- DO NOT add comments except for code that is really complex or hard to understand.

### Responsive Sizing with flutter_screenutil

- Use `flutter_screenutil` for all size values to ensure responsive layouts across devices
- Use `.w` for width values, e.g. `20.w`
- Use `.h` for height values, e.g. `16.h`
- Use `.sp` for font size and letter spacing, e.g. `14.sp`
- Use `.r` for radius values, e.g. `8.r`
- Apply to: padding, margins, gaps, icon sizes, font sizes, border radius, container dimensions

### Avoid StatefulWidget

- In line with rules number 6 & 7 below in the [Development philosophy](#development-philosophy), we should avoid the use of StatefulWidgets. Prefer to use providers (shared app-wide state) or hooks (widget-local state) instead.

## Testing

**IMPORTANT: Test coverage is of utmost importance. Never submit a PR that reduces test coverage.**

- Test files mirror source structure with `_test.dart` suffix
- Minimum coverage requirement: 99%
- Use helpers from `test/test_helpers.dart`:
  - `setUpTestView(tester)` - Configure test view dimensions
  - `mountTestApp(tester, overrides)` - Mount full app with provider overrides
  - `mountHook(tester, useHook)` - Test individual hooks
  - `mountWidget(child, tester)` - Mount single widget
  - `mountStackedWidget(child, tester)` - Mount widget in Stack
- Mock Rust API using `RustLib.initMock(api: mockApi)`
- Always extend `MockWnApi` from `test/mocks/mock_wn_api.dart` instead of implementing `RustLibApi` directly - this ensures consistent mock behavior and reuses common mock implementations
- Prefer `find.byKey()` over `find.byIcon()` - add keys to icons in widgets and use `find.byKey(const Key('icon_name'))` in tests
- Use valid 64-char hex strings for pubkeys in tests (see `test_helpers.dart` for examples), not dummy values like `'abc'` or `'test-pubkey'`
- **Avoid `// coverage:ignore`** - Do not use `// coverage:ignore-line`, `// coverage:ignore-start`, or `// coverage:ignore-end` to bypass coverage requirements. Write tests for the code instead. The only acceptable exception is truly unreachable code (e.g., a `default` case in a switch that is exhaustive but required by the compiler).

## Development philosophy

Follow these principles when writing code:

1. **Simplicity over complexity** - Keep the app thin
2. **Test all code** - No untested code
3. **No dead code** - Delete commented/unused code
4. **Whitenoise is source of truth** - Don't duplicate logic from the Rust crate
5. **No caching in Flutter** - Whitenoise persists data in local DB
6. **Shared state in providers** - Use Riverpod for app-wide state
7. **Ephemeral state in hooks** - Use flutter_hooks for widget-local state
8. **Pass data to hooks, not refs** - Hooks receive data, not widget references
9. **Screens watch providers** - Screens observe providers and pass data to hooks
10. **Self-explanatory code** - Avoid comments; write clear, readable code

## State Management Pattern

```text
Screen (watches providers)
    │
    ├── Providers (shared/persistent state)
    │   └── Auth, account pubkey, etc.
    │
    └── Hooks (ephemeral/local state)
        └── Chat list, messages, form inputs, etc.
```

## Rust API Guidelines

- Modules in `rust/src/api/` are exposed to Flutter
- Functions use `#[frb]` attribute for bridge generation
- Structs use `#[frb(non_opaque)]` for Flutter compatibility
- Errors wrapped in `ApiError` enum using `thiserror`
- Files in `lib/src/rust/` are auto-generated - DO NOT EDIT manually

## Fixing Bugs

When I report a bug, don't start by trying to fix it. Instead, start by writing a test that reproduces the bug. Then, have subagents try to fix the bug and prove it with a passing test.
