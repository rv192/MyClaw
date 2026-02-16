#!/bin/bash
set -euo pipefail

# 检查权限
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root" >&2
    exit 1
fi

PLATFORM="${1:-}"
ENV_FILE="/root/.secure/.env"

if [ -z "$PLATFORM" ]; then
    echo "Usage: $0 <platform>" >&2
    exit 1
fi

# 从标准输入读取环境变量
while IFS='=' read -r key value; do
    # 跳过空行和注释
    [[ -z "$key" || "$key" =~ ^#.* ]] && continue
    
    # 检查是否已存在
    if grep -q "^${key}=" "$ENV_FILE" 2>/dev/null; then
        # 更新现有值
        sed -i "s/^${key}=.*/${key}=${value}/" "$ENV_FILE"
        echo "✅ 更新 $key"
    else
        # 添加新值
        echo "${key}=${value}" >> "$ENV_FILE"
        echo "✅ 添加 $key"
    fi
done

echo "🔒 配置已安全写入 $ENV_FILE"
exit 0