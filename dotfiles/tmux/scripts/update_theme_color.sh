#!/usr/bin/env bash
set -euo pipefail

# Determine theme color from tmux environments with fallback
# Prefer session env, then global env; if unset, default differs by OS:
# 普通模式浅绿，插入模式紫色
default_base="#b5e8a8"

theme_line=$(tmux show-environment TMUX_THEME_COLOR 2>/dev/null || true)
if [[ "$theme_line" == TMUX_THEME_COLOR=* ]]; then
  base_theme="${theme_line#TMUX_THEME_COLOR=}"
else
  theme_line=$(tmux show-environment -g TMUX_THEME_COLOR 2>/dev/null || true)
  if [[ "$theme_line" == TMUX_THEME_COLOR=* ]]; then
    base_theme="${theme_line#TMUX_THEME_COLOR=}"
  else
    base_theme="$default_base"
  fi
fi

# Mode-aware theme for active border / top labels
insert_theme="#bd93f9"
tmux_mode="normal"
mode_line=$(tmux show-environment TMUX_MODE 2>/dev/null || tmux show-environment -g TMUX_MODE 2>/dev/null || true)
if [[ "$mode_line" == TMUX_MODE=* ]]; then
  tmux_mode="${mode_line#TMUX_MODE=}"
fi

if [[ "$tmux_mode" == "insert" ]]; then
  theme="$insert_theme"   # insert -> purple
else
  theme="$default_base"   # normal -> green
fi

# Cache as a user option and apply to border style
tmux set -g @theme_color "$theme"
tmux set -g pane-active-border-style "fg=$theme"

exit 0
