#!/bin/bash
set -euo pipefail

PLATFORM="${1:-}"
ENV_FILE="/root/.secure/.env"

# 定义每个平台需要的变量
declare -A PLATFORM_VARS
PLATFORM_VARS[feishu]="FEISHU_APP_ID FEISHU_APP_SECRET"
PLATFORM_VARS[dingtalk]="DINGTALK_CLIENT_ID DINGTALK_CLIENT_SECRET DINGTALK_ROBOT_CODE DINGTALK_AGENT_ID"
PLATFORM_VARS[qqbot]="QQBOT_APP_ID QQBOT_CLIENT_SECRET"
PLATFORM_VARS[wecom]="WECOM_TOKEN WECOM_ENCODING_AES_KEY"
PLATFORM_VARS[google]="GOOGLE_CLIENT_ID GOOGLE_CLIENT_SECRET"
PLATFORM_VARS[notion]="NOTION_INTEGRATION_TOKEN"
PLATFORM_VARS[twitter]="TWITTER_API_KEY TWITTER_API_SECRET TWITTER_ACCESS_TOKEN TWITTER_ACCESS_SECRET"
PLATFORM_VARS[reddit]="REDDIT_CLIENT_ID REDDIT_CLIENT_SECRET"
PLATFORM_VARS[ai]="MODEL_ID BASE_URL API_KEY"

if [ -z "$PLATFORM" ]; then
    echo '{"configured": false, "missing": []}'
    exit 0
fi

# 检查环境变量是否存在（以 secure 用户身份）
VARS="${PLATFORM_VARS[$PLATFORM]}"
MISSING=()

for VAR in $VARS; do
    if ! sudo -u secure grep -q "^${VAR}=" "$ENV_FILE" 2>/dev/null; then
        MISSING+=("$VAR")
    fi
done

if [ ${#MISSING[@]} -eq 0 ]; then
    echo "{\"configured\": true, \"missing\": []}"
else
    MISSING_JSON=$(printf '"%s",' "${MISSING[@]}" | sed 's/,$//')
    echo "{\"configured\": false, \"missing\": [$MISSING_JSON]}"
fi