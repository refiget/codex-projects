#!/bin/bash

SERVER="bob@8.134.121.201"
REMOTE_SCRIPT="~/scripts/start_jupyter_serve.sh"
LOCAL_PORT=8888
REMOTE_PORT=8888
SESSION_NAME="JupyRun"

echo "🔧 开始启动远程 Jupyter Lab..."

# 杀掉旧 tmux 会话
tmux has-session -t "$SESSION_NAME" 2>/dev/null && tmux kill-session -t "$SESSION_NAME"

# 创建新的 tmux 会话（后台，不 attach）
tmux new-session -d -s "$SESSION_NAME"

# 1️⃣ 在远程启动 Jupyter（后台执行，不阻塞）
tmux send-keys -t "$SESSION_NAME" \
"ssh -f $SERVER \"bash $REMOTE_SCRIPT\"" C-m

# 给远程脚本 1 秒启动时间
sleep 1

# 2️⃣ 建立 SSH 隧道（在 tmux 中后台运行）
tmux send-keys -t "$SESSION_NAME" \
"ssh -N -L ${LOCAL_PORT}:127.0.0.1:${REMOTE_PORT} $SERVER" C-m

echo "🌐 远程 Jupyter 启动中，请稍候..."

# ⏳ 3️⃣ 延迟5 秒等待隧道建立
sleep 5

echo "🔗 正在打开：http://localhost:${LOCAL_PORT}/lab"
open "http://localhost:${LOCAL_PORT}/lab"

echo "✨ 一切准备就绪！"
