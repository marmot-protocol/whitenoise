#!/bin/bash

# Proof runbook for scripts/check_frb_revs.sh.
#
# Run this after the FRB codegen workflow on marmot-protocol/whitenoise-rs
# has produced at least one orphan-branch update on flutter-package (i.e.
# a commit carrying REGENERATED.txt). Until that's true, the proof bails
# cleanly with a "CI hasn't run yet" message and restores any temp state.
#
# What it does:
#   1. Locates the most recent commit on origin/flutter-package that carries
#      REGENERATED.txt and extracts its 'Regenerated from: ...@<sha>' value.
#   2. Backs up pubspec.lock and .whitenoise-rs-rev.
#   3. Test 1 (PASS): temporarily points pubspec.lock at the CI commit and
#      sets .whitenoise-rs-rev to match the recorded source SHA. Runs
#      check_frb_revs.sh — expects exit 0. The check does a real HTTPS GET
#      against raw.githubusercontent.com, so this is end-to-end.
#   4. Test 2 (HARD-FAIL): keeps pubspec.lock pointed at the same CI commit
#      but flips .whitenoise-rs-rev to a *different* real whitenoise-rs SHA.
#      Re-runs the check — expects non-zero exit AND the diagnostic to
#      contain "FRB rev mismatch:".
#   5. Restores pubspec.lock and .whitenoise-rs-rev from backup on EXIT,
#      whether the proof succeeded, failed, or was interrupted.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

print_step()    { echo -e "\n\033[1;34m=== $1 ===\033[0m"; }
print_ok()      { echo -e "\033[1;32m✅ $1\033[0m"; }
print_fail()    { echo -e "\033[1;31m❌ $1\033[0m"; }
print_warning() { echo -e "\033[1;33m⚠️  $1\033[0m"; }

LOCK="$PROJECT_ROOT/pubspec.lock"
REV="$PROJECT_ROOT/.whitenoise-rs-rev"
CHECK="$SCRIPT_DIR/check_frb_revs.sh"

if [ ! -f "$LOCK" ] || [ ! -f "$REV" ] || [ ! -x "$CHECK" ]; then
  print_fail "Missing one of: pubspec.lock, .whitenoise-rs-rev, scripts/check_frb_revs.sh"
  exit 1
fi

LOCK_BAK="$(mktemp)"
REV_BAK="$(mktemp)"
OUT_BUF="$(mktemp)"
cp "$LOCK" "$LOCK_BAK"
cp "$REV"  "$REV_BAK"

restore() {
  local status=$?
  cp "$LOCK_BAK" "$LOCK"
  cp "$REV_BAK"  "$REV"
  rm -f "$LOCK_BAK" "$REV_BAK" "$OUT_BUF"
  if [ "$status" -ne 0 ]; then
    print_fail "Proof aborted. Originals restored."
  else
    echo
    print_ok "Originals restored."
  fi
}
trap restore EXIT

