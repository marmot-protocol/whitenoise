#!/usr/bin/env bash
#
# Fetches a user's follow list (kind 3) from public relays,
# then fetches metadata (kind 0) for all followed pubkeys,
# and republishes everything to local dev relays.
#
# Usage:
#   ./scripts/seed_test_follows.sh <npub or hex pubkey>
#
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <npub or hex pubkey>"
  exit 1
fi

INPUT="$1"

# Detect format and normalize to both npub and hex
if [[ "$INPUT" == npub1* ]]; then
  NPUB="$INPUT"
  HEX=$(nak decode "$INPUT" 2>/dev/null) || {
    echo "ERROR: Invalid npub"
    exit 1
  }
else
  HEX="$INPUT"
  NPUB=$(nak encode npub "$INPUT" 2>/dev/null) || {
    echo "ERROR: Invalid hex pubkey"
    exit 1
  }
fi

SOURCE_RELAYS="wss://relay.primal.net wss://relay.damus.io wss://purplepag.es wss://nos.lol"
LOCAL_RELAYS=(ws://localhost:8080 ws://localhost:7777)
BATCH_SIZE=20

echo "Pubkey: $HEX"
echo "Npub:   $NPUB"
echo ""

# Publish a single event to all local relays, tolerating per-relay failures
publish() {
  local event="$1"
  for relay in "${LOCAL_RELAYS[@]}"; do
    echo "$event" | nak event "$relay" 2>&1 | sed "s/^/  /" || true
  done
}

echo "=== Fetching follow list (kind 3) ==="
FOLLOW_EVENT=$(nak req -k 3 -l 1 -a "$HEX" $SOURCE_RELAYS 2>/dev/null | head -1)

if [ -z "$FOLLOW_EVENT" ]; then
  echo "ERROR: No follow list found"
  exit 1
fi

FOLLOW_COUNT=$(echo "$FOLLOW_EVENT" | jq '[.tags[] | select(.[0] == "p")] | length')
echo "Found $FOLLOW_COUNT follows"

echo ""
echo "=== Publishing follow list to local relays ==="
publish "$FOLLOW_EVENT"

echo ""
echo "=== Extracting followed pubkeys ==="
PUBKEYS=$(echo "$FOLLOW_EVENT" | jq -r '.tags[] | select(.[0] == "p") | .[1]')

echo ""
echo "=== Fetching and publishing metadata (kind 0) in batches of $BATCH_SIZE ==="
PUBLISHED=0
BATCH_NUM=0
BATCH_ARGS=()

while read -r pk; do
  [ -z "$pk" ] && continue
  BATCH_ARGS+=("-a" "$pk")

  if [ ${#BATCH_ARGS[@]} -ge $((BATCH_SIZE * 2)) ]; then
    BATCH_NUM=$((BATCH_NUM + 1))
    EVENTS=$(nak req -k 0 "${BATCH_ARGS[@]}" $SOURCE_RELAYS 2>/dev/null || true)
    BATCH_COUNT=0
    while read -r event; do
      [ -z "$event" ] && continue
      publish "$event" >/dev/null 2>&1
      BATCH_COUNT=$((BATCH_COUNT + 1))
    done <<<"$EVENTS"
    PUBLISHED=$((PUBLISHED + BATCH_COUNT))
    printf "  batch %d: %d metadata events (%d total)\n" "$BATCH_NUM" "$BATCH_COUNT" "$PUBLISHED"
    BATCH_ARGS=()
  fi
done <<<"$PUBKEYS"

if [ ${#BATCH_ARGS[@]} -gt 0 ]; then
  BATCH_NUM=$((BATCH_NUM + 1))
  EVENTS=$(nak req -k 0 "${BATCH_ARGS[@]}" $SOURCE_RELAYS 2>/dev/null || true)
  BATCH_COUNT=0
  while read -r event; do
    [ -z "$event" ] && continue
    publish "$event" >/dev/null 2>&1
    BATCH_COUNT=$((BATCH_COUNT + 1))
  done <<<"$EVENTS"
  PUBLISHED=$((PUBLISHED + BATCH_COUNT))
  printf "  batch %d: %d metadata events (%d total)\n" "$BATCH_NUM" "$BATCH_COUNT" "$PUBLISHED"
fi

echo ""
echo "=== Fetching and publishing user's own metadata ==="
OWN_METADATA=$(nak req -k 0 -l 1 -a "$HEX" $SOURCE_RELAYS 2>/dev/null | head -1)
if [ -n "$OWN_METADATA" ]; then
  publish "$OWN_METADATA"
else
  echo "  No metadata found"
fi

echo ""
echo "=== Done ==="
echo "Published follow list ($FOLLOW_COUNT follows) + $PUBLISHED metadata events"
