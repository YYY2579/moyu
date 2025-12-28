#!/bin/bash

echo "🔍 验证部署结果..."
echo "================================"

# 设置变量
PROJECT_DIR="/opt/moyu"
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "localhost")
TEST_RESULTS=()

# 进入项目目录
cd "$PROJECT_DIR" || {
    echo "❌ 无法进入项目目录: $PROJECT_DIR"
    exit 1
}

echo "🧪 执行部署验证测试..."
echo ""

# 测试1: 检查容器状态
echo "📋 测试1: 容器状态检查"
if docker-compose ps | grep -q "Up"; then
    echo "✅ 容器状态正常"
    TEST_RESULTS+=("containers:pass")
else
    echo "❌ 容器状态异常"
    TEST_RESULTS+=("containers:fail")
fi

# 测试2: HTTP服务响应
echo ""
echo "📋 测试2: HTTP服务响应"
WEB_RESPONSE=$(curl -s -w "%{http_code}" -o /dev/null http://localhost/health || echo "000")
API_RESPONSE=$(curl -s -w "%{http_code}" -o /dev/null http://localhost:8080/health || echo "000")

if [ "$WEB_RESPONSE" = "200" ]; then
    echo "✅ Web服务响应正常 (HTTP $WEB_RESPONSE)"
    WEB_TEST="pass"
else
    echo "❌ Web服务响应异常 (HTTP $WEB_RESPONSE)"
    WEB_TEST="fail"
fi

if [ "$API_RESPONSE" = "200" ]; then
    echo "✅ API服务响应正常 (HTTP $API_RESPONSE)"
    API_TEST="pass"
else
    echo "❌ API服务响应异常 (HTTP $API_RESPONSE)"
    API_TEST="fail"
fi

TEST_RESULTS+=("web:$WEB_TEST")
TEST_RESULTS+=("api:$API_TEST")

# 测试3: 数据库连接
echo ""
echo "📋 测试3: 数据库连接"
if docker-compose exec -T mysql mysqladmin ping -h"localhost" --silent 2>/dev/null; then
    echo "✅ 数据库连接正常"
    DB_CONN_TEST="pass"
else
    echo "❌ 数据库连接失败"
    DB_CONN_TEST="fail"
fi

TEST_RESULTS+=("database:$DB_CONN_TEST")

# 测试4: 基本功能测试
echo ""
echo "📋 测试4: 基本功能测试"

# 测试API端点
API_ENDPOINTS=(
    "/api/questions"
    "/api/meta"
    "/api/stats"
)

API_FUNCTIONAL="pass"
for endpoint in "${API_ENDPOINTS[@]}"; do
    RESPONSE=$(curl -s -w "%{http_code}" -o /dev/null "http://localhost:8080$endpoint" || echo "000")
    if [ "$RESPONSE" != "200" ]; then
        echo "❌ API端点 $endpoint 响应异常 (HTTP $RESPONSE)"
        API_FUNCTIONAL="fail"
    fi
done

if [ "$API_FUNCTIONAL" = "pass" ]; then
    echo "✅ API端点响应正常"
else
    echo "❌ 部分API端点响应异常"
fi

TEST_RESULTS+=("api-functional:$API_FUNCTIONAL")

# 测试5: 静态资源检查
echo ""
echo "📋 测试5: 静态资源检查"
STATIC_RESOURCES=(
    "/"
    "/linux"
    "/docker"
    "/practice"
)

WEB_STATIC="pass"
for path in "${STATIC_RESOURCES[@]}"; do
    RESPONSE=$(curl -s -w "%{http_code}" -o /dev/null "http://localhost$path" || echo "000")
    if [ "$RESPONSE" != "200" ]; then
        echo "❌ 页面 $path 加载失败 (HTTP $RESPONSE)"
        WEB_STATIC="fail"
    fi
done

if [ "$WEB_STATIC" = "pass" ]; then
    echo "✅ 静态资源加载正常"
else
    echo "❌ 部分静态资源加载失败"
fi

TEST_RESULTS+=("static-resources:$WEB_STATIC")

# 测试6: 外部访问测试
echo ""
echo "📋 测试6: 外部访问测试"
if [ "$SERVER_IP" != "localhost" ]; then
    EXTERNAL_WEB=$(curl -s -w "%{http_code}" -o /dev/null --max-time 10 "http://$SERVER_IP/health" || echo "000")
    if [ "$EXTERNAL_WEB" = "200" ]; then
        echo "✅ 外部访问正常"
        EXTERNAL_TEST="pass"
    else
        echo "❌ 外部访问失败 (HTTP $EXTERNAL_WEB)"
        echo "💡 请检查防火墙设置和网络配置"
        EXTERNAL_TEST="fail"
    fi
else
    echo "⚠️  跳过外部访问测试（无法获取公网IP）"
    EXTERNAL_TEST="skip"
fi

TEST_RESULTS+=("external-access:$EXTERNAL_TEST")

# 生成验证报告
echo ""
echo "📊 验证结果报告"
echo "================================"

PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

for result in "${TEST_RESULTS[@]}"; do
    test_name=$(echo "$result" | cut -d':' -f1)
    test_status=$(echo "$result" | cut -d':' -f2)
    
    case "$test_status" in
        "pass")
            echo "✅ $test_name: 通过"
            ((PASS_COUNT++))
            ;;
        "fail")
            echo "❌ $test_name: 失败"
            ((FAIL_COUNT++))
            ;;
        "skip")
            echo "⚠️  $test_name: 跳过"
            ((SKIP_COUNT++))
            ;;
    esac
