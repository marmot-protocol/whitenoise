#!/usr/bin/env bash
set -euo pipefail

# Generate a static "WHEN APK" download page for the latest WhiteNoise
# Android APK from GitHub Actions. Retro NES vibes. Marmot energy.
#
# Requirements: curl, jq
# Usage:   GITHUB_TOKEN=ghp_xxx ./scripts/when-apk.sh
# Output:  site/index.html  (ready to deploy to Cloudflare Pages)

REPO="marmot-protocol/whitenoise"
WORKFLOW_FILE="android-apk.yml"
API="https://api.github.com"
OUT_DIR="site"
MAX_PR_BUILDS=5

# ---------------------------------------------------------------------------
# Auth header (optional but recommended – unauthenticated rate-limit is 60/h)
# ---------------------------------------------------------------------------
AUTH_HEADER=""
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  AUTH_HEADER="Authorization: Bearer $GITHUB_TOKEN"
fi

gh_api() {
  local url="$1"
  if [[ -n "$AUTH_HEADER" ]]; then
    curl -fsSL -H "$AUTH_HEADER" -H "Accept: application/vnd.github+json" "$url"
  else
    curl -fsSL -H "Accept: application/vnd.github+json" "$url"
  fi
}

html_escape() {
  printf '%s' "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&#39;/g'
}

format_date() {
  date -u -d "$1" '+%B %d, %Y at %H:%M UTC' 2>/dev/null \
    || TZ=UTC date -jf '%Y-%m-%dT%H:%M:%SZ' "$1" '+%B %d, %Y at %H:%M UTC' 2>/dev/null \
    || echo "$1"
}

# ---------------------------------------------------------------------------
# 1. Find the latest *successful* workflow run on master
# ---------------------------------------------------------------------------
echo "Fetching latest successful workflow run..."
RUNS_JSON=$(gh_api "$API/repos/$REPO/actions/workflows/$WORKFLOW_FILE/runs?branch=master&status=success&per_page=1")

RUN_ID=$(echo "$RUNS_JSON" | jq -r '.workflow_runs[0].id // empty')
if [[ -z "$RUN_ID" ]]; then
  echo "Error: no successful runs found for $WORKFLOW_FILE" >&2
  exit 1
fi

HEAD_SHA=$(echo "$RUNS_JSON"  | jq -r '.workflow_runs[0].head_sha')
RUN_URL=$(echo "$RUNS_JSON"   | jq -r '.workflow_runs[0].html_url')
RUN_DATE=$(echo "$RUNS_JSON"  | jq -r '.workflow_runs[0].updated_at')

echo "  Run #$RUN_ID  sha=$HEAD_SHA"

# ---------------------------------------------------------------------------
# 2. Get artifact metadata for that run
# ---------------------------------------------------------------------------
echo "Fetching artifacts..."
ARTIFACTS_JSON=$(gh_api "$API/repos/$REPO/actions/runs/$RUN_ID/artifacts")

ARTIFACT_NAME=$(echo "$ARTIFACTS_JSON" | jq -r '.artifacts[0].name // empty')
ARTIFACT_ID=$(echo "$ARTIFACTS_JSON"   | jq -r '.artifacts[0].id // empty')
ARTIFACT_SIZE=$(echo "$ARTIFACTS_JSON" | jq -r '.artifacts[0].size_in_bytes // 0')
ARTIFACT_EXPIRED=$(echo "$ARTIFACTS_JSON" | jq -r '.artifacts[0].expired // false')

if [[ -z "$ARTIFACT_ID" ]]; then
  echo "Error: no artifacts found for run $RUN_ID" >&2
  exit 1
fi

if [[ "$ARTIFACT_EXPIRED" == "true" ]]; then
  echo "Warning: artifact has expired and may not be downloadable" >&2
fi

ARTIFACT_SIZE_MB=$(awk "BEGIN {printf \"%.1f\", $ARTIFACT_SIZE / 1048576}")

NIGHTLY_LINK_URL="https://nightly.link/$REPO/actions/artifacts/$ARTIFACT_ID.zip"

