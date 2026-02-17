#!/bin/bash
# OpenClaw 初始化脚本

set -e

cd "$(dirname "$0")"

# 加载环境变量
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
else
    echo "❌ 错误: .env 文件不存在"
    exit 1
fi

echo "🔧 OpenClaw 初始化配置"
echo ""

# ========================================
# 1. AI Model Provider 配置
# ========================================
echo "📋 配置 AI Model Provider..."

if [ -n "$BASE_URL" ] && [ -n "$API_KEY" ] && [ -n "$API_PROTOCOL" ]; then
    PROVIDER_NAME="${PROVIDER_NAME:-custom-openai}"
    DEFAULT_MODEL="${DEFAULT_MODEL:-${PROVIDER_NAME}/gpt-5.3-codex}"

    echo "  Provider: $PROVIDER_NAME"
    echo "  Base URL: $BASE_URL"
    echo "  API 协议: $API_PROTOCOL"
    echo "  默认模型: $DEFAULT_MODEL"

    if docker compose ps openclaw-gateway &>/dev/null && docker compose ps openclaw-gateway | grep -q "Up"; then
        # 构建 provider 配置
        PROVIDER_CONFIG=$(cat << EOF
{
  "models": {
    "mode": "merge",
    "providers": {
      "$PROVIDER_NAME": {
        "baseUrl": "$BASE_URL",
        "apiKey": "$API_KEY",
        "api": "$API_PROTOCOL",
        "models": [
          {"id":"gpt-5.3-codex","name":"GPT-5.3 Codex","contextWindow":128000,"maxTokens":8192},
          {"id":"gpt-5.2","name":"GPT-5.2","contextWindow":128000,"maxTokens":8192},
          {"id":"glm-4.7","name":"GLM-4.7","contextWindow":128000,"maxTokens":8192}
        ]
      }
    }
  }
}
EOF
)

        # 写入临时文件
        echo "$PROVIDER_CONFIG" | docker compose exec -T openclaw-gateway bash -c 'cat > /tmp/provider_config.json'

        # 使用 Node.js 合并配置
        docker compose exec -T openclaw-gateway bash -c "
node -e \"
const fs = require('fs');
const config = JSON.parse(fs.readFileSync('/root/.openclaw/openclaw.json', 'utf8'));
const provider = JSON.parse(fs.readFileSync('/tmp/provider_config.json', 'utf8'));
const merged = {...config, ...provider};
fs.writeFileSync('/root/.openclaw/openclaw.json', JSON.stringify(merged, null, 2));
console.log('配置已合并');
\"
" || echo "  ⚠️  警告: 配置 models.providers 失败"

        # 设置默认模型
        docker compose exec -T openclaw-gateway openclaw models set "$DEFAULT_MODEL" || echo "  ⚠️  警告: 设置默认模型失败"

        echo "  ✅ 已配置（需要重启容器生效）"
    else
        echo "  ⚠️  容器未运行，跳过配置（启动后需手动执行）"
    fi
else
    echo "  ⏭️  跳过（未设置 BASE_URL、API_KEY 或 API_PROTOCOL）"
fi

echo ""

# ========================================
# 2. Telegram Bot 配置
# ========================================
echo "📱 配置 Telegram Bot..."

if [ -n "$TELEGRAM_BOT_TOKEN" ]; then
    echo "  Token: ${TELEGRAM_BOT_TOKEN:0:10}..."

    if docker compose ps openclaw-gateway &>/dev/null && docker compose ps openclaw-gateway | grep -q "Up"; then
        # 添加 Telegram channel
        docker compose exec -T openclaw-gateway openclaw channels add \
            --channel telegram \
            --token "$TELEGRAM_BOT_TOKEN" \
            --account default \
            --use-env || echo "  ⚠️  警告: 添加 Telegram channel 失败"

        # 配置 dmPolicy 和 allowFrom
        docker compose exec -T openclaw-gateway openclaw config set channels.telegram.dmPolicy open || echo "  ⚠️  警告: 设置 dmPolicy 失败"
        docker compose exec -T openclaw-gateway openclaw config set channels.telegram.allowFrom '["*"]' --json || echo "  ⚠️  警告: 设置 allowFrom 失败"
        docker compose exec -T openclaw-gateway openclaw config set channels.telegram.groupPolicy allowlist || echo "  ⚠️  警告: 设置 groupPolicy 失败"
        docker compose exec -T openclaw-gateway openclaw config set channels.telegram.streamMode partial || echo "  ⚠️  警告: 设置 streamMode 失败"

        echo "  ✅ 已配置（需要重启容器生效）"
    else
        echo "  ⚠️  容器未运行，跳过配置（启动后需手动执行）"
    fi
