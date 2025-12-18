#!/usr/bin/env bash
set -euo pipefail

current_session_id="${1:-}"
current_session_name="${2:-}"

detect_current_session_id=$(tmux display-message -p '#{session_id}')
detect_current_session_name=$(tmux display-message -p '#{session_name}')

if [[ -z "$current_session_id" ]]; then
  current_session_id="$detect_current_session_id"
fi

if [[ -z "$current_session_name" ]]; then
  current_session_name="$detect_current_session_name"
fi

status_bg=$(tmux show -gqv status-bg)
[[ -z "$status_bg" ]] && status_bg=default

inactive_bg=$(tmux show -gqv '@status_inactive_bg')
inactive_fg=$(tmux show -gqv '@status_inactive_fg')
active_bg=$(tmux show -gqv '@status_active_bg')
active_fg=$(tmux show -gqv '@status_active_fg')

# fallbacks if options not set
[[ -z "$inactive_bg" ]] && inactive_bg="$status_bg"
[[ -z "$inactive_fg" ]] && inactive_fg="#c5c8c6"
[[ -z "$active_bg" ]] && active_bg="$status_bg"
[[ -z "$active_fg" ]] && active_fg="#f8f8f2"
separator=""
left_cap="█"
max_width=18

# width-based label policy: when narrow (<80 cols by default),
# show title for active session and only the numeric index for inactive ones.
left_narrow_width=${TMUX_LEFT_NARROW_WIDTH:-80}
term_width=$(tmux display-message -p '#{client_width}' 2>/dev/null || true)
if [[ -z "${term_width:-}" || "$term_width" == "0" ]]; then
  term_width=$(tmux display-message -p '#{window_width}' 2>/dev/null || true)
fi
if [[ -z "${term_width:-}" || "$term_width" == "0" ]]; then
  term_width=${COLUMNS:-}
fi
is_narrow=0
if [[ -n "${term_width:-}" && "$term_width" =~ ^[0-9]+$ ]]; then
  if (( term_width < left_narrow_width )); then
    is_narrow=1
  fi
fi

normalize_session_id() {
  local value="$1"
  value="${value#\$}"
  printf '%s' "$value"
}

trim_label() {
  local value="$1"
  if [[ "$value" =~ ^[0-9]+-(.*)$ ]]; then
    printf '%s' "${BASH_REMATCH[1]}"
  else
    printf '%s' "$value"
  fi
}

extract_index() {
  local value="$1"
  if [[ "$value" =~ ^([0-9]+)-.*$ ]]; then
    printf '%s' "${BASH_REMATCH[1]}"
  else
    printf ''
  fi
}

sessions=$(tmux list-sessions -F '#{session_id}::#{session_name}' 2>/dev/null || true)
if [[ -z "$sessions" ]]; then
  exit 0
fi

rendered=""
prev_bg=""
current_session_id_norm=$(normalize_session_id "$current_session_id")
current_session_trimmed=$(trim_label "$current_session_name")
while IFS= read -r entry; do
  [[ -z "$entry" ]] && continue
  session_id="${entry%%::*}"
  name="${entry#*::}"
  [[ -z "$session_id" ]] && continue

  session_id_norm=$(normalize_session_id "$session_id")
  segment_bg="$inactive_bg"
  segment_fg="$inactive_fg"
  trimmed_name=$(trim_label "$name")
  is_current=0
  if [[ "$session_id" == "$current_session_id" || "$session_id_norm" == "$current_session_id_norm" || "$trimmed_name" == "$current_session_trimmed" ]]; then
    is_current=1
    segment_bg="$active_bg"
    segment_fg="$active_fg"
  fi

  if (( is_narrow == 1 )); then
    if (( is_current == 1 )); then
      label="$trimmed_name"  # active: show TITLE (trim N-)
    else
      idx=$(extract_index "$name")
      if [[ -n "$idx" ]]; then
        label="$idx"
      else
        label="$trimmed_name"
      fi
    fi
  else
    label="$trimmed_name"      # wide: current behavior (TITLE everywhere)
  fi
  if (( ${#label} > max_width )); then
    label="${label:0:max_width-1}…"
  fi

  if [[ -z "$prev_bg" ]]; then
    rendered+="#[fg=${segment_bg},bg=${status_bg}]${left_cap}"
  else
    rendered+="#[fg=${prev_bg},bg=${segment_bg}]${separator}"
  fi
  rendered+="#[fg=${segment_fg},bg=${segment_bg}] ${label} "
  prev_bg="$segment_bg"
done <<< "$sessions"

if [[ -n "$prev_bg" ]]; then
  rendered+="#[fg=${prev_bg},bg=${status_bg}]${separator}"
fi

printf '%s' "$rendered"
