FROM node:24-slim

ENV DEBIAN_FRONTEND="noninteractive"

# 1. 安装系统依赖
RUN apt-get update && \
    apt-get install -y \
    ca-certificates \
    proxychains-ng \
    libcairo2 \
    libpango-1.0-0 \
    libpangocairo-1.0-0 \
    libgif7 \
    librsvg2-2 \
    libjpeg62-turbo \
    && rm -rf /var/lib/apt/lists/*

# 2. 修复 Node 路径
RUN ln -sf /usr/local/bin/node /bin/node

# 3. 复制应用文件
COPY --from=lobehub/lobehub:2.0.0-next.302 /app /app
COPY --from=ghcr.io/komari-monitor/komari-agent:latest /app/komari-agent /app/komari-agent

# 4. 环境变量
ENV NODE_ENV="production" \
    NODE_OPTIONS="--dns-result-order=ipv4first --use-openssl-ca" \
    HOSTNAME="0.0.0.0" \
    PORT="3210"

# 5. 安装 Canvas
RUN mkdir -p /tmp/canvas-build && \
    cd /tmp/canvas-build && \
    npm install @napi-rs/canvas && \
    cp -r node_modules/* /app/node_modules/ && \
    rm -rf /tmp/canvas-build

# =======================================================
# 🔧 结构调整
# =======================================================

# A. 移动 .next 到备份目录
RUN mv /app/.next /app/.next_source

# B. 创建软链接 (指向尚未存在的 /tmp/next)
RUN ln -s /tmp/next /app/.next

COPY entrypoint.sh /app/entrypoint.sh

# 6. 权限设置
# 确保 10014 拥有所有权
RUN chmod +x /app/entrypoint.sh && \
    chmod +x /app/komari-agent && \
    chown -R 10014:10014 /app

WORKDIR /app
USER 10014
EXPOSE 3210

CMD ["/app/entrypoint.sh"]
