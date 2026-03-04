#!/bin/bash

# Build script for iOS targets
set -euo pipefail

echo "🚀 Building Rust library for iOS targets..."

# Build mode: all (default), simulator, or device
BUILD_MODE="${1:-all}"
case "$BUILD_MODE" in
  all|simulator|device) ;;
  *)
    echo "❌ Invalid build mode: $BUILD_MODE" >&2
    echo "Usage: ./scripts/build_ios.sh [all|simulator|device]" >&2
    exit 1
    ;;
esac

# Keep Rust iOS min version aligned with Xcode project settings.
IOS_DEPLOYMENT_TARGET="${IOS_DEPLOYMENT_TARGET:-13.0}"
export IPHONEOS_DEPLOYMENT_TARGET="$IOS_DEPLOYMENT_TARGET"

# Function to print colored output
print_step() {
  echo -e "\n\033[1;34m=== $1 ===\033[0m"
}

print_success() {
  echo -e "\033[1;32m✅ $1\033[0m"
}

print_error() {
  echo -e "\033[1;31m❌ $1\033[0m"
}

# Check if required tools are installed
print_step "Checking development environment"
if ! command -v rustup &>/dev/null; then
  print_error "Rustup is not installed or not in PATH"
  exit 1
fi

if ! command -v cargo &>/dev/null; then
  print_error "Cargo is not installed or not in PATH"
  exit 1
fi

if ! command -v xcodebuild &>/dev/null; then
  print_error "Xcode command line tools are not installed"
  exit 1
fi

if ! command -v pod &>/dev/null; then
  print_error "CocoaPods is not installed or not in PATH"
  exit 1
fi

if ! command -v flutter &>/dev/null; then
  print_error "Flutter is not installed or not in PATH"
  exit 1
fi

print_step "Using iOS deployment target ${IPHONEOS_DEPLOYMENT_TARGET}"

# Add required iOS Rust targets
print_step "Adding iOS targets to Rust"
if [ "$BUILD_MODE" = "all" ] || [ "$BUILD_MODE" = "device" ]; then
  rustup target add aarch64-apple-ios
fi
if [ "$BUILD_MODE" = "all" ] || [ "$BUILD_MODE" = "simulator" ]; then
  rustup target add aarch64-apple-ios-sim
fi
print_success "Required iOS Rust targets added"

# Build selected iOS architectures
print_step "Building for selected iOS architectures"
if ! test -d "rust"; then
  print_error "rust directory not found"
  exit 1
fi
cd rust

if [ "$BUILD_MODE" = "all" ] || [ "$BUILD_MODE" = "device" ]; then
  print_step "Building for aarch64-apple-ios (physical devices)"
  cargo build --target aarch64-apple-ios --release --quiet
  print_success "Built for aarch64-apple-ios"
fi

if [ "$BUILD_MODE" = "all" ] || [ "$BUILD_MODE" = "simulator" ]; then
  print_step "Building for aarch64-apple-ios-sim (simulator)"
  cargo build --target aarch64-apple-ios-sim --release --quiet
  print_success "Built for aarch64-apple-ios-sim"
fi

cd ..

# Refresh Flutter-generated iOS settings.
print_step "Refreshing Flutter iOS config"
flutter pub get >/dev/null

# Guard against stale absolute paths in Generated.xcconfig.
GENERATED_XCCONFIG="ios/Flutter/Generated.xcconfig"
if [ -f "$GENERATED_XCCONFIG" ]; then
  APP_PATH="$(pwd -P)"
  TMP_XCCONFIG="${GENERATED_XCCONFIG}.tmp"
  awk -v flutter_root="$FLUTTER_ROOT" -v app_path="$APP_PATH" '
    BEGIN { found_root=0; found_app=0 }
    /^FLUTTER_ROOT=/ { print "FLUTTER_ROOT=" flutter_root; found_root=1; next }
    /^FLUTTER_APPLICATION_PATH=/ { print "FLUTTER_APPLICATION_PATH=" app_path; found_app=1; next }
    { print }
    END {
      if (!found_root) print "FLUTTER_ROOT=" flutter_root
      if (!found_app) print "FLUTTER_APPLICATION_PATH=" app_path
    }
  ' "$GENERATED_XCCONFIG" > "$TMP_XCCONFIG"
  mv "$TMP_XCCONFIG" "$GENERATED_XCCONFIG"
fi

# Run pod install to ensure pods are up to date
print_step "Installing CocoaPods dependencies"
pushd ios >/dev/null || {
  print_error "Failed to enter ios directory"
  exit 1
}
if ! pod install --silent; then
  print_error "pod install failed"
  popd >/dev/null
  exit 1
fi
popd >/dev/null

print_success "iOS Rust build completed successfully (mode: ${BUILD_MODE})"
print_success "You can now run 'flutter build ios' or 'flutter run' to test the app on iOS"
