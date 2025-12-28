#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# ✅ 部署验证脚本
# 验证摸鱼学习站CentOS 7部署的正确性
# =============================================================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[PASS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[FAIL]${NC} $1"; }
log_step() { echo -e "${PURPLE}[STEP]${NC} $1"; }

echo -e "${PURPLE}"
echo "=============================================================================="
echo "✅ 摸鱼学习站 - 部署验证"
echo "=============================================================================="
echo -e "${NC}"

# 获取项目目录
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

# 验证计数器
TOTAL_CHECKS=0
PASSED_CHECKS=0

# 验证函数
verify() {
    local test_name="$1"
    local test_command="$2"
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    if eval "$test_command" >/dev/null 2>&1; then
        log_success "$test_name"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        log_error "$test_name"
        return 1
    fi
}

# =============================================================================
# 1. 系统环境验证
# =============================================================================
log_step "1. 系统环境验证"

verify "CentOS 7操作系统" "grep -q 'CentOS Linux release 7' /etc/redhat-release"
verify "Root权限" "[ \$(id -u) -eq 0 ]"
verify "Docker 23.x版本" "docker --version | grep -q '23.'"
verify "Docker Compose 2.5版本" "docker-compose version | grep -q '2.5'"
verify "Docker服务运行" "systemctl is-active --quiet docker"
verify "防火墙服务运行" "systemctl is-active --quiet firewalld"

echo ""

# =============================================================================
# 2. 项目文件验证
# =============================================================================
log_step "2. 项目文件验证"

verify "项目目录存在" "[ -d '$PROJECT_ROOT' ]"
verify "环境配置文件存在" "[ -f '.env' ]"
verify "Docker Compose配置存在" "[ -f 'docker-compose.yml' ]"
verify "部署配置备份存在" "[ -f 'deploy-config.txt' ]"
verify "API目录存在" "[ -d 'api/src' ]"
verify "Web目录存在" "[ -d 'web/src' ]"
verify "数据目录存在" "[ -d 'deploy/volumes' ]"

echo ""

# =============================================================================
# 3. 配置内容验证
# =============================================================================
log_step "3. 配置内容验证"

verify "数据库密码配置" "grep -q 'MYSQL_PASSWORD=Aa123456' .env"
verify "数据库Root密码配置" "grep -q 'MYSQL_ROOT_PASSWORD=Aa123456' .env"
verify "服务器IP配置" "grep -q 'SERVER_IP=114.132.189.90' .env"
verify "时区配置" "grep -q 'TZ=Asia/Shanghai' .env"
verify "数据库名称配置" "grep -q 'MYSQL_DATABASE=study_site' .env"

echo ""

# =============================================================================
# 4. Docker镜像验证
# =============================================================================
log_step "4. Docker镜像验证"

verify "MySQL镜像存在" "docker images -q mysql:5.7.44 | grep -q ."
verify "API镜像构建" "docker images -q moyu-study-2-api | grep -q ."
verify "Web镜像构建" "docker images -q moyu-study-2-web | grep -q ."

echo ""

# =============================================================================
# 5. 容器状态验证
# =============================================================================
log_step "5. 容器状态验证"

verify "MySQL容器运行" "docker-compose ps -q mysql | grep -q ."
verify "API容器运行" "docker-compose ps -q api | grep -q ."
verify "Web容器运行" "docker-compose ps -q web | grep -q ."

# 检查容器健康状态
if verify "MySQL健康状态" "docker inspect -f '{{.State.Health.Status}}' \$(docker-compose ps -q mysql) | grep -q healthy"; then
    log_success "MySQL健康状态正常"
else
    log_warning "MySQL健康状态检查中..."
fi

echo ""

# =============================================================================
# 6. 网络服务验证
# =============================================================================
log_step "6. 网络服务验证"

verify "HTTP端口监听" "netstat -tlnp 2>/dev/null | grep -q ':80 '"
verify "MySQL端口监听(本机)" "netstat -tlnp 2>/dev/null | grep -q ':33066 '"

echo ""

# =============================================================================
# 7. 应用服务验证
# =============================================================================
log_step "7. 应用服务验证"

# API健康检查
API_STATUS=0
if curl -s -f "http://localhost/api/health" >/dev/null 2>&1; then
    API_RESPONSE=$(curl -s "http://localhost/api/health" 2>/dev/null || echo "{}")
    if echo "$API_RESPONSE" | grep -q "healthy\|ok"; then
        log_success "API服务响应正常"
        API_STATUS=1
    else
        log_error "API服务响应异常"
    fi
else
    log_error "API服务无响应"
fi

# Web服务检查
if curl -s -f "http://localhost/" >/dev/null 2>&1; then
    log_success "Web服务访问正常"
    WEB_STATUS=1
