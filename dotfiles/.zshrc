# ============================================================
# Basic Environment
# ============================================================

# 1. 开启变量动态刷新 (关键：让 Vim 和 Venv 能够实时变化)
setopt PROMPT_SUBST  # 自动替换特殊字符

setopt HIST_IGNORE_ALL_DUPS  # ignore the duplicated CMD
setopt HIST_IGNORE_SPACE  # ignore the CMD head of a space
setopt HIST_REDUCE_BLANKS # reduce the superfluous blanks
setopt HIST_VERIFY  # a traditional way to auto complete
HISTSIZE=5000 # the current number of history
SAVEHIST=5000  # the saved history locally
HISTFILE=~/.zsh_history

setopt CORRECT  # spell check for CMD
setopt AUTO_CD # auto-cd when type a name of a directory
setopt INTERACTIVE_COMMENTS

# ============================================================
# 🌍 OS Detection & Path (跨平台核心)
# ============================================================
os_name=$(uname -s)            
is_macos=false                
is_linux=false
case "$os_name" in
  Darwin) is_macos=true ;;
  Linux)  is_linux=true ;;
esac

# 处理 PATH (兼容 Mac Homebrew 和 Linux)
typeset -U path PATH  # declare a variable, -U mean remove the duplicates/
path=(
  "$HOME/.local/bin"
  "/usr/local/bin"
  "/usr/bin"
  "/bin"
  "/usr/sbin"
  "/sbin"
  $path
)