echo "  Artifact: $ARTIFACT_NAME ($ARTIFACT_SIZE_MB MB)"

# ---------------------------------------------------------------------------
# 3. Fetch commit details (message, author, date)
# ---------------------------------------------------------------------------
echo "Fetching commit info for $HEAD_SHA..."
COMMIT_JSON=$(gh_api "$API/repos/$REPO/commits/$HEAD_SHA")

COMMIT_MSG=$(echo "$COMMIT_JSON"    | jq -r '.commit.message' | head -1)
COMMIT_AUTHOR=$(echo "$COMMIT_JSON" | jq -r '.commit.author.name')
COMMIT_AUTHOR_ESCAPED=$(html_escape "$COMMIT_AUTHOR")
COMMIT_DATE=$(echo "$COMMIT_JSON"   | jq -r '.commit.author.date')
COMMIT_URL="https://github.com/$REPO/commit/$HEAD_SHA"
SHORT_SHA="${HEAD_SHA:0:7}"

echo "  Commit: $SHORT_SHA by $COMMIT_AUTHOR — $COMMIT_MSG"

# ---------------------------------------------------------------------------
# 4. Fetch recent successful PR builds
# ---------------------------------------------------------------------------
echo ""
echo "Fetching recent PR builds..."

# Get recent successful runs for the workflow (across all branches, event=pull_request)
PR_RUNS_JSON=$(gh_api "$API/repos/$REPO/actions/workflows/$WORKFLOW_FILE/runs?event=pull_request&status=success&per_page=20")

# We'll collect up to MAX_PR_BUILDS PR build entries as HTML fragments
PR_BUILDS_HTML=""
PR_COUNT=0

