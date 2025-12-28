#!/bin/bash

echo "🔍 执行健康检查..."
echo "================================"

# 设置变量
PROJECT_DIR="/opt/moyu"
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "localhost")

# 进入项目目录
cd "$PROJECT_DIR" || {
    echo "❌ 无法进入项目目录: $PROJECT_DIR"
    exit 1
}

# 检查Docker服务状态
echo "🐳 检查Docker服务..."
if ! command -v docker &> /dev/null; then
    echo "❌ Docker未安装"
    exit 1
fi

if ! sudo systemctl is-active --quiet docker; then
    echo "❌ Docker服务未运行"
    exit 1
fi

# 检查容器状态
echo "📊 检查容器状态..."
CONTAINER_STATUS=$(docker-compose ps --format json 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "❌ 无法获取容器状态"
    exit 1
fi

# 解析容器状态
WEB_STATUS="unknown"
API_STATUS="unknown"
MYSQL_STATUS="unknown"

while IFS= read -r line; do
    SERVICE=$(echo "$line" | grep -o '"Service":"[^"]*"' | cut -d'"' -f4)
    STATE=$(echo "$line" | grep -o '"State":"[^"]*"' | cut -d'"' -f4)
    
    case "$SERVICE" in
        "web")
            WEB_STATUS="$STATE"
            ;;
        "api")
            API_STATUS="$STATE"
            ;;
        "mysql")
            MYSQL_STATUS="$STATE"
            ;;
    esac
done <<< "$CONTAINER_STATUS"

echo "  Web容器: $WEB_STATUS"
echo "  API容器: $API_STATUS"
echo "  MySQL容器: $MYSQL_STATUS"

# 检查端口监听
echo ""
echo "🔌 检查端口监听..."
if command -v netstat &> /dev/null; then
    if netstat -tlnp 2>/dev/null | grep -q ":80 "; then
        echo "✅ 端口80: 正在监听"
    else
        echo "❌ 端口80: 未监听"
    fi
    
    if netstat -tlnp 2>/dev/null | grep -q ":8080 "; then
        echo "✅ 端口8080: 正在监听"
    else
        echo "❌ 端口8080: 未监听"
    fi
    
    if netstat -tlnp 2>/dev/null | grep -q ":33067 "; then
        echo "✅ 端口33067: 正在监听"
    else
        echo "❌ 端口33067: 未监听"
    fi
else
    echo "⚠️  netstat命令不可用，跳过端口检查"
fi

# 检查HTTP服务
echo ""
echo "🌐 检查HTTP服务..."

# 检查Web服务
echo "🔍 检查Web服务响应..."
if curl -f -s --max-time 10 http://localhost/health > /dev/null 2>&1; then
    echo "✅ Web服务: 响应正常"
    WEB_HTTP="ok"
elif curl -f -s --max-time 10 http://$SERVER_IP/health > /dev/null 2>&1; then
    echo "✅ Web服务: 响应正常"
    WEB_HTTP="ok"
else
    echo "❌ Web服务: 无响应"
    WEB_HTTP="fail"
fi

# 检查API服务
echo "🔍 检查API服务响应..."
if curl -f -s --max-time 10 http://localhost:8080/health > /dev/null 2>&1; then
    echo "✅ API服务: 响应正常"
    API_HTTP="ok"
else
    echo "❌ API服务: 无响应"
    API_HTTP="fail"
fi

# 检查数据库连接
echo ""
echo "🗄️ 检查数据库连接..."
if docker-compose exec -T mysql mysqladmin ping -h"localhost" --silent 2>/dev/null; then
    echo "✅ 数据库: 连接正常"
    DB_CONN="ok"
    
    # 检查数据库是否存在
    if docker-compose exec -T mysql mysql -u root -p$MYSQL_ROOT_PASSWORD -e "USE moyu_study; SELECT 1;" &>/dev/null; then
        echo "✅ 数据库: moyu_study存在"
        DB_EXIST="ok"
    else
        echo "❌ 数据库: moyu_study不存在"
        DB_EXIST="fail"
    fi
