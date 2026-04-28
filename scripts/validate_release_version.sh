#!/usr/bin/env bash

set -euo pipefail

PUBSPEC="pubspec.yaml"
TAG="${GITHUB_REF_NAME:-}"
GITHUB_OUTPUT_FILE="${GITHUB_OUTPUT:-}"

usage() {
  cat <<'EOF'
Usage: scripts/validate_release_version.sh [--pubspec PATH] [--tag TAG] [--github-output PATH]

Validates that the Flutter pubspec version has a build number and, when a tag
is provided, that the tag matches the pubspec version.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
  --pubspec)
    PUBSPEC="$2"
    shift 2
    ;;
  --tag)
    TAG="$2"
    shift 2
    ;;
  --github-output)
    GITHUB_OUTPUT_FILE="$2"
    shift 2
    ;;
  --help)
    usage
    exit 0
    ;;
  *)
    echo "Unknown option: $1" >&2
    usage >&2
    exit 2
    ;;
  esac
done

if [[ ! -f "$PUBSPEC" ]]; then
  echo "Pubspec not found: $PUBSPEC" >&2
  exit 1
fi

VERSION_LINE="$(grep -E '^version:[[:space:]]*[^[:space:]]+' "$PUBSPEC" | head -n 1 || true)"
if [[ -z "$VERSION_LINE" ]]; then
  echo "Could not find version in $PUBSPEC" >&2
  exit 1
fi

FULL_VERSION="$(printf '%s\n' "$VERSION_LINE" | sed -E 's/^version:[[:space:]]*//' | tr -d '[:space:]')"
if [[ "$FULL_VERSION" != *+* ]]; then
  echo "Release version must include a build number, e.g. 2026.4.28+23" >&2
  exit 1
fi

VERSION_NAME="${FULL_VERSION%%+*}"
BUILD_NUMBER="${FULL_VERSION##*+}"

if [[ -z "$VERSION_NAME" || -z "$BUILD_NUMBER" || "$VERSION_NAME" == "$BUILD_NUMBER" ]]; then
  echo "Invalid release version: $FULL_VERSION" >&2
  exit 1
fi

if ! [[ "$BUILD_NUMBER" =~ ^[0-9]+$ ]]; then
  echo "Build number must be numeric: $BUILD_NUMBER" >&2
  exit 1
fi

if [[ -n "$TAG" ]]; then
  TAG_VERSION="${TAG#v}"
  if [[ "$TAG_VERSION" != "$FULL_VERSION" ]]; then
    echo "Tag $TAG does not match pubspec version $FULL_VERSION" >&2
    exit 1
  fi
fi

emit() {
  local key="$1"
  local value="$2"
  printf '%s=%s\n' "$key" "$value"
  if [[ -n "$GITHUB_OUTPUT_FILE" ]]; then
    printf '%s=%s\n' "$key" "$value" >>"$GITHUB_OUTPUT_FILE"
  fi
}

emit "full_version" "$FULL_VERSION"
emit "version_name" "$VERSION_NAME"
emit "build_number" "$BUILD_NUMBER"
if [[ -n "$TAG" ]]; then
  emit "tag" "$TAG"
fi