# Iterate through runs, extract PR info from each
while IFS= read -r row; do
  if [[ "$PR_COUNT" -ge "$MAX_PR_BUILDS" ]]; then
    break
  fi

  unset pr_artifacts_json

  pr_run_id=$(echo "$row" | jq -r '.id')
  pr_head_sha=$(echo "$row" | jq -r '.head_sha')
  pr_run_date=$(echo "$row" | jq -r '.updated_at')

  # Get PR number from the run's pull_requests array
  pr_number=$(echo "$row" | jq -r '.pull_requests[0].number // empty')

  if [[ -z "$pr_number" ]]; then
    # Fallback: check artifact name for pr-<number> pattern
    pr_artifacts_json=$(gh_api "$API/repos/$REPO/actions/runs/$pr_run_id/artifacts")
    pr_artifact_name=$(echo "$pr_artifacts_json" | jq -r '.artifacts[0].name // empty')

    if [[ "$pr_artifact_name" =~ apk-staging-pr-([0-9]+)- ]]; then
      pr_number="${BASH_REMATCH[1]}"
    else
      echo "  Skipping run $pr_run_id — cannot determine PR number"
      continue
    fi
  fi

  # Fetch PR metadata
  pr_json=$(gh_api "$API/repos/$REPO/pulls/$pr_number" 2>/dev/null || echo '{}')
  pr_title=$(echo "$pr_json" | jq -r '.title // "Unknown"')
  pr_author=$(echo "$pr_json" | jq -r '.user.login // "unknown"')
  pr_state=$(echo "$pr_json" | jq -r '.state // "unknown"')
  merged_at=$(echo "$pr_json" | jq -r '.merged_at // empty')
  pr_url="https://github.com/$REPO/pull/$pr_number"

  # Get artifact info for this run
  if [[ -z "${pr_artifacts_json:-}" ]]; then
    pr_artifacts_json=$(gh_api "$API/repos/$REPO/actions/runs/$pr_run_id/artifacts")
  fi

  pr_artifact_id=$(echo "$pr_artifacts_json" | jq -r '.artifacts[0].id // empty')
  pr_artifact_size=$(echo "$pr_artifacts_json" | jq -r '.artifacts[0].size_in_bytes // 0')
  pr_artifact_expired=$(echo "$pr_artifacts_json" | jq -r '.artifacts[0].expired // false')

  if [[ -z "$pr_artifact_id" || "$pr_artifact_expired" == "true" ]]; then
    echo "  Skipping PR #$pr_number — artifact missing or expired"
    continue
  fi

  pr_artifact_size_mb=$(awk "BEGIN {printf \"%.1f\", $pr_artifact_size / 1048576}")
  pr_nightly_url="https://nightly.link/$REPO/actions/artifacts/$pr_artifact_id.zip"
  pr_short_sha="${pr_head_sha:0:7}"
  pr_pretty_date=$(format_date "$pr_run_date")
  pr_title_escaped=$(html_escape "$pr_title")
  pr_author_escaped=$(html_escape "$pr_author")
  pr_commit_url="https://github.com/$REPO/commit/$pr_head_sha"

  # Determine state badge
  if [[ "$pr_state" == "open" ]]; then
    state_badge="OPEN"
    state_color="var(--nes-green)"
  elif [[ -n "$merged_at" ]]; then
    state_badge="MERGED"
    state_color="var(--nes-blue)"
  else
    state_badge="CLOSED"
    state_color="var(--nes-red)"
  fi

  echo "  PR #$pr_number: $pr_title (by $pr_author, $pr_short_sha)"

  PR_BUILDS_HTML+="
    <div class=\"nes-box is-dark\" style=\"margin: 0.75rem 0;\">
      <div style=\"display: flex; justify-content: space-between; align-items: flex-start; flex-wrap: wrap; gap: 0.5rem;\">
        <div>
          <span style=\"color: var(--nes-orange); font-size: 0.6rem;\">PR BUILD</span>
          <span style=\"color: ${state_color}; font-size: 0.5rem; margin-left: 0.5rem;\">[${state_badge}]</span>
        </div>
        <a class=\"nes-btn\" href=\"${pr_nightly_url}\" style=\"font-size: 0.5rem; padding: 0.4rem 0.8rem;\">
          DOWNLOAD
        </a>
      </div>
      <div style=\"margin-top: 0.75rem;\">
        <a href=\"${pr_url}\" style=\"color: var(--nes-yellow); text-decoration: none; font-size: 0.6rem;\">#${pr_number}</a>
        <span style=\"font-size: 0.55rem;\"> ${pr_title_escaped}</span>
      </div>
      <table class=\"commit-table\" style=\"margin-top: 0.5rem;\">
        <tr>
          <td>HERO</td>
          <td>${pr_author_escaped}</td>
        </tr>
        <tr>
          <td>COMMIT</td>
          <td><a href=\"${pr_commit_url}\"><span class=\"sha\">${pr_short_sha}</span></a></td>
        </tr>
        <tr>
          <td>BUILT</td>
          <td>${pr_pretty_date}</td>
        </tr>
        <tr>
          <td>SIZE</td>
          <td>${pr_artifact_size_mb} MB (zip)</td>
        </tr>
      </table>
    </div>"

  PR_COUNT=$((PR_COUNT + 1))
done < <(echo "$PR_RUNS_JSON" | jq -c '.workflow_runs[]')

echo "  Found $PR_COUNT PR builds"

# ---------------------------------------------------------------------------
# 5. Generate static HTML — NES retro style, marmot energy
# ---------------------------------------------------------------------------
mkdir -p "$OUT_DIR"

PRETTY_BUILD_DATE=$(format_date "$RUN_DATE")
PRETTY_COMMIT_DATE=$(format_date "$COMMIT_DATE")

# Escape commit message for safe HTML embedding
COMMIT_MSG_ESCAPED=$(html_escape "$COMMIT_MSG")

