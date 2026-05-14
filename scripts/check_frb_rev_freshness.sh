#!/bin/bash

# Soft-warns when .whitenoise-rs-rev is not at origin/master HEAD of the
# upstream whitenoise-rs repo. The pin is intentionally a manual cursor (for
# FRB content-hash stability), so falling behind is normal — but invisible.
# This check makes it visible without blocking the build.
#
# Always exits 0. This is purely informational.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

print_warning() {
  echo -e "\033[1;33m⚠️  $1\033[0m"
}
print_info() {
  echo -e "\033[1;34mℹ  $1\033[0m"
}

REV_FILE="$PROJECT_ROOT/.whitenoise-rs-rev"
LOCK_FILE="$PROJECT_ROOT/pubspec.lock"
WHITENOISE_RS_URL="https://github.com/marmot-protocol/whitenoise-rs.git"

if [ ! -f "$REV_FILE" ]; then
  exit 0
fi
REV="$(tr -d '[:space:]' <"$REV_FILE")"
if [ -z "$REV" ]; then
  exit 0
fi

# Optionally derive the URL from pubspec.lock so we stay aligned with the
# whitenoise_frb dep instead of hardcoding marmot-protocol.
if [ -f "$LOCK_FILE" ]; then
  LOCK_URL="$(awk '/^  whitenoise_frb:/{flag=1; next} flag && /^  [a-zA-Z_]/{flag=0} flag' "$LOCK_FILE" \
              | sed -n 's|.*url: *"\([^"]*\)".*|\1|p' | head -1)"
  if [[ "$LOCK_URL" =~ ^https?://github\.com/ ]]; then
    WHITENOISE_RS_URL="${LOCK_URL%.git}.git"
  fi
fi

MASTER_SHA="$(git ls-remote "$WHITENOISE_RS_URL" refs/heads/master 2>/dev/null | awk '{print $1}' | head -1)"
if [ -z "$MASTER_SHA" ]; then
  print_warning ".whitenoise-rs-rev freshness: couldn't reach $WHITENOISE_RS_URL. Skipping."
  exit 0
fi

if [ "$REV" = "$MASTER_SHA" ]; then
  echo ".whitenoise-rs-rev freshness: at origin/master HEAD (${REV:0:12}) ✓"
  exit 0
fi

# Both SHAs differ. Try to count commits via the local cache.
WS_CACHE="$PROJECT_ROOT/.whitenoise-rs-cache/whitenoise-rs"
COUNT_INFO=""
if [ -d "$WS_CACHE/.git" ]; then
  # The cache's default refspec is master-only; make sure we have both SHAs
  # reachable locally so rev-list can compute distance. Map the pin's branch
  # broadly: try master first, then any branch on origin that contains it.
  git -C "$WS_CACHE" fetch --quiet origin master 2>/dev/null || true
  if ! git -C "$WS_CACHE" cat-file -e "${REV}^{commit}" 2>/dev/null; then
    git -C "$WS_CACHE" fetch --quiet --filter=blob:none origin "$REV" 2>/dev/null || true
  fi

  if git -C "$WS_CACHE" cat-file -e "${REV}^{commit}" 2>/dev/null && \
     git -C "$WS_CACHE" cat-file -e "${MASTER_SHA}^{commit}" 2>/dev/null; then
    BEHIND="$(git -C "$WS_CACHE" rev-list --count "${REV}..${MASTER_SHA}" 2>/dev/null || echo "")"
    DIVERGED="$(git -C "$WS_CACHE" rev-list --count "${MASTER_SHA}..${REV}" 2>/dev/null || echo "")"
    if [ -n "$BEHIND" ] && [ -n "$DIVERGED" ]; then
      if [ "$BEHIND" -gt 0 ] && [ "$DIVERGED" -eq 0 ]; then
        COUNT_INFO=" (${BEHIND} commits behind master)"
      elif [ "$BEHIND" -eq 0 ] && [ "$DIVERGED" -gt 0 ]; then
        COUNT_INFO=" (${DIVERGED} commits ahead of master — likely a side branch)"
      elif [ "$BEHIND" -gt 0 ] && [ "$DIVERGED" -gt 0 ]; then
        COUNT_INFO=" (${DIVERGED} ahead, ${BEHIND} behind master — diverged side branch)"
      fi
    fi
  fi
fi

print_warning ".whitenoise-rs-rev is not at origin/master HEAD${COUNT_INFO}"
print_info "  pinned:        ${REV}"
print_info "  origin/master: ${MASTER_SHA}"
print_info "  Soft warning — build will continue."
print_info "  To track master: echo ${MASTER_SHA} > .whitenoise-rs-rev"
exit 0
