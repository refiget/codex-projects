#!/usr/bin/env bash
set -euo pipefail

slot="${1:-}"
if [[ -z "$slot" ]]; then
  echo "Usage: yabai_focus_mark.sh <slot>" >&2
  exit 1
fi

YABAI_BIN="${YABAI_BIN:-/opt/homebrew/bin/yabai}"
dir="${XDG_CACHE_HOME:-$HOME/.cache}/yabai_marks"
file="$dir/$slot"

if [[ ! -f "$file" ]]; then
  echo "No mark stored for $slot" >&2
  exit 1
fi

win_id=$(cat "$file")
if [[ -z "$win_id" ]]; then
  echo "Mark file empty for $slot" >&2
  exit 1
fi

# Focus; if window不存在则清理标记
if ! $YABAI_BIN -m window --focus "$win_id" 2>/dev/null; then
  rm -f "$file"
  echo "Mark $slot invalid, removed" >&2
  exit 1
fi

exit 0
