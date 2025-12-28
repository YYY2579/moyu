#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# 🏥 快速健康检查脚本
# 用于验证服务是否正常运行
# =============================================================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }

echo -e "${BLUE}"
echo "=============================================================================="
echo "🏥 摸鱼学习站 - 快速健康检查"
echo "=============================================================================="
echo -e "${NC}"

# 获取项目目录
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

# 确定Docker Compose命令
if docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_CMD="docker-compose"
else
    log_error "未找到Docker Compose命令"
    exit 1
fi

log_info "使用命令: $COMPOSE_CMD"
echo ""

# 检查1: 容器状态
log_info "检查容器运行状态..."
echo ""

CONTAINERS=$($COMPOSE_CMD ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "")

if [[ -n "$CONTAINERS" ]]; then
    echo "$CONTAINERS"
    echo ""
    
    # 检查关键容器是否运行
    if echo "$CONTAINERS" | grep -q "mysql.*Up"; then
        log_success "MySQL 容器运行正常"
    else
        log_error "MySQL 容器未运行"
    fi
    
    if echo "$CONTAINERS" | grep -q "api.*Up"; then
        log_success "API 容器运行正常"
    else
        log_error "API 容器未运行"
    fi
    
    if echo "$CONTAINERS" | grep -q "web.*Up"; then
        log_success "Web 容器运行正常"
    else
        log_error "Web 容器未运行"
    fi
else
    log_error "无法获取容器状态，服务可能未启动"
fi

echo ""

# 检查2: 端口访问
log_info "检查端口访问..."
echo ""

# 检查端口是否监听
check_port() {
    local port=$1
    local service=$2
    
    if netstat -tlnp 2>/dev/null | grep -q ":$port "; then
        log_success "端口 $port ($service) 正在监听"
    else
        log_error "端口 $port ($service) 未监听"
    fi
}

check_port "80" "Web服务"
check_port "33066" "MySQL外部访问"

echo ""

# 检查3: 服务响应
log_info "检查服务响应..."
echo ""

# API健康检查
if curl -s -f "http://localhost/api/health" >/dev/null 2>&1; then
    API_STATUS=$(curl -s "http://localhost/api/health" 2>/dev/null || echo "{}")
    if echo "$API_STATUS" | grep -q "healthy"; then
        log_success "API 服务响应正常"
    else
        log_warning "API 服务响应异常: $API_STATUS"
    fi
else
    log_error "API 服务无响应"
fi

# Web页面检查
if curl -s -f "http://localhost/" >/dev/null 2>&1; then
    log_success "Web 服务响应正常"
else
    log_error "Web 服务无响应"
fi

# MySQL连接检查
log_info "检查数据库连接..."
MYSQL_CONTAINER=$($COMPOSE_CMD ps -q mysql 2>/dev/null || echo "")
if [[ -n "$MYSQL_CONTAINER" ]]; then
    # 检查MySQL健康状态
    HEALTH_STATUS=$(docker inspect -f '{{.State.Health.Status}}' "$MYSQL_CONTAINER" 2>/dev/null || echo "unknown")
    case "$HEALTH_STATUS" in
        "healthy")
            log_success "MySQL 数据库连接正常"
            ;;
        "unhealthy")
            log_error "MySQL 数据库连接异常"
            ;;
        "starting")
            log_warning "MySQL 数据库启动中..."
            ;;
        *)
            log_warning "MySQL 健康状态未知: $HEALTH_STATUS"
            ;;
    esac
else
    log_error "MySQL 容器不存在"
fi

echo ""

# 检查4: 配置文件
log_info "检查配置文件..."
echo ""

if [[ -f ".env" ]]; then
    log_success "环境配置文件存在"
    
    # 检查关键配置项
    if grep -q "MYSQL_PASSWORD=" .env && grep -q "MYSQL_ROOT_PASSWORD=" .env && grep -q "ADMIN_TOKEN=" .env; then
        log_success "环境配置完整"
    else
        log_warning "环境配置可能不完整"
    fi
else
    log_error "环境配置文件不存在"
fi

echo ""

# 检查5: 日志错误
log_info "检查最近的错误日志..."
echo ""

ERROR_COUNT=0

# 检查API容器错误日志
API_ERRORS=$($COMPOSE_CMD logs api --tail=20 2>/dev/null | grep -i error | wc -l || echo "0")
if [[ "$API_ERRORS" -gt 0 ]]; then
    log_warning "API 容器发现 $API_ERRORS 个错误"
    ERROR_COUNT=$((ERROR_COUNT + API_ERRORS))
fi

# 检查MySQL容器错误日志
MYSQL_ERRORS=$($COMPOSE_CMD logs mysql --tail=20 2>/dev/null | grep -i error | wc -l || echo "0")
if [[ "$MYSQL_ERRORS" -gt 0 ]]; then
    log_warning "MySQL 容器发现 $MYSQL_ERRORS 个错误"
    ERROR_COUNT=$((ERROR_COUNT + MYSQL_ERRORS))
fi

if [[ "$ERROR_COUNT" -eq 0 ]]; then
    log_success "未发现最近的错误日志"
fi

echo ""

# 总结
echo -e "${BLUE}"
echo "=============================================================================="
echo "📊 健康检查总结"
echo "=============================================================================="
echo -e "${NC}"

if [[ "$ERROR_COUNT" -eq 0 ]]; then
    echo -e "${GREEN}🎉 系统状态良好，所有服务运行正常！${NC}"
    echo ""
    echo -e "🌐 访问地址: ${GREEN}http://localhost${NC}"
    echo -e "📚 开始学习: ${GREEN}http://localhost/practice${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠️  发现 $ERROR_COUNT 个问题，建议检查服务日志${NC}"
    echo ""
    echo -e "🔍 查看详细日志: ${BLUE}$COMPOSE_CMD logs -f${NC}"
    echo -e "🔄 重启服务: ${BLUE}$COMPOSE_CMD restart${NC}"
    exit 1
fi