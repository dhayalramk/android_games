#!/usr/bin/env bash
# Build debug APK and install on a connected Android device/emulator.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec bash "$ROOT/scripts/qa_smoke.sh" apk