else
    echo "  ⏭️  跳过（未设置 TELEGRAM_BOT_TOKEN）"
fi

echo ""

# ========================================
# 3. 搜索服务配置
# ========================================
echo "🔍 配置搜索服务..."

if [ -n "$BRAVE_API_KEY" ]; then
    echo "  Brave Search: ${BRAVE_API_KEY:0:10}..."
    echo "  ✅ 已配置（通过环境变量 BRAVE_API_KEY）"
else
    echo "  ⏭️  Brave Search: 未配置"
fi

if [ -n "$TAVILY_API_KEY" ]; then
    echo "  Tavily Search: ${TAVILY_API_KEY:0:10}..."
    echo "  ✅ 已配置（通过环境变量 TAVILY_API_KEY）"
else
    echo "  ⏭️  Tavily Search: 未配置"
fi

echo ""

# ========================================
# 4. 其他平台配置
# ========================================
echo "💬 配置其他平台..."

# 飞书
if [ -n "$FEISHU_APP_ID" ] && [ -n "$FEISHU_APP_SECRET" ]; then
    echo "  飞书: 已配置（通过环境变量）"
else
    echo "  ⏭️  飞书: 未配置"
fi

# 钉钉
if [ -n "$DINGTALK_CLIENT_ID" ] && [ -n "$DINGTALK_CLIENT_SECRET" ]; then
    echo "  钉钉: 已配置（通过环境变量）"
else
    echo "  ⏭️  钉钉: 未配置"
fi

# QQ 机器人
if [ -n "$QQBOT_APP_ID" ] && [ -n "$QQBOT_CLIENT_SECRET" ]; then
    echo "  QQ 机器人: 已配置（通过环境变量）"
else
    echo "  ⏭️  QQ 机器人: 未配置"
fi

# 企业微信
if [ -n "$WECOM_TOKEN" ] && [ -n "$WECOM_ENCODING_AES_KEY" ]; then
    echo "  企业微信: 已配置（通过环境变量）"
else
    echo "  ⏭️  企业微信: 未配置"
fi

# Google
if [ -n "$GOOGLE_CLIENT_ID" ] && [ -n "$GOOGLE_CLIENT_SECRET" ]; then
    echo "  Google: 已配置（通过环境变量）"
else
    echo "  ⏭️  Google: 未配置"
fi

# Notion
if [ -n "$NOTION_INTEGRATION_TOKEN" ]; then
    echo "  Notion: ${NOTION_INTEGRATION_TOKEN:0:10}..."
    echo "  ✅ 已配置（需要手动安装插件：openclaw plugins install notion）"
else
    echo "  ⏭️  Notion: 未配置"
fi

echo ""

# ========================================
# 5. Tailscale VPN 配置
# ========================================
echo "🔗 配置 Tailscale VPN..."

if [ -n "$TAILSCALE_AUTH_KEY" ]; then
    echo "  Auth Key: ${TAILSCALE_AUTH_KEY:0:10}..."
    echo "  ✅ 已配置（将在容器启动时连接）"
else
    echo "  ⏭️  Tailscale VPN: 未配置"
fi

echo ""
echo "✅ 初始化完成！"
echo ""
echo "说明："
echo "  - scripts/ 目录：源脚本目录（打包到 Docker 镜像）"
echo "  - data/ 目录：所有持久化数据（gitignore，不提交）"
echo ""
echo "使用流程："
echo "  1. docker compose build"
echo "  2. docker compose up -d"
echo "  3. ./init.sh"
echo "  4. docker compose restart  # 应用配置更改"
echo ""
echo "验证："
echo "  docker compose exec openclaw-gateway openclaw models status --probe"
echo "  docker compose exec openclaw-gateway openclaw channels status"