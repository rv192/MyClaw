#!/bin/bash
# 敏感信息读写操作

set -e

SECURE_DIR="/root/.secure"
ENV_FILE="$SECURE_DIR/.env"

validate_key() {
    case "$1" in
        [a-zA-Z_][a-zA-Z0-9_]*) return 0 ;;
        *) return 1 ;;
    esac
}

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
        if ! validate_key "$2"; then
            echo "错误: 键名不合法（仅支持字母、数字、下划线，且不能以数字开头）"
            exit 1
        fi
        awk -F'=' -v key="$2" '$1 == key { print substr($0, index($0, "=") + 1); exit }' "$ENV_FILE"
        ;;
    write)
        # 写入键值对
        if [ -z "$2" ] || [ -z "$3" ]; then
            echo "错误: 需要指定键名和值"
            exit 1
        fi
        if ! validate_key "$2"; then
            echo "错误: 键名不合法（仅支持字母、数字、下划线，且不能以数字开头）"
            exit 1
        fi

        TMP_FILE=$(mktemp)
        awk -F'=' -v key="$2" -v value="$3" '
            BEGIN { updated = 0 }
            $1 == key {
                print key "=" value
                updated = 1
                next
            }
            { print }
            END {
                if (!updated) {
                    print key "=" value
                }
            }
        ' "$ENV_FILE" > "$TMP_FILE"
        mv "$TMP_FILE" "$ENV_FILE"
        chmod 600 "$ENV_FILE"
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
