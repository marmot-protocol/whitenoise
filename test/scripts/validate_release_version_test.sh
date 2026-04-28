#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/validate_release_version.sh"

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  if [[ "$haystack" != *"$needle"* ]]; then
    fail "expected output to contain '$needle'; got: $haystack"
  fi
}

write_pubspec() {
  local version="$1"
  cat >"$TMPDIR/pubspec.yaml" <<EOF
name: whitenoise
version: $version
EOF
}

write_pubspec "2026.4.28+23"

output="$("$SCRIPT" --pubspec "$TMPDIR/pubspec.yaml" --tag "v2026.4.28+23")"
assert_contains "$output" "full_version=2026.4.28+23"
assert_contains "$output" "version_name=2026.4.28"
assert_contains "$output" "build_number=23"
assert_contains "$output" "tag=v2026.4.28+23"

if "$SCRIPT" --pubspec "$TMPDIR/pubspec.yaml" --tag "v2026.4.28+24" >"$TMPDIR/out" 2>"$TMPDIR/err"; then
  fail "expected mismatched tag to fail"
fi
assert_contains "$(cat "$TMPDIR/err")" "does not match pubspec version"

write_pubspec "2026.4.28"
if "$SCRIPT" --pubspec "$TMPDIR/pubspec.yaml" >"$TMPDIR/out" 2>"$TMPDIR/err"; then
  fail "expected missing build number to fail"
fi
assert_contains "$(cat "$TMPDIR/err")" "must include a build number"

echo "validate_release_version_test passed"
