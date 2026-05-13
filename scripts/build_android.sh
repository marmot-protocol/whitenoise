#!/bin/bash

# Build script for Android targets
set -e # Exit on any error

echo "🚀 Building Rust library for Android targets..."

# Function to print colored output
print_step() {
  echo -e "\n\033[1;34m=== $1 ===\033[0m"
}

print_success() {
  echo -e "\033[1;32m✅ $1\033[0m"
}

print_warning() {
  echo -e "\033[1;33m⚠️ $1\033[0m"
}

print_error() {
  echo -e "\033[1;31m❌ $1\033[0m"
}

# Auto-detect Android SDK and NDK paths
print_step "Detecting Android SDK and NDK paths"

# Try to find Android SDK
if [ -z "$ANDROID_HOME" ] && [ -z "$ANDROID_SDK_ROOT" ]; then
  # Common Android SDK locations
  POSSIBLE_SDK_PATHS=(
    "$HOME/Library/Android/sdk"       # macOS default
    "$HOME/Android/Sdk"               # Linux default
    "$HOME/AppData/Local/Android/Sdk" # Windows default
    "/opt/android-sdk"                # Linux alternative
  )

  for path in "${POSSIBLE_SDK_PATHS[@]}"; do
    if [ -d "$path" ]; then
      export ANDROID_HOME="$path"
      export ANDROID_SDK_ROOT="$path"
      print_success "Found Android SDK at: $path"
      break
    fi
  done
else
  export ANDROID_HOME="${ANDROID_HOME:-$ANDROID_SDK_ROOT}"
  export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$ANDROID_HOME}"
  print_success "Using Android SDK from environment: $ANDROID_HOME"
fi

if [ -z "$ANDROID_HOME" ]; then
  print_error "Android SDK not found. Please install Android SDK or set ANDROID_HOME environment variable"
  exit 1
fi

# Auto-detect NDK path
if [ -z "$ANDROID_NDK_HOME" ]; then
  # Look for NDK in the SDK directory
  NDK_DIR="$ANDROID_HOME/ndk"
  if [ -d "$NDK_DIR" ]; then
    # Find the latest NDK version
    NDK_VERSION=$(ls "$NDK_DIR" | sort -V | tail -n 1)
    if [ -n "$NDK_VERSION" ]; then
      export ANDROID_NDK_HOME="$NDK_DIR/$NDK_VERSION"
      print_success "Found NDK version $NDK_VERSION at: $ANDROID_NDK_HOME"
    fi
  fi
fi

if [ -z "$ANDROID_NDK_HOME" ] || [ ! -d "$ANDROID_NDK_HOME" ]; then
  print_error "Android NDK not found. Please install Android NDK or set ANDROID_NDK_HOME environment variable"
  print_error "You can install NDK through Android Studio SDK Manager"
  exit 1
fi

# Detect host OS for NDK toolchain path
case "$(uname -s)" in
Darwin*) HOST_TAG="darwin-x86_64" ;;
Linux*) HOST_TAG="linux-x86_64" ;;
MINGW* | CYGWIN* | MSYS*) HOST_TAG="windows-x86_64" ;;
*)
  print_error "Unsupported host OS: $(uname -s)"
  exit 1
  ;;
esac

export PATH="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/$HOST_TAG/bin:$PATH"

# Set environment variables for ring crate and cc-rs
export CC_armv7_linux_androideabi="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/$HOST_TAG/bin/armv7a-linux-androideabi33-clang"
export CXX_armv7_linux_androideabi="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/$HOST_TAG/bin/armv7a-linux-androideabi33-clang++"
export AR_armv7_linux_androideabi="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/$HOST_TAG/bin/llvm-ar"

# Fetch the Rust wrapper source from whitenoise-rs at the pinned rev.
# The wrapper crate (rust_lib_whitenoise) lives at crates/whitenoise-frb/ on the
# frb-gen branch of marmot-protocol/whitenoise-rs. The pubspec git dep only
# ships the Dart bindings + cargokit shell, not the Rust source — so we clone
# it here to produce the per-ABI .so files for jniLibs.
print_step "Fetching whitenoise-rs source"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"
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

# Build static OpenSSL for Android targets (SQLCipher requires libcrypto)
print_step "Building OpenSSL for Android"
./scripts/build_openssl_android.sh
OPENSSL_ANDROID_DIR="$PROJECT_ROOT/.whitenoise-rs-cache/openssl/install"

# Check if required tools are installed
print_step "Checking development environment"
if ! command -v rustup &>/dev/null; then
  print_error "Rustup is not installed or not in PATH"
  exit 1
fi

# Generate Cargo config inside the cached whitenoise-rs workspace
print_step "Setting up Cargo configuration"
CARGO_CONFIG_DIR="$WHITENOISE_RS_CACHE/.cargo" ./scripts/setup_android_config.sh

# Create output directories
print_step "Creating output directories"
mkdir -p "$PROJECT_ROOT/android/app/src/main/jniLibs/arm64-v8a"
mkdir -p "$PROJECT_ROOT/android/app/src/main/jniLibs/armeabi-v7a"
mkdir -p "$PROJECT_ROOT/android/app/src/main/jniLibs/x86_64"

# Build for each Android architecture
print_step "Building for Android architectures"
cd "$WHITENOISE_FRB_DIR"

# Add Android targets to the toolchain pinned by whitenoise-rs's rust-toolchain.toml.
# Running rustup after `cd` ensures the override activates the right toolchain.
print_step "Adding Android targets to Rust ($(rustup show active-toolchain | awk '{print $1}'))"
rustup target add aarch64-linux-android   # arm64-v8a (64-bit ARM)
rustup target add armv7-linux-androideabi # armeabi-v7a (32-bit ARM)
rustup target add x86_64-linux-android    # x86_64 (64-bit Intel)
print_success "Android targets added to Rust"

# Build helper: sets per-target OpenSSL env vars and runs cargo build
build_for_target() {
  local target="$1"
  local label="$2"
  local jni_dir="$3"

  print_step "Building for $label"
  OPENSSL_DIR="$OPENSSL_ANDROID_DIR/$target" \
    OPENSSL_INCLUDE_DIR="$OPENSSL_ANDROID_DIR/$target/include" \
    OPENSSL_LIB_DIR="$OPENSSL_ANDROID_DIR/$target/lib" \
    OPENSSL_STATIC=1 \
    OPENSSL_NO_VENDOR=1 \
    cargo build --target "$target" --release --quiet
  cp "$WHITENOISE_RS_CACHE/target/$target/release/librust_lib_whitenoise.so" \
    "$PROJECT_ROOT/android/app/src/main/jniLibs/$jni_dir/"
  print_success "Built for $label"
}

build_for_target "aarch64-linux-android" "aarch64 (arm64-v8a)" "arm64-v8a"
build_for_target "armv7-linux-androideabi" "armv7 (armeabi-v7a)" "armeabi-v7a"
build_for_target "x86_64-linux-android" "x86_64" "x86_64"

cd "$PROJECT_ROOT"

print_success "All Rust libraries built and copied to Android project"
print_success "Android build completed successfully!"
print_success "You can now run 'flutter run' to test the app on Android"
