#!/bin/bash
# ============================================
# OpenClaw Browser Service - Minimal Version
# 启动脚本
# ============================================

set -e

echo "=========================================="
echo "  OpenClaw Browser Service (Minimal)"
echo "=========================================="

# --------------------------------------------
# 1. 环境变量默认值
# --------------------------------------------
": "${DISPLAY:=:99}"
": "${SCREEN_WIDTH:=1920}"
": "${SCREEN_HEIGHT:=1080}"
": "${SCREEN_DEPTH:=24}"
": "${REMOTE_TYPE:=1}"
": "${VNC_PORT:=5900}"
": "${RUSTDESK_PORT:=5900}"
": "${REMOTE_PASSWORD:=openclaw123}"

echo "Display: ${DISPLAY} (${SCREEN_WIDTH}x${SCREEN_HEIGHT}x${SCREEN_DEPTH})"
echo "Remote Type: ${REMOTE_TYPE} (0=none, 1=VNC, 2=RustDesk, 3=both)"

# --------------------------------------------
# 2. 启动 Xvfb (虚拟显示器)
# --------------------------------------------
echo "[1/5] Cleaning X11 lock files..."
rm -f /tmp/.X${DISPLAY#:}-lock
rm -f /tmp/.X11-unix/X${DISPLAY#:}
rm -rf /tmp/.X11-unix

echo "[1/5] Starting Xvfb..."
Xvfb "${DISPLAY}" \
    -screen 0 "${SCREEN_WIDTH}x${SCREEN_HEIGHT}x${SCREEN_DEPTH}" \
    -ac \
    -nolisten tcp \
    -pixdepths 24 32 \
    &

XVFB_PID=$!
sleep 2

if ! ps -p $XVFB_PID > /dev/null; then
    echo "ERROR: Xvfb failed to start"
    exit 1
fi
echo "  ✓ Xvfb running (PID: $XVFB_PID)"

# --------------------------------------------
# 3. 启动 FluxBox 窗口管理器
# --------------------------------------------
echo "[2/5] Starting FluxBox..."
DISPLAY="${DISPLAY}" fluxbox &
FLUXBOX_PID=$!
sleep 3

if ! ps -p $FLUXBOX_PID > /dev/null; then
    echo "  WARNING: FluxBox failed to start, continuing without WM"
else
    echo "  ✓ FluxBox running (PID: $FLUXBOX_PID)"
fi

# --------------------------------------------
# 4. 启动远程访问服务
# --------------------------------------------
echo "[3/5] Starting remote access services..."

case $REMOTE_TYPE in
    0)
        echo "  Remote access disabled"
        ;;
    1)
        echo "  Starting VNC on port ${VNC_PORT}"
        VNC_PASSWORD_FILE="/root/.vnc/passwd"

        if [ -f "$VNC_PASSWORD_FILE" ]; then
            echo "  Using password file: $VNC_PASSWORD_FILE"
            x11vnc -display "${DISPLAY}" \
                -rfbport "${VNC_PORT}" \
                -rfbauth "$VNC_PASSWORD_FILE" \
                -forever \
                -shared \
                -bg \
                -o /var/log/browser-service/vnc.log \
                -noxdamage \
                -nowf \
                -ncache 10
        elif [ -n "$REMOTE_PASSWORD" ]; then
            echo "  Using password from environment variable"
            x11vnc -display "${DISPLAY}" \
                -rfbport "${VNC_PORT}" \
                -passwd "${REMOTE_PASSWORD}" \
                -forever \
                -shared \
                -bg \
                -o /var/log/browser-service/vnc.log \
                -noxdamage \
                -nowf \
                -ncache 10
        else
            echo "  WARNING: Running without VNC password!"
            x11vnc -display "${DISPLAY}" \
                -rfbport "${VNC_PORT}" \
                -nopw \
                -forever \
                -shared \
                -bg \
                -o /var/log/browser-service/vnc.log \
                -noxdamage \
                -nowf \
                -ncache 10
        fi
        sleep 2
        echo "  ✓ VNC server running on port ${VNC_PORT}"
        ;;
    2)
        echo "  Starting RustDesk on port ${RUSTDESK_PORT}"
        # RustDesk 需要在标准版中安装，极简版不支持
        echo "  ERROR: RustDesk is not available in minimal version"
        echo "  Please use standard version for RustDesk support"
        ;;
    3)
        echo "  Starting VNC on port ${VNC_PORT} and RustDesk on port ${RUSTDESK_PORT}"
        VNC_PASSWORD_FILE="/root/.vnc/passwd"

        if [ -f "$VNC_PASSWORD_FILE" ]; then
            x11vnc -display "${DISPLAY}" \
                -rfbport "${VNC_PORT}" \
                -rfbauth "$VNC_PASSWORD_FILE" \
                -forever \
                -shared \
                -bg \
                -o /var/log/browser-service/vnc.log \
                -noxdamage \
                -nowf \
                -ncache 10
        elif [ -n "$REMOTE_PASSWORD" ]; then
            x11vnc -display "${DISPLAY}" \
                -rfbport "${VNC_PORT}" \
                -passwd "${REMOTE_PASSWORD}" \
                -forever \
                -shared \
                -bg \
                -o /var/log/browser-service/vnc.log \
                -noxdamage \
                -nowf \
                -ncache 10
        else
            echo "  WARNING: Running without VNC password!"
            x11vnc -display "${DISPLAY}" \
                -rfbport "${VNC_PORT}" \
                -nopw \
                -forever \
                -shared \
                -bg \
                -o /var/log/browser-service/vnc.log \
                -noxdamage \
                -nowf \
                -ncache 10
        fi

        echo "  ERROR: RustDesk is not available in minimal version"
        echo "  Please use standard version for RustDesk support"
        ;;
    *)
        echo "  ERROR: Invalid REMOTE_TYPE value: ${REMOTE_TYPE}"
        echo "  Valid values: 0=none, 1=VNC, 2=RustDesk, 3=both"
        ;;
esac

# --------------------------------------------
# 5. 输出连接信息
# --------------------------------------------
echo ""
echo "=========================================="
echo "  Browser Service Ready!"
echo "=========================================="
echo ""
echo "  Available Tools:"
echo "    - Playwright (Python)"
echo "    - Selenium (Python)"
echo "    - Puppeteer-extra (Node.js)"
echo ""

if [ "$REMOTE_TYPE" = "1" ] || [ "$REMOTE_TYPE" = "3" ]; then
    echo "  VNC Connection:"
    echo "    Address: <container-ip>:${VNC_PORT}"
    echo "    Password: ${REMOTE_PASSWORD:-<no password>}"
    echo ""
fi

echo "  Logs:"
echo "    VNC: /var/log/browser-service/vnc.log"
echo ""
echo "=========================================="

# --------------------------------------------
# 6. 保持容器运行
# --------------------------------------------
echo "[5/5] Service is running. Press Ctrl+C to stop."

# 信号处理
trap 'echo "Stopping services..."; kill $XVFB_PID $FLUXBOX_PID 2>/dev/null; exit 0' SIGTERM SIGINT

# 等待
wait