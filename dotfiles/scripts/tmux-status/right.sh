#!/usr/bin/env bash
set -euo pipefail

# hide entire right status if terminal width is below threshold
min_width=${TMUX_RIGHT_MIN_WIDTH:-90}
width=$(tmux display-message -p '#{client_width}' 2>/dev/null || true)
if [[ -z "${width:-}" || "$width" == "0" ]]; then
  width=$(tmux display-message -p '#{window_width}' 2>/dev/null || true)
fi
if [[ -z "${width:-}" || "$width" == "0" ]]; then
  width=${COLUMNS:-}
fi
if [[ -n "${width:-}" && "$width" =~ ^[0-9]+$ ]]; then
  if (( width < min_width )); then
    exit 0
  fi
fi

status_bg=$(tmux show -gqv status-bg)
[[ -z "$status_bg" || "$status_bg" == "default" ]] && status_bg="default"

# Keep segments on the terminal background to avoid solid blocks on transparent themes
segment_bg="$status_bg"
segment_fg=$(tmux show -gqv '@status_fg')
[[ -z "$segment_fg" ]] && segment_fg="#d0d0d0"
time_bg="$segment_bg"
time_fg="$segment_fg"
separator=""
right_cap="█"
rainbarf_bg="#2e3440"
rainbarf_segment=""
rainbarf_toggle="${TMUX_RAINBARF:-1}"

case "$rainbarf_toggle" in
  0|false|FALSE|off|OFF|no|NO)
    rainbarf_toggle="0"
    ;;
  *)
    rainbarf_toggle="1"
    ;;
esac

if [[ "$rainbarf_toggle" == "1" ]] && command -v rainbarf >/dev/null 2>&1; then
  rainbarf_output=$(rainbarf --no-battery --no-remaining --no-bolt --tmux --rgb 2>/dev/null || true)
  rainbarf_output=${rainbarf_output//$'\n'/}
  if [[ -n "$rainbarf_output" ]]; then
    rainbarf_segment=$(printf '#[fg=%s,bg=%s]%s#[fg=%s,bg=%s]%s' \
      "$rainbarf_bg" "$status_bg" "$separator" \
      "$segment_fg" "$rainbarf_bg" "$rainbarf_output")
  fi
fi

# Build middle net segment和右侧时间段
connector_bg="$status_bg"
if [[ -n "$rainbarf_segment" ]]; then
  connector_bg="$rainbarf_bg"
fi

net_cmd="$HOME/scripts/tmux-status/net.sh"
net_output=""
if [[ -x "$net_cmd" ]]; then
  net_output=$(bash "$net_cmd" 2>/dev/null || true)
fi

net_segment=""
if [[ -n "$net_output" ]]; then
  net_segment=$(printf '#[fg=%s,bg=%s]%s#[fg=%s,bg=%s] %s ' \
    "$segment_fg" "$connector_bg" "$separator" \
    "$segment_fg" "$segment_bg" "$net_output")
fi

time_output=$(date '+%Y-%m-%d %H:%M')
time_prefix=$(printf '#[fg=%s,bg=%s]%s#[fg=%s,bg=%s] ' \
  "$time_fg" "$segment_bg" "$separator" \
  "$time_fg" "$time_bg")

printf '%s%s%s#[fg=%s,bg=%s]%s' \
  "$rainbarf_segment" \
  "$net_segment" \
  "$time_prefix$time_output " \
  "$time_fg" "$status_bg" "$right_cap"
