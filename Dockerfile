FROM node:24-slim

ENV DEBIAN_FRONTEND="noninteractive"

# 1. 安装系统级依赖
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
COPY --from=lobehub/lobehub:2.0.0-next.272 /app /app
COPY --from=ghcr.io/komari-monitor/komari-agent:latest /app/komari-agent /app/komari-agent

# 4. 补全环境变量
ENV NODE_ENV="production" \
    NODE_OPTIONS="--dns-result-order=ipv4first --use-openssl-ca" \
    HOSTNAME="0.0.0.0" \
    PORT="3210"

# 5. 补全 Canvas
RUN mkdir -p /tmp/canvas-build && \
    cd /tmp/canvas-build && \
    npm install @napi-rs/canvas && \
    cp -r node_modules/* /app/node_modules/ && \
    rm -rf /tmp/canvas-build

# 6. 关键修改：适配只读文件系统 (Read-Only FS)
# A. 删除原本的 .next/cache 目录 (如果有的话)
RUN rm -rf /app/.next/cache

# B. 创建一个指向 /tmp 的软链接
RUN ln -s /tmp/next-cache /app/.next/cache

COPY entrypoint.sh /app/entrypoint.sh

# 7. 权限设置
RUN chmod +x /app/entrypoint.sh && \
    chmod +x /app/komari-agent && \
    # 依然修正 /app 的归属，虽然它是只读的，但为了防止某些读取权限问题
    chown -R 10014:10014 /app

WORKDIR /app

# 8. 切换用户
USER 10014

EXPOSE 3210

CMD ["/app/entrypoint.sh"]
