# OpenClaw 初始化任务清单

> 请按照以下步骤完成配置，所有敏感信息将安全存储在受保护的配置文件中

---

## 🔐 安全架构设计

### 权限隔离原则

OpenClaw 采用纵深防御策略保护敏感配置，防止 AI 系统意外泄露密钥：

#### 目录权限划分

| 路径 | 权限 | 所有者 | 用途 | 访问方式 |
|------|------|--------|------|----------|
| `/root/.secure/` | 700 | `secure` | 存储敏感配置（.env） | 仅通过 `/scripts/` 脚本 |
| `/scripts/` | 750 | root:secure | 授权脚本集合 | root 调用，以 secure 用户执行 |
| `/root/.openclaw/` | 755 | root | OpenClaw 全局配置 | OpenClaw 主进程读取 |
| `/root/workspace/` | 755 | root | 用户工作目录（AGENTS.md、SOULS.md 等） | 用户挂载和编辑 |

#### 访问规约

1. **直接访问限制**
   - `/root/.secure/` 目录由 `secure` 用户拥有，权限 700
   - 即使容器以 root 运行，按约定也不应直接访问该目录
   - 所有敏感操作必须通过 `/scripts/` 中的授权脚本完成

2. **脚本访问通道**
   - `/scripts/write-env.sh` - 以 secure 用户身份写入环境变量
   - `/scripts/check-env.sh` - 以 secure 用户身份检查环境变量
   - `/scripts/configure-tailscale.sh` - 配置 Tailscale VPN

3. **用户脚本规范**
   - **位置**: 用户脚本应放在 `/root/workspace/scripts/` 目录（通过 volume 挂载）
   - **用途**: 用户自定义操作脚本，可由用户在宿主机编辑或 OpenClaw 运行时生成
   - **访问配置**: 用户脚本必须通过调用 `/scripts/` 中的官方脚本来访问敏感配置
   - **禁止行为**: 用户脚本不得直接读取 `/root/.secure/.env` 或其他敏感文件

   **示例**:
   ```bash
   # /root/workspace/scripts/my-task.sh
   #!/bin/bash
   # ✅ 正确：通过官方脚本获取配置
   API_KEY=$(sudo -u secure /scripts/check-env.sh ai | grep API_KEY)

   # ❌ 错误：直接访问敏感配置
   # API_KEY=$(cat /root/.secure/.env | grep API_KEY)
   ```

4. **安全目标**
   - 创建技术障碍，防止 AI 失智时被骗直接访问密钥
   - 集中审计所有敏感操作（记录到 `/var/log/openclaw-audit.log`）
   - 便于追踪和审查敏感配置变更

5. **注意事项**
   - root 用户理论上可以绕过权限检查（Linux 特性）
   - 本设计提供的是"设计约定"和"技术障碍"，而非绝对隔离
   - SELinux/AppArmor 可提供更强的强制访问控制

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