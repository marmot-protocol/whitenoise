# Justfile for White Noise Flutter project

# Default recipe - show available commands
default:
    @just --list

# Pre-commit checks: run the same checks as CI locally (quiet mode - minimal output)
precommit:
    @just _run-quiet "deps-flutter"    "flutter deps"
    @just _run-quiet "deps-rust"       "rust deps"
    @just _run-quiet "l10n"            "l10n generation"
    @just _run-quiet "validate-locales-keys" "l10n validation"
    @just _run-quiet "fix"             "auto-fix"
    @just _run-quiet "format"          "formatting"
    @just _run-quiet "lint"            "linting"
    @just _run-quiet "test-flutter"    "flutter tests"
    @just _run-quiet "test-rust"       "rust tests"
    @echo "✅ PRECOMMIT PASSED"

# Pre-commit checks with verbose output (shows all command output)
precommit-verbose:
    just deps-flutter
    just deps-rust
    just l10n
    just validate-locales-keys
    just fix
    just format
    just lint
    just test-flutter
    just test-rust
    @echo ""
    @echo "════════════════════════════════════════"
    @echo "✅ ALL PRECOMMIT CHECKS PASSED"
    @echo "════════════════════════════════════════"

# Pre-commit checks without auto-fixing (for releases)
precommit-check:
    just deps-flutter
    just deps-rust
    just l10n-check
    just validate-locales-keys
    just check-rust-format
    just check-dart-format
    just lint
    just test-flutter
    just test-rust
    @echo "✅ All pre-commit checks passed!"

# ==============================================================================
# CODE GENERATION
# ==============================================================================

# Generate Rust bridge code
generate:
    @echo "🔄 Generating flutter_rust_bridge code..."
    @flutter_rust_bridge_codegen generate > /dev/null 2>&1 || flutter_rust_bridge_codegen generate

# Clean and regenerate Rust bridge code
regenerate: clean-bridge generate

# Generate localizations from ARB files
l10n:
    @echo "🌍 Generating localizations..."
    flutter gen-l10n

# Validate l10n files are in sync (fails if regeneration would change anything)
l10n-check:
    @echo "🔍 Checking l10n files are up-to-date..."
    flutter gen-l10n
    @if ! git diff --quiet lib/l10n/generated/; then \
        echo "❌ Generated l10n files are out of sync. Run 'just l10n' and commit."; \
        git diff --name-only lib/l10n/generated/; \
        exit 1; \
    fi
    @echo "✅ L10n files are up-to-date"

# ==============================================================================
# DEPENDENCIES
# ==============================================================================

# Install/update all dependencies
deps: deps-rust deps-flutter

# Install/update Rust dependencies
deps-rust:
    @echo "📦 Installing Rust dependencies..."
    cd rust && cargo fetch

# Install/update Flutter dependencies
deps-flutter:
    @echo "📦 Installing Flutter dependencies..."
    @flutter pub get > /dev/null 2>&1 || flutter pub get
    @cd widgetbook && (flutter pub get > /dev/null 2>&1 || flutter pub get)

# ==============================================================================
# RUST OPERATIONS
# ==============================================================================

# Build Rust library for development (debug)
build-rust-debug:
    @echo "🔨 Building Rust library (debug)..."
    cd rust && cargo build

# Test Rust code
test-rust:
    @echo "🧪 Testing Rust code..."
    cd rust && cargo test

# Test Rust code with minimal output (for agents/CI)
test-rust-quiet:
    @cd rust && cargo test -q

# Format Rust code
format-rust:
    @echo "💅 Formatting Rust code..."
    cd rust && cargo fmt

# Check Rust code formatting (CI-style check)
check-rust-format:
    @echo "🔍 Checking Rust code formatting..."
    cd rust && cargo fmt --check

# Lint Rust code
lint-rust:
    @echo "🧹 Linting Rust code..."
    cd rust && cargo clippy --package rust_lib_whitenoise -- -D warnings

# Run Rust documentation
docs-rust:
    @echo "📚 Generating Rust documentation..."
    cd rust && cargo doc --open

# ==============================================================================
# FLUTTER OPERATIONS
# ==============================================================================

# Run Flutter analyzer
analyze:
    @echo "🔍 Running Flutter analyzer..."
    flutter analyze --fatal-infos
    @echo "🔍 Running Flutter analyzer (widgetbook)..."
    cd widgetbook && flutter analyze --fatal-infos

