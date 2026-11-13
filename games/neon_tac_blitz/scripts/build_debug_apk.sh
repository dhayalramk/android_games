#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT_BIN="${GODOT:-/tmp/Godot_v4.3-stable_linux.x86_64}"
mkdir -p "$ROOT/build"
OUT="$ROOT/build/neon_tac_blitz-debug.apk"
"$GODOT_BIN" --headless --path "$ROOT" --export-debug "Android Debug APK" "$OUT"
ls -lh "$OUT"
