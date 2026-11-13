#!/usr/bin/env bash
# Export debug APK for device sideload / QA.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
GODOT_BIN="${GODOT:-}"
if [[ -z "$GODOT_BIN" ]]; then
  if command -v godot >/dev/null 2>&1; then
    GODOT_BIN="$(command -v godot)"
  elif [[ -x /tmp/Godot_v4.3-stable_linux.x86_64 ]]; then
    GODOT_BIN=/tmp/Godot_v4.3-stable_linux.x86_64
  else
    echo "ERROR: set GODOT to your Godot 4.x binary" >&2
    exit 1
  fi
fi
mkdir -p "$ROOT/build"
OUT="$ROOT/build/neon_sky_roller_3d-debug.apk"
echo "Exporting Android Debug APK → $OUT"
"$GODOT_BIN" --headless --path "$ROOT" --export-debug "Android Debug APK" "$OUT"
ls -lh "$OUT"
echo "OK: $OUT"