cat > "$OUT_DIR/index.html" <<'HTMLEOF_PART1'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>WHEN APK — WhiteNoise Android Download</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link href="https://fonts.googleapis.com/css2?family=Press+Start+2P&display=swap" rel="stylesheet">
  <style>
    :root {
      --bg: #000;
      --surface: #111;
      --border: #444;
      --text: #fcfcfc;
      --muted: #888;
      --nes-red: #e74040;
      --nes-green: #5cb85c;
      --nes-blue: #209cee;
      --nes-yellow: #f7d51d;
      --nes-orange: #f08030;
    }

    * { margin: 0; padding: 0; box-sizing: border-box; }

    body {
      font-family: 'Press Start 2P', monospace;
      background: var(--bg);
      color: var(--text);
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      align-items: center;
      padding: 1rem;
      image-rendering: pixelated;
    }

    .scanlines {
      position: fixed;
      top: 0; left: 0; right: 0; bottom: 0;
      pointer-events: none;
      z-index: 999;
      background: repeating-linear-gradient(
        0deg,
        rgba(0,0,0,0.15) 0px,
        rgba(0,0,0,0.15) 1px,
        transparent 1px,
        transparent 3px
      );
    }

    .container {
      max-width: 680px;
      width: 100%;
      position: relative;
      z-index: 1;
    }

    /* ---- NES-style bordered box ---- */
    .nes-box {
      position: relative;
      margin: 1rem 0;
      padding: 1.5rem;
      background: var(--surface);
      border: 4px solid var(--text);
      box-shadow:
        inset -4px -4px 0 0 #555,
        inset 4px 4px 0 0 #ddd,
        8px 8px 0 0 rgba(0,0,0,0.5);
    }

    .nes-box.is-dark {
      border-color: var(--border);
      box-shadow:
        inset -4px -4px 0 0 #222,
        inset 4px 4px 0 0 #666,
        8px 8px 0 0 rgba(0,0,0,0.5);
    }

    /* ---- Header ---- */
    .header {
      text-align: center;
      padding: 2rem 0 0.5rem;
    }

    .marmot {
      font-size: 4rem;
      display: block;
      margin-bottom: 0.5rem;
      animation: bounce 0.6s infinite alternate;
    }

    @keyframes bounce {
      from { transform: translateY(0); }
      to { transform: translateY(-12px); }
    }

    .title {
      font-size: 1.8rem;
      color: var(--nes-yellow);
      text-shadow: 4px 4px 0 #8b6914;
      letter-spacing: 2px;
      margin-bottom: 0.5rem;
    }

    .tagline {
      font-size: 0.6rem;
      color: var(--nes-orange);
      line-height: 1.8;
    }

    /* ---- Blink ---- */
    .blink {
      animation: blinker 1s step-start infinite;
    }
    @keyframes blinker {
      50% { opacity: 0; }
    }

    /* ---- Download button ---- */
    .download-section { text-align: center; }

    .nes-btn {
      display: inline-block;
      padding: 1rem 2rem;
      font-family: 'Press Start 2P', monospace;
      font-size: 1rem;
      color: #fff;
      background: var(--nes-green);
      border: none;
      text-decoration: none;
      cursor: pointer;
      position: relative;
      box-shadow:
        inset -4px -4px 0 0 #2d8a2d,
        inset 4px 4px 0 0 #8ade8a,
        0 6px 0 0 #2d6b2d;
      transition: transform 0.05s;
      image-rendering: pixelated;
    }

    .nes-btn:hover {
      transform: translateY(2px);
      box-shadow:
        inset -4px -4px 0 0 #2d8a2d,
        inset 4px 4px 0 0 #8ade8a,
        0 4px 0 0 #2d6b2d;
    }

    .nes-btn:active {
      transform: translateY(4px);
      box-shadow:
        inset -4px -4px 0 0 #2d8a2d,
        inset 4px 4px 0 0 #8ade8a,
        0 2px 0 0 #2d6b2d;
    }

    .nes-btn-red {
      background: var(--nes-red);
      box-shadow:
        inset -4px -4px 0 0 #a02020,
        inset 4px 4px 0 0 #ff8080,
        0 6px 0 0 #8b1a1a;
    }
    .nes-btn-red:hover {
      box-shadow:
        inset -4px -4px 0 0 #a02020,
        inset 4px 4px 0 0 #ff8080,
        0 4px 0 0 #8b1a1a;
    }

    .meta-text {
      font-size: 0.5rem;
      color: var(--muted);
      margin-top: 1rem;
      line-height: 2;
    }

    /* ---- Commit log ---- */
    .section-title {
      font-size: 0.7rem;
      color: var(--nes-blue);
      margin-bottom: 1rem;
      text-transform: uppercase;
    }

    .commit-table {
      width: 100%;
      font-size: 0.55rem;
      line-height: 2.2;
    }

    .commit-table td {
      vertical-align: top;
      padding: 0.25rem 0;
    }

    .commit-table td:first-child {
      color: var(--muted);
      white-space: nowrap;
      padding-right: 1rem;
      width: 90px;
    }

    .commit-table a {
      color: var(--nes-yellow);
      text-decoration: none;
    }
    .commit-table a:hover {
      color: #fff;
      text-decoration: underline;
    }

    .sha {
      background: #333;
      padding: 2px 6px;
      border: 2px solid #555;
      font-size: 0.55rem;
    }

    /* ---- Dialogue boxes ---- */
    .dialogue {
      font-size: 0.6rem;
      line-height: 2;
      color: var(--text);
      text-align: center;
      padding: 1rem;
    }

    .dialogue .speaker {
      color: var(--nes-red);
    }

    /* ---- Pixel art footer ---- */
    .pixel-divider {
      text-align: center;
      font-size: 0.5rem;
      color: var(--border);
      margin: 0.5rem 0;
      letter-spacing: 4px;
      overflow: hidden;
    }

    footer {
      text-align: center;
      font-size: 0.45rem;
      color: var(--muted);
      padding: 2rem 0 1rem;
      line-height: 2.5;
    }

    footer a {
      color: var(--nes-blue);
      text-decoration: none;
    }

    /* ---- Stars background ---- */
    .stars {
      position: fixed;
      top: 0; left: 0; right: 0; bottom: 0;
      pointer-events: none;
      z-index: 0;
      overflow: hidden;
    }
    .star {
      position: absolute;
      width: 2px;
      height: 2px;
      background: #fff;
      animation: twinkle 2s infinite;
    }
    @keyframes twinkle {
      0%, 100% { opacity: 0.2; }
      50% { opacity: 1; }
    }

    /* ---- PR builds section ---- */
    .pr-section-header {
      font-size: 0.7rem;
      color: var(--nes-orange);
      margin-bottom: 0.5rem;
      text-transform: uppercase;
      text-align: center;
    }

    .pr-section-sub {
      font-size: 0.45rem;
      color: var(--muted);
      text-align: center;
      margin-bottom: 1rem;
      line-height: 2;
    }

    .pr-empty {
      font-size: 0.5rem;
      color: var(--muted);
      text-align: center;
      padding: 1rem;
      line-height: 2;
    }

    /* ---- Responsive ---- */
    @media (max-width: 500px) {
      .title { font-size: 1.2rem; }
      .nes-btn { font-size: 0.75rem; padding: 0.75rem 1.5rem; }
      .marmot { font-size: 3rem; }
    }
  </style>
