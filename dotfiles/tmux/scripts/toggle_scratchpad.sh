#!/usr/bin/env bash
set -euo pipefail

# Toggle a per-session scratchpad window. When invoked from the scratchpad
# window it jumps back to the previous window; otherwise it selects or
# creates the scratchpad in the current session.
name="${TMUX_SCRATCHPAD_NAME:-scratchpad}"
start_dir="${TMUX_SCRATCHPAD_PATH:-$HOME}"

session_name=$(tmux display-message -p '#S')
current_window=$(tmux display-message -p '#{window_name}')
target_window="${session_name}:${name}"

if [[ "$current_window" == "$name" ]]; then
  tmux last-window
  exit 0
fi

if tmux list-windows -F '#{window_name}' -t "$session_name" 2>/dev/null | grep -Fxq "$name"; then
  tmux select-window -t "$target_window"
else
  tmux new-window -n "$name" -c "$start_dir"
fi
