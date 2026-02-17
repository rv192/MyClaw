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
RUN mkdir -p /root/.secure /scripts /credentials && \
    mkdir -p /root/.openclaw/extensions /root/.openclaw/skills /root/.openclaw/data /root/.openclaw/models && \
    mkdir -p /root/.openclaw/scripts && \
    mkdir -p /root/.openclaw/workspace && \
    useradd -r -s /bin/false secure && \
    chown -R root:root /root/.secure && \
    chmod 700 /root/.secure /scripts /credentials && \
    chmod 755 /root/.openclaw /root/.openclaw/extensions /root/.openclaw/skills /root/.openclaw/data /root/.openclaw/models /root/.openclaw/scripts /root/.openclaw/workspace

# 预装 bird（加速 npm 全局包安装）
RUN npm install -g @steipete/bird

# 安装 OpenClaw 中文版
RUN npm install -g @qingchencloud/openclaw-zh@latest

# 复制运行时脚本到镜像（使用不会被挂载覆盖的路径）
COPY scripts/secrets.sh /usr/local/bin/openclaw-secrets.sh
COPY scripts/start.sh /usr/local/bin/openclaw-start.sh
RUN chmod 750 /usr/local/bin/openclaw-secrets.sh /usr/local/bin/openclaw-start.sh && \
    echo "root ALL=(root) NOPASSWD: ALL" > /etc/sudoers.d/secure-access && \
    chmod 440 /etc/sudoers.d/secure-access

# 创建审计日志目录
RUN mkdir -p /var/log && touch /var/log/openclaw-audit.log && \
    chmod 640 /var/log/openclaw-audit.log

# 暴露端口
EXPOSE 18789 18790

# 启动脚本
CMD ["bash", "/usr/local/bin/openclaw-start.sh"]
