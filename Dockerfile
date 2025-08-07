FROM node:22-alpine

# 设置时区
ENV TZ=Asia/Shanghai
RUN apk add --no-cache tzdata && \
    cp /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone

# 安装编译工具和 canvas 所需的系统依赖
RUN apk add --no-cache \
    cairo-dev \
    jpeg-dev \
    pango-dev \
    giflib-dev

# 设置工作目录
WORKDIR /app

# 安装 pnpm
RUN npm install -g pnpm

# 强制重新编译不兼容的原生模块
RUN pnpm install @napi-rs/canvas --force

# 从 lobe-chat-database 镜像复制整个 /app 目录
COPY --from=lobehub/lobe-chat-database:latest --chmod=777 /app /app

# 复制启动脚本
COPY start.sh ./

# 使启动脚本可执行
RUN chmod +x /app/start.sh

# 设置运行时环境变量
ENV HOSTNAME="0.0.0.0" \
    PORT="3000"

# 设置容器入口点
ENTRYPOINT ["./start.sh"]