# Format Dart code
format-dart:
    @echo "💅 Formatting Dart code..."
    dart format lib/ test/ integration_test/ widgetbook/lib/

# Check Dart code formatting (CI-style check)
check-dart-format:
    @echo "🔍 Checking Dart code formatting..."
    dart format --set-exit-if-changed lib/ test/ integration_test/ widgetbook/lib/

# Test Flutter code
test-flutter:
    @echo "🧪 Testing Flutter code..."
    @if [ -d "test" ]; then \
        flutter test --reporter=compact && echo "✅ Flutter tests passed!" || (echo "❌ Flutter tests failed!" && exit 1); \
    else \
        echo "No test directory found. Create tests in test/ directory."; \
    fi

# Test Flutter code with minimal output (for agents/CI)
test-flutter-quiet:
    @if [ -d "test" ]; then \
        flutter test --no-pub --reporter=failures-only; \
    else \
        echo "No test directory found."; \
    fi

# Resolves the integration-test device: the given id, else the one booted iOS simulator or Android device.
_resolve-device device:
    @device="{{ device }}"; \
    if [ -n "$device" ]; then echo "$device"; exit 0; fi; \
    if command -v xcrun >/dev/null 2>&1; then \
        booted=$(xcrun simctl list devices booted 2>/dev/null | grep -oiE '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}'); \
    else \
        booted=""; \
    fi; \
    ios_count=$(printf '%s' "$booted" | grep -c .); \
    if command -v adb >/dev/null 2>&1; then \
        android=$(adb devices 2>/dev/null | awk 'NR>1 && $2=="device" {print $1}'); \
    else \
        android=""; \
    fi; \
    android_count=$(printf '%s' "$android" | grep -c .); \
    total=$((ios_count + android_count)); \
    if [ "$total" -eq 1 ]; then \
        picked="${booted}${android}"; \
        echo "Using device $picked" >&2; \
        echo "$picked"; \
    elif [ "$total" -eq 0 ]; then \
        echo "No device id given and no booted iOS simulator or Android device found. Boot one, pass a device id, or set WHITENOISE_INTEGRATION_DEVICE." >&2; \
        exit 1; \
    else \
        echo "Multiple devices found — pass a device id or set WHITENOISE_INTEGRATION_DEVICE:" >&2; \
        [ -n "$booted" ] && echo "iOS simulators:" >&2 && echo "$booted" >&2; \
        [ -n "$android" ] && echo "Android devices:" >&2 && echo "$android" >&2; \
        exit 1; \
    fi

# Run Flutter integration tests. iOS uses local Nostr relays on ports 8080 and 7777;
# Android auto-uses public relays (emulator can't reach host localhost).

# Run one file by passing its path: `just int-test integration_test/messaging_interactions_test.dart`.
# Device: WHITENOISE_INTEGRATION_DEVICE, else the one booted simulator/emulator.
# Relays: WHITENOISE_INTEGRATION_RELAYS (comma-separated) overrides defaults.
int-test target="integration_test/all_tests.dart" device=env("WHITENOISE_INTEGRATION_DEVICE", "") flavor="staging" relays=env("WHITENOISE_INTEGRATION_RELAYS", ""):
    @echo "🧪 Testing Flutter integration flows..."
    @device=$(just _resolve-device "{{ device }}") || exit 1; \
    relays="{{ relays }}"; \
    if [ -z "$relays" ] && command -v adb >/dev/null 2>&1 && adb devices 2>/dev/null | awk 'NR>1 && $2=="device" {print $1}' | grep -qx "$device"; then \
        relays="wss://nos.lol,wss://relay.primal.net,wss://relay.damus.io"; \
        echo "📡 Android device detected — using public relays: $relays" >&2; \
    fi; \
    define=""; \
    [ -n "$relays" ] && define="--dart-define=WHITENOISE_INTEGRATION_RELAYS=$relays"; \
    if [ -n "{{ flavor }}" ]; then \
        flutter test -d "$device" --flavor {{ flavor }} $define {{ target }}; \
    else \
        flutter test -d "$device" $define {{ target }}; \
    fi

# Run Flutter integration tests with minimal output. Requires local Nostr relays on ports 8080 and 7777.

