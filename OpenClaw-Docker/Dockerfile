FROM node:18

# 安装必要工具
RUN apt-get update && apt-get install -y \
    sudo \
    curl \
    git \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# 安装 Tailscale
RUN curl -fsSL https://tailscale.com/install.sh | sh

# 创建安全目录结构
RUN mkdir -p /root/.secure /scripts /credentials /home/node/.openclaw && \
    mkdir -p /root/.openclaw/extensions /root/.openclaw/skills /root/.openclaw/data /root/.openclaw/models /root/.openclaw/workspace && \
    mkdir -p /opt/wx-filehelper-api && \
    chmod 700 /root/.secure /scripts /credentials && \
    chmod 755 /home/node/.openclaw /root/.openclaw/extensions /root/.openclaw/skills /root/.openclaw/data /root/.openclaw/models /root/.openclaw/workspace /opt/wx-filehelper-api

# 预装 bird（加速 npm 全局包安装）
RUN npm install -g @steipete/bird

# 安装 OpenClaw 中文版
RUN npm install -g @qingchencloud/openclaw-zh@latest

# 复制授权脚本
COPY scripts/*.sh /scripts/
RUN chmod 700 /scripts/*.sh

# 复制配置脚本
COPY .openclaw/scripts/*.js /home/node/.openclaw/scripts/
RUN chmod 755 /home/node/.openclaw/scripts/*.js

# 复制初始化任务清单
COPY INIT_TODO.md /home/node/.openclaw/INIT_TODO.md
RUN chmod 644 /home/node/.openclaw/INIT_TODO.md

# 创建空的 .env 文件（占位）
RUN touch /root/.secure/.env && chmod 600 /root/.secure/.env

# 配置 sudoers
RUN echo "node ALL=(root) NOPASSWD: /scripts/*.sh" > /etc/sudoers.d/openclaw && \
    chmod 440 /etc/sudoers.d/openclaw

# 创建审计日志目录
RUN mkdir -p /var/log && touch /var/log/openclaw-audit.log && \
    chown root:root /var/log/openclaw-audit.log && chmod 640 /var/log/openclaw-audit.log

# 创建非 root 用户
RUN useradd -m -s /bin/bash node && \
    chown -R node:node /home/node/.openclaw

USER node

# 暴露端口
EXPOSE 18789 18790

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD node /home/node/.openclaw/scripts/health-check.js || exit 1

# 启动脚本
CMD ["/home/node/.openclaw/scripts/start.sh"]