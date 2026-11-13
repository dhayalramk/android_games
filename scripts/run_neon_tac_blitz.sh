#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT_BIN="${GODOT:-}"
if [[ -z "$GODOT_BIN" ]]; then
  if [[ -x /tmp/Godot_v4.3-stable_linux.x86_64 ]]; then
    GODOT_BIN=/tmp/Godot_v4.3-stable_linux.x86_64
  elif command -v godot >/dev/null 2>&1; then
    GODOT_BIN="$(command -v godot)"
  else
    echo "Set GODOT to your Godot 4.x binary" >&2
    exit 1
  fi
fi
exec "$GODOT_BIN" --path "$ROOT/games/neon_tac_blitz" --rendering-driver opengl3 "$@"
