#!/bin/bash

echo "🔨 构建和启动服务..."
echo "================================"

# 设置变量
PROJECT_DIR="/opt/moyu"
MAX_RETRIES=3
RETRY_DELAY=10

# 进入项目目录
cd "$PROJECT_DIR" || {
    echo "❌ 无法进入项目目录: $PROJECT_DIR"
    exit 1
}

# 检查必要文件
if [ ! -f ".env" ]; then
    echo "❌ 未找到环境变量文件，请先运行: ./scripts/deploy-moyu.sh"
    exit 1
fi

if [ ! -f "docker-compose.yml" ]; then
    echo "❌ 未找到 docker-compose.yml 文件"
    exit 1
fi

# 停止现有容器
echo "🛑 停止现有容器..."
docker-compose down --remove-orphans 2>/dev/null || true

# 清理冲突的容器
echo "🗑️ 清理冲突容器..."
docker stop moyu-study-2-web-1 2>/dev/null || true
docker rm moyu-study-2-web-1 2>/dev/null || true
docker stop moyu-study-2-api-1 2>/dev/null || true
docker rm moyu-study-2-api-1 2>/dev/null || true
docker stop moyu-study-2-mysql-1 2>/dev/null || true
docker rm moyu-study-2-mysql-1 2>/dev/null || true
docker stop webhook 2>/dev/null || true
docker rm webhook 2>/dev/null || true

# 清理未使用的网络
echo "🌐 清理Docker网络..."
docker network prune -f 2>/dev/null || true

# 拉取最新镜像
echo "📥 拉取最新基础镜像..."
docker-compose pull || true

# 构建镜像
echo "🏗️ 构建Docker镜像..."
for i in $(seq 1 $MAX_RETRIES); do
    if docker-compose build --no-cache; then
        echo "✅ 镜像构建成功"
        break
    else
        echo "❌ 镜像构建失败，重试 $i/$MAX_RETRIES..."
        if [ $i -eq $MAX_RETRIES ]; then
            echo "❌ 镜像构建最终失败"
            exit 1
        fi
        sleep $RETRY_DELAY
    fi
done

# 启动服务
echo "🚀 启动服务..."
for i in $(seq 1 $MAX_RETRIES); do
    if docker-compose up -d; then
        echo "✅ 服务启动成功"
        break
    else
        echo "❌ 服务启动失败，重试 $i/$MAX_RETRIES..."
        if [ $i -eq $MAX_RETRIES ]; then
            echo "❌ 服务启动最终失败"
            exit 1
        fi
        sleep $RETRY_DELAY
    fi
done

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 30

# 检查服务状态
echo "📊 检查服务状态..."
docker-compose ps

# 等待数据库就绪
echo "🗄️ 等待数据库就绪..."
DB_READY=false
for i in $(seq 1 30); do
    if docker-compose exec -T mysql mysqladmin ping -h"localhost" --silent; then
        DB_READY=true
        echo "✅ 数据库已就绪"
        break
    else
        echo "⏳ 等待数据库启动... ($i/30)"
        sleep 2
    fi
done

if [ "$DB_READY" = false ]; then
    echo "❌ 数据库启动超时"
    echo "📋 MySQL日志:"
    docker-compose logs mysql --tail=20
    exit 1
fi

# 初始化数据库（如果需要）
echo "🔧 初始化数据库..."
if ! docker-compose exec -T mysql mysql -u root -p$MYSQL_ROOT_PASSWORD -e "USE moyu_study; SELECT COUNT(*) FROM users;" 2>/dev/null; then
    echo "📝 执行数据库初始化脚本..."
    if [ -d "deploy/mysql-init" ]; then
        for sql_file in deploy/mysql-init/*.sql; do
            if [ -f "$sql_file" ]; then
                echo "📄 执行: $sql_file"
                docker-compose exec -T mysql mysql -u root -p$MYSQL_ROOT_PASSWORD < "$sql_file"
            fi
        done
    fi
    
    # 执行API种子数据
    if docker-compose exec -T api npm run seed 2>/dev/null; then
        echo "✅ API种子数据初始化成功"
    else
        echo "⚠️  API种子数据初始化失败（可能已存在）"
    fi
else
    echo "✅ 数据库已初始化"
fi

# 健康检查
echo "🔍 执行健康检查..."

# 检查Web服务
WEB_HEALTH=false
for i in $(seq 1 30); do
    if curl -f http://localhost/health > /dev/null 2>&1; then
        WEB_HEALTH=true
        echo "✅ Web服务健康检查通过"
        break
    else
        echo "⏳ 等待Web服务... ($i/30)"
        sleep 2
    fi
done

# 检查API服务
API_HEALTH=false
for i in $(seq 1 30); do
    if curl -f http://localhost:8080/health > /dev/null 2>&1; then
        API_HEALTH=true
        echo "✅ API服务健康检查通过"
        break
    else
        echo "⏳ 等待API服务... ($i/30)"
        sleep 2
    fi
done

# 显示服务日志
echo ""
echo "📋 服务日志概要:"
echo "=== Web服务日志 ==="
docker-compose logs web --tail=10

echo ""
echo "=== API服务日志 ==="
docker-compose logs api --tail=10

echo ""
echo "=== MySQL服务日志 ==="
docker-compose logs mysql --tail=10

# 健康检查结果
echo ""
echo "🏥 健康检查结果:"
if [ "$WEB_HEALTH" = true ]; then
    echo "✅ Web服务: 正常"
else
    echo "❌ Web服务: 异常"
fi

if [ "$API_HEALTH" = true ]; then
    echo "✅ API服务: 正常"
else
    echo "❌ API服务: 异常"
fi

if [ "$DB_READY" = true ]; then
    echo "✅ 数据库: 正常"
else
    echo "❌ 数据库: 异常"
fi

# 获取服务器IP
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "localhost")

echo ""
echo "✅ 服务启动完成"
echo "================================"
echo ""
echo "🌐 访问地址:"
echo "  主站: http://$SERVER_IP"
echo "  Linux学习: http://$SERVER_IP/linux"
echo "  Docker学习: http://$SERVER_IP/docker"
echo "  练习系统: http://$SERVER_IP/practice"
echo "  健康检查: http://$SERVER_IP/health"
echo ""
echo "📋 管理命令:"
echo "  查看状态: docker-compose ps"
echo "  查看日志: docker-compose logs -f"
echo "  重启服务: docker-compose restart"
echo "  停止服务: docker-compose down"
echo "  进入容器: docker-compose exec [service] sh"
echo ""

if [ "$WEB_HEALTH" = true ] && [ "$API_HEALTH" = true ] && [ "$DB_READY" = true ]; then
    echo "🎉 所有服务运行正常！"
else
    echo "⚠️  部分服务可能存在问题，请查看日志排查"
fi

echo ""