#!/bin/bash
# 敏感信息读写操作

set -e

SECURE_DIR="/root/.secure"
ENV_FILE="$SECURE_DIR/.env"

# 确保 .env 文件存在
mkdir -p "$SECURE_DIR"
chmod 700 "$SECURE_DIR"
touch "$ENV_FILE"
chmod 600 "$ENV_FILE"

# 解析命令行参数
case "${1:-}" in
    read)
        # 读取指定键的值
        if [ -z "$2" ]; then
            echo "错误: 需要指定键名"
            exit 1
        fi
        grep "^${2}=" "$ENV_FILE" | cut -d'=' -f2-
        ;;
    write)
        # 写入键值对
        if [ -z "$2" ] || [ -z "$3" ]; then
            echo "错误: 需要指定键名和值"
            exit 1
        fi
        if grep -q "^${2}=" "$ENV_FILE"; then
            # 更新现有值
            sed -i "s/^${2}=.*/${2}=${3}/" "$ENV_FILE"
        else
            # 添加新值
            echo "${2}=${3}" >> "$ENV_FILE"
        fi
        ;;
    list)
        # 列出所有键值对（脱敏显示）
        while IFS='=' read -r key value; do
            if [ -n "$key" ] && [ "${key:0:1}" != "#" ]; then
                masked="${value:0:4}..."
                echo "  $key: $masked"
            fi
        done < "$ENV_FILE"
        ;;
    *)
        echo "用法: $0 {read|write|list}"
        echo ""
        echo "命令:"
        echo "  read <key>   - 读取指定键的值"
        echo "  write <key> <value> - 写入键值对"
        echo "  list         - 列出所有键值对（脱敏显示）"
        exit 1
        ;;
esac