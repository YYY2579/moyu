#!/bin/bash

echo "🔧 修复部署问题（端口冲突版本）"
echo "=========================="

# 1. 停止并清理所有相关容器
echo "🛑 停止并清理现有容器..."
docker-compose down --remove-orphans 2>/dev/null || true

# 强制删除冲突的容器
echo "🗑️ 清理冲突容器..."
docker stop webhook 2>/dev/null || true
docker rm webhook 2>/dev/null || true
docker stop web 2>/dev/null || true  
docker rm web 2>/dev/null || true
docker stop api 2>/dev/null || true
docker rm api 2>/dev/null || true
docker stop moyu-study-2-mysql-1 2>/dev/null || true
docker rm moyu-study-2-mysql-1 2>/dev/null || true

# 2. 杀死占用端口的进程
echo "🔫 杀死占用33066端口的进程..."
if command -v netstat >/dev/null 2>&1; then
    netstat -tulpn | grep :33066 | awk '{print $7}' | cut -d'/' -f1 | xargs -r kill -9 2>/dev/null || true
fi

# 3. 清理未使用的网络
echo "🌐 清理Docker网络..."
docker network prune -f 2>/dev/null || true

# 3. 创建环境文件
echo "📝 设置环境变量..."
cat > .env << EOF
MYSQL_ROOT_PASSWORD=moyu123456
MYSQL_DATABASE=moyu_study
MYSQL_USER=moyu_user
MYSQL_PASSWORD=moyu_user_password

# JWT密钥
JWT_SECRET=moyu_jwt_secret_key_2023

# Webhook密钥
WEBHOOK_SECRET=moyu_webhook_secret_2023
EOF

echo "✅ 环境变量已设置"

# 4. 重新构建和启动
echo "🔨 重新构建镜像..."
docker-compose build --no-cache

echo "🚀 启动服务..."
docker-compose up -d

# 5. 等待服务启动
echo "⏳ 等待服务启动..."
sleep 20

# 6. 检查服务状态
echo "📊 检查服务状态..."
docker-compose ps

# 7. 检查日志
echo "📋 检查服务日志..."
echo "=== Web服务日志 ==="
docker-compose logs web --tail=10

echo "=== API服务日志 ==="  
docker-compose logs api --tail=10

echo "=== MySQL服务日志 ==="
docker-compose logs mysql --tail=10

# 8. 测试服务
echo "🔍 测试服务..."
echo "测试Web服务..."
if curl -f http://localhost/health > /dev/null 2>&1; then
    echo "✅ Web服务正常"
else
    echo "❌ Web服务异常"
fi

echo "测试API服务..."
if curl -f http://localhost:8080/health > /dev/null 2>&1; then
    echo "✅ API服务正常"
else
    echo "❌ API服务异常"
fi

echo ""
echo "🎉 部署完成！"
echo "=========================="
echo "🌐 访问地址: http://114.132.189.90"
echo "🔍 健康检查: http://114.132.189.90/health"
echo "📱 移动端: http://114.132.189.90"
echo ""
echo "📋 管理命令:"
echo "  查看日志: docker-compose logs -f [service-name]"
echo "  重启服务: docker-compose restart [service-name]"
echo "  停止服务: docker-compose down"
echo "  进入容器: docker-compose exec web sh"
echo ""