</head>
<body>

<div class="scanlines"></div>

<div class="stars" id="stars"></div>

<div class="container">

  <div class="header">
    <span class="marmot">🦫</span>
    <h1 class="title">WHEN APK</h1>
    <p class="tagline">
      APK NOW. <span class="blink">&#9608;</span>
    </p>
  </div>

  <!-- DIALOGUE -->
  <div class="nes-box">
    <div class="dialogue">
      <span class="speaker">MAX:</span> &quot;when apk&quot;<br>
      <span class="speaker">MARMOT:</span> &quot;apk now. big plans.&quot;<br>
      <span class="speaker">MAX:</span> &quot;...really?&quot;<br>
      <span class="speaker">MARMOT:</span> &quot;yes. press the button.&quot;
    </div>
  </div>

  <!-- DOWNLOAD -->
  <div class="nes-box download-section">
    <p class="section-title">&#9660; GRAB THE LATEST BUILD &#9660;</p>
HTMLEOF_PART1

# --- inject dynamic master build values ---
cat >> "$OUT_DIR/index.html" <<HTMLEOF_PART2
    <a class="nes-btn" href="${NIGHTLY_LINK_URL}">
      &#9733; DOWNLOAD APK &#9733;
    </a>
    <p class="meta-text">
      ${ARTIFACT_NAME}<br>
      ${ARTIFACT_SIZE_MB} MB (zip) &bull; Built ${PRETTY_BUILD_DATE}
    </p>
    <p class="meta-text" style="color: var(--nes-orange); margin-top: 0.5rem;">
      Contains split APKs (arm64-v8a, armeabi-v7a, x86_64).<br>
      Most phones want arm64-v8a. Unzip and install.
    </p>
  </div>

  <!-- COMMIT INFO -->
  <div class="nes-box is-dark">
    <p class="section-title">&#9654; LATEST QUEST LOG</p>
    <table class="commit-table">
      <tr>
        <td>COMMIT</td>
        <td><a href="${COMMIT_URL}"><span class="sha">${SHORT_SHA}</span></a></td>
      </tr>
      <tr>
        <td>HERO</td>
        <td>${COMMIT_AUTHOR_ESCAPED}</td>
      </tr>
      <tr>
        <td>DATE</td>
        <td>${PRETTY_COMMIT_DATE}</td>
      </tr>
      <tr>
        <td>MESSAGE</td>
        <td>${COMMIT_MSG_ESCAPED}</td>
      </tr>
    </table>
  </div>

  <!-- BUILD INFO -->
  <div class="nes-box is-dark">
    <p class="section-title">&#9654; BUILD STATS</p>
    <table class="commit-table">
      <tr>
        <td>WORKFLOW</td>
        <td><a href="${RUN_URL}">Run #${RUN_ID}</a></td>
      </tr>
      <tr>
        <td>REPO</td>
        <td><a href="https://github.com/${REPO}">${REPO}</a></td>
      </tr>
      <tr>
        <td>BRANCH</td>
        <td>master</td>
      </tr>
    </table>
  </div>

  <div class="pixel-divider">&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;</div>

  <!-- PR BUILDS -->
  <div style="margin: 1.5rem 0;">
    <p class="pr-section-header">&#9654; SIDE QUESTS (PR BUILDS) &#9654;</p>
    <p class="pr-section-sub">
      Experimental builds from open pull requests.<br>
      Use at your own risk, adventurer.
    </p>
