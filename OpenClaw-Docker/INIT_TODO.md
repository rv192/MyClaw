# OpenClaw 初始化任务清单

> 请按照以下步骤完成配置，所有敏感信息将安全存储在受保护的配置文件中

---

## 📋 第一阶段：基础网络配置

### 1.1 Tailscale VPN 配置 ✅ 守护进程已启动
**状态**: `tailscale status`
**所需信息**: Auth Key（可选，或手动登录）

**操作步骤**:
```bash
# 方式 A: 使用 Auth Key 自动连接（推荐）
docker exec -it openclaw-gateway sudo /scripts/configure-tailscale.sh --auth-key YOUR_KEY

# 方式 B: 手动登录（需要浏览器）
docker exec -it openclaw-gateway sudo tailscale up

# 查看连接状态
docker exec -it openclaw-gateway sudo tailscale status
```

**完成标志**: `tailscale status` 显示已连接

---

## 📋 第二阶段：IM 平台配置

### 2.1 飞书（Feishu）绑定
**状态**: ⏳ 待配置
**所需信息**: App ID, App Secret

**操作步骤**:
1. 访问 https://open.feishu.cn/app 创建自建应用
2. 添加机器人能力，申请权限
3. 获取 App ID 和 App Secret
4. 配置事件订阅（使用长连接模式）
5. 运行配置命令:
```bash
docker exec -it openclaw-gateway node /home/node/.openclaw/scripts/config-platform.js feishu
```

**验证**: `docker logs openclaw-gateway` 显示飞书插件已加载

---

### 2.2 钉钉（DingTalk）绑定
**状态**: ⏳ 待配置
**所需信息**: Client ID, Client Secret, Robot Code, Agent ID

**操作步骤**:
1. 访问 https://open.dingtalk.com 创建企业内部应用
2. 添加机器人能力，配置 Stream 模式
3. 运行配置命令:
```bash
docker exec -it openclaw-gateway node /home/node/.openclaw/scripts/config-platform.js dingtalk
```

---

### 2.3 QQ 机器人绑定
**状态**: ⏳ 待配置
**所需信息**: App ID, Client Secret

**操作步骤**:
1. 访问 QQ 开放平台创建机器人应用
2. 配置 IP 白名单
3. 运行配置命令:
```bash
docker exec -it openclaw-gateway node /home/node/.openclaw/scripts/config-platform.js qqbot
```

---

### 2.4 企业微信（WeCom）绑定
**状态**: ⏳ 待配置
**所需信息**: Token, Encoding AES Key

**操作步骤**:
1. 访问企业微信管理后台创建智能机器人
2. 配置接收消息 URL（需要公网访问）
3. 运行配置命令:
```bash
docker exec -it openclaw-gateway node /home/node/.openclaw/scripts/config-platform.js wecom
```

---

## 📋 第三阶段：第三方服务配置

### 3.1 Google 账号绑定
**状态**: ⏳ 待配置
**所需信息**: Client ID, Client Secret

**操作步骤**:
1. 访问 Google Cloud Console 创建 OAuth 2.0 凭证
2. 配置授权回调 URL
3. 运行配置命令:
```bash
docker exec -it openclaw-gateway node /home/node/.openclaw/scripts/config-platform.js google
```

---

### 3.2 Notion 账号绑定
**状态**: ⏳ 待配置
**所需信息**: Integration Token

**操作步骤**:
1. 访问 https://www.notion.so/my-integrations 创建集成
2. 授权集成到工作区
3. 运行配置命令:
```bash
docker exec -it openclaw-gateway node /home/node/.openclaw/scripts/config-platform.js notion
```

---

### 3.3 X/Twitter 账号绑定
**状态**: ⏳ 待配置
**所需信息**: API Key, API Secret, Access Token, Access Secret

**操作步骤**:
1. 访问 Twitter Developer Portal 创建应用
2. 配置 OAuth 1.0a 回调 URL
3. 运行配置命令:
```bash
docker exec -it openclaw-gateway node /home/node/.openclaw/scripts/config-platform.js twitter
```

---

### 3.4 Reddit 账号绑定
**状态**: ⏳ 待配置
**所需信息**: Client ID, Client Secret, User Agent

**操作步骤**:
1. 访问 Reddit App Preferences 创建应用
2. 配置回调 URL
3. 运行配置命令:
```bash
docker exec -it openclaw-gateway node /home/node/.openclaw/scripts/config-platform.js reddit
```

---

## 📋 第四阶段：AI 模型配置

### 4.1 AI Provider 配置
**状态**: ⏳ 待配置
**所需信息**: Model ID, Base URL, API Key

**操作步骤**:
1. 配置 AI 服务提供商（OpenAI/Claude/Gemini）
2. 运行配置命令:
```bash
docker exec -it openclaw-gateway node /home/node/.openclaw/scripts/config-platform.js ai
```

---

## ✅ 完成检查

所有配置完成后，运行验证命令:
```bash
docker exec -it openclaw-gateway node /home/node/.openclaw/scripts/verify-config.js
```

验证通过后，此文件将被自动删除。

---

## 🔒 安全说明

- 所有敏感信息通过授权脚本安全写入 `/root/.secure/.env`
- OpenClaw 主进程无法直接访问敏感文件
- 每次配置都会记录审计日志到 `/var/log/openclaw-audit.log`
- 配置完成后建议重启容器使所有配置生效