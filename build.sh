#!/bin/bash
set -e

cd "$(dirname "$0")"

echo ">>> 停止旧容器..."
docker-compose down --remove-orphans 2>/dev/null || true

echo ">>> 构建新镜像..."
docker-compose build --no-cache

echo ">>> 启动服务..."
docker-compose up -d

echo ">>> 清理旧镜像..."
docker image prune -f

echo ">>> 完成！"
docker-compose ps
