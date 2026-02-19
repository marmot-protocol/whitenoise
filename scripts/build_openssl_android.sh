#!/bin/bash

# Build OpenSSL static libraries for Android targets
# This is needed because libsqlite3-sys (SQLCipher) requires libcrypto,
# and Android doesn't ship a system libcrypto.so.
set -eo pipefail

print_step() {
    echo -e "\n\033[1;34m=== $1 ===\033[0m"
}

print_success() {
    echo -e "\033[1;32m$1\033[0m"
}

print_error() {
    echo -e "\033[1;31m$1\033[0m"
}

# Spinner for long-running commands
# Usage: run_quiet "description" logfile command [args...]
run_quiet() {
    local desc="$1"
    local logfile="$2"
    shift 2

    printf "  %-40s " "$desc"

    # Run command in background with output redirected to log file
    "$@" >> "$logfile" 2>&1 &
    local pid=$!
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    while kill -0 "$pid" 2>/dev/null; do
        printf "\b%s" "${spin:i++%${#spin}:1}"
        sleep 0.1
    done
    wait "$pid"
    local exit_code=$?

    if [ $exit_code -eq 0 ]; then
        printf "\b\033[1;32m✓\033[0m\n"
    else
        printf "\b\033[1;31m✗\033[0m\n"
        print_error "Command failed. Last 20 lines of log:"
        tail -20 "$logfile"
        print_error "Full log: $logfile"
        exit 1
    fi
}

# Configuration
OPENSSL_VERSION="3.4.1"
OPENSSL_SHA256="002a2d6b30b58bf4bea46c43bdd96365aaf8daa6c428782aa4feee06da197df3"
ANDROID_API=33

# Resolve paths
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OPENSSL_BUILD_DIR="$PROJECT_ROOT/rust/target/openssl"
OPENSSL_SRC_DIR="$OPENSSL_BUILD_DIR/openssl-$OPENSSL_VERSION"
OPENSSL_INSTALL_DIR="$OPENSSL_BUILD_DIR/install"

# Auto-detect Android NDK
if [ -z "$ANDROID_NDK_HOME" ]; then
    if [ -n "$NDK_HOME" ]; then
        ANDROID_NDK_HOME="$NDK_HOME"
    elif [ -n "$ANDROID_HOME" ]; then
        NDK_DIR="$ANDROID_HOME/ndk"
        if [ -d "$NDK_DIR" ]; then
            NDK_VERSION=$(ls "$NDK_DIR" | sort -V | tail -n 1)
            if [ -n "$NDK_VERSION" ]; then
                ANDROID_NDK_HOME="$NDK_DIR/$NDK_VERSION"
            fi
        fi
    fi
fi

if [ -z "$ANDROID_NDK_HOME" ] || [ ! -d "$ANDROID_NDK_HOME" ]; then
    print_error "Android NDK not found. Set ANDROID_NDK_HOME or NDK_HOME."
    exit 1
fi

# Detect host OS
case "$(uname -s)" in
    Darwin*)
        case "$(uname -m)" in
            arm64|aarch64) HOST_TAG="darwin-arm64" ;;
            *)             HOST_TAG="darwin-x86_64" ;;
        esac
        ;;
    Linux*)     HOST_TAG="linux-x86_64" ;;
    *)          print_error "Unsupported host OS: $(uname -s)"; exit 1 ;;
esac

TOOLCHAIN="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/$HOST_TAG"

# Target configurations: (rust_target openssl_target arch)
TARGETS=(
    "aarch64-linux-android:android-arm64:aarch64"
    "armv7-linux-androideabi:android-arm:armv7a"
    "x86_64-linux-android:android-x86_64:x86_64"
)

build_openssl_for_target() {
    local rust_target="$1"
    local openssl_target="$2"
    local arch="$3"
    local install_prefix="$OPENSSL_INSTALL_DIR/$rust_target"

    # Skip if already built
    if [ -f "$install_prefix/lib/libcrypto.a" ]; then
        print_success "OpenSSL already built for $rust_target (skipping)"
        return 0
    fi

    print_step "Building OpenSSL for $rust_target ($openssl_target)"

    # Clean and re-extract source for each target (OpenSSL doesn't support out-of-tree builds well)
    local build_src="$OPENSSL_BUILD_DIR/build-$rust_target"
    local logfile="$OPENSSL_BUILD_DIR/$rust_target.log"
    rm -rf "$build_src"
    : > "$logfile"
    cp -r "$OPENSSL_SRC_DIR" "$build_src"
    cd "$build_src"

    export ANDROID_NDK_ROOT="$ANDROID_NDK_HOME"
    export PATH="$TOOLCHAIN/bin:$PATH"

    run_quiet "Configuring ($openssl_target)..." "$logfile" \
        ./Configure "$openssl_target" \
            -D__ANDROID_API__=$ANDROID_API \
            --prefix="$install_prefix" \
            --openssldir="$install_prefix/ssl" \
            no-shared \
            no-tests \
            no-ui-console \
            no-stdio \
            -fPIC

    run_quiet "Compiling..." "$logfile" \
        make -j"$(nproc 2>/dev/null || sysctl -n hw.ncpu)" build_libs

    run_quiet "Installing headers & libs..." "$logfile" \
        make install_dev

    cd "$PROJECT_ROOT"
    rm -rf "$build_src"

    if [ -f "$install_prefix/lib/libcrypto.a" ]; then
        print_success "  Built OpenSSL for $rust_target"
    else
        print_error "Failed to build OpenSSL for $rust_target"
        print_error "Check log: $logfile"
        exit 1
    fi
}

# Download OpenSSL source if needed
if [ ! -d "$OPENSSL_SRC_DIR" ]; then
    print_step "Downloading OpenSSL $OPENSSL_VERSION"
    mkdir -p "$OPENSSL_BUILD_DIR"
    cd "$OPENSSL_BUILD_DIR"

    TARBALL="openssl-$OPENSSL_VERSION.tar.gz"
    if [ ! -f "$TARBALL" ]; then
        curl -L --progress-bar -o "$TARBALL" "https://github.com/openssl/openssl/releases/download/openssl-$OPENSSL_VERSION/$TARBALL"
    fi

    print_step "Verifying tarball integrity"
    if command -v shasum >/dev/null 2>&1; then
        ACTUAL_SHA256=$(shasum -a 256 "$TARBALL" | awk '{print $1}')
    elif command -v sha256sum >/dev/null 2>&1; then
        ACTUAL_SHA256=$(sha256sum "$TARBALL" | awk '{print $1}')
    else
        print_error "No SHA-256 tool found (need shasum or sha256sum)"
        exit 1
    fi
    if [ "$ACTUAL_SHA256" != "$OPENSSL_SHA256" ]; then
        print_error "SHA-256 mismatch for $TARBALL"
        print_error "  Expected: $OPENSSL_SHA256"
        print_error "  Actual:   $ACTUAL_SHA256"
        rm -f "$TARBALL"
        exit 1
    fi
    print_success "SHA-256 verified"

    tar xzf "$TARBALL"
    cd "$PROJECT_ROOT"
fi

# Build for each target
for target_spec in "${TARGETS[@]}"; do
    IFS=':' read -r rust_target openssl_target arch <<< "$target_spec"
    build_openssl_for_target "$rust_target" "$openssl_target" "$arch"
done

print_success "All OpenSSL Android builds complete!"
echo "Install directory: $OPENSSL_INSTALL_DIR"
