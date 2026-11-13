#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MODE="${1:-checklist}"
GODOT_BIN="${GODOT:-/tmp/Godot_v4.3-stable_linux.x86_64}"
PKG=com.dhayalram.neontacblitz
case "$MODE" in
  desktop)
    "$GODOT_BIN" --headless --path "$ROOT" --quit-after 2 2>&1 | tee /tmp/ntb-qa.log | tail -15
    grep -E 'SCRIPT ERROR|Parse Error' /tmp/ntb-qa.log && exit 2 || echo PASS
    ;;
  apk)
    bash "$ROOT/scripts/build_debug_apk.sh"
    adb install -r "$ROOT/build/neon_tac_blitz-debug.apk"
    adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1
    ;;
  checklist)
    cat <<'EOF'
[ ] Menu → Claim Daily → Start Blitz
[ ] Place marks before 5s timer; power cells trigger
[ ] Win / lose / draw banners + Play Again
[ ] Ult after 2 wins; place twice
[ ] Home returns to menu; gems persist
[ ] Immersive phone UI; no crash 5 min
EOF
    ;;
  *) echo "usage: $0 desktop|apk|checklist"; exit 1;;
esac
