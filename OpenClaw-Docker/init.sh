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
    PROVIDER_NAME="MyAPI"
    DEFAULT_MODEL="${PROVIDER_NAME}/gpt-5.3-codex"
    if [ -z "$PROVIDER_MODELS_JSON" ]; then
        PROVIDER_MODELS_JSON='[{"id":"gpt-5.3-codex","name":"GPT-5.3 Codex","contextWindow":128000,"maxTokens":8192},{"id":"gpt-5.1-codex-mini","name":"GPT-5.1 Codex Mini","contextWindow":128000,"maxTokens":8192},{"id":"kimi-k2.5","name":"Kimi K2.5","contextWindow":128000,"maxTokens":8192},{"id":"qwen3-max","name":"Qwen3 Max","contextWindow":128000,"maxTokens":8192},{"id":"glm-5","name":"GLM-5","contextWindow":128000,"maxTokens":8192},{"id":"deepseek-v3.2","name":"DeepSeek V3.2","contextWindow":128000,"maxTokens":8192},{"id":"minimax-m2.5","name":"MiniMax M2.5","contextWindow":128000,"maxTokens":8192}]'
    fi
    if [ -z "$MODEL_ALIASES" ]; then
        MODEL_ALIASES="gpt53code=${PROVIDER_NAME}/gpt-5.3-codex,gpt51mini=${PROVIDER_NAME}/gpt-5.1-codex-mini,kimi25=${PROVIDER_NAME}/kimi-k2.5,qwen3max=${PROVIDER_NAME}/qwen3-max,glm5=${PROVIDER_NAME}/glm-5,ds32=${PROVIDER_NAME}/deepseek-v3.2,minimax25=${PROVIDER_NAME}/minimax-m2.5"
    fi

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
        "models": $PROVIDER_MODELS_JSON
      }
    }
  }
}
EOF
)

        # 写入临时文件
        echo "$PROVIDER_CONFIG" | docker compose exec -T openclaw-gateway bash -c 'cat > /tmp/provider_config.json'

        # 使用 Node.js 合并配置
        docker compose exec -T -e DEFAULT_MODEL="$DEFAULT_MODEL" openclaw-gateway bash -c "
