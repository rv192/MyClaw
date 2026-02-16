#!/bin/bash
set -e

# 检查权限
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root" >&2
    exit 1
fi

# 解析参数
AUTH_KEY=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --auth-key)
            AUTH_KEY="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

echo "🔗 配置 Tailscale..."

if [ -n "$AUTH_KEY" ]; then
    # 使用 Auth Key 自动连接
    tailscale up --authkey="$AUTH_KEY" --hostname="openclaw-gateway"
    echo "✅ Tailscale 已使用 Auth Key 连接"
else
    # 检查当前状态
    if tailscale status >/dev/null 2>&1; then
        echo "✅ Tailscale 已连接"
        tailscale status | head -n 5
    else
        echo "⚠️  Tailscale 未连接"
        echo "请运行以下命令手动连接:"
        echo "  docker exec -it openclaw-gateway sudo tailscale up"
        echo "或使用 Auth Key:"
        echo "  docker exec -it openclaw-gateway sudo /scripts/configure-tailscale.sh --auth-key YOUR_KEY"
    fi
fi

exit 0