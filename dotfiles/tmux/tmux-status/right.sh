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

# Keep segments on the terminal background to avoid color blocks on transparent themes
segment_bg="$status_bg"
segment_fg=$(tmux show -gqv '@status_fg')
[[ -z "$segment_fg" ]] && segment_fg="#f1fa8c"
# 固定时间段为 Dracula 黄，背景透明，避免模式切换色块不同步
host_bg="$status_bg"
host_fg="#f1fa8c"
time_fmt="${TMUX_TIME_FMT:-%H:%M %a %m-%d}"
separator=""
right_cap=""
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

now=$(date +"$time_fmt")
time_text=" ${now}"

# Build a connector into the time segment using host colors
host_connector_bg="$status_bg"
if [[ -n "$rainbarf_segment" ]]; then
  host_connector_bg="$rainbarf_bg"
fi
host_prefix=$(printf '#[fg=%s,bg=%s]%s#[fg=%s,bg=%s]' \
  "$host_fg" "$host_bg" "$time_text" \
  "$host_bg" "$status_bg")

printf '%s%s%s' \
  "$rainbarf_segment" \
  "$host_prefix" \
  "$right_cap"