# Run one file by passing its path: `just int-test-quiet integration_test/messaging_interactions_test.dart`.
# Device: WHITENOISE_INTEGRATION_DEVICE, else the one booted simulator.
int-test-quiet target="integration_test/all_tests.dart" device=env("WHITENOISE_INTEGRATION_DEVICE", "") flavor="staging":
    @if [ ! -e "{{ target }}" ]; then \
        echo "No integration test target found at {{ target }}."; \
        exit 1; \
    fi; \
    device=$(just _resolve-device "{{ device }}") || exit 1; \
    if [ -n "{{ flavor }}" ]; then \
        flutter test -d "$device" --flavor {{ flavor }} --no-pub --reporter=failures-only {{ target }}; \
    else \
        flutter test -d "$device" --no-pub --reporter=failures-only {{ target }}; \
    fi

coverage min="99":
    @echo "🧪 Running Flutter tests with coverage..."
    flutter test --coverage && \
        ./scripts/check-coverage.sh --min {{ min }}

coverage-report:
    @echo "🧪 Generating coverage report..."
    flutter test --coverage && \
    ./scripts/check-coverage.sh && \
    genhtml coverage/lcov.info -o coverage/html
    @echo "📊 Coverage report generated at coverage/html/index.html"

validate-locales-keys:
    @echo "🔍 Validating l10n keys..."
    ./scripts/validate-locales-keys.sh

test-release-scripts:
    @bash test/scripts/validate_release_version_test.sh
    @bash test/scripts/release_automation_config_test.sh

# ==============================================================================
# CLEANING
# ==============================================================================

# Clean generated bridge files only
clean-bridge:
    @echo "🧹 Cleaning generated bridge files..."
    rm -f rust/src/frb_generated.rs
    rm -rf lib/src/rust/

# Clean Flutter build cache
clean-flutter:
    @echo "🧹 Cleaning Flutter build cache..."
    flutter clean

# Clean Rust build cache
clean-rust:
    @echo "🧹 Cleaning Rust build cache..."
    cd rust && cargo clean

# Clean everything (bridge files + flutter + rust)
clean-all: clean-bridge clean-flutter clean-rust
    @echo "✨ All clean!"

# ==============================================================================
# WIDGETBOOK
# ==============================================================================

deps-widgetbook:
    @echo "📦 Installing Widgetbook dependencies..."
    @cd widgetbook && (flutter pub get > /dev/null 2>&1 || flutter pub get)

generate-widgetbook:
    @echo "🔄 Generating Widgetbook stories..."
    cd widgetbook && dart run build_runner build --delete-conflicting-outputs

widgetbook-macos: deps-widgetbook generate-widgetbook
    @echo "📖 Running Widgetbook on macOS..."
    cd widgetbook && flutter run -d macos

widgetbook-linux: deps-widgetbook generate-widgetbook
    @echo "📖 Running Widgetbook on Linux..."
    cd widgetbook && flutter run -d linux

# ==============================================================================
# FORMATTING & LINTING
# ==============================================================================

# Format all code (Rust + Dart)
format: format-rust format-dart

# Lint all code (Rust + Dart)
lint: lint-rust analyze

# Fix common issues
fix:
    @echo "🔧 Fixing common issues..."
    cd rust && cargo fix --allow-dirty
    dart fix --apply

# ==============================================================================
# BUILDING - ANDROID

# ==============================================================================
build-android:
    ./scripts/build_android.sh

build-android-quiet:
    @./scripts/build_android.sh > /dev/null 2>&1 && echo "✅ Android build complete" || { echo "❌ Android build failed"; false; }

# Build per-ABI split APKs (separate .apk per architecture)
build-split-apk flavor="production":
    ./scripts/build_android.sh && flutter build apk --flavor {{ flavor }} --split-per-abi

# Build an Android App Bundle (per-ABI splitting handled by Play Store)
build-aab flavor="production":
    ./scripts/build_android.sh && flutter build appbundle --flavor {{ flavor }}

when-apk: (build-split-apk "staging")

# Build versioned release artifacts for all platforms (APKs + IPA) into build/releases/

# Produces split APKs with .sha256 sidecar files, an IPA (macOS only), and build_info.txt
build-release:
    ./scripts/build_release.sh

# Android-only release artifacts
build-release-android:
    ./scripts/build_release.sh --android

# iOS-only release artifacts (macOS only)
build-release-ios:
    ./scripts/build_release.sh --ios

# ==============================================================================
# RELEASE AUTOMATION
# ==============================================================================

