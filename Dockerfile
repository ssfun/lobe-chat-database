FROM node:24-slim

ENV DEBIAN_FRONTEND="noninteractive"

# 1. 安装依赖
RUN apt-get update && \
    apt-get install -y \
    ca-certificates \
    proxychains-ng \
    libcairo2 \
    libpango-1.0-0 \
    libpangocairo-1.0-0 \
    libgif7 \
    librsvg2-2 \
    && rm -rf /var/lib/apt/lists/*

# 2. 修复 Node 路径
RUN ln -sf /usr/local/bin/node /bin/node

COPY --from=lobehub/lobehub:2.0.0-next.272 /app /app
COPY --from=ghcr.io/komari-monitor/komari-agent:latest /app/komari-agent /app/komari-agent

# 3. 补全环境变量
ENV NODE_ENV="production" \
    NODE_OPTIONS="--dns-result-order=ipv4first --use-openssl-ca" \
    HOSTNAME="0.0.0.0" \
    PORT="3210"

COPY entrypoint.sh /app/entrypoint.sh

# 4. 创建缓存目录结构
RUN mkdir -p /app/.next/cache

# 5. 权限修复
RUN chmod +x /app/entrypoint.sh && \
    chmod +x /app/komari-agent && \
    chown -R 10014:10014 /app

WORKDIR /app

USER 10014

EXPOSE 3210

CMD ["/app/entrypoint.sh"]
