#!/usr/bin/env bash
set -euo pipefail

# 部署状态检查脚本
# 用于验证系统各组件是否正常运行

PROJECT_DIR="${1:-/opt/moyu-study}"
VERBOSE="${2:-false}"

echo "========================================="
echo "🔍 摸鱼学习站部署状态检查"
echo "========================================="
echo "检查时间: $(date)"
echo "项目目录: $PROJECT_DIR"
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查函数
check_status() {
    local service="$1"
    local status="$2"
    local details="$3"
    
    if [ "$status" = "0" ]; then
        echo -e "${GREEN}✅ $service: 正常${NC}"
        if [ "$VERBOSE" = "true" ] && [ -n "$details" ]; then
            echo "   $details"
        fi
    else
        echo -e "${RED}❌ $service: 异常${NC}"
        if [ -n "$details" ]; then
            echo -e "   ${YELLOW}详情: $details${NC}"
        fi
    fi
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# 进入项目目录
if [ ! -d "$PROJECT_DIR" ]; then
    echo -e "${RED}错误: 项目目录不存在: $PROJECT_DIR${NC}"
    exit 1
fi

cd "$PROJECT_DIR"

# 1. 检查基础环境
echo "📋 基础环境检查"
echo "-------------------"

# 检查用户权限
USER=$(whoami)
DOCKER_GROUPS=$(groups "$USER" | grep -o docker || echo "无")
if [ "$DOCKER_GROUPS" != "无" ]; then
    check_status "Docker用户权限" "0" "用户$USER在docker组中"
else
    check_status "Docker用户权限" "1" "用户$USER不在docker组中，可能需要sudo"
fi

# 检查Docker服务
if systemctl is-active --quiet docker; then
    DOCKER_VER=$(docker --version 2>/dev/null | cut -d' ' -f3 | cut -d',' -f1 || echo "未知")
    check_status "Docker服务" "0" "版本: $DOCKER_VER"
else
    check_status "Docker服务" "1" "Docker服务未运行"
fi

# 检查Docker Compose
if command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_VER=$(docker-compose --version 2>/dev/null | cut -d' ' -f3 || echo "未知")
    check_status "Docker Compose" "0" "版本: $COMPOSE_VER"
elif docker compose version >/dev/null 2>&1; then
    COMPOSE_VER=$(docker compose version 2>/dev/null | head -n1 | awk '{print $4}' || echo "未知")
    check_status "Docker Compose" "0" "版本: $COMPOSE_VER (Docker插件)"
else
    check_status "Docker Compose" "1" "Docker Compose未安装"
fi

echo ""

# 2. 检查项目配置
echo "📁 项目配置检查"
echo "-------------------"

# 检查环境配置文件
if [ -f ".env" ]; then
    check_status "环境配置文件" "0" ".env文件存在"
    
    # 检查必填配置项
    MISSING_VARS=""
    while IFS='=' read -r key value; do
        case "$key" in
            MYSQL_PASSWORD|MYSQL_ROOT_PASSWORD|ADMIN_TOKEN)
                if [ -z "$value" ] || [[ "$value" == *"your"* ]] || [[ "$value" == *"here"* ]]; then
                    MISSING_VARS="$MISSING_VARS $key"
                fi
                ;;
        esac
    done < <(grep -E '^[^#]' .env)
    
    if [ -z "$MISSING_VARS" ]; then
        check_status "环境变量配置" "0" "必填项已配置"
    else
        check_status "环境变量配置" "1" "缺失或未配置的变量:$MISSING_VARS"
    fi
else
    check_status "环境配置文件" "1" ".env文件不存在"
fi

# 检查项目文件权限
if [ -x "deploy.sh" ]; then
    check_status "部署脚本权限" "0" "deploy.sh可执行"
else
    check_status "部署脚本权限" "1" "deploy.sh不可执行"
fi

echo ""

# 3. 检查服务状态
echo "🚀 服务状态检查"
echo "-------------------"

# 确定Docker Compose命令
if command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_CMD="docker-compose"
else
    COMPOSE_CMD="docker compose"
fi

