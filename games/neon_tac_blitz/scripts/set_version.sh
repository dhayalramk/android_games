#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
NAME="${1:-}"; CODE="${2:-}"
[[ -n "$NAME" ]] || { echo "Usage: $0 <version> [code]"; exit 1; }
if [[ -z "$CODE" ]]; then
  IFS='.' read -r MA MI PA <<<"$NAME"
  CODE=$(( ${MA:-0}*10000 + ${MI:-0}*100 + ${PA:-0} ))
fi
python3 - "$ROOT/export_presets.cfg" "$NAME" "$CODE" <<'PY'
import re,sys
path,name,code=sys.argv[1],sys.argv[2],sys.argv[3]
t=open(path,encoding='utf-8').read()
t=re.sub(r'(?m)^(version/code=).*$', rf'\g<1>{code}', t)
t=re.sub(r'(?m)^(version/name=).*$', rf'\g<1>"{name}"', t)
open(path,'w',encoding='utf-8').write(t)
print(f'Set {name} / {code}')
PY
echo "$NAME" > "$ROOT/VERSION"
sed -i "s|^config/version=.*|config/version=\"$NAME\"|" "$ROOT/project.godot" 2>/dev/null || true
