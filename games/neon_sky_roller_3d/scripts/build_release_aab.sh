#!/usr/bin/env bash
# Export signed Play Store AAB for Neon Sky Roller 3D.
#
# Required env:
#   GODOT          path to Godot 4.3+ binary (or on PATH as `godot`)
#   ANDROID_HOME   Android SDK root (Godot Editor → Editor Settings → Export → Android)
#
# Release signing (recommended via env, never commit keystores):
#   NSR_RELEASE_KEYSTORE       absolute path to .jks / .keystore
#   NSR_RELEASE_KEYSTORE_USER  key alias
#   NSR_RELEASE_KEYSTORE_PASS  keystore + key password
#
# Optional:
#   NSR_VERSION    override version name (also updates export_presets via set_version.sh)
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

if [[ -n "${NSR_VERSION:-}" ]]; then
  bash "$ROOT/scripts/set_version.sh" "$NSR_VERSION"
fi

PRESET="$ROOT/export_presets.cfg"
if [[ -n "${NSR_RELEASE_KEYSTORE:-}" ]]; then
  python3 - "$PRESET" <<'PY'
import os, re, sys
path = sys.argv[1]
ks = os.environ["NSR_RELEASE_KEYSTORE"]
user = os.environ.get("NSR_RELEASE_KEYSTORE_USER", "")
pw = os.environ.get("NSR_RELEASE_KEYSTORE_PASS", "")
text = open(path, encoding="utf-8").read()
# Only patch the Release AAB preset block (preset.1)
parts = text.split("[preset.1]")
if len(parts) < 2:
    raise SystemExit("preset.1 (Android Release AAB) missing")
head, rest = parts[0], parts[1]
# Split options section for preset.1
if "[preset.1.options]" not in rest:
    raise SystemExit("preset.1.options missing")
body, opts = rest.split("[preset.1.options]", 1)
# opts runs until next [preset.N] or EOF
m = re.search(r'\n\[preset\.\d', opts)
if m:
    opt_body, tail = opts[:m.start()], opts[m.start():]
else:
    opt_body, tail = opts, ""

def set_opt(s, key, val):
    pat = rf'(?m)^({re.escape(key)}=).*$'
    if re.search(pat, s):
        return re.sub(pat, rf'\g<1>"{val}"' if not val.isdigit() and not val.startswith('"') else rf'\g<1>{val}', s)
    return s

# Godot expects bare paths without forcing quotes for empty; use quoted for paths
def repl(s, key, val):
    return re.sub(rf'(?m)^({re.escape(key)}=).*$', rf'\g<1>"{val}"', s)

opt_body = repl(opt_body, "keystore/release", ks)
opt_body = repl(opt_body, "keystore/release_user", user)
opt_body = repl(opt_body, "keystore/release_password", pw)
open(path, "w", encoding="utf-8").write(head + "[preset.1]" + body + "[preset.1.options]" + opt_body + tail)
print(f"Injected release keystore into preset.1: {ks}")
PY
fi

mkdir -p "$ROOT/build"
OUT="$ROOT/build/neon_sky_roller_3d-release.aab"
echo "Exporting Android Release AAB → $OUT"
echo "Godot: $GODOT_BIN"
"$GODOT_BIN" --headless --path "$ROOT" --export-release "Android Release AAB" "$OUT"
if [[ ! -f "$OUT" ]]; then
  echo "ERROR: AAB not produced. Install Android build templates + SDK, enable Gradle in Editor." >&2
  exit 2
fi
ls -lh "$OUT"
echo "OK: $OUT"
