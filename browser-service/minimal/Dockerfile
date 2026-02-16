# ============================================
# OpenClaw Browser Service - Minimal Version
# ============================================
# 功能：轻量级浏览器自动化容器
# 大小：约 500MB
# 特点：Chromium + FluxBox + VNC + Puppeteer-extra

FROM registry.cn-hangzhou.aliyuncs.com/library/ubuntu:22.04

LABEL maintainer="OpenClaw Team"
LABEL description="Minimal browser automation service with VNC support"

# 避免交互式提示
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai

# ============================================
# 1. 系统基础 + Chromium 依赖
# ============================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    # 基础工具
    wget curl gnupg ca-certificates \
    # X11 虚拟显示
    xvfb \
    # VNC 服务
    x11vnc \
    # 轻量级窗口管理器
    fluxbox \
    # 中文字体
    fonts-wqy-zenhei \
    fonts-noto-color-emoji \
    fonts-noto-cjk-extra \
    # Chromium 核心依赖
    libnss3 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libasound2 \
    libpango-1.0-0 \
    libcairo2 \
    libatspi2.0-0 \
    libxshmfence1 \
    # 其他依赖
    libglu1-mesa \
    libgtk-3-0 \
    libnotify4 \
    libnss3-dev \
    libxss1 \
    xdg-utils \
    # 网络工具
    iproute2 \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# ============================================
# 2. Node.js 22.x (官方源)
# ============================================
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g npm@latest \
    && rm -rf /var/lib/apt/lists/*

# ============================================
# 3. Python 3 + 自动化库
# ============================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip python3-venv \
    && rm -rf /var/lib/apt/lists/*

# 创建虚拟环境，安装自动化库
RUN python3 -m venv /opt/python-venv
ENV PATH="/opt/python-venv/bin:$PATH"
RUN pip install --no-cache-dir \
    playwright \
    selenium \
    requests \
    && playwright install chromium \
    && playwright install-deps chromium

# ============================================
# 4. Node.js 自动化包
# ============================================
RUN npm install -g \
    puppeteer-core \
    puppeteer-extra \
    puppeteer-extra-plugin-stealth \
    axios

# ============================================
# 5. 环境变量
# ============================================
ENV DISPLAY=:99
ENV SCREEN_WIDTH=1920
ENV SCREEN_HEIGHT=1080
ENV SCREEN_DEPTH=24

# 远程访问配置
ENV REMOTE_TYPE=1
ENV VNC_PORT=5900
ENV RUSTDESK_PORT=5900
ENV REMOTE_PASSWORD=openclaw123

# ============================================
# 6. 目录结构
# ============================================
RUN mkdir -p \
    /root/.cache/chromium \
    /var/log/browser-service \
    /tmp/.X11-unix

# ============================================
# 7. 启动脚本
# ============================================
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# ============================================
# 8. 端口暴露
# ============================================
EXPOSE ${VNC_PORT} ${RUSTDESK_PORT}

# ============================================
# 9. 健康检查
# ============================================
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD curl -s http://localhost:9222/json/version > /dev/null 2>&1 || exit 1

# ============================================
# 10. 启动
# ============================================
ENTRYPOINT ["/entrypoint.sh"]