else
    echo "❌ 数据库: 连接失败"
    DB_CONN="fail"
    DB_EXIST="unknown"
fi

# 检查系统资源
echo ""
echo "📊 系统资源状态..."

# CPU使用率
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 2>/dev/null)
if [ -n "$CPU_USAGE" ]; then
    echo "  CPU使用率: ${CPU_USAGE}%"
fi

# 内存使用
MEM_INFO=$(free -h 2>/dev/null | grep '^Mem:')
if [ -n "$MEM_INFO" ]; then
    MEM_TOTAL=$(echo "$MEM_INFO" | awk '{print $2}')
    MEM_USED=$(echo "$MEM_INFO" | awk '{print $3}')
    MEM_PERCENT=$(echo "$MEM_INFO" | awk '{print $3}' | sed 's/[A-Za-z]//g' | awk '{printf "%.1f", ($1/$2)*100}' 2>/dev/null)
    echo "  内存使用: $MEM_USED / $MEM_TOTAL"
fi

# 磁盘使用
DISK_USAGE=$(df -h / 2>/dev/null | tail -1)
if [ -n "$DISK_USAGE" ]; then
    DISK_PERCENT=$(echo "$DISK_USAGE" | awk '{print $5}')
    echo "  磁盘使用: $DISK_PERCENT"
fi

# 检查Docker资源使用
echo ""
echo "🐳 Docker资源使用..."
if command -v docker-stats &> /dev/null || docker stats --no-stream 2>/dev/null; then
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null || {
        echo "⚠️  无法获取Docker统计信息"
    }
fi

# 检查最近的错误日志
echo ""
echo "📋 最近错误日志..."

# Web服务错误
echo "=== Web服务错误日志 ==="
docker-compose logs web --tail=5 2>/dev/null | grep -i error || echo "无错误日志"

echo ""

# API服务错误
echo "=== API服务错误日志 ==="
docker-compose logs api --tail=5 2>/dev/null | grep -i error || echo "无错误日志"

echo ""

# MySQL服务错误
echo "=== MySQL服务错误日志 ==="
docker-compose logs mysql --tail=5 2>/dev/null | grep -i error || echo "无错误日志"

# 生成健康检查报告
echo ""
echo "📋 健康检查报告"
echo "================================"

OVERALL_STATUS="healthy"

# 评估整体状态
if [ "$WEB_STATUS" != "running" ] || [ "$API_STATUS" != "running" ] || [ "$MYSQL_STATUS" != "running" ]; then
    OVERALL_STATUS="unhealthy"
    echo "❌ 容器状态异常"
fi

if [ "$WEB_HTTP" != "ok" ] || [ "$API_HTTP" != "ok" ]; then
    OVERALL_STATUS="unhealthy"
    echo "❌ HTTP服务异常"
fi

if [ "$DB_CONN" != "ok" ] || [ "$DB_EXIST" != "ok" ]; then
    OVERALL_STATUS="unhealthy"
    echo "❌ 数据库异常"
fi

case "$OVERALL_STATUS" in
    "healthy")
        echo "🟢 整体状态: 健康"
        echo ""
        echo "🎉 系统运行正常！"
        echo "🌐 访问地址: http://$SERVER_IP"
        ;;
    "unhealthy")
        echo "🔴 整体状态: 异常"
        echo ""
        echo "⚠️  请检查以上错误信息并进行修复"
        echo "🔧 常用修复命令:"
        echo "  重启服务: docker-compose restart"
        echo "  重新构建: docker-compose build --no-cache && docker-compose up -d"
        echo "  查看详细日志: docker-compose logs -f"
        ;;
esac

echo ""
echo "📞 如需帮助，请查看: https://github.com/YYY2579/moyu/issues"
echo "================================"