# Parse the orphan repo URL from the current pubspec.lock — same logic
# check_frb_revs.sh uses, so we agree on the repo slug.
LOCK_BLOCK="$(awk '/^  rust_lib_whitenoise:/{flag=1; next} flag && /^  [a-zA-Z_]/{flag=0} flag' "$LOCK")"
ORPHAN_URL="$(echo "$LOCK_BLOCK" | sed -n 's|.*url: *"\([^"]*\)".*|\1|p' | head -1)"
if ! [[ "$ORPHAN_URL" =~ ^https?://github\.com/ ]]; then
  print_fail "pubspec.lock rust_lib_whitenoise url is not on github.com: $ORPHAN_URL"
  exit 1
fi
REPO_SLUG="$(echo "$ORPHAN_URL" | sed -E 's#^https?://github\.com/([^/]+/[^/]+?)(\.git)?/?$#\1#')"

print_step "Locating the latest CI commit on origin/flutter-package"
WS_CACHE="$PROJECT_ROOT/.whitenoise-rs-cache/whitenoise-rs"
if [ ! -d "$WS_CACHE/.git" ]; then
  mkdir -p "$(dirname "$WS_CACHE")"
  git clone --quiet --filter=blob:none --no-checkout "https://github.com/${REPO_SLUG}.git" "$WS_CACHE"
fi
# The cache clone (created by build_*.sh) restricts its default refspec to
# master, so a plain 'fetch origin flutter-package' updates FETCH_HEAD but
# does not create refs/remotes/origin/flutter-package. Map it explicitly.
git -C "$WS_CACHE" fetch --quiet origin \
  "+refs/heads/flutter-package:refs/remotes/origin/flutter-package"

CI_SHA=""
SOURCE_SHA=""
for c in $(git -C "$WS_CACHE" log origin/flutter-package --format=%H); do
  if git -C "$WS_CACHE" cat-file -e "$c:REGENERATED.txt" 2>/dev/null; then
    BODY="$(git -C "$WS_CACHE" show "$c:REGENERATED.txt")"
    SHA="$(echo "$BODY" | sed -n 's/^Regenerated from:.*@\([0-9a-f]\{7,40\}\).*/\1/p' | head -1)"
    if [ -n "$SHA" ]; then
      CI_SHA="$c"
      SOURCE_SHA="$SHA"
      break
    fi
  fi
done

if [ -z "$CI_SHA" ]; then
  print_warning "No commit on origin/flutter-package carries REGENERATED.txt yet."
  print_warning "Run this proof after the FRB codegen workflow has produced at least one update."
  exit 1
fi

print_ok "CI commit: $CI_SHA"
print_ok "  REGENERATED.txt records source SHA: $SOURCE_SHA"

# Pick a real, different whitenoise-rs SHA for the hard-fail test. Prefer the
# bootstrap-source SHA recorded in the orphan branch's first commit message
# ("frb: bootstrap flutter-package orphan branch from <SHA>"); fall back to
# origin/master if that's somehow missing or accidentally equals SOURCE_SHA.
BOOTSTRAP_MSG="$(git -C "$WS_CACHE" log origin/flutter-package --format=%s --reverse | head -1)"
WRONG_SHA="$(echo "$BOOTSTRAP_MSG" | grep -oE '[0-9a-f]{40}' | head -1 || true)"
if [ -z "$WRONG_SHA" ] || [ "$WRONG_SHA" = "$SOURCE_SHA" ]; then
  WRONG_SHA="$(git -C "$WS_CACHE" rev-parse origin/master 2>/dev/null || true)"
fi
if [ -z "$WRONG_SHA" ] || [ "$WRONG_SHA" = "$SOURCE_SHA" ]; then
  print_fail "Couldn't pick a 'wrong' real SHA distinct from $SOURCE_SHA. Aborting."
  exit 1
fi
print_ok "  Wrong SHA for hard-fail test: $WRONG_SHA"

# Repoint pubspec.lock at the CI commit. The rust_lib_whitenoise block has a
# 'ref:' line (symbolic or sha) and a 'resolved-ref:' line (always a real sha).
# Rewrite both so check_frb_revs.sh — which reads resolved-ref — sees the CI ref.
print_step "Rewriting pubspec.lock to point at CI commit (temporary)"
awk -v ci="$CI_SHA" '
  /^  rust_lib_whitenoise:/ { in_block = 1 }
  in_block && /^  [a-zA-Z_][a-zA-Z_]*:/ && !/^  rust_lib_whitenoise:/ { in_block = 0 }
  in_block && /resolved-ref:/ { sub(/"[^"]*"/, "\"" ci "\"") }
  in_block && /^      ref:/   { sub(/"[^"]*"/, "\"" ci "\"") }
  { print }
' "$LOCK" > "$LOCK.tmp"
mv "$LOCK.tmp" "$LOCK"

# === Test 1: PASS ===
print_step "Test 1 (expect PASS): .whitenoise-rs-rev == SOURCE_SHA"
echo "$SOURCE_SHA" > "$REV"
if "$CHECK" > "$OUT_BUF" 2>&1; then
  cat "$OUT_BUF"
  print_ok "Test 1 passed — check exited 0 as expected."
else
  cat "$OUT_BUF"
  print_fail "Test 1 FAILED — check should have exited 0 but did not."
  exit 1
fi

# === Test 2: HARD-FAIL ===
print_step "Test 2 (expect HARD-FAIL): .whitenoise-rs-rev = $WRONG_SHA"
echo "$WRONG_SHA" > "$REV"
set +e
"$CHECK" > "$OUT_BUF" 2>&1
RC=$?
set -e
cat "$OUT_BUF"
if [ "$RC" -eq 0 ]; then
  print_fail "Test 2 FAILED — check should have exited non-zero but exited 0."
  exit 1
fi
if ! grep -q "FRB rev mismatch:" "$OUT_BUF"; then
  print_fail "Test 2 FAILED — diagnostic did not contain 'FRB rev mismatch:'."
  exit 1
fi
if ! grep -q "$SOURCE_SHA" "$OUT_BUF"; then
  print_fail "Test 2 FAILED — diagnostic did not name the real source SHA $SOURCE_SHA."
  exit 1
fi
if ! grep -q "$WRONG_SHA" "$OUT_BUF"; then
  print_fail "Test 2 FAILED — diagnostic did not name the wrong rev $WRONG_SHA."
  exit 1
fi
print_ok "Test 2 passed — hard-fail with real CI-produced REGENERATED.txt."

print_step "Proof complete"
print_ok "check_frb_revs.sh PASS path verified against real CI commit $CI_SHA"
print_ok "check_frb_revs.sh HARD-FAIL path verified against real REGENERATED.txt"
