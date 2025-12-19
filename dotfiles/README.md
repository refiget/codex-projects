# Dotfiles 指南

## 依赖与额外安装
- 基础：tmux ≥3.2、fzf、ripgrep(`rg`)、git、Python3（含 `pynvim`）、Nerd Font 终端字体。
- Neovim：v0.8+，Node 16+，npm/pnpm/yarn 任一；`markdown-preview.nvim` 首次会 `cd app && npm install`（已在 Plug 配置中）。
- 剪贴板：终端需支持 OSC52；macOS 自带 `pbcopy/pbpaste`，Linux 建议 `wl-clipboard` 或 `xclip`。
- 可选：starship（tmux pane 标题），rainbarf（tmux 右侧带宽条）。

## tmux（mac 前缀 C-s，服务器 C-b）
- 状态栏：脚本位于 `tmux/tmux-status/left.sh|right.sh`，右侧显示时间（块保留，去掉箭头），可选 rainbarf；pane 顶栏用 starship 显示路径+git。
- 复制：`M-v` 进入 copy-mode，`y` 复制 tmux buffer，`Y` 复制系统剪贴板（OSC52 支持 SSH 回传）；`C-S-v`/`M-V` 粘贴系统剪贴板。
- 窗口/会话：`C-p/C-n` 切窗口；`M-1..9` 直达窗口；`C-1..9`/F1..F5 切会话；`M-o` 新窗口同路径，`M-O` 拆窗格成新窗口。
- 分屏/移动：`h/j/k/l` 分割；`M-h/j/k/l` 移动 pane；`M-H/J/K/L` 调大小；`M-f` 缩放；`Space` 横竖切换。
- 其他：`C-g` 切同步输入；`prefix + r` 重载配置。

## Zsh
- 基于 Zim，启用 fzf-tab；`reload` 重载 shell；`o` 打开文件/目录；`update` 包更新。
- nvm 懒加载，首次调用 node/npm 时初始化。

## Neovim（Leader 空格）
- 依赖：Node 16+、Python3 + `pynvim`，vim-plug 管理。
- 快捷：`<leader>w` 查找（Telescope）；`<leader>e` 文件树（coc-explorer）；`r` 运行当前 Python；`<leader>f` 格式化；`cr` 重命名；`<leader>mp/mP` 打开/关闭 Markdown 预览（浏览器，KaTeX/Mermaid）。
- 补全/LSP：coc.nvim + coc-pyright 等，缺失时后台新 tab 自动 `CocInstall`。
- 片段：LuaSnip + friendly-snippets；Obsidian LaTeX Suite 常用触发已迁移为 Markdown autosnippet。
- 复制：OSC52 + `unnamedplus`；可视 `Y` 复制系统剪贴板；`x/X/c/C` 写黑洞寄存器防止污染。
- coc-explorer 目录图标配色已与 Yazi Dracula Pro 同步（紫色 `#bd93f9`）。

## 部署与更新
- 首次启动 Neovim：自动 `PlugInstall --sync`，随后自动检测并后台安装缺失 coc 扩展。
- tmux 重载：`prefix + r`；zsh 重载：`reload`。
