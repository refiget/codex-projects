#!/usr/bin/env bash
set -euo pipefail

content=$(cat | tr -d '\r')

# Keep tmux buffer in sync (and trigger set-clipboard if enabled)
copy_via_tmux() {
  if command -v tmux >/dev/null 2>&1 && [[ -n "${TMUX:-}" ]]; then
    tmux set-buffer -w -- "$content" 2>/dev/null || tmux set-buffer -- "$content"
    return 0
  fi
  return 1
}

# Platform clip helpers (local sessions)
copy_via_host() {
  if command -v pbcopy >/dev/null 2>&1; then
    printf '%s' "$content" | pbcopy || true
    return 0
  fi
  if command -v wl-copy >/dev/null 2>&1; then
    printf '%s' "$content" | wl-copy --type text || wl-copy || true
    return 0
  fi
  if command -v xclip >/dev/null 2>&1; then
    printf '%s' "$content" | xclip -selection clipboard || true
    return 0
  fi
  if command -v xsel >/dev/null 2>&1; then
    printf '%s' "$content" | xsel --clipboard --input || true
    return 0
  fi
  if command -v powershell.exe >/dev/null 2>&1; then
    powershell.exe -NoProfile -Command Set-Clipboard -Value @"
${content}
"@ || true
    return 0
  fi
  return 1
}

# OSC52 fallback (works over SSH to local terminal if allowed)
copy_via_osc52() {
  local max_bytes=${OSC52_MAX_BYTES:-100000}
  if (( max_bytes > 0 )) && (( ${#content} > max_bytes )); then
    return 1
  fi

  local base64
  base64=$(printf '%s' "$content" | base64 | tr -d '\r\n')
  local osc="\e]52;c;${base64}\a"

  # Wrap when inside tmux so the outer terminal receives the sequence
  if [[ -n "${TMUX:-}" ]]; then
    osc="\ePtmux;\e${osc}\e\\"
  fi

  local tty_target=${TTY:-$(tty 2>/dev/null || true)}
  if [[ -n "$tty_target" && -w "$tty_target" ]]; then
    printf '%b' "$osc" > "$tty_target"
  else
    printf '%b' "$osc"
  fi
}

copy_via_tmux || true
copy_via_host || copy_via_osc52 || true