else
    log_error "Web服务访问失败"
    WEB_STATUS=0
fi

# 数据库连接检查
if docker-compose exec -T mysql mysqladmin ping -h localhost -u root -pAa123456 >/dev/null 2>&1; then
    log_success "数据库连接正常"
    DB_STATUS=1
else
    log_error "数据库连接失败"
    DB_STATUS=0
fi

echo ""

# =============================================================================
# 8. 功能验证
# =============================================================================
log_step "8. 功能验证"

# 检查API端点
API_ENDPOINTS=(
    "http://localhost/api/questions"
    "http://localhost/api/meta"
    "http://localhost/api/health"
)

for endpoint in "${API_ENDPOINTS[@]}"; do
    if curl -s -f "$endpoint" >/dev/null 2>&1; then
        log_success "API端点可访问: $(basename "$endpoint")"
    else
        log_warning "API端点不可访问: $(basename "$endpoint")"
    fi
done

echo ""

# =============================================================================
# 验证结果总结
# =============================================================================
echo -e "${PURPLE}"
echo "=============================================================================="
echo "📊 验证结果总结"
echo "=============================================================================="
echo -e "${NC}"

# 计算通过率
PASS_RATE=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))

echo -e "${BLUE}验证统计:${NC}"
echo -e "   📊 总检查项目: ${YELLOW}$TOTAL_CHECKS${NC}"
echo -e "   ✅ 通过项目: ${GREEN}$PASSED_CHECKS${NC}"
echo -e "   ❌ 失败项目: ${RED}$((TOTAL_CHECKS - PASSED_CHECKS))${NC}"
echo -e "   📈 通过率: ${YELLOW}$PASS_RATE%${NC}"
echo ""

# 关键服务状态
echo -e "${BLUE}关键服务状态:${NC}"
echo -e "   🌐 Web服务: ${([ "$WEB_STATUS" -eq 1 ] && echo "${GREEN}正常${NC}" || echo "${RED}异常${NC}")"
echo -e "   🔧 API服务: ${([ "$API_STATUS" -eq 1 ] && echo "${GREEN}正常${NC}" || echo "${RED}异常${NC}")"
echo -e "   🗄️  数据库服务: ${([ "$DB_STATUS" -eq 1 ] && echo "${GREEN}正常${NC}" || echo "${RED}异常${NC}")"
echo ""

# 部署建议
if [ "$PASS_RATE" -ge 90 ] && [ "$WEB_STATUS" -eq 1 ] && [ "$API_STATUS" -eq 1 ] && [ "$DB_STATUS" -eq 1 ]; then
    echo -e "${GREEN}"
    echo "=============================================================================="
    echo "🎉 部署验证通过！系统可正常使用"
    echo "=============================================================================="
    echo -e "${NC}"
    
    echo -e "${CYAN}🌐 访问地址:${NC}"
    echo -e "   🌐 主站: ${GREEN}http://114.132.189.90${NC}"
    echo -e "   📚 题库练习: ${GREEN}http://114.132.189.90/practice${NC}"
    echo -e "   📅 每日十题: ${GREEN}http://114.132.189.90/daily${NC}"
    echo ""
    
    echo -e "${CYAN}🎮 使用提示:${NC}"
    echo -e "   🎯 按下 ${YELLOW}Alt + B${NC} 可开启老板模式"
    echo -e "   📱 支持手机、平板、电脑访问"
    echo -e "   🔄 每日十题自动刷新"
    echo ""
    
    exit 0
else
    echo -e "${RED}"
    echo "=============================================================================="
    echo "⚠️  部署验证未完全通过，请检查以下问题"
    echo "=============================================================================="
    echo -e "${NC}"
    
    echo -e "${YELLOW}建议操作:${NC}"
    
    if [ "$WEB_STATUS" -ne 1 ]; then
        echo -e "   🔧 检查Web容器: ${BLUE}docker-compose logs web${NC}"
    fi
    
    if [ "$API_STATUS" -ne 1 ]; then
        echo -e "   🔧 检查API容器: ${BLUE}docker-compose logs api${NC}"
    fi
    
    if [ "$DB_STATUS" -ne 1 ]; then
        echo -e "   🔧 检查MySQL容器: ${BLUE}docker-compose logs mysql${NC}"
    fi
    
    if [ "$PASS_RATE" -lt 90 ]; then
        echo -e "   🔄 重新部署: ${BLUE}sudo ./deploy-centos7.sh${NC}"
        echo -e "   🔍 系统优化: ${BLUE}sudo ./scripts/centos7-optimization.sh${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}📋 配置文件位置:${NC}"
    echo -e "   📄 环境配置: ${YELLOW}.env${NC}"
    echo -e "   📄 部署备份: ${YELLOW}deploy-config.txt${NC}"
    echo ""
    
    exit 1
fi