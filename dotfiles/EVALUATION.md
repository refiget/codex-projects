# Dotfiles 全面评估（维护性/兼容性/功能保持）

## 概览
- 平台：macOS + Arch，双层 tmux + SSH；终端 iTerm2 支持 OSC52。
- 配置模块化：Neovim 分拆 env/options/autocmds/clipboard/plugins/coc/keymaps/snippets/tmux；tmux/zsh 独立；deploy 支持软链+可选 lazy 同步。
- 主要需求：复制统一（tmux/Neovim/本地-远程）、插入模式配色同步、Python/脚本开发。

## 发现（按组件）
### tmux
- 复制链路：`copy_to_clipboard.sh`/`paste_from_clipboard.sh` 处理 pbcopy/xclip/xsel/PowerShell + OSC52，带 TTY 解析；`@theme_color` 依赖 `update_theme_color.sh` 与 `TMUX_MODE` 环境。
- 嵌套支持：`allow-passthrough on`、`Ms` 覆盖、Tmux mode sync（zsh/Neovim）已启用；Neovim 也可用内置 OSC52 fallback。
- 状态栏：本地与远程分支；右侧时间栏已改为固定 Dracula 黄前景，透明背景；pane 标题、窗口标签使用 `@theme_color`（normal=绿、insert=紫）。
- 冗余：`scripts/tmux-status` 已清理；仍有双 devicons 已去重（仅 nvim-web-devicons）。

### Neovim
- 插件：lazy.nvim，默认懒加载；Coc 扩展列表在 `dotfiles/coc/extensions/package.json`（pyright/tsserver/json/yaml/sh/snippets/explorer/lua）。
- 复制：优先 tmux 脚本；找不到脚本用内置 `vim.ui.clipboard.osc52`；再无则 Lua OSC52。`vim.opt.clipboard=""` 保持 y/Y 分离。
- 模式同步：`user.tmux` 自动把 Insert/Normal 写入 TMUX_MODE 并触发 tmux 配色更新。
- Python host：自动探测 `~/venvs/nvim` → `~/.venvs/nvim` → Homebrew → 系统；Black 路径固定 `~/venvs/nvim/bin/black`，格式化仅 Python on save。
- 可能缺口：未生成 `lazy-lock.json`（可复现性）；Markdown/YAML/JSON 等通用格式化未配 Prettier，若有需求需补。

### zsh
- 模式同步：去重后单一 `_tmux_mode_sync`，启动 tmux 会初始化 TMUX_MODE=insert 并跑配色脚本；zle hooks 继续同步，响应快。
- 依赖提示：无 node/npm/python 会警告，不改功能。

### deploy
- 支持 `--force` 覆盖、`--lazy` 自动 `Lazy sync`；未加严格模式（未 set -euo pipefail），但逻辑简单。

### 其他
- Coc Explorer/文件图标：仅 nvim-web-devicons 保留；配色一致。
- 复制仍需终端/各层 tmux 支持 OSC52；脚本链路已统一。

## 建议（保持现有功能/外观）
1) 生成并提交 `lazy-lock.json`，提高插件版本可复现性。
2) deploy 脚本可加 `set -euo pipefail` 与 `IFS=$'\n\t'` 提升健壮性；可选添加 `--no-lazy` 关闭自动拉插件。
3) tmux 配色刷新：在 `update_theme_color.sh` 末尾添加一次 `tmux refresh-client -S`，确保 pane/窗口/状态栏同时更新，避免偶发不同步。
4) 纯 OSC52 使用者可考虑在 Neovim clipboard 中优先使用内置 `vim.ui.clipboard.osc52`（已启用）；保持 tmux 脚本为首选以兼容 pbcopy/xclip。
5) Black 体验：若需更严格检查，可移除 `--fast`；若无需求可保持。
