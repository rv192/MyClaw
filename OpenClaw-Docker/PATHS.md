# OpenClaw Docker 外挂路径说明

## 📂 外挂目录结构

```
/root/services/MyClaw/OpenClaw-Docker/
├── Dockerfile                    # 容器镜像定义
├── docker-compose.yml            # 编排配置
├── .env.example                 # 环境变量模板
├── .gitignore                   # Git 忽略规则
├── INIT_TODO.md                 # 初始化任务清单
├── scripts/                     # 授权脚本（root 执行）
│   ├── write-env.sh            # 安全写入环境变量
│   ├── check-env.sh            # 检查环境变量
│   └── configure-tailscale.sh  # Tailscale 配置
├── .openclaw/
│   └── scripts/                 # 配置脚本（node 执行）
│       ├── start.sh            # 容器启动脚本
│       ├── config-platform.js  # 平台配置工具
│       ├── verify-config.js    # 配置验证
│       └── health-check.js     # 健康检查
└── data/                        # 外挂数据目录（宿主机）
    ├── tailscale/              # Tailscale 状态
    ├── secure/                 # 敏感配置（.env）
    ├── logs/                   # 审计日志
    ├── openclaw/               # OpenClaw 主配置
    │   ├── config.json         # 主配置文件
    │   ├── extensions/         # 插件扩展
    │   ├── skills/             # 自定义技能
    │   ├── data/               # 运行数据
    │   ├── models/             # QMD 模型文件
    │   └── workspace/          # 工作目录 ⭐
    │       ├── AGENTS.md       # 智能代理配置
    │       ├── SOULS.md        # 灵魂配置
    │       ├── SKILLS.md       # 技能配置
    │       ├── README.md       # 项目说明
    │       └── *.md            # 其他工作文件    ├── wx/                     # 微信插件代码
    │   ├── main.py             # 微信插件入口
    │   ├── config.py           # 配置文件
    │   ├── requirements.txt    # Python 依赖
    │   ├── plugins/            # 插件目录
    │   └── messages.db         # 消息数据库
    └── wx-downloads/           # 微信文件下载目录
```

## 🔧 容器内路径映射

| 宿主机路径 | 容器内路径 | 用途 |
|-----------|-----------|------|
| `./data/tailscale` | `/var/lib/tailscale` | Tailscale VPN 状态 |
| `./data/secure` | `/root/.secure` | 敏感配置文件 |
| `./data/logs` | `/var/log/openclaw-audit.log` | 审计日志 |
| `./data/openclaw` | `/root/.openclaw` | OpenClaw 主配置目录 |
| `./data/extensions` | `/root/.openclaw/extensions` | 插件扩展目录 |
| `./data/skills` | `/root/.openclaw/skills` | 自定义技能目录 |
| `./data/models` | `/root/.openclaw/models` | QMD 模型文件 |
| `./data/workspace` | `/root/.openclaw/workspace` | 工作目录（AGENTS.md、SOULS.md 等） |
| `./data/wx` | `/opt/wx-filehelper-api` | 微信插件代码 |
| `./data/wx-downloads` | `/app/downloads` | 微信文件下载 |

## 📦 微信插件部署

### 1. 克隆插件代码
```bash
cd /root/services/MyClaw/OpenClaw-Docker/data/wx
git clone https://github.com/CJackHwang/wx-filehelper-api.git .
```

### 2. 配置插件
编辑 `data/wx/config.py` 设置必要参数。

### 3. 启动容器
```bash
docker-compose up -d
```

### 4. 访问插件
```bash
# 获取二维码
curl http://localhost:8000/qr -o qr.png

# 检查登录状态
curl http://localhost:8000/login/status
```

## 🤖 QMD 模型外挂

QMD 模型文件放在 `./data/models/` 目录：

```
data/models/
├── embedding/              # 向量模型
│   └── model.bin
├── reranker/               # 重排序模型
│   └── model.bin
└── memory/                 # 记忆模型
    └── model.bin
```

在 OpenClaw 配置中指定模型路径：
```json
{
  "memory": {
    "qmd": {
      "enabled": true,
      "models": {
        "embedding": "/root/.openclaw/models/embedding/model.bin",
        "reranker": "/root/.openclaw/models/reranker/model.bin"
      }
    }
  }
}
```

## 🔌 插件扩展目录

第三方插件放在 `./data/extensions/` 目录：

```
data/extensions/
├── my-plugin-1/
│   ├── package.json
│   ├── index.js
│   └── README.md
└── my-plugin-2/
    ├── package.json
    ├── index.js
    └── README.md
```

## 📜 自定义技能目录

自定义技能放在 `./data/skills/` 目录：

```
data/skills/
├── my-skill-1.md
├── my-skill-2.md
└── custom/
    ├── skill.js
    └── utils.js
```

## 💼 工作目录

工作文件放在 `./data/workspace/` 目录：

```
data/workspace/
├── AGENTS.md              # 智能代理配置
├── SOULS.md               # 灵魂配置
├── SKILLS.md              # 技能配置
├── README.md              # 项目说明
├── agents/                # 代理子目录
│   ├── agent1.md
│   └── agent2.md
├── souls/                 # 灵魂子目录
│   ├── soul1.md
│   └── soul2.md
└── *.md                   # 其他工作文件
```

**主要文件说明**：

- **AGENTS.md** - 定义智能代理的配置、角色和能力
- **SOULS.md** - 定义代理的"灵魂"，包括性格、价值观和行为模式
- **SKILLS.md** - 定义可用的技能列表和配置

这些文件是 OpenClaw 的核心配置，通过外挂可以方便地在宿主机上编辑和版本控制。

## 🔐 敏感配置目录

敏感信息放在 `./data/secure/.env`：

```bash
# AI 模型
MODEL_ID=xxx
API_KEY=xxx

# 平台配置
FEISHU_APP_ID=xxx
FEISHU_APP_SECRET=xxx

# Tailscale
TAILSCALE_AUTH_KEY=xxx
```

## 📊 审计日志

所有配置操作记录在 `./data/logs/openclaw-audit.log`。