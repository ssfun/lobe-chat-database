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

# 5. 补全缺失的原生模块
WORKDIR /app
RUN npm install --no-save @napi-rs/canvas

# 6. 修复目录结构和权限
RUN mkdir -p /app/.next/cache && \
    chmod 755 /app/.next/cache

COPY entrypoint.sh /app/entrypoint.sh

# 7. 最终权限修正
RUN chmod +x /app/entrypoint.sh && \
    chmod +x /app/komari-agent && \
    chown -R 10014:10014 /app

# 8. 切换用户启动
USER 10014

EXPOSE 3210

CMD ["/app/entrypoint.sh"]
