# OpenClaw Docker 容器

基于 OpenClaw 的 AI 机器人网关 Docker 镜像，支持多平台接入和自动化配置。

## 特性

- ✅ **Tailscale VPN 集成** - 自动连接，安全内网访问
- ✅ **多平台支持** - 飞书、钉钉、QQ、企业微信、Google、Notion、Twitter、Reddit
- ✅ **安全配置** - 敏感信息隔离存储，审计日志
- ✅ **交互式引导** - INIT_TODO.md 引导完成初始化
- ✅ **健康检查** - 自动监控服务状态

## 快速开始

### 1. 构建镜像

```bash
cd /root/services/OpenClaw-Docker
docker compose build
```

### 2. 启动容器

```bash
docker compose up -d
```

### 3. 查看初始化任务

```bash
docker exec -it openclaw-gateway cat /root/.openclaw/INIT_TODO.md
```

### 4. 配置平台

```bash
# 配置飞书
docker exec -it openclaw-gateway node /root/.openclaw/scripts/config-platform.js feishu

# 配置 AI 模型
docker exec -it openclaw-gateway node /root/.openclaw/scripts/config-platform.js ai

# 配置 Tailscale（使用 Auth Key）
docker exec -it openclaw-gateway sudo tailscale up --authkey YOUR_KEY
```

### 5. 验证配置

```bash
docker exec -it openclaw-gateway node /root/.openclaw/scripts/verify-config.js
```

### 6. 重启使配置生效

```bash
docker compose restart
```

## 支持的平台

| 平台 | 配置命令 |
|------|----------|
| 飞书 | `config-platform.js feishu` |
| 钉钉 | `config-platform.js dingtalk` |
| QQ 机器人 | `config-platform.js qqbot` |
| 企业微信 | `config-platform.js wecom` |
| Google | `config-platform.js google` |
| Notion | `config-platform.js notion` |
| Twitter/X | `config-platform.js twitter` |
| Reddit | `config-platform.js reddit` |
| AI Provider | `config-platform.js ai` |

## 安全特性

- **权限隔离** - 敏感配置文件仅 root 可访问
- **授权脚本** - 通过 sudo 限制的可执行脚本写入
- **审计日志** - 所有配置操作记录到日志
- **无密钥运行** - 主进程不持有敏感信息

## 环境变量

可选的环境变量（用于自动配置）：

```bash
# Tailscale Auth Key（可选）
TAILSCALE_AUTH_KEY=tskey-xxx
```

其他平台凭证请通过交互式命令配置，不要硬编码。

## 数据持久化

配置文件存储在 `data/` 目录：

```
data/
├── tailscale/     # Tailscale 状态
└── secure/        # 敏感配置（.env）
```

## 健康检查

容器每 30 秒进行一次健康检查：

```bash
docker ps --format "table {{.Names}}\t{{.Status}}"
```

## 日志查看

```bash
# 查看容器日志
docker compose logs -f

# 查看审计日志
docker exec -it openclaw-gateway sudo cat /var/log/openclaw-audit.log
```

## 故障排查

### Tailscale 未连接

```bash
# 查看状态
docker exec -it openclaw-gateway sudo tailscale status

# 重新连接
docker exec -it openclaw-gateway sudo tailscale up
```

### 平台未加载

检查日志中的错误信息：

```bash
docker compose logs | grep -i error
```

### 权限问题

确保脚本有执行权限：

```bash
docker exec -it openclaw-gateway ls -la /usr/local/bin/openclaw-*.sh
```

## 项目结构

```
OpenClaw-Docker/
├── Dockerfile              # 容器镜像定义
├── docker-compose.yml      # 编排配置
├── .env.example           # 环境变量模板
├── .gitignore             # Git 忽略规则
├── INIT_TODO.md           # 初始化任务清单
├── scripts/               # 镜像构建时复制的本地脚本
│   ├── start.sh           # 启动脚本源文件（复制为 /usr/local/bin/openclaw-start.sh）
│   └── secrets.sh         # 敏感信息脚本源文件（复制为 /usr/local/bin/openclaw-secrets.sh）
└── （容器运行时）/root/.openclaw/scripts/  # 由 npm 包初始化，非仓库目录
    ├── config-platform.js     # 平台配置工具
    ├── verify-config.js       # 配置验证
    └── health-check.js        # 健康检查
```

## 许可证

MIT License
