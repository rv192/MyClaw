# 基于 Node.js 官方镜像构建最新版 OpenClaw
# 添加中国 IM 平台插件、Tailscale、Playwright + Camoufox

FROM node:22-bookworm

# 设置环境变量
ENV TZ=Asia/Shanghai
ENV NODE_ENV=production

# 安装基础依赖和 Tailscale
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    ca-certificates \
    curl \
    tzdata \
    python3 \
    python3-pip \
    make \
    g++ \
    iptables \
    iproute2 \
    libgtk-3-0 \
    libdbus-glib-1-2 \
    libxt6 \
    libx11-xcb1 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    libxshmfence1 \
    libgbm1 \
    libasound2 \
    && rm -rf /var/lib/apt/lists/*

# 安装 Tailscale
RUN curl -fsSL https://tailscale.com/install.sh | sh

# 设置时区
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 安装最新版 OpenClaw (2026.2.23)
RUN npm install -g openclaw@2026.2.23 && npm cache clean --force

# 安装中国 IM 平台插件
RUN npm install -g \
    @openclaw-china/channels@latest \
    && npm cache clean --force

# 安装 Playwright（浏览器自动化框架）
RUN npm install -g playwright@latest && npm cache clean --force

# 安装 Puppeteer-extra + Stealth 插件（包含 stealth.min.js 反检测脚本）
RUN npm install -g puppeteer-core puppeteer-extra puppeteer-extra-plugin-stealth && npm cache clean --force

# 安装 Camoufox（Playwright 的轻量级浏览器后端，替代 Chromium）
# Camoufox 基于 Firefox，提供更好的反检测能力和更小的体积
RUN npm install -g camoufox-js@latest && npm cache clean --force

# Camoufox 浏览器二进制文件将在运行时自动安装

# 安装 Python 版本的 Playwright 和 Camoufox
RUN pip3 install --no-cache-dir --break-system-packages playwright camoufox

# 安装 Bun
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"

# 安装 sing-box（代理工具）
RUN curl -fsSL -o /usr/local/bin/sing-box.tar.gz "https://github.com/SagerNet/sing-box/releases/download/v1.11.4/sing-box-1.11.4-linux-amd64.tar.gz" \
    && tar -xzf /usr/local/bin/sing-box.tar.gz -C /usr/local/bin --strip-components=1 \
    && rm /usr/local/bin/sing-box.tar.gz \
    && chmod +x /usr/local/bin/sing-box

# 安装 qmd（使用 npm 安装正确的包 @tobilu/qmd）
RUN npm install -g @tobilu/qmd@latest && npm cache clean --force

# 创建必要的目录结构
RUN mkdir -p /root/.openclaw/extensions \
    /root/.openclaw/skills \
    /root/.openclaw/workspace \
    /root/.openclaw/data \
    /opt/openclaw-context \
    /var/lib/tailscale \
    && chmod -R 755 /root/.openclaw

# 复制配置文件和脚本
COPY docker-compose.yml /opt/openclaw-context/
COPY Dockerfile /opt/openclaw-context/
COPY scripts/start.sh /usr/local/bin/openclaw-start.sh
RUN chmod +x /usr/local/bin/openclaw-start.sh

# 暴露端口
EXPOSE 18789 18790

# 启动命令
CMD ["/usr/local/bin/openclaw-start.sh"]