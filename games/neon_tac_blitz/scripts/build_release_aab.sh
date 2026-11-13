#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
GODOT_BIN="${GODOT:-}"
if [[ -z "$GODOT_BIN" ]]; then
  if [[ -x /tmp/Godot_v4.3-stable_linux.x86_64 ]]; then GODOT_BIN=/tmp/Godot_v4.3-stable_linux.x86_64
  elif command -v godot >/dev/null; then GODOT_BIN=$(command -v godot)
  else echo "set GODOT"; exit 1; fi
fi
if [[ -n "${NSR_VERSION:-}" ]]; then bash "$ROOT/scripts/set_version.sh" "$NSR_VERSION"; fi
PRESET="$ROOT/export_presets.cfg"
if [[ -n "${NSR_RELEASE_KEYSTORE:-}" ]]; then
  python3 - "$PRESET" <<'PY'
import os,re,sys
path=sys.argv[1]
ks,user,pw=os.environ['NSR_RELEASE_KEYSTORE'],os.environ.get('NSR_RELEASE_KEYSTORE_USER',''),os.environ.get('NSR_RELEASE_KEYSTORE_PASS','')
t=open(path,encoding='utf-8').read()
# Only patch release fields (both presets get cleared later for commit)
for k,v in [('keystore/release',ks),('keystore/release_user',user),('keystore/release_password',pw)]:
    t=re.sub(rf'(?m)^({re.escape(k)}=).*$', rf'\g<1>"{v}"', t)
open(path,'w',encoding='utf-8').write(t)
print('keystore injected')
PY
fi
mkdir -p "$ROOT/build"
OUT="$ROOT/build/neon_tac_blitz-release.aab"
"$GODOT_BIN" --headless --path "$ROOT" --export-release "Android Release AAB" "$OUT"
[[ -f "$OUT" ]] || { echo "AAB missing"; exit 2; }
ls -lh "$OUT"
# scrub secrets from preset after build
python3 - "$PRESET" <<'PY'
import re, sys
from pathlib import Path
p = Path(sys.argv[1])
t = p.read_text()
for k in ['keystore/debug','keystore/debug_user','keystore/debug_password','keystore/release','keystore/release_user','keystore/release_password']:
    t = re.sub(rf'(?m)^({k}=).*$', r'\1""', t)
p.write_text(t)
print('scrubbed')
PY
echo "OK: $OUT"
