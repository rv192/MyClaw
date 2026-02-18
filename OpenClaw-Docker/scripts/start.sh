#!/bin/bash
# OpenClaw Gateway 启动脚本

set -e

export BUN_INSTALL="/root/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

echo "🚀 启动 OpenClaw Gateway..."

# ========================================
# 1. 初始化 /root/.secure（只存储 Tailscale auth key）
# ========================================
echo "🔐 初始化敏感信息..."
SECURE_DIR="/root/.secure"
mkdir -p "$SECURE_DIR"
chmod 700 "$SECURE_DIR"

# 只写入 Tailscale Auth Key（如果有）
if [ -n "$TAILSCALE_AUTH_KEY" ]; then
    echo "$TAILSCALE_AUTH_KEY" > "$SECURE_DIR/tailscale-auth-key"
    chmod 600 "$SECURE_DIR/tailscale-auth-key"
    echo "✅ Tailscale Auth Key 已存储"
else
    echo "⚠️  Tailscale Auth Key 未设置"
fi

# ========================================
# 2. 启动 Tailscale（如果配置了）
# ========================================
if [ -f "$SECURE_DIR/tailscale-auth-key" ]; then
    echo "🔗 启动 Tailscale..."
    TAILSCALE_KEY=$(cat "$SECURE_DIR/tailscale-auth-key")
    sudo tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock &
    sleep 3
    tailscale up --authkey="$TAILSCALE_KEY" || true
else
    echo "⚠️  跳过 Tailscale 启动"
fi

# ========================================
# 3. 启动 OpenClaw Gateway
# ========================================
echo "🤖 启动 OpenClaw Gateway..."
exec openclaw gateway --verbose --allow-unconfigured
