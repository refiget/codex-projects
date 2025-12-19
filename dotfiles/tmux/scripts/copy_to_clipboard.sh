#!/usr/bin/env bash
set -euo pipefail

# Routes tmux/vim copy to the right clipboard backend.
# Defaults:
#   - Local（非 SSH）：优先系统剪贴板，失败时 OSC52。
#   - SSH 会话：优先 OSC52 回传到本地；如需写入远端剪贴板，设置 TMUX_CLIPBOARD_PREFER_REMOTE=1。
#   - 强制 OSC52：TMUX_CLIPBOARD_FORCE_OSC52=1。

content=$(cat | tr -d '\r')

is_ssh_session() {
  [[ -n "${SSH_CONNECTION:-}" || -n "${SSH_TTY:-}" ]]
}

# Keep tmux buffer in sync (and trigger set-clipboard if enabled)
copy_via_tmux() {
  if command -v tmux >/dev/null 2>&1 && [[ -n "${TMUX:-}" ]]; then
    if tmux set-buffer -w -- "$content" 2>/dev/null || tmux set-buffer -- "$content"; then
      return 0
    fi
  fi
  return 1
}

# Platform clip helpers (local sessions)
copy_via_host() {
  if command -v pbcopy >/dev/null 2>&1; then
    if printf '%s' "$content" | pbcopy; then
      return 0
    fi
  fi
  if command -v wl-copy >/dev/null 2>&1; then
    if printf '%s' "$content" | wl-copy --type text 2>/dev/null || printf '%s' "$content" | wl-copy 2>/dev/null; then
      return 0
    fi
  fi
  if command -v xclip >/dev/null 2>&1; then
    if printf '%s' "$content" | xclip -selection clipboard 2>/dev/null; then
      return 0
    fi
  fi
  if command -v xsel >/dev/null 2>&1; then
    if printf '%s' "$content" | xsel --clipboard --input 2>/dev/null; then
      return 0
    fi
  fi
  if command -v powershell.exe >/dev/null 2>&1; then
    if powershell.exe -NoProfile -Command Set-Clipboard -Value @"
${content}
"@; then
      return 0
    fi
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

prefer_remote=${TMUX_CLIPBOARD_PREFER_REMOTE:-0}
force_osc52=${TMUX_CLIPBOARD_FORCE_OSC52:-0}

prefer_osc52=0
if [[ "$force_osc52" == "1" ]]; then
  prefer_osc52=1
elif is_ssh_session && [[ "$prefer_remote" != "1" ]]; then
  prefer_osc52=1
fi

copied=0
if [[ $prefer_osc52 -eq 1 ]]; then
  if copy_via_osc52; then
    copied=1
  elif copy_via_host; then
    copied=1
  fi
else
  if copy_via_host; then
    copied=1
  elif copy_via_osc52; then
    copied=1
  fi
fi

exit 0
