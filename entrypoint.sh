#!/bin/sh

# ==============================
# 环境变量配置与默认值
# ==============================
KOMARI_SECRET=${KOMARI_SECRET:-""}
KOMARI_SERVER=${KOMARI_SERVER:-""}

# ==============================
# 0. 【核心】初始化可写环境
# ==============================
echo "[Init] Initializing runtime environment..."

# 1. 强制清理并重建目标目录 (防止残留坏数据)
rm -rf /tmp/next
mkdir -p /tmp/next

# 2. 使用 tar 进行精确复制 (比 cp 更稳健)
# 将 .next_source 的内容解压到 /tmp/next
echo "[Init] Copying build assets to /tmp/next..."
cd /app/.next_source && tar cf - . | (cd /tmp/next && tar xf -)

# 3. 强制创建缓存目录
mkdir -p /tmp/next/cache

# ==============================
# 🔍 启动前自检 (Self-Check)
# ==============================
if [ -f "/app/.next/BUILD_ID" ]; then
    echo "[Check] ✅ Build ID found: $(cat /app/.next/BUILD_ID)"
else
    echo "[Check] ❌ FATAL: BUILD_ID not found in /app/.next!"
    echo "[Debug] Content of /app/.next (symlink target):"
    ls -la /app/.next/ || echo "Cannot list /app/.next"
    echo "[Debug] Content of /tmp/next:"
    ls -la /tmp/next/ || echo "Cannot list /tmp/next"
    # 如果检测失败，不要强行启动，否则只会报 generic error
    echo "[Check] Trying to start anyway, but expect failure..."
fi

# 返回 app 目录
cd /app

# ==============================
# 1. 启动 komari-agent
# ==============================
KOMARI_SECRET=${KOMARI_SECRET:-""}
if [ -n "$KOMARI_SERVER" ] && [ -n "$KOMARI_SECRET" ]; then
    echo "[Komari] Starting agent..."
    /app/komari-agent -e "$KOMARI_SERVER" -t "$KOMARI_SECRET" --disable-auto-update >/dev/null 2>&1 &
fi

# ==============================
# 2. 启动主应用
# ==============================
echo "[LobeHub] Starting server on port $PORT..."
exec node /app/startServer.js
