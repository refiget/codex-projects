# Deploy 使用说明

- 正常模式：`./deploy.sh` 会为关键配置创建软链，冲突会备份到 `~/dotfiles_backup_时间戳/`。
- 强制同步（不保留备份）：`./deploy.sh --force`（或 `-f/--sync`）。会删除已有目标后重新创建软链，适合远程已有老版本文件/目录需要直接覆盖的场景（例如更新 `~/.config/tmux/scripts/copy_to_clipboard.sh`）。

注意：强制模式会删除目标文件/目录，请在可接受的情况下使用；若需保留原始文件，请使用默认模式。
