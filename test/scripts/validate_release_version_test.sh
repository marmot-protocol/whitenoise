#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/validate_release_version.sh"

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT
RELEASE_REPO="$TMPDIR/repo"

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
  cat >"$RELEASE_REPO/pubspec.yaml" <<EOF
name: whitenoise
version: $version
EOF
}

write_pubspec_line() {
  local version_line="$1"
  cat >"$RELEASE_REPO/pubspec.yaml" <<EOF
name: whitenoise
$version_line
EOF
}

mkdir "$RELEASE_REPO"
git -C "$RELEASE_REPO" init --quiet
git -C "$RELEASE_REPO" config user.email "release-test@example.com"
git -C "$RELEASE_REPO" config user.name "Release Test"

write_pubspec "2026.4.28+23"
git -C "$RELEASE_REPO" add pubspec.yaml
git -C "$RELEASE_REPO" commit --quiet -m "prepare release"
git -C "$RELEASE_REPO" tag v2026.4.28+23

output="$("$SCRIPT" --pubspec "$RELEASE_REPO/pubspec.yaml" --repo "$RELEASE_REPO" --tag "v2026.4.28+23")"
assert_contains "$output" "full_version=2026.4.28+23"
assert_contains "$output" "version_name=2026.4.28"
assert_contains "$output" "build_number=23"
assert_contains "$output" "tag=v2026.4.28+23"
assert_contains "$output" "tag_commit=$(git -C "$RELEASE_REPO" rev-parse HEAD)"

if "$SCRIPT" --pubspec "$RELEASE_REPO/pubspec.yaml" --repo "$RELEASE_REPO" --tag "v2026.4.28+24" >"$TMPDIR/out" 2>"$TMPDIR/err"; then
  fail "expected mismatched tag to fail"
fi
assert_contains "$(cat "$TMPDIR/err")" "does not match pubspec version"

git -C "$RELEASE_REPO" tag -d v2026.4.28+23 >/dev/null
if "$SCRIPT" --pubspec "$RELEASE_REPO/pubspec.yaml" --repo "$RELEASE_REPO" --tag "v2026.4.28+23" >"$TMPDIR/out" 2>"$TMPDIR/err"; then
  fail "expected missing tag to fail"
fi
assert_contains "$(cat "$TMPDIR/err")" "does not exist"

git -C "$RELEASE_REPO" tag v2026.4.28+23
echo "change after tag" >"$RELEASE_REPO/after-tag.txt"
git -C "$RELEASE_REPO" add after-tag.txt
git -C "$RELEASE_REPO" commit --quiet -m "move head"
if "$SCRIPT" --pubspec "$RELEASE_REPO/pubspec.yaml" --repo "$RELEASE_REPO" --tag "v2026.4.28+23" >"$TMPDIR/out" 2>"$TMPDIR/err"; then
  fail "expected tag not at HEAD to fail"
fi
assert_contains "$(cat "$TMPDIR/err")" "does not point at HEAD"

write_pubspec "2026.4.28"
if "$SCRIPT" --pubspec "$RELEASE_REPO/pubspec.yaml" --repo "$RELEASE_REPO" >"$TMPDIR/out" 2>"$TMPDIR/err"; then
  fail "expected missing build number to fail"
fi
assert_contains "$(cat "$TMPDIR/err")" "must include a build number"

write_pubspec_line 'version: "2026.4.28+23" # release candidate'
output="$("$SCRIPT" --pubspec "$RELEASE_REPO/pubspec.yaml" --repo "$RELEASE_REPO")"
assert_contains "$output" "full_version=2026.4.28+23"

write_pubspec_line '  version: "2026.4.28+23" # release candidate'
output="$("$SCRIPT" --pubspec "$RELEASE_REPO/pubspec.yaml" --repo "$RELEASE_REPO")"
assert_contains "$output" "full_version=2026.4.28+23"

mkdir "$TMPDIR/outside"
output="$(cd "$TMPDIR/outside" && "$SCRIPT" --pubspec pubspec.yaml --repo "$RELEASE_REPO")"
assert_contains "$output" "full_version=2026.4.28+23"

rm -f "$TMPDIR/out"
"$SCRIPT" --pubspec "$RELEASE_REPO/pubspec.yaml" --repo "$RELEASE_REPO" --github-output "$TMPDIR/out" >/dev/null
assert_contains "$(cat "$TMPDIR/out")" "full_version=2026.4.28+23"
assert_contains "$(cat "$TMPDIR/out")" "version_name=2026.4.28"
assert_contains "$(cat "$TMPDIR/out")" "build_number=23"

if "$SCRIPT" --pubspec >"$TMPDIR/out" 2>"$TMPDIR/err"; then
  fail "expected missing --pubspec value to fail"
fi
assert_contains "$(cat "$TMPDIR/err")" "Missing value for --pubspec"

if "$SCRIPT" --pubspec "$RELEASE_REPO/pubspec.yaml" --repo --tag "v2026.4.28+23" >"$TMPDIR/out" 2>"$TMPDIR/err"; then
  fail "expected missing --repo value to fail"
fi
assert_contains "$(cat "$TMPDIR/err")" "Missing value for --repo"

if "$SCRIPT" --pubspec "$RELEASE_REPO/pubspec.yaml" --tag --github-output "$TMPDIR/github-output" >"$TMPDIR/out" 2>"$TMPDIR/err"; then
  fail "expected missing --tag value to fail"
fi
assert_contains "$(cat "$TMPDIR/err")" "Missing value for --tag"

if "$SCRIPT" --pubspec "$RELEASE_REPO/pubspec.yaml" --github-output >"$TMPDIR/out" 2>"$TMPDIR/err"; then
  fail "expected missing --github-output value to fail"
fi
assert_contains "$(cat "$TMPDIR/err")" "Missing value for --github-output"

echo "validate_release_version_test passed"
