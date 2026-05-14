#!/bin/bash

# Build script for iOS targets
set -e # Exit on any error

echo "🚀 Building Rust library for iOS targets..."

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

without_bundler_env() {
  env \
    -u BUNDLE_BIN_PATH \
    -u BUNDLE_GEMFILE \
    -u BUNDLE_PATH \
    -u BUNDLER_VERSION \
    -u BUNDLER_SETUP \
    -u RUBYOPT \
    "$@"
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

# Fetch the Rust wrapper source from whitenoise-rs at the pinned rev (see
# scripts/build_android.sh for context — same mechanism, same cache).
print_step "Fetching whitenoise-rs source"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

# Soft-warn if .whitenoise-rs-rev lags upstream master (informational only).
"$SCRIPT_DIR/check_frb_rev_freshness.sh"

# Catch FRB rev drift between pubspec orphan-ref and .whitenoise-rs-rev before
# wasting a full cross-compile (would otherwise fail the hash check at startup).
"$SCRIPT_DIR/check_frb_revs.sh"
WHITENOISE_RS_CACHE="$PROJECT_ROOT/.whitenoise-rs-cache/whitenoise-rs"
WHITENOISE_RS_URL="https://github.com/marmot-protocol/whitenoise-rs.git"
REV_FILE="$PROJECT_ROOT/.whitenoise-rs-rev"
if [ ! -f "$REV_FILE" ]; then
  print_error ".whitenoise-rs-rev is missing at $REV_FILE"
  exit 1
fi
WHITENOISE_RS_REV="$(tr -d '[:space:]' <"$REV_FILE")"

if [ -z "$WHITENOISE_RS_REV" ]; then
  print_error ".whitenoise-rs-rev is empty"
  exit 1
fi

if [ ! -d "$WHITENOISE_RS_CACHE/.git" ]; then
  mkdir -p "$(dirname "$WHITENOISE_RS_CACHE")"
  git clone --quiet --filter=blob:none --no-checkout "$WHITENOISE_RS_URL" "$WHITENOISE_RS_CACHE"
fi

(
  cd "$WHITENOISE_RS_CACHE"
  if ! git cat-file -e "${WHITENOISE_RS_REV}^{commit}" 2>/dev/null; then
    git fetch --quiet --filter=blob:none origin "$WHITENOISE_RS_REV"
  fi
  git -c advice.detachedHead=false checkout --quiet --force "$WHITENOISE_RS_REV"
)
print_success "whitenoise-rs checked out at $WHITENOISE_RS_REV"

WHITENOISE_FRB_DIR="$WHITENOISE_RS_CACHE/crates/whitenoise-frb"

IOS_DEPLOYMENT_TARGET="${IOS_DEPLOYMENT_TARGET:-13.0}"
export IPHONEOS_DEPLOYMENT_TARGET="$IOS_DEPLOYMENT_TARGET"
print_step "Using iOS deployment target $IPHONEOS_DEPLOYMENT_TARGET"

# Build for each iOS architecture
print_step "Building for iOS architectures"
cd "$WHITENOISE_FRB_DIR"


print_step "Adding iOS targets to Rust"
rustup target add aarch64-apple-ios 
rustup target add aarch64-apple-ios-sim 
print_success "iOS targets added to Rust"

print_step "Building for aarch64-apple-ios (physical devices)"
cargo build --target aarch64-apple-ios --release --quiet
print_success "Built for aarch64-apple-ios"

print_step "Building for aarch64-apple-ios-sim (simulator)"
cargo build --target aarch64-apple-ios-sim --release --quiet
print_success "Built for aarch64-apple-ios-sim"

cd "$PROJECT_ROOT"

# Run pod install to ensure pods are up to date
print_step "Installing CocoaPods dependencies"
pushd ios >/dev/null || {
  print_error "Failed to enter ios directory"
  exit 1
}
if ! without_bundler_env pod install --silent; then
  print_error "pod install failed"
  popd >/dev/null
  exit 1
fi
popd >/dev/null

print_success "All Rust libraries built for iOS"
print_success "iOS build completed successfully!"
print_success "You can now run 'flutter build ios' or 'flutter run' to test the app on iOS"
