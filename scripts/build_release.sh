#!/bin/bash

# Build release artifacts for White Noise
#
# Produces a versioned output directory containing:
#   - Split APKs (arm64-v8a, armeabi-v7a, x86_64) with .sha256 sidecar files
#   - IPA (macOS only)
#   - build_info.txt with version, git metadata, and checksums
#
# Usage:
#   ./scripts/build_release.sh [--android] [--ios] [--output-dir DIR]
#
#   --android       Build Android APKs only
#   --ios           Build iOS IPA only (macOS only)
#   --output-dir    Custom output directory (default: build/releases/v<version>+<build>)
#
#   With no flags, builds both platforms (iOS only on macOS).

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_step()    { echo -e "\n${BLUE}=== $1 ===${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error()   { echo -e "${RED}❌ $1${NC}"; }
print_info()    { echo -e "${BLUE}ℹ️  $1${NC}"; }

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

BUILD_ANDROID=false
BUILD_IOS=false
CUSTOM_OUTPUT_DIR=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --android)    BUILD_ANDROID=true; shift ;;
        --ios)        BUILD_IOS=true;     shift ;;
        --output-dir) CUSTOM_OUTPUT_DIR="$2"; shift 2 ;;
        --help)
            sed -n '/^# Usage:/,/^[^#]/p' "$0" | sed 's/^# \{0,2\}//'
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Default: build both (iOS only on macOS)
if [ "$BUILD_ANDROID" = false ] && [ "$BUILD_IOS" = false ]; then
    BUILD_ANDROID=true
    [[ "$OSTYPE" == "darwin"* ]] && BUILD_IOS=true
fi

# iOS requires macOS
if [ "$BUILD_IOS" = true ] && [[ "$OSTYPE" != "darwin"* ]]; then
    print_warning "iOS builds require macOS — skipping iOS."
    BUILD_IOS=false
fi

# ---------------------------------------------------------------------------
# Version from pubspec.yaml
# ---------------------------------------------------------------------------

VERSION_LINE=$(grep "^version:" pubspec.yaml)
if [ -z "$VERSION_LINE" ]; then
    print_error "Could not find version in pubspec.yaml"
    exit 1
fi

FULL_VERSION=$(echo "$VERSION_LINE" | sed 's/version: //' | tr -d ' ')
VERSION_NAME=$(echo "$FULL_VERSION" | cut -d'+' -f1)
BUILD_NUMBER=$(echo "$FULL_VERSION" | cut -d'+' -f2)

# ---------------------------------------------------------------------------
# Output directory
# ---------------------------------------------------------------------------

if [ -n "$CUSTOM_OUTPUT_DIR" ]; then
    OUTPUT_DIR="$CUSTOM_OUTPUT_DIR"
else
    OUTPUT_DIR="build/releases/v${VERSION_NAME}+${BUILD_NUMBER}"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

print_step "Building White Noise release"
print_info "Version:      $VERSION_NAME ($BUILD_NUMBER)"
print_info "Platforms:    $([ "$BUILD_ANDROID" = true ] && echo -n "Android ")$([ "$BUILD_IOS" = true ] && echo -n "iOS")"
print_info "Output dir:   $OUTPUT_DIR"

mkdir -p "$OUTPUT_DIR"

# ---------------------------------------------------------------------------
# Android
# ---------------------------------------------------------------------------

if [ "$BUILD_ANDROID" = true ]; then
    print_step "Building Android"
    print_info "Building Rust native libraries..."
    ./scripts/build_android.sh

    print_info "Building split APKs (production flavor)..."
    flutter build apk --flavor production --split-per-abi

    APK_DIR="build/app/outputs/flutter-apk"

    print_step "Staging Android artifacts"

    for ABI in arm64-v8a armeabi-v7a x86_64; do
        # Flutter names the file: app-<abi>-production-release.apk
        SRC=$(find "$APK_DIR" -name "app-${ABI}-production-release.apk" -type f | head -n 1)

        if [ -z "$SRC" ] || [ ! -f "$SRC" ]; then
            if [ "$ABI" = "armeabi-v7a" ]; then
                print_warning "armeabi-v7a APK not found (expected for modern-only builds)"
            else
                print_error "$ABI APK not found in $APK_DIR"
            fi
            continue
        fi

        DEST_NAME="whitenoise-${VERSION_NAME}-${ABI}.apk"
        DEST="$OUTPUT_DIR/$DEST_NAME"

        cp "$SRC" "$DEST"

        # SHA-256 file hash (download integrity)
        HASH=$(shasum -a 256 "$DEST" | awk '{print $1}')
        echo "$HASH  $DEST_NAME" > "${DEST}.sha256"

        print_success "$DEST_NAME"
        print_info "  SHA-256: $HASH"
        print_info "  Hash file: ${DEST_NAME}.sha256"
    done
fi

# ---------------------------------------------------------------------------
# iOS
# ---------------------------------------------------------------------------

if [ "$BUILD_IOS" = true ]; then
    print_step "Building iOS"
    print_info "Building Rust native libraries..."
    ./scripts/build_ios.sh

    print_info "Building IPA (production flavor)..."
    flutter build ipa --flavor production --export-method app-store

    IPA_PATH=$(find build/ios -name "*.ipa" -type f | head -n 1)

    if [ -n "$IPA_PATH" ] && [ -f "$IPA_PATH" ]; then
        DEST_NAME="whitenoise-${VERSION_NAME}+${BUILD_NUMBER}.ipa"
        cp "$IPA_PATH" "$OUTPUT_DIR/$DEST_NAME"
        print_success "$DEST_NAME"
    else
        print_warning "IPA not found after build — check signing configuration"
    fi
fi

# ---------------------------------------------------------------------------
# build_info.txt
# ---------------------------------------------------------------------------

print_step "Writing build_info.txt"

{
    echo "White Noise Build Information"
    echo "=============================="
    echo ""
    echo "Version:      $VERSION_NAME"
    echo "Build Number: $BUILD_NUMBER"
    echo "Build Date:   $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    echo "Git Commit:   $(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')"
    echo "Git Branch:   $(git branch --show-current 2>/dev/null || echo 'unknown')"
    echo ""
    echo "Artifacts:"
    for f in "$OUTPUT_DIR"/*.apk "$OUTPUT_DIR"/*.ipa; do
        [ -f "$f" ] || continue
        fname=$(basename "$f")
        hash=$(shasum -a 256 "$f" | awk '{print $1}')
        echo "  $fname"
        echo "    SHA-256: $hash"
    done
} > "$OUTPUT_DIR/build_info.txt"

print_success "build_info.txt written"

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------

print_step "Release build complete"
print_success "Artifacts in: $OUTPUT_DIR"
echo ""
ls -lh "$OUTPUT_DIR"
