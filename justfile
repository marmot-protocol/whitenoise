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
    flutter_rust_bridge_codegen generate

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
    dart format lib/ test/ widgetbook/lib/

# Check Dart code formatting (CI-style check)
check-dart-format:
    @echo "🔍 Checking Dart code formatting..."
    dart format --set-exit-if-changed lib/ test/ widgetbook/lib/

# Test Flutter code
test-flutter:
    @echo "🧪 Testing Flutter code..."
    @if [ -d "test" ]; then \
        flutter test --reporter=compact --dart-define=APP_FLAVOR=staging && echo "✅ Flutter tests passed!" || (echo "❌ Flutter tests failed!" && exit 1); \
    else \
        echo "No test directory found. Create tests in test/ directory."; \
    fi

# Test Flutter code with minimal output (for agents/CI)
test-flutter-quiet:
    @if [ -d "test" ]; then \
        flutter test --no-pub --reporter=failures-only --dart-define=APP_FLAVOR=staging; \
    else \
        echo "No test directory found."; \
    fi


coverage min="99":
    @echo "🧪 Running Flutter tests with coverage..."
    flutter test --coverage --dart-define=APP_FLAVOR=staging && \
        ./scripts/check-coverage.sh --min {{min}}

coverage-report:
  @echo "🧪 Generating coverage report..."
  flutter test --coverage --dart-define=APP_FLAVOR=staging && \
  ./scripts/check-coverage.sh && \
  genhtml coverage/lcov.info -o coverage/html
  @echo "📊 Coverage report generated at coverage/html/index.html"

validate-locales-keys:
    @echo "🔍 Validating l10n keys..."
    ./scripts/validate-locales-keys.sh

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

build-android-apk flavor:
    ./scripts/build_android.sh && flutter build apk --flavor {{flavor}} --dart-define=APP_FLAVOR={{flavor}}

# Build a fat APK (all ABIs in one file)
build-production-apk:
    ./scripts/build_android.sh && flutter build apk --flavor production --dart-define=APP_FLAVOR=production

build-staging-apk:
    ./scripts/build_android.sh && flutter build apk --flavor staging --dart-define=APP_FLAVOR=staging

# Build per-ABI split APKs (separate .apk per architecture)
build-split-apk flavor="production":
    ./scripts/build_android.sh && flutter build apk --flavor {{flavor}} --split-per-abi --dart-define=APP_FLAVOR={{flavor}}

# Build an Android App Bundle (per-ABI splitting handled by Play Store)
build-aab flavor="production":
    ./scripts/build_android.sh && flutter build appbundle --flavor {{flavor}} --dart-define=APP_FLAVOR={{flavor}}

# Release builds
build-release-apk: (build-split-apk "production")
build-release-aab: (build-aab "production")

when-apk: build-staging-apk

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
    ./scripts/build_ios.sh && flutter build ipa --flavor production --export-method app-store --dart-define=APP_FLAVOR=production

# Build a staging IPA for App Store Connect submission
build-staging-ipa:
    ./scripts/build_ios.sh && flutter build ipa --flavor staging --export-method app-store --dart-define=APP_FLAVOR=staging

# Build a staging IPA for local device installation (development signing)
build-staging-ipa-dev:
    ./scripts/build_ios.sh && flutter build ipa --flavor staging --export-method development --dart-define=APP_FLAVOR=staging

# ==============================================================================
# RUN
# ==============================================================================

# Run the app on a connected device (staging flavor by default)
run flavor="staging":
    flutter run --flavor {{flavor}} --dart-define=APP_FLAVOR={{flavor}}

# Run the app on a connected device (production flavor)
run-production:
    flutter run --flavor production --dart-define=APP_FLAVOR=production

# Build Rust libs and install on connected iOS device
# Usage: just install-ios <device> [flavor] [extra flags]
# Example: just install-ios "JG 16e Test"
# Example: just install-ios "JG 16e Test" production --release
install-ios device flavor="staging" *FLAGS="":
    ./scripts/build_ios.sh && flutter run --flavor {{flavor}} --dart-define=APP_FLAVOR={{flavor}} -d "{{device}}" {{FLAGS}}
# ==============================================================================
# HELPER RECIPES
# ==============================================================================

# Run a recipe quietly, showing only name and pass/fail status (internal use)
[private]
_run-quiet recipe label:
    #!/usr/bin/env bash
    TMPFILE=$(mktemp)
    trap 'rm -f "$TMPFILE"' EXIT
    printf "%-20s" "{{label}}..."
    if just {{recipe}} > "$TMPFILE" 2>&1; then
        echo "✓"
    else
        echo "✗"
        echo ""
        cat "$TMPFILE"
        exit 1
    fi