# 检查容器运行状态
if $COMPOSE_CMD ps --format json 2>/dev/null | jq -r '.[] | "\(.Service):\(.State)"' >/dev/null 2>&1; then
    SERVICES=$($COMPOSE_CMD ps --format json 2>/dev/null | jq -r '.[] | "\(.Service):\(.State)"')
    
    while IFS=':' read -r service state; do
        case "$state" in
            "running")
                check_status "$service服务" "0" "运行中"
                ;;
            "exited")
                check_status "$service服务" "1" "已退出"
                ;;
            "restarting")
                warning "$service服务: 重启中"
                ;;
            *)
                check_status "$service服务" "1" "状态: $state"
                ;;
        esac
    done <<< "$SERVICES"
else
    warning "无法获取服务状态"
fi

echo ""

# 4. 检查网络连接
echo "🌐 网络连接检查"
echo "-------------------"

# 检查端口占用
declare -A PORTS=(
    ["80"]="Web服务"
    ["33066"]="MySQL外部端口"
    ["9000"]="Webhook服务"
)

for port in "${!PORTS[@]}"; do
    if netstat -tlnp 2>/dev/null | grep -q ":$port "; then
        check_status "端口$port" "0" "${PORTS[$port]}正在监听"
    else
        check_status "端口$port" "1" "${PORTS[$port]}未监听"
    fi
done

echo ""

# 5. 检查应用健康状态
echo "💊 应用健康检查"
echo "-------------------"

# API健康检查
if curl -s -f "http://localhost/api/health" >/dev/null 2>&1; then
    API_STATUS=$(curl -s "http://localhost/api/health" 2>/dev/null || echo "{}")
    API_UPTIME=$(echo "$API_STATUS" | jq -r '.uptime // "未知"' 2>/dev/null || echo "未知")
    check_status "API服务" "0" "运行时间: ${API_UPTIME}s"
else
    check_status "API服务" "1" "健康检查失败"
fi

# Web页面检查
if curl -s -f "http://localhost/" >/dev/null 2>&1; then
    check_status "Web服务" "0" "首页可访问"
else
    check_status "Web服务" "1" "首页不可访问"
fi

# MySQL连接检查（简单测试）
if $COMPOSE_CMD exec -T mysql mysqladmin ping -h localhost -u root -p"${MYSQL_ROOT_PASSWORD:-}" 2>/dev/null | grep -q "mysqld is alive"; then
    check_status "MySQL连接" "0" "数据库响应正常"
else
    check_status "MySQL连接" "1" "数据库连接失败"
fi

echo ""

# 6. 检查日志
echo "📝 日志检查"
echo "-------------------"

# 检查最近的错误日志
RECENT_ERRORS=""
if [ -f "/var/log/moyu-deploy.log" ]; then
    RECENT_ERRORS=$(tail -n 50 /var/log/moyu-deploy.log | grep -i error | tail -n 5 || true)
fi

if [ -n "$RECENT_ERRORS" ]; then
    warning "发现最近的错误日志:"
    echo "$RECENT_ERRORS" | head -n 3 | sed 's/^/   /'
else
    check_status "错误日志" "0" "无最近错误"
fi

echo ""

# 7. 总结和建议
echo "📊 检查总结"
echo "-------------------"

# 统计检查结果
TOTAL_CHECKS=0
PASSED_CHECKS=0

# 这里简化统计，实际可以通过分析上面的输出来统计
info "部署状态检查完成"

# 提供改进建议
echo ""
echo "💡 改进建议"
echo "-------------------"

# Docker权限建议
if [ "$DOCKER_GROUPS" = "无" ]; then
    echo "• 建议将用户添加到docker组: sudo usermod -aG docker $USER"
fi

# 备份建议
if [ ! -d "deploy/backups" ]; then
    echo "• 建议创建备份目录: mkdir -p deploy/backups"
fi

# 监控建议
echo "• 建议设置定期健康检查: */5 * * * * $PROJECT_DIR/scripts/check-deployment.sh"
echo "• 建议配置日志轮转，防止日志文件过大"

echo ""
echo "========================================="
echo "✅ 部署状态检查完成"
echo "========================================="
echo "如需详细信息，请运行: $0 $PROJECT_DIR true"
echo "查看服务日志: $COMPOSE_CMD logs -f"
echo "重启服务: $COMPOSE_CMD restart"