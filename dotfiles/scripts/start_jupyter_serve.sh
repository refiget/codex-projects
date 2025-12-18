#!/bin/bash

# ========== 1. 激活虚拟环境 ==========
echo "🔧 Activating venv..."
source ~/.venvs/cs61a_learning/bin/activate

# ========== 2. 检查端口是否被 Jupyter 占用 ==========
PORT=8888
echo "🔍 Checking if port $PORT is in use..."

# 查找占用 $PORT 的 Jupyter 进程（只杀死 jupyter，不杀别的服务）
PID=$(lsof -t -i:$PORT -sTCP:LISTEN | xargs -r ps -o pid,cmd | grep jupyter | awk '{print $1}')

if [ -n "$PID" ]; then
    echo "⚠️ Found existing Jupyter on port $PORT (PID: $PID), killing..."
    kill -9 $PID
    sleep 1
else
    echo "✅ No existing Jupyter using port $PORT."
fi

# ========== 3. 启动 Jupyter Lab ==========
echo "🚀 Starting JupyterLab on port $PORT..."
jupyter lab --no-browser --ip=0.0.0.0 --port=$PORT