HTMLEOF_PART2

# --- inject PR builds ---
if [[ -n "$PR_BUILDS_HTML" ]]; then
  cat >> "$OUT_DIR/index.html" <<HTMLEOF_PR_BUILDS
${PR_BUILDS_HTML}
HTMLEOF_PR_BUILDS
else
  cat >> "$OUT_DIR/index.html" <<'HTMLEOF_PR_EMPTY'
    <div class="nes-box is-dark">
      <p class="pr-empty">
        No active PR builds right now.<br>
        The marmot is resting. &#x1F634;
      </p>
    </div>
HTMLEOF_PR_EMPTY
fi

# --- close out the page ---
cat >> "$OUT_DIR/index.html" <<HTMLEOF_PART3
  </div>

  <div class="pixel-divider">&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;</div>

  <footer>
    POWERED BY MARMOT PROTOCOL 🦫<br>
    <a href="https://github.com/${REPO}">GITHUB</a> &bull;
    GENERATED $(date -u '+%Y-%m-%d %H:%M UTC')
  </footer>

</div>

<script>
// Generate random pixel stars
(function() {
  var c = document.getElementById('stars');
  for (var i = 0; i < 60; i++) {
    var s = document.createElement('div');
    s.className = 'star';
    s.style.left = Math.random() * 100 + '%';
    s.style.top = Math.random() * 100 + '%';
    s.style.animationDelay = (Math.random() * 3).toFixed(1) + 's';
    s.style.animationDuration = (1 + Math.random() * 2).toFixed(1) + 's';
    c.appendChild(s);
  }
})();
</script>

</body>
</html>
HTMLEOF_PART3

echo ""
echo "Static site generated at $OUT_DIR/index.html"
