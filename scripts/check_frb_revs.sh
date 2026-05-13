#!/bin/bash

# Verifies that the orphan-branch ref pinned in pubspec.lock for
# rust_lib_whitenoise was regenerated from the same whitenoise-rs source SHA
# we're about to compile (read from .whitenoise-rs-rev). When they disagree,
# the Dart bindings and the compiled .so embed different FRB content hashes
# and the app fails at startup with:
#
#   Bad state: Content hash on Dart side (...) is different from Rust side (...)
#
# This check catches that at build time rather than runtime.
#
# Behavior:
#   - Hard-fail when REGENERATED.txt exists at the orphan ref AND records a
#     source SHA that disagrees with .whitenoise-rs-rev.
#   - Soft-warn (exit 0) when REGENERATED.txt is missing — that means a manual
#     regen commit that doesn't carry CI's provenance marker, so the invariant
#     can't be mechanically checked.
#   - Soft-warn when anything else prevents the check (missing files,
#     unparseable lock, non-github url).

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

print_warning() {
  echo -e "\033[1;33m⚠️  $1\033[0m"
}

print_error() {
  echo -e "\033[1;31m❌ $1\033[0m"
}

REV_FILE="$PROJECT_ROOT/.whitenoise-rs-rev"
LOCK_FILE="$PROJECT_ROOT/pubspec.lock"

if [ ! -f "$REV_FILE" ] || [ ! -f "$LOCK_FILE" ]; then
  exit 0
fi

REV="$(tr -d '[:space:]' <"$REV_FILE")"
if [ -z "$REV" ]; then
  exit 0
fi

# Extract resolved-ref + url from the rust_lib_whitenoise block in pubspec.lock.
# The lock format is:
#   rust_lib_whitenoise:
#     dependency: "direct main"
#     description:
#       path: "."
#       ref: "<symbolic-or-sha>"
#       resolved-ref: "<sha>"
#       url: "<url>"
#     source: git
LOCK_BLOCK="$(awk '/^  rust_lib_whitenoise:/{flag=1; next} flag && /^  [a-zA-Z_]/{flag=0} flag' "$LOCK_FILE")"
ORPHAN_REF="$(echo "$LOCK_BLOCK" | sed -n 's/.*resolved-ref: *"\([^"]*\)".*/\1/p' | head -1)"
ORPHAN_URL="$(echo "$LOCK_BLOCK" | sed -n 's|.*url: *"\([^"]*\)".*|\1|p' | head -1)"

if [ -z "$ORPHAN_REF" ] || [ -z "$ORPHAN_URL" ]; then
  print_warning "FRB rev check: couldn't parse rust_lib_whitenoise from pubspec.lock — skipping."
  exit 0
fi

if ! [[ "$ORPHAN_URL" =~ ^https?://github\.com/ ]]; then
  print_warning "FRB rev check: rust_lib_whitenoise url ($ORPHAN_URL) is not on github.com — skipping."
  exit 0
fi

REPO_SLUG="${ORPHAN_URL#http://}"
REPO_SLUG="${REPO_SLUG#https://}"
REPO_SLUG="${REPO_SLUG#github.com/}"
REPO_SLUG="${REPO_SLUG%/}"
REPO_SLUG="${REPO_SLUG%.git}"
RAW_URL="https://raw.githubusercontent.com/${REPO_SLUG}/${ORPHAN_REF}/REGENERATED.txt"
HTTP_BODY="$(curl --silent --fail --location "$RAW_URL" 2>/dev/null || true)"

if [ -z "$HTTP_BODY" ]; then
  print_warning "FRB rev check: ref ${ORPHAN_REF:0:12} has no REGENERATED.txt (manual regen commit?)."
  print_warning "  Can't verify it matches .whitenoise-rs-rev (${REV:0:12}). Proceeding."
  exit 0
fi

# REGENERATED.txt line shape (workflow line 163):
#   Regenerated from: <owner>/<repo>@<sha>
SOURCE_SHA="$(echo "$HTTP_BODY" | sed -n 's/^Regenerated from:.*@\([0-9a-f]\{7,40\}\).*/\1/p' | head -1)"

if [ -z "$SOURCE_SHA" ]; then
  print_warning "FRB rev check: REGENERATED.txt at ${ORPHAN_REF:0:12} has no 'Regenerated from: ...@<sha>' line. Proceeding."
  exit 0
fi

if [ "$SOURCE_SHA" != "$REV" ]; then
  print_error "FRB rev mismatch:"
  print_error "  pubspec.lock rust_lib_whitenoise ref:  $ORPHAN_REF"
  print_error "  that ref's REGENERATED.txt source SHA: $SOURCE_SHA"
  print_error "  .whitenoise-rs-rev (this build):       $REV"
  print_error ""
  print_error "The Dart bindings (from the pubspec ref) were regenerated from a"
  print_error "different whitenoise-rs commit than the one this build will compile."
  print_error "The resulting .so will fail the FRB content-hash check at app startup."
  print_error ""
  print_error "Fix by aligning .whitenoise-rs-rev with the source SHA:"
  print_error "  echo $SOURCE_SHA > .whitenoise-rs-rev"
  exit 1
fi

echo "FRB rev check: pubspec ref ${ORPHAN_REF:0:12} regen'd from ${SOURCE_SHA:0:12} == .whitenoise-rs-rev ✓"
