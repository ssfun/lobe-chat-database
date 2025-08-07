#!/bin/sh

# 启动 docker cjs 服务
echo "Starting docker cjs..."
node /app/docker.cjs &

# 启动 lobechat 服务
echo "Starting lobechat..."
node /app/server.js
