#!/bin/bash
set -e

echo "🚀 启动 OpenClaw Gateway..."

# 启动 Tailscale 守护进程（后台运行）
echo "🔗 启动 Tailscale 守护进程..."
sudo tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock &
TAILSCALE_PID=$!

# 等待 Tailscale 启动
sleep 2

# 尝试自动连接（如果有 Auth Key）
if [ -n "$TAILSCALE_AUTH_KEY" ]; then
    echo "🔗 使用 Auth Key 连接 Tailscale..."
    sudo tailscale up --authkey="$TAILSCALE_AUTH_KEY" --hostname="openclaw-gateway"
fi

# 检查状态
if sudo tailscale status >/dev/null 2>&1; then
    echo "✅ Tailscale 已连接"
    sudo tailscale status | head -n 5
else
    echo "⚠️  Tailscale 未连接，运行以下命令连接:"
    echo "  docker exec -it openclaw-gateway sudo tailscale up"
    echo "或使用 Auth Key:"
    echo "  docker exec -it openclaw-gateway sudo /scripts/configure-tailscale.sh --auth-key YOUR_KEY"
fi

# 检查初始化任务清单
if [ -f "/home/node/.openclaw/INIT_TODO.md" ]; then
    echo ""
    echo "📋 检测到初始化任务清单"
    echo "📖 查看任务: docker exec -it openclaw-gateway cat /home/node/.openclaw/INIT_TODO.md"
    echo "🔧 配置平台: docker exec -it openclaw-gateway node /home/node/.openclaw/scripts/config-platform.js <platform>"
    echo ""
fi

# 启动 OpenClaw
echo "🤖 启动 OpenClaw Gateway..."
exec openclaw gateway --verbose

# 清理
trap "kill $TAILSCALE_PID" EXIT