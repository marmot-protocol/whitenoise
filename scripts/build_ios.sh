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

# Add iOS targets
print_step "Adding iOS targets to Rust"
rustup target add aarch64-apple-ios     # Physical devices (arm64)
rustup target add aarch64-apple-ios-sim # Simulator on Apple Silicon
print_success "iOS targets added to Rust"

# Build for each iOS architecture
print_step "Building for iOS architectures"
if ! test -d "rust"; then
  print_error "rust directory not found"
  exit 1
fi

IOS_DEPLOYMENT_TARGET="${IOS_DEPLOYMENT_TARGET:-13.0}"
export IPHONEOS_DEPLOYMENT_TARGET="$IOS_DEPLOYMENT_TARGET"
print_step "Using iOS deployment target $IPHONEOS_DEPLOYMENT_TARGET"

cd rust

print_step "Building for aarch64-apple-ios (physical devices)"
cargo build --target aarch64-apple-ios --release --quiet
print_success "Built for aarch64-apple-ios"

print_step "Building for aarch64-apple-ios-sim (simulator)"
cargo build --target aarch64-apple-ios-sim --release --quiet
print_success "Built for aarch64-apple-ios-sim"

cd ..

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

print_success "All Rust libraries built for iOS"
print_success "iOS build completed successfully!"
print_success "You can now run 'flutter build ios' or 'flutter run' to test the app on iOS"
