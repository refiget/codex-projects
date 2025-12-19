# Workflow 2（tmux 剪贴板脚本）

## 目标
- 让 tmux/Neovim 中的 `Y` 可靠写入系统剪贴板：本地走系统剪贴板，SSH 优先回传本地（OSC52），按键/功能不变。
- 检查 tmux 相关脚本的兼容性，避免冗余或引入外观改动。

## 环境快照
- macOS: tmux 3.5a, Neovim 0.11.5, iTerm2（内置剪贴板）。
- Arch: tmux 3.6a, Neovim 0.11.5, xclip 已装。

## 现状与问题
- `copy_to_clipboard.sh` 在 SSH 场景优先 OSC52，但 host 方案（pbcopy/wl-copy/xclip/xsel）即使失败也返回成功，若终端禁用/不支持 OSC52 且远端无 DISPLAY，会出现“看似成功但未复制”的问题（符合当前复制失败的怀疑点）。
- tmux 配置、其他脚本对 3.5a/3.6a 兼容性正常；未发现可安全移除的冗余脚本。

## 主流方案
- 直接系统剪贴板：pbcopy/wl-clipboard/xclip/xsel。
- tmux copy-pipe + set-buffer：同步 tmux buffer 与剪贴板。
- OSC52：SSH 回传本地终端。
- 插件式方案（tmux-yank 等）功能等价但当前脚本已覆盖需求。

## 方案与执行
- 强化 `copy_to_clipboard.sh` 的后端成功检测：只有当 pbcopy/wl-copy/xclip/xsel/powershell 实际成功时才视为命中，否则再尝试其他后端；保持 tmux buffer 同步及 OSC52 优先策略（SSH 默认回传，可用 `TMUX_CLIPBOARD_PREFER_REMOTE=1` 覆盖）。
- 不改 tmux/ui 相关配置与按键。

## 方案评估
- 优点：避免 xclip 无 DISPLAY 等场景下的“假成功”，提高 SSH 场景复制成功率；保持现有键位与外观。
- 风险：若终端完全屏蔽 OSC52 且无可用剪贴板工具，仍会失败；可通过安装可用剪贴板工具或设置 `TMUX_CLIPBOARD_FORCE_OSC52`/`TMUX_CLIPBOARD_PREFER_REMOTE` 微调。
- 验证建议：本地 tmux copy-mode 选中 `Y` 后运行 `pbpaste`；SSH 远程 tmux/Neovim 选中 `Y` 后回到本地终端确认剪贴板；必要时在远端临时设置 `TMUX_CLIPBOARD_PREFER_REMOTE=1` 观察远端剪贴板是否生效。
