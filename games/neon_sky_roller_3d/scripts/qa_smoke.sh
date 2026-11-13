#!/usr/bin/env bash
# Device / desktop smoke QA for Neon Sky Roller 3D.
# Modes:
#   ./scripts/qa_smoke.sh desktop     — headless boot + script parse (no device)
#   ./scripts/qa_smoke.sh apk         — build debug APK then adb install + launch
#   ./scripts/qa_smoke.sh checklist   — print manual QA checklist
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MODE="${1:-checklist}"
GODOT_BIN="${GODOT:-}"
if [[ -z "$GODOT_BIN" ]]; then
  if command -v godot >/dev/null 2>&1; then GODOT_BIN=$(command -v godot)
  elif [[ -x /tmp/Godot_v4.3-stable_linux.x86_64 ]]; then GODOT_BIN=/tmp/Godot_v4.3-stable_linux.x86_64
  fi
fi
PKG=com.dhayalram.neonskyroller3d

desktop() {
  [[ -n "$GODOT_BIN" ]] || { echo "set GODOT"; exit 1; }
  echo "== Desktop headless boot =="
  "$GODOT_BIN" --headless --path "$ROOT" --quit-after 2 2>&1 | tee /tmp/nsr-qa-desktop.log | tail -20
  if grep -E 'SCRIPT ERROR|Parse Error' /tmp/nsr-qa-desktop.log; then
    echo "FAIL: script errors"
    exit 2
  fi
  echo "PASS: desktop boot (no script errors)"
}

apk_install() {
  [[ -n "$GODOT_BIN" ]] || { echo "set GODOT"; exit 1; }
  command -v adb >/dev/null || { echo "adb not on PATH (install platform-tools)"; exit 1; }
  adb get-state >/dev/null 2>&1 || { echo "No device/emulator (adb get-state failed)"; exit 1; }
  bash "$ROOT/scripts/build_debug_apk.sh"
  APK="$ROOT/build/neon_sky_roller_3d-debug.apk"
  echo "== adb install -r $APK =="
  adb install -r "$APK"
  echo "== launch =="
  adb shell am start -n "$PKG/com.godot.game.GodotApp" || adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1
  echo "PASS: installed + launched $PKG"
  echo "Manual: claim daily → Play → steer/turbo → Home → replay"
}

checklist() {
  cat <<'EOF'
Neon Sky Roller 3D — manual QA checklist
========================================
[ ] Cold start → Meta Hub visible (brand, rank, daily, play, garage)
[ ] Claim Daily Gift (once) — gems increase; toast shows
[ ] PLAY starts level; hub hidden; HUD shows speed/score/gems
[ ] Drag ←→ steers; ↑ turbo raises SPEED; ↓ brake lowers SPEED
[ ] Collect gems; hit gate / spinner death → retry works
[ ] Clear level → next / stars update; Solo Rank XP increases
[ ] HOME returns to hub; progress persists after kill+relaunch
[ ] Garage: equip owned skin; buy with gems when affordable
[ ] Level chips / replay for ★★★
[ ] Immersive fullscreen on phone; back/home doesn't corrupt save
[ ] No ANR / crash for 5 min free play
[ ] Release AAB installs via internal testing track (Play)

Automate what you can:
  ./scripts/qa_smoke.sh desktop
  ./scripts/qa_smoke.sh apk          # needs USB device + debug APK toolchain
EOF
}

case "$MODE" in
  desktop) desktop ;;
  apk) apk_install ;;
  checklist) checklist ;;
  *) echo "Usage: $0 desktop|apk|checklist"; exit 1 ;;
esac
