# 基于 Node.js 官方镜像构建最新版 OpenClaw
# 添加中国 IM 平台插件、Tailscale、Playwright + Camoufox

FROM node:22-bookworm

# 设置环境变量
ENV TZ=Asia/Shanghai
ENV NODE_ENV=production

# 配置国内镜像源加速
# apt 换阿里云源
RUN sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list.d/debian.sources \
    && sed -i 's/security.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list.d/debian.sources

# npm 换淘宝源
RUN npm config set registry https://registry.npmmirror.com

# pip 换清华源
RUN mkdir -p /root/.pip && echo "[global]\nindex-url = https://pypi.tuna.tsinghua.edu.cn/simple\ntrusted-host = pypi.tuna.tsinghua.edu.cn" > /root/.pip/pip.conf

# 安装基础依赖
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

# 一次性安装所有 npm 包，避免层叠加导致的"删除不减空间"
# 安装 OpenClaw + 中国插件 + 浏览器自动化工具 + Bun + qmd
RUN npm install -g \
    openclaw@2026.2.23 \
    @openclaw-china/channels@latest \
    playwright@latest \
    puppeteer-core \
    puppeteer-extra \
    puppeteer-extra-plugin-stealth \
    camoufox-js@latest \
    bun \
    @tobilu/qmd@latest \
    && npm cache clean --force

# 安装 Python 版本的 Playwright 和 Camoufox
RUN pip3 install --no-cache-dir --break-system-packages playwright camoufox

# 安装 sing-box（代理工具）
RUN curl -fsSL -o /usr/local/bin/sing-box.tar.gz "https://github.com/SagerNet/sing-box/releases/download/v1.11.4/sing-box-1.11.4-linux-amd64.tar.gz" \
    && tar -xzf /usr/local/bin/sing-box.tar.gz -C /usr/local/bin --strip-components=1 \
    && rm /usr/local/bin/sing-box.tar.gz \
    && chmod +x /usr/local/bin/sing-box

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