#!/bin/sh

# ==============================
# 环境变量配置与默认值
# ==============================
KOMARI_SECRET=${KOMARI_SECRET:-""}
KOMARI_SERVER=${KOMARI_SERVER:-""}

# ==============================
# 1. 初始化缓存目录 (适配只读文件系统)
# ==============================
echo "[Init] Preparing writable .next directory in /tmp..."

# A. 确保目标目录存在
mkdir -p /tmp/next

# B. 将构建产物从备份目录复制到 /tmp (如果 /tmp 为空)
if [ ! -d "/tmp/next/server" ]; then
    cp -a /app/.next_source/. /tmp/next/
    echo "[Init] Assets copied to /tmp/next"
else
    echo "[Init] /tmp/next already exists, skipping copy"
fi

# ==============================
# 2. 启动 komari-agent
# ==============================
if [ -n "$KOMARI_SERVER" ] && [ -n "$KOMARI_SECRET" ]; then
    echo "[Komari] 启动监控..."
    # 确保后台运行
    /app/komari-agent -e "$KOMARI_SERVER" -t "$KOMARI_SECRET" --disable-auto-update >/dev/null 2>&1 &
else
    echo "[Komari] 未配置，跳过。"
fi

# ==============================
# 3. 启动主应用
# ==============================
echo "[LobeHub] 启动服务 (Port: $PORT)..."

exec node /app/startServer.js
