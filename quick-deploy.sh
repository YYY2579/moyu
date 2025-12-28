#!/bin/bash

echo "🚀 摸鱼学习站 - 快速部署"
echo "================================"

# 检查Docker是否安装
if ! command -v docker &> /dev/null; then
    echo "❌ Docker 未安装，请先安装 Docker"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose 未安装，请先安装 Docker Compose"
    exit 1
fi

# 停止现有容器
echo "🛑 停止现有服务..."
docker-compose down 2>/dev/null || true

# 拉取最新代码
echo "📥 拉取最新代码..."
git pull origin main

# 构建和启动
echo "🔨 构建镜像..."
docker-compose build --no-cache

echo "🚀 启动服务..."
docker-compose up -d

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 15

# 检查服务状态
echo "📊 检查服务状态..."
docker-compose ps

# 显示访问地址
echo ""
echo "✅ 部署完成！"
echo "================================"
echo "🌐 访问地址: http://114.132.189.90"
echo "🔍 健康检查: http://114.132.189.90/health"
echo "📱 移动端: http://114.132.189.90 (手机浏览器访问)"
echo ""
echo "📋 管理命令:"
echo "  查看日志: docker-compose logs -f"
echo "  重启服务: docker-compose restart"
echo "  停止服务: docker-compose down"
echo ""
echo "🎉 摸鱼学习站部署成功！开始学习吧！"