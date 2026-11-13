#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TPL_DIR="${GODOT_TEMPLATES:-$HOME/.local/share/godot/export_templates/4.3.stable}"
SRC="$TPL_DIR/android_source.zip"
VERSION="$(tr -d '\r\n' < "$TPL_DIR/version.txt" 2>/dev/null || echo 4.3.stable)"
[[ -f "$SRC" ]] || { echo "Missing $SRC"; exit 1; }
rm -rf "$ROOT/android/build"
mkdir -p "$ROOT/android/build"
unzip -q "$SRC" -d "$ROOT/android/build"
printf '%s' "$VERSION" > "$ROOT/android/.build_version"
printf '*\n' > "$ROOT/android/.gdignore"
echo "Installed android/build ($VERSION)"
