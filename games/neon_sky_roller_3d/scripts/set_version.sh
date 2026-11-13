#!/usr/bin/env bash
# Bump Android version/name + version/code in export_presets.cfg
# Usage: ./scripts/set_version.sh 1.0.1 [code]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
NAME="${1:-}"
CODE="${2:-}"
if [[ -z "$NAME" ]]; then
  echo "Usage: $0 <version_name> [version_code]" >&2
  exit 1
fi
if [[ -z "$CODE" ]]; then
  # Derive code from semver: major*10000 + minor*100 + patch
  IFS='.' read -r MA MI PA <<<"$NAME"
  CODE=$(( ${MA:-0} * 10000 + ${MI:-0} * 100 + ${PA:-0} ))
fi
PRESET="$ROOT/export_presets.cfg"
python3 - "$PRESET" "$NAME" "$CODE" <<'PY'
import re, sys
path, name, code = sys.argv[1], sys.argv[2], sys.argv[3]
text = open(path, encoding="utf-8").read()
n_code = len(re.findall(r'(?m)^version/code=', text))
n_name = len(re.findall(r'(?m)^version/name=', text))
if n_code < 1 or n_name < 1:
    raise SystemExit("version/code or version/name missing in export_presets.cfg")
text2 = re.sub(r'(?m)^(version/code=).*$', rf'\g<1>{code}', text)
text2 = re.sub(r'(?m)^(version/name=).*$', rf'\g<1>"{name}"', text2)
open(path, "w", encoding="utf-8").write(text2)
print(f"Set version/name={name} version/code={code} ({n_code} code + {n_name} name fields)")
PY
echo "$NAME" > "$ROOT/VERSION"
# Keep project.godot config/version in sync when present
if grep -q '^config/version=' "$ROOT/project.godot" 2>/dev/null; then
  sed -i "s|^config/version=.*|config/version=\"$NAME\"|" "$ROOT/project.godot"
fi
echo "Wrote $ROOT/VERSION"
