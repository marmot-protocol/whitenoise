#!/bin/bash
# Workaround for the whitenoise_frb hosted-pub iOS layout.
#
# When whitenoise_frb is consumed as a hosted-pub dep, Flutter only symlinks the
# per-platform subdirs (ios/, macos/, ...) into ios/.symlinks/plugins/. The
# package's CocoaPods script_phase invokes cargokit with `../../rust`, which
# resolves through the ios/ symlink target and lands OUTSIDE the pub-cache
# package — causing `PathNotFoundException: rust/Cargo.toml`.
#
# Fix: add rust/ and cargokit/ symlinks alongside the ios/ symlink, both
# pointing into the real pub-cache package root. Idempotent; no-op when the
# plugin symlink dir isn't present yet (e.g., on Linux CI or pre-pub-get).

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

PLUGIN_LINK_DIR="$PROJECT_ROOT/ios/.symlinks/plugins/whitenoise_frb"

if [ ! -d "$PLUGIN_LINK_DIR" ]; then
  exit 0
fi

if [ ! -e "$PLUGIN_LINK_DIR/ios" ]; then
  echo "fix_ios_symlinks: $PLUGIN_LINK_DIR/ios missing — cannot resolve pub-cache package root" >&2
  exit 1
fi

PKG_ROOT="$(cd "$PLUGIN_LINK_DIR/ios" && cd .. && pwd -P)"

for sub in rust cargokit; do
  src="$PKG_ROOT/$sub"
  dest="$PLUGIN_LINK_DIR/$sub"
  if [ ! -e "$src" ]; then
    echo "fix_ios_symlinks: $src not in pub-cache; skipping" >&2
    continue
  fi
  ln -sfn "$src" "$dest"
  echo "fix_ios_symlinks: $dest -> $src"
done
