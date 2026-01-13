# 1. 使用与 LobeHub 一致的 Node 版本作为基础，确保 ABI 兼容，同时提供 Shell 环境
FROM node:24-slim

# 2. 设置必要的系统环境
ENV DEBIAN_FRONTEND="noninteractive"

# 3. 安装运行时依赖 (LobeHub 依赖 ca-certificates 和 proxychains)
# 既然我们有 apt，直接安装 proxychains-ng 比复制二进制文件更稳定
RUN apt-get update && \
    apt-get install -y ca-certificates proxychains-ng && \
    rm -rf /var/lib/apt/lists/*

# 4. 从 LobeHub 复制核心应用文件
# 注意：只复制 /app，不要复制系统库，以免破坏 node-slim 的环境
COPY --from=lobehub/lobehub:2.0.0-next.272 /app /app

# 5. 复制 Komari Agent
COPY --from=ghcr.io/komari-monitor/komari-agent:latest /app/komari-agent /app/komari-agent

# 6. 补全 LobeHub 运行所需的关键环境变量 (从原 Dockerfile 提取)
ENV NODE_ENV="production" \
    NODE_OPTIONS="--dns-result-order=ipv4first --use-openssl-ca" \
    HOSTNAME="0.0.0.0" \
    PORT="3210"

# 7. 复制并处理 entrypoint
COPY entrypoint.sh /app/entrypoint.sh

# 8. 【关键步骤】权限修复
# 我们目前还是 root 用户，必须现在修正所有文件的归属权
RUN chmod +x /app/entrypoint.sh && \
    chmod +x /app/komari-agent && \
    # 将 /app 下原本属于 UID 1001 的文件全部改为 10014，防止权限不足报错
    chown -R 10014:10014 /app

# 9. 设置工作目录
WORKDIR /app

# 10. 切换到你的目标用户
USER 10014

# 11. 暴露端口
EXPOSE 3210

# 12. 启动
CMD ["/app/entrypoint.sh"]