node -e \"
const fs = require('fs');
const config = JSON.parse(fs.readFileSync('/root/.openclaw/openclaw.json', 'utf8'));
const provider = JSON.parse(fs.readFileSync('/tmp/provider_config.json', 'utf8'));
const providerName = Object.keys(provider.models.providers || {})[0];
const providerModels = provider.models.providers?.[providerName]?.models || [];
const defaultModel = process.env.DEFAULT_MODEL;
const merged = {
  ...config,
  ...provider,
  models: {
    ...(config.models || {}),
    ...(provider.models || {}),
    providers: {
      [providerName]: provider.models.providers?.[providerName],
    },
  },
};
if (!merged.agents) merged.agents = {};
if (!merged.agents.defaults) merged.agents.defaults = {};
if (!merged.agents.defaults.model) merged.agents.defaults.model = {};
merged.agents.defaults.model.primary = defaultModel;
const providerModelEntries = Object.fromEntries(
  providerModels
    .filter((m) => m && m.id)
    .map((m) => [providerName + '/' + m.id, {}])
);
merged.agents.defaults.models = providerModelEntries;
fs.writeFileSync('/root/.openclaw/openclaw.json', JSON.stringify(merged, null, 2));
console.log('配置已合并');
\"
" || echo "  ⚠️  警告: 配置 models.providers 失败"

        # 设置默认模型
        docker compose exec -T openclaw-gateway openclaw models set "$DEFAULT_MODEL" || echo "  ⚠️  警告: 设置默认模型失败"

        for PAIR in ${MODEL_ALIASES//,/ }; do
            ALIAS_NAME="${PAIR%%=*}"
            MODEL_NAME="${PAIR#*=}"
            docker compose exec -T openclaw-gateway openclaw models aliases add "$ALIAS_NAME" "$MODEL_NAME" || echo "  ⚠️  警告: 设置模型别名 $ALIAS_NAME 失败"
        done

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
# ========================================
echo "🧠 配置 QMD Memory..."

if docker compose ps openclaw-gateway &>/dev/null && docker compose ps openclaw-gateway | grep -q "Up"; then
    docker compose exec -T openclaw-gateway bash -lc '
if ! command -v qmd >/dev/null 2>&1; then
  if command -v bun >/dev/null 2>&1; then
    bun install -g @tobilu/qmd
  elif command -v npm >/dev/null 2>&1; then
    npm i -g @tobilu/qmd
  else
    exit 2
  fi
fi
command -v qmd >/dev/null 2>&1
' || echo "  ⚠️  警告: qmd 未安装成功"

    docker compose exec -T openclaw-gateway bash -lc 'python3 - <<"PY"
from pathlib import Path

file = Path("/root/.bun/install/global/node_modules/@tobilu/qmd/dist/llm.js")
if file.exists():
    source = file.read_text()
    # CPU-first patch: only probe GPU when QMD_ALLOW_GPU=1.
    source = source.replace(
        "const gpuTypes = await getLlamaGpuTypes();\n            // Prefer CUDA > Metal > Vulkan > CPU\n            const preferred = [\"cuda\", \"metal\", \"vulkan\"].find(g => gpuTypes.includes(g));",
        "const allowGpu = process.env.QMD_ALLOW_GPU === \"1\";\n            const gpuTypes = allowGpu ? await getLlamaGpuTypes() : [];\n            const preferred = allowGpu ? [\"cuda\", \"metal\", \"vulkan\"].find(g => gpuTypes.includes(g)) : undefined;"
    )
    file.write_text(source)
PY' || echo "  ⚠️  警告: QMD CPU/GPU 自动切换补丁失败"

    docker compose exec -T openclaw-gateway bash -lc "cat > /usr/local/bin/qmd-cpu <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
export OMP_NUM_THREADS=\"\${OMP_NUM_THREADS:-\$(nproc)}\"
export CUDA_VISIBLE_DEVICES=\"\"
export NODE_LLAMA_CPP_GPU=\"off\"
exec /usr/local/bin/qmd \"\$@\"
EOF
chmod +x /usr/local/bin/qmd-cpu" || echo "  ⚠️  警告: 写入 qmd-cpu 包装器失败"

    docker compose exec -T openclaw-gateway bash -lc "cat > /usr/local/bin/qmd-auto <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

has_gpu=0
if [ -e /dev/nvidiactl ]; then
  has_gpu=1
fi
if command -v nvidia-smi >/dev/null 2>&1; then
  if nvidia-smi -L >/dev/null 2>&1; then
    has_gpu=1
  fi
fi

export OMP_NUM_THREADS=\"\${OMP_NUM_THREADS:-\$(nproc)}\"
# Default to CPU to avoid CUDA probe/fallback noise on CPU-only hosts.
if [ \"\${QMD_FORCE_CPU:-1}\" = \"1\" ]; then
  has_gpu=0
fi
# GPU is opt-in: set QMD_ALLOW_GPU=1 to enable GPU path.
if [ \"\${QMD_ALLOW_GPU:-0}\" != \"1\" ]; then
  has_gpu=0
fi

if [ \"\$has_gpu\" = \"1\" ]; then
  exec /usr/local/bin/qmd \"\$@\"
else
  export CUDA_VISIBLE_DEVICES=\"\"
  export NODE_LLAMA_CPP_GPU=\"off\"
  exec /usr/local/bin/qmd \"\$@\"
fi
EOF
chmod +x /usr/local/bin/qmd-auto" || echo "  ⚠️  警告: 写入 qmd-auto 包装器失败"

    docker compose exec -T openclaw-gateway openclaw config set memory.backend qmd || echo "  ⚠️  警告: 设置 memory.backend 失败"
    docker compose exec -T openclaw-gateway openclaw config set memory.qmd.command /usr/local/bin/qmd-auto || echo "  ⚠️  警告: 设置 memory.qmd.command 失败"

    if [ "${WARM_QMD:-0}" = "1" ]; then
        docker compose exec -T openclaw-gateway bash -lc '/usr/local/bin/qmd-auto status >/tmp/qmd-init-status.log 2>&1 || true' || echo "  ⚠️  警告: QMD 预热失败"
        echo "  ✅ QMD 预热已执行"
    else
        echo "  ⏭️  跳过 QMD 预热（WARM_QMD=0，不下载模型）"
    fi

    echo "  ✅ QMD Memory 已配置"
else
    echo "  ⚠️  容器未运行，跳过配置（启动后需手动执行）"
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
echo "  docker compose exec openclaw-gateway openclaw config get memory.backend"
echo "  docker compose exec openclaw-gateway openclaw config get memory.qmd.command"
