# 剪贴板 Workflow

## 目标
- 保持现有按键方案（tmux/nvim 中 `Y` 复制），但确保复制落到「当前使用者的系统剪贴板」。
- 本地（macOS）使用原生剪贴板工具，远程（SSH 到 Arch）优先回传到本地终端，必要时使用 OSC52。
- tmux 与 Neovim 共享同一套脚本，避免行为分叉。

## 现状评估
- tmux：copy-mode-vi 中 `Y` 已绑定 `copy_to_clipboard.sh`；`set-clipboard` 已开启；支持 `C-S-v/M-V` 粘贴。脚本依次尝试 `pbcopy/wl-copy/xclip/xsel`，然后 OSC52。
- Neovim：`Y`/可视 `Y` 映射到 `"+` 寄存器，`vim.g.clipboard` 使用同一个 tmux 脚本；`clipboard` 选项保持默认，不影响寄存器行为。
- 问题：在 SSH 登录的远程 tmux/Neovim 会优先命中远端的 `xclip`/`wl-copy`，导致 `Y` 落在服务器剪贴板而非本地；未明确本地与远程的切换策略。

## 主流方案扫描
- 直接调用系统工具：macOS `pbcopy/pbpaste`、Wayland `wl-clipboard`、X11 `xclip/xsel`。
- tmux-yank/自定义 `copy-pipe`：在 copy-mode 中将选区送给剪贴板工具，并可同时写入 tmux buffer。
- OSC52：通过 `Ms` 终端能力或手写转义，将内容回传到外层终端（适合 SSH）；Neovim 常用 `osc52`/`win32yank` 提供器。
- macOS 旧方案 `reattach-to-user-namespace`（新版 tmux + pbcopy 已可省略）。

## 本仓库实施方案
1) 入口保持不变：tmux copy-mode-vi 的 `Y`、Neovim 的 `Y`/可视 `Y`。
2) 复制脚本改为“先分场景，再选后端”：
   - 检测 SSH（`SSH_CONNECTION`/`SSH_TTY`）时，优先 OSC52（直接回传本地终端）；若被禁用再尝试远端剪贴板工具。
   - 非 SSH 时仍优先本地剪贴板工具（pbcopy/wl-copy/xclip/xsel），失败时退回 OSC52。
   - 始终同步 tmux buffer（便于 `paste-buffer` 与 `set-clipboard`）。
3) Neovim 继续复用同一脚本；`clipboard` 选项保持默认，避免破坏默认寄存器。
4) OSC52 限长由 `OSC52_MAX_BYTES` 控制，防止过大输出卡死终端。

## 评审与改进
- 风险：少数终端/跳板禁用 OSC52；解决：失败后回退到可用的远端剪贴板工具，并保持 tmux buffer 可粘贴。
- 风险：用户确实想写入远端剪贴板；解决：允许通过环境变量 `TMUX_CLIPBOARD_PREFER_REMOTE=1` 覆盖行为。
- 改动后，远程默认体验改为“优先回本地”，与任务需求一致，且按键与默认寄存器习惯保持不变。

## 验证建议
- 本地 macOS：tmux 中进入 copy-mode，选中文本按 `Y`，在 shell 中 `pbpaste` 应有内容。
- SSH 到远程 tmux/Neovim：按 `Y` 后在本地终端直接 `pbpaste`/`xclip -o` 应能得到内容；若终端不支持 OSC52，远端 `xclip` 可作为兜底。
