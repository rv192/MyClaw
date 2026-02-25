#!/bin/bash
# OpenClaw Gateway 启动脚本（官方版 + 中国插件 + Tailscale）

set -e

echo "🚀 启动 OpenClaw Gateway（官方版 + 中国插件 + Tailscale）..."

# ========================================
# 1. 初始化目录结构
# ========================================
echo "📁 初始化目录结构..."
mkdir -p /root/.openclaw/extensions
mkdir -p /root/.openclaw/skills
mkdir -p /root/.openclaw/workspace
mkdir -p /root/.openclaw/data
mkdir -p /var/lib/tailscale

# ========================================
# 2. 启动 Tailscale（如果配置了 Auth Key）
# ========================================
if [ -n "$TAILSCALE_AUTH_KEY" ]; then
    echo "🔗 启动 Tailscale..."
    
    # 启动 tailscaled 守护进程
    tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock &
    
    # 等待 tailscaled 启动
    sleep 3
    
    # 使用 auth key 登录
    tailscale up --authkey="$TAILSCALE_AUTH_KEY" --accept-routes || true
    
    echo "✅ Tailscale 已启动"
else
    echo "⚠️  TAILSCALE_AUTH_KEY 未设置，跳过 Tailscale 启动"
fi

# ========================================
# 3. 启动 sing-box（如果配置文件存在）
# ========================================
if [ -f "/etc/sing-box/config.json" ]; then
    echo "🌐 启动 sing-box 代理服务..."
    mkdir -p /var/log/sing-box
    sing-box run -c /etc/sing-box/config.json > /var/log/sing-box/sing-box.log 2>&1 &
    echo "✅ sing-box 已启动（配置文件: /etc/sing-box/config.json）"
else
    echo "⚠️  /etc/sing-box/config.json 不存在，跳过 sing-box 启动"
fi

# ========================================
# 4. 配置 HTTP 代理（用于访问被墙服务如 Telegram）
# ========================================
if [ -f "/etc/sing-box/config.json" ]; then
    echo "🔧 配置 HTTP 代理环境变量..."
    export HTTP_PROXY=http://127.0.0.1:7890
    export HTTPS_PROXY=http://127.0.0.1:7890
    export http_proxy=http://127.0.0.1:7890
    export https_proxy=http://127.0.0.1:7890
    echo "✅ 代理环境变量已设置 (http://127.0.0.1:7890)"
fi

# ========================================
# 5. 启动 OpenClaw Gateway
# ========================================
echo "🦞 启动 OpenClaw Gateway..."
exec openclaw gateway --verbose --allow-unconfigured
