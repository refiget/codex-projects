#!/usr/bin/env bash
set -euo pipefail

slot="${1:-}"
if [[ -z "$slot" ]]; then
  echo "Usage: yabai_mark.sh <slot>" >&2
  exit 1
fi

YABAI_BIN="${YABAI_BIN:-/opt/homebrew/bin/yabai}"

dir="${XDG_CACHE_HOME:-$HOME/.cache}/yabai_marks"
mkdir -p "$dir"

win_info="$($YABAI_BIN -m query --windows --window 2>/dev/null || true)"
win_id=$(printf '%s' "$win_info" | /usr/bin/python3 - <<'PY'
import json,sys
try:
    data=json.load(sys.stdin)
    if isinstance(data,dict) and "id" in data:
        print(data["id"])
except Exception:
    pass
PY
)

if [[ -z "$win_id" ]]; then
  echo "No focused window to mark" >&2
  exit 1
fi

printf '%s' "$win_id" > "$dir/$slot"
exit 0
