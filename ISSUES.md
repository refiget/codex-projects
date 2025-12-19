# Issue Log

## 已修复
- [clipboard-ssh-default] 远程 tmux/Neovim 复制会优先命中远端 `xclip/wl-copy`，无法把 `Y` 回传到本地。已在 `dotfiles/tmux/scripts/copy_to_clipboard.sh` 上增加 SSH 场景优先 OSC52（可用 `TMUX_CLIPBOARD_PREFER_REMOTE=1` 覆盖），同时保留 tmux buffer 同步。
- [nvim-cr-dup-map] `dotfiles/nvim/init.lua` 与 `dotfiles/nvim/lua/user/keymaps.lua` 重复定义插入模式 `<CR>`，逻辑不一致。已移除 init.lua 中的重复映射，保留 keymaps 里的版本。
- [tmux-doc-mismatch] README 说明的 tmux 复制按键与实际配置不一致（y 实际写 tmux buffer、Y 才写系统剪贴板）。已修正文档描述：`y` → tmux buffer，`Y` → 系统剪贴板（含 OSC52）。

## 待关注
- 暂无。
