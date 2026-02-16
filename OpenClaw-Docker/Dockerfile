FROM node:22

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
RUN mkdir -p /root/.secure /scripts /credentials /root/workspace && \
    mkdir -p /root/.openclaw/extensions /root/.openclaw/skills /root/.openclaw/data /root/.openclaw/models && \
    mkdir -p /opt/wx-filehelper-api && \
    useradd -r -s /bin/false secure && \
    chown -R secure:secure /root/.secure && \
    chmod 700 /root/.secure /scripts /credentials && \
    chmod 755 /root/workspace /root/.openclaw /root/.openclaw/extensions /root/.openclaw/skills /root/.openclaw/data /root/.openclaw/models /opt/wx-filehelper-api

# 预装 bird（加速 npm 全局包安装）
RUN npm install -g @steipete/bird

# 安装 OpenClaw 中文版
RUN npm install -g @qingchencloud/openclaw-zh@latest

# 复制授权脚本
COPY scripts/*.sh /scripts/
RUN chmod 750 /scripts/*.sh && \
    chown root:secure /scripts/*.sh && \
    echo "root ALL=(secure) NOPASSWD: ALL" > /etc/sudoers.d/secure-access && \
    chmod 440 /etc/sudoers.d/secure-access

# 复制配置脚本
COPY .openclaw/scripts/*.js /root/.openclaw/scripts/
RUN chmod 755 /root/.openclaw/scripts/*.js

# 复制初始化任务清单
COPY INIT_TODO.md /root/.openclaw/INIT_TODO.md
RUN chmod 644 /root/.openclaw/INIT_TODO.md

# 创建审计日志目录
RUN mkdir -p /var/log && touch /var/log/openclaw-audit.log && \
    chmod 640 /var/log/openclaw-audit.log

# 暴露端口
EXPOSE 18789 18790

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD node /root/.openclaw/scripts/health-check.js || exit 1

# 启动脚本
CMD ["/root/.openclaw/scripts/start.sh"]