done

echo ""
echo "📈 统计信息:"
echo "  通过: $PASS_COUNT"
echo "  失败: $FAIL_COUNT"
echo "  跳过: $SKIP_COUNT"

# 总体评估
TOTAL_TESTS=$((PASS_COUNT + FAIL_COUNT))
if [ $TOTAL_TESTS -eq 0 ]; then
    OVERALL="unknown"
    STATUS_ICON="❓"
elif [ $FAIL_COUNT -eq 0 ]; then
    OVERALL="success"
    STATUS_ICON="🟢"
elif [ $PASS_COUNT -gt $FAIL_COUNT ]; then
    OVERALL="partial"
    STATUS_ICON="🟡"
else
    OVERALL="failed"
    STATUS_ICON="🔴"
fi

echo ""
echo "🎯 总体评估: $STATUS_ICON $OVERALL"

case "$OVERALL" in
    "success")
        echo "🎉 部署完全成功！系统运行正常"
        echo ""
        echo "🌐 立即访问:"
        echo "  主站: http://$SERVER_IP"
        echo "  开始学习: http://$SERVER_IP/linux"
        ;;
    "partial")
        echo "⚠️  部署部分成功，部分功能可能受限"
        echo ""
        echo "🔧 建议检查:"
        echo "  查看服务日志: docker-compose logs"
        echo "  重启相关服务: docker-compose restart [service]"
        ;;
    "failed")
        echo "❌ 部署验证失败，请排查问题"
        echo ""
        echo "🚨 紧急处理:"
        echo "  查看详细日志: docker-compose logs --tail=50"
        echo "  重新部署: docker-compose down && docker-compose up -d"
        echo "  完整重建: docker-compose down && docker-compose build --no-cache && docker-compose up -d"
        ;;
    "unknown")
        echo "❓ 无法确定部署状态"
        ;;
esac

# 性能建议
echo ""
echo "💡 性能优化建议:"
echo "  1. 定期清理Docker缓存: docker system prune -f"
echo "  2. 监控资源使用: docker stats"
echo "  3. 定期备份数据库: docker-compose exec mysql mysqldump ..."
echo "  4. 检查磁盘空间: df -h"

echo ""
echo "📞 如需帮助，请访问:"
echo "  问题反馈: https://github.com/YYY2579/moyu/issues"
echo "  文档地址: https://github.com/YYY2579/moyu/blob/main/README.md"
echo "================================"