# Validate release version metadata, optionally against a git tag
release-doctor tag="":
    @if [ -n "{{ tag }}" ]; then \
        bundle exec fastlane release_doctor tag:"{{ tag }}"; \
    else \
        bundle exec fastlane release_doctor; \
    fi

# Build staging Android release artifacts with Fastlane
release-build-android-staging tag="":
    @if [ -n "{{ tag }}" ]; then \
        bundle exec fastlane build_android_staging tag:"{{ tag }}"; \
    else \
        bundle exec fastlane build_android_staging; \
    fi

# Build production Android release artifacts with Fastlane
release-build-android-production tag="":
    @if [ -n "{{ tag }}" ]; then \
        bundle exec fastlane build_android_production tag:"{{ tag }}"; \
    else \
        bundle exec fastlane build_android_production; \
    fi

# Build staging iOS IPA for App Store Connect/TestFlight with Fastlane
release-build-ios-staging tag="":
    @if [ -n "{{ tag }}" ]; then \
        bundle exec fastlane build_ios_staging tag:"{{ tag }}"; \
    else \
        bundle exec fastlane build_ios_staging; \
    fi

# Build production iOS IPA for App Store Connect/TestFlight with Fastlane
release-build-ios-production tag="":
    @if [ -n "{{ tag }}" ]; then \
        bundle exec fastlane build_ios_production tag:"{{ tag }}"; \
    else \
        bundle exec fastlane build_ios_production; \
    fi

# Build staging app release artifacts with Fastlane
release-build-staging tag="":
    @if [ -n "{{ tag }}" ]; then \
        bundle exec fastlane build_staging_release tag:"{{ tag }}"; \
    else \
        bundle exec fastlane build_staging_release; \
    fi

# Build production app release artifacts with Fastlane
release-build-production tag="":
    @if [ -n "{{ tag }}" ]; then \
        bundle exec fastlane build_production_release tag:"{{ tag }}"; \
    else \
        bundle exec fastlane build_production_release; \
    fi

# Build staging and production release artifacts with Fastlane
release-build-all tag="":
    @if [ -n "{{ tag }}" ]; then \
        bundle exec fastlane build_all_release_artifacts tag:"{{ tag }}"; \
    else \
        bundle exec fastlane build_all_release_artifacts; \
    fi

# ==============================================================================
# BUILDING - iOS
# ==============================================================================

# Build Rust native libraries for iOS (device + simulator)
build-ios:
    ./scripts/build_ios.sh

# Build Rust native libraries for iOS (quiet, for agents/CI)
build-ios-quiet:
    @./scripts/build_ios.sh > /dev/null 2>&1 && echo "✅ iOS build complete" || { echo "❌ iOS build failed"; false; }

# Build a production IPA for App Store Connect submission
build-production-ipa:
    ./scripts/build_ios.sh && flutter build ipa --flavor production --export-method app-store

# Build a staging IPA for App Store Connect submission
build-staging-ipa:
    ./scripts/build_ios.sh && flutter build ipa --flavor staging --export-method app-store

# Build a staging IPA for local device installation (development signing)
build-staging-ipa-dev:
    ./scripts/build_ios.sh && flutter build ipa --flavor staging --export-method development

# ==============================================================================
# RUN
# ==============================================================================

# Run the app on a connected device (staging flavor by default)
run flavor="staging":
    flutter run --flavor {{ flavor }}

# Run the app on a connected device (production flavor)
run-production:
    flutter run --flavor production

# Build Rust libs and install on connected iOS device
# Usage: just install-ios <device> [flavor] [extra flags]
# Example: just install-ios "JG 16e Test"

# Example: just install-ios "JG 16e Test" production --release
install-ios device flavor="staging" *FLAGS="":
    ./scripts/build_ios.sh && flutter run --flavor {{ flavor }} -d "{{ device }}" {{ FLAGS }}

# ==============================================================================
# HELPER RECIPES
# ==============================================================================

# Run a recipe quietly, showing only name and pass/fail status (internal use)
[private]
_run-quiet recipe label:
    #!/usr/bin/env bash
    TMPFILE=$(mktemp)
    trap 'rm -f "$TMPFILE"' EXIT
    printf "%-20s" "{{ label }}..."
    if just {{ recipe }} > "$TMPFILE" 2>&1; then
        echo "✓"
    else
        echo "✗"
        echo ""
        cat "$TMPFILE"
        exit 1
    fi
