# tmux status 外观 (参考 tmux_reference)

实现参考外观的左/右状态栏，脚本路径会在 `~/.tmux.conf` 中调用。

## 组件
- `left.sh`：Powerline 风格 session 列表（当前用主题色、非当前灰底，窄屏仅显示编号）。
- `right.sh`：雨条(rainbarf，可选) → 网络速率两段（使用 `TMUX_THEME_COLOR` 背景），宽度不足自动隐藏；未安装 rainbarf 或无速率输出时回退为时间。
- `update_theme_color.sh`：读取 `TMUX_THEME_COLOR`，同步活动边框颜色。
- `net.sh`：跨平台获取主接口的上下行速率，输出 `xK/S yK/S` 纯文本。

## 依赖
- Powerline 字符字体。
- 可选：`rainbarf`（资源条）、`jq`、`python3`。

## 可调环境变量
- `TMUX_THEME_COLOR`：主题色（默认 `#b294bb`）。
- `TMUX_LEFT_NARROW_WIDTH`：左侧窄屏阈值，默认 80 列。
- `TMUX_RIGHT_MIN_WIDTH`：右侧显示阈值，默认 90 列。
- `TMUX_RAINBARF`：是否显示雨条，默认 1（开启）。

## 使用
1) 确认 `dotfiles/scripts` 已通过 `deploy.sh` 链接到 `~/scripts`，并使用最新的 `~/.tmux.conf`。
2) macOS 部署时 `deploy.sh` 会生成 `~/.config/tmux/local-status.conf` 写入背景色（默认 Dracula）；可在部署前导出 `TMUX_STATUS_BG` 指定颜色。
3) 如需自定义主题色：`tmux set-environment -g TMUX_THEME_COLOR '#a3be8c'` 后 `tmux source-file ~/.tmux.conf`。
4) 在已有 tmux 内重载：`tmux source-file ~/.tmux.conf`。
5) 未安装的可选依赖（rainbarf）对应段落会自动隐藏或降级。