# 如果是 Mac 且有 Brew，加入 Brew 路径
if [[ -f /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
if $is_linux && command -v pacman >/dev/null 2>&1; then
  export PATH="/usr/local/sbin:/usr/local/bin:$PATH"
fi

# TexLive path (Mac)
if $is_macos; then
  export PATH="/usr/local/texlive/2025/bin/universal-darwin:$PATH"
fi


export EDITOR="nvim"
export VISUAL="nvim"
export PAGER="less"

autoload -U colors && colors
[[ $- != *i* ]] && return  # only for interactive shells

# --- 虚拟环境获取函数 ---
function get_venv_prompt() {
  local venv_name="base"
  if [[ -n "$CONDA_DEFAULT_ENV" ]]; then
    venv_name="$CONDA_DEFAULT_ENV"
  elif [[ -n "$VIRTUAL_ENV" ]]; then
    venv_name="$(basename "$VIRTUAL_ENV")"
  fi
  echo "(%F{cyan}${venv_name}%f)"
}

# ============================================================
# Zim Framework
# ============================================================
export ZIM_HOME=${ZIM_HOME:-${ZDOTDIR:-${HOME}}/.zim}

prompt-pwd() { print -P "%~" }

[[ -s ${ZIM_HOME}/init.zsh ]] && source ${ZIM_HOME}/init.zsh

# ============================================================
# Prompt Injection (Left Side)
# ============================================================
if [[ "$PROMPT" != *"get_venv_prompt"* ]]; then
  PROMPT='$(get_venv_prompt) '"$PROMPT"
fi

# ============================================================
# 🛠 Aliases (跨平台适配)
# ============================================================
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias ..='cd ..'
alias ...='cd ../..'

# --- ls 颜色适配 ---
if $is_macos; then
  alias ls='ls -G'
  alias o='open'
  alias flushdns='sudo killall -HUP mDNSResponder'
else
  alias ls='ls --color=auto'
  alias o='xdg-open'
  if command -v pacman >/dev/null 2>&1; then
    alias update='sudo pacman -Syu'
  else
    alias update='sudo apt update && sudo apt upgrade -y'
  fi
fi

alias ll='ls -lh'
alias la='ls -lah'
alias l='ls -CF'

alias reload='source ~/.zshrc && echo "✅ Reloaded!"'
alias nvimrc="nvim ~/.config/nvim/init.lua"
alias vim='nvim'
alias vi='nvim'
alias lg='lazygit'
alias jl='jupyter lab'


# ============================================================
# External Tools (Yazi, Zoxide, FZF, NVM)
# ============================================================

# Yazi
y() {
  local tmp="$(mktemp)"
  yazi --cwd-file="$tmp" "$@"
  [[ -f "$tmp" ]] && cd "$(cat "$tmp")" && rm -f "$tmp"
}

# Zoxide
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
  alias za='zoxide add $(pwd)'
  alias zl='zoxide query -l'
  alias zf='zoxide query'
fi

# FZF
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && source /usr/share/doc/fzf/examples/key-bindings.zsh
[ -f /usr/share/doc/fzf/examples/completion.zsh ] && source /usr/share/doc/fzf/examples/completion.zsh
export FZF_IGNORE_FILE="$HOME/.ignore"
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --strip-cwd-prefix --ignore-file "$FZF_IGNORE_FILE" --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --strip-cwd-prefix --ignore-file "$FZF_IGNORE_FILE" --exclude .git'

# Lazy NVM
export NVM_DIR="$HOME/.nvm"
lazy_nvm() {
  unset -f node npm nvm
  [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
}
node() { lazy_nvm; node "$@"; }
npm() { lazy_nvm; npm "$@"; }
nvm() { lazy_nvm; nvm "$@"; }

# ============================================================
# Keybindings
# ============================================================
bindkey -v
bindkey '^R' history-incremental-search-backward
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[1~' beginning-of-line
bindkey '^[[4~' end-of-line

# ============================================================
# Tmux mode sync (colors only; no cursor output)
# ============================================================
if [[ -n "$TMUX" ]]; then
  tmux set-environment -g TMUX_MODE insert >/dev/null 2>&1
  tmux run-shell -b "~/.config/tmux/scripts/update_theme_color.sh" >/dev/null 2>&1
fi

_tmux_mode_sync() {
  [[ -z "$TMUX" ]] && return
  local km="${1:-$KEYMAP}"
  local mode="insert"
  [[ "$km" == "vicmd" ]] && mode="normal"
  tmux set-environment -g TMUX_MODE "$mode" >/dev/null 2>&1
  tmux run-shell -b "~/.config/tmux/scripts/update_theme_color.sh" >/dev/null 2>&1
  tmux refresh-client -S >/dev/null 2>&1
}
autoload -Uz add-zsh-hook
zle -N zle-keymap-select _tmux_mode_sync
zle -N zle-line-init _tmux_mode_sync
add-zsh-hook precmd _tmux_mode_sync

# ============================================================
# Init Checks
# ============================================================
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# 依赖自检（保守提示，不改现有功能/UI）
if ! command -v node >/dev/null 2>&1; then
  if $is_linux; then
    print "⚠️  未检测到 node，部分工具（如 coc）可能不可用。Arch: pacman -S nodejs npm"
  elif $is_macos; then
    print "⚠️  未检测到 node，部分工具（如 coc）可能不可用。macOS: brew install node"
  else
    print "⚠️  未检测到 node，部分工具（如 coc）可能不可用。"
  fi
fi

if ! command -v npm >/dev/null 2>&1 && ! command -v pnpm >/dev/null 2>&1 && ! command -v yarn >/dev/null 2>&1; then
  if $is_linux; then
    print "⚠️  未检测到 npm/pnpm/yarn，无法安装 js 依赖（coc 扩展等）。Arch: pacman -S npm"
  elif $is_macos; then
    print "⚠️  未检测到 npm/pnpm/yarn，无法安装 js 依赖（coc 扩展等）。macOS: brew install node"
  else
    print "⚠️  未检测到 npm/pnpm/yarn，无法安装 js 依赖（coc 扩展等）。"
  fi
fi

if ! command -v python3 >/dev/null 2>&1; then
  if $is_linux; then
    print "⚠️  未检测到 python3，nvim python host 可能不可用。Arch: pacman -S python"
  elif $is_macos; then
    print "⚠️  未检测到 python3，nvim python host 可能不可用。macOS: brew install python"
  else
    print "⚠️  未检测到 python3，nvim python host 可能不可用。"
  fi
fi

if ! command -v fzf >/dev/null 2>&1; then
  if $is_linux; then
    print "⚠️  未检测到 fzf，fzf-tab 等功能不可用。Arch: pacman -S fzf"
  elif $is_macos; then
    print "⚠️  未检测到 fzf，fzf-tab 等功能不可用。macOS: brew install fzf"
  else
    print "⚠️  未检测到 fzf，fzf-tab 等功能不可用。"
  fi
fi

if [[ ! -f ~/.zshrc.zwc || ~/.zshrc -nt ~/.zshrc.zwc ]]; then
  zcompile ~/.zshrc 2>/dev/null
fi

if [[ -o interactive ]]; then
  command -v fastfetch >/dev/null && fastfetch
fi

# ===========================================================
# load local config
# ===========================================================
# Load machine-local overrides if present (not synced to Git)
if [ -f "$HOME/.zshrc.local" ]; then
  source "$HOME/.zshrc.local"
fi

# ============================================================
# 🚀 Auto-Start Tmux (Linux Server Only)
# ============================================================
# 只在 Linux 服务器上自动进入 Tmux，Mac 本地不进
if [[ -z "$TMUX" && "$(uname)" == "Linux" ]]; then
  # 连接 main 会话，没有则新建。退出 Tmux 后自动断开 SSH
  exec tmux new-session -A -s main
fi
