#!/usr/bin/env bash
# Install Godot Android Gradle build template into this project (required for AAB).
# Usage: GODOT_TEMPLATES=~/.local/share/godot/export_templates/4.3.stable ./scripts/install_android_template.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TPL_DIR="${GODOT_TEMPLATES:-$HOME/.local/share/godot/export_templates/4.3.stable}"
SRC="$TPL_DIR/android_source.zip"
VERSION_FILE="$TPL_DIR/version.txt"
if [[ ! -f "$SRC" ]]; then
  echo "ERROR: missing $SRC — download Godot export templates matching your editor." >&2
  exit 1
fi
VERSION="$(tr -d '\r\n' < "$VERSION_FILE" 2>/dev/null || echo 4.3.stable)"
rm -rf "$ROOT/android"
mkdir -p "$ROOT/android/build"
unzip -q "$SRC" -d "$ROOT/android/build"
printf '%s' "$VERSION" > "$ROOT/android/.build_version"
printf '*\n' > "$ROOT/android/.gdignore"
echo "Installed Android build template → $ROOT/android/build (version $VERSION)"
echo "Next: ./scripts/build_release_aab.sh"
