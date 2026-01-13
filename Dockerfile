# 1. 使用 Node 24 slim 作为基础
FROM node:24-slim

# 2. 设置系统环境
ENV DEBIAN_FRONTEND="noninteractive"

# 3. 安装依赖
RUN apt-get update && \
    apt-get install -y ca-certificates proxychains-ng && \
    rm -rf /var/lib/apt/lists/*

# LobeHub 硬编码了 /bin/node，所以我们创建一个指向真实 node 路径的链接
RUN ln -sf /usr/local/bin/node /bin/node

# 4. 从 LobeHub 复制应用文件
COPY --from=lobehub/lobehub:2.0.0-next.272 /app /app

# 5. 复制 Komari Agent
COPY --from=ghcr.io/komari-monitor/komari-agent:latest /app/komari-agent /app/komari-agent

# 6. 补全环境变量
ENV NODE_ENV="production" \
    NODE_OPTIONS="--dns-result-order=ipv4first --use-openssl-ca" \
    HOSTNAME="0.0.0.0" \
    PORT="3210"

# 7. 复制脚本
COPY entrypoint.sh /app/entrypoint.sh

# 8. 修复权限
# 给脚本可执行权限，并将所有文件归属权给 10014
RUN chmod +x /app/entrypoint.sh && \
    chmod +x /app/komari-agent && \
    chown -R 10014:10014 /app

# 9. 设置工作目录
WORKDIR /app

# 10. 切换用户
USER 10014

# 11. 暴露端口
EXPOSE 3210

# 12. 启动
CMD ["/app/entrypoint.sh"]
