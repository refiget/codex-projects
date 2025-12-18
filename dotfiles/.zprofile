eval "$(/opt/homebrew/bin/brew shellenv)"
# Auto-start tmux for interactive login shells
if command -v tmux >/dev/null 2>&1; then
    if [[ -z "$TMUX" && -n "$PS1" && "$TERM_PROGRAM" != "Apple_Terminal" ]]; then
        tmux new-session -A -s main
    fi
fi
