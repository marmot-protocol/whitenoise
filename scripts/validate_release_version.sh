#!/usr/bin/env bash

set -euo pipefail

PUBSPEC="pubspec.yaml"
TAG=""
if [[ "${GITHUB_REF_TYPE:-}" == "tag" ]]; then
  TAG="${GITHUB_REF_NAME:-}"
fi
GITHUB_OUTPUT_FILE="${GITHUB_OUTPUT:-}"
REPO="."

usage() {
  cat <<'EOF'
Usage: scripts/validate_release_version.sh [--pubspec PATH] [--repo PATH] [--tag TAG] [--github-output PATH]

Validates that the Flutter pubspec version has a build number and, when a tag
is provided, that the tag matches the pubspec version and points at HEAD.
EOF
}

require_option_value() {
  local option="$1"
  local value="${2:-}"

  if [[ -z "$value" || "$value" == --* ]]; then
    echo "Missing value for $option" >&2
    usage >&2
    exit 2
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
  --pubspec)
    require_option_value "$1" "${2:-}"
    PUBSPEC="$2"
    shift 2
    ;;
  --repo)
    require_option_value "$1" "${2:-}"
    REPO="$2"
    shift 2
    ;;
  --tag)
    require_option_value "$1" "${2:-}"
    TAG="$2"
    shift 2
    ;;
  --github-output)
    require_option_value "$1" "${2:-}"
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

VERSION_LINE="$(grep -E '^[[:space:]]*version:[[:space:]]*[^[:space:]]+' "$PUBSPEC" | head -n 1 || true)"
if [[ -z "$VERSION_LINE" ]]; then
  echo "Could not find version in $PUBSPEC" >&2
  exit 1
fi

FULL_VERSION="$(
  printf '%s\n' "$VERSION_LINE" |
    sed -E 's/^[[:space:]]*version:[[:space:]]*//' |
    sed -E 's/[[:space:]]*#.*$//' |
    sed -E 's/^[[:space:]]*["'\'']?//; s/["'\'']?[[:space:]]*$//'
)"
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
  TAG_NAME="${TAG#refs/tags/}"
  TAG_VERSION="${TAG_NAME#v}"
  if [[ "$TAG_VERSION" != "$FULL_VERSION" ]]; then
    echo "Tag $TAG_NAME does not match pubspec version $FULL_VERSION" >&2
    exit 1
  fi

  if ! git -C "$REPO" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Tag validation requires a git repository: $REPO" >&2
    exit 1
  fi

  if ! TAG_COMMIT="$(git -C "$REPO" rev-parse --verify --quiet "$TAG_NAME^{commit}" 2>/dev/null)"; then
    echo "Tag $TAG_NAME does not exist in $REPO" >&2
    exit 1
  fi

  HEAD_COMMIT="$(git -C "$REPO" rev-parse HEAD)"
  if [[ "$TAG_COMMIT" != "$HEAD_COMMIT" ]]; then
    echo "Tag $TAG_NAME does not point at HEAD" >&2
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
  emit "tag" "$TAG_NAME"
  emit "tag_commit" "$TAG_COMMIT"
fi
