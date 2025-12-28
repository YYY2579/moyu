#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# 🚀 摸鱼学习站 - 生产环境自动部署脚本
# 部署目录: /opt/moyu/
# 支持Webhook自动触发部署
# 仓库: https://github.com/YYY2579/moyu.git
# =============================================================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# 配置常量
readonly DEPLOY_DIR="/opt/moyu"
readonly REPO_URL="https://github.com/YYY2579/moyu.git"
readonly WEBHOOK_PORT="9000"
readonly WEBHOOK_SECRET_FILE="${DEPLOY_DIR}/.webhook_secret"
readonly DEPLOY_LOG="${DEPLOY_DIR}/logs/deploy.log"
readonly BACKUP_DIR="${DEPLOY_DIR}/backups"

# 日志函数
log_info() { 
    echo -e "${BLUE}[INFO]${NC} $1" 
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $1" >> "${DEPLOY_LOG}" 2>/dev/null || true
}

log_success() { 
    echo -e "${GREEN}[SUCCESS]${NC} $1" 
    echo "$(date '+%Y-%m-%d %H:%M:%S') [SUCCESS] $1" >> "${DEPLOY_LOG}" 2>/dev/null || true
}

log_warning() { 
    echo -e "${YELLOW}[WARNING]${NC} $1" 
    echo "$(date '+%Y-%m-%d %H:%M:%S') [WARNING] $1" >> "${DEPLOY_LOG}" 2>/dev/null || true
}

log_error() { 
    echo -e "${RED}[ERROR]${NC} $1" 
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $1" >> "${DEPLOY_LOG}" 2>/dev/null || true
}

log_step() { echo -e "${PURPLE}[STEP]${NC} $1"; }

# 错误处理
error_exit() {
    log_error "$1"
    log_error "部署失败！请检查日志: ${DEPLOY_LOG}"
    exit 1
}

# 确保以root权限运行
ensure_root() {
    if [[ $EUID -ne 0 ]]; then
        error_exit "此脚本需要root权限运行，请使用: sudo $0"
    fi
}

# 创建目录结构
create_directories() {
    log_step "创建部署目录结构..."
    
    mkdir -p "${DEPLOY_DIR}"
    mkdir -p "${DEPLOY_DIR}/logs"
    mkdir -p "${DEPLOY_DIR}/data/mysql"
    mkdir -p "${DEPLOY_DIR}/data/uploads"
    mkdir -p "${DEPLOY_DIR}/backups"
    mkdir -p "${DEPLOY_DIR}/scripts"
    
    # 设置正确的权限
    chmod 755 "${DEPLOY_DIR}"
    chmod -R 755 "${DEPLOY_DIR}/scripts"
    chmod -R 755 "${DEPLOY_DIR}/logs"
    
    # 设置脚本执行权限
    if [[ -f "${DEPLOY_DIR}/deploy.sh" ]]; then
        chmod +x "${DEPLOY_DIR}/deploy.sh"
    fi
    
    for script in "${DEPLOY_DIR}/scripts"/*.sh; do
        if [[ -f "$script" ]]; then
            chmod +x "$script"
        fi
    done
    
    log_success "目录结构创建完成"
}

# 检查系统环境
check_environment() {
    log_step "检查系统环境..."
    
    # 检查操作系统
    if ! grep -q "CentOS Linux release 7" /etc/redhat-release 2>/dev/null; then
        if ! grep -q "Ubuntu" /etc/os-release 2>/dev/null; then
            log_warning "未检测到CentOS 7或Ubuntu系统，继续部署可能出现兼容性问题"
        fi
    fi
    
    # 检查网络连接
    if ! ping -c 1 github.com >/dev/null 2>&1; then
        error_exit "无法连接到GitHub，请检查网络连接"
    fi
    
    log_success "环境检查通过"
}

# 安装系统依赖
install_dependencies() {
    log_step "安装系统依赖..."
    
    # 检测包管理器
    if command -v yum >/dev/null 2>&1; then
        PKG_MANAGER="yum"
        INSTALL_CMD="yum install -y"
    elif command -v apt-get >/dev/null 2>&1; then
        PKG_MANAGER="apt-get"
        INSTALL_CMD="apt-get update && apt-get install -y"
    else
        error_exit "不支持的包管理器"
    fi
    
    # 安装基础依赖
    ${INSTALL_CMD} curl wget git unzip >/dev/null 2>&1 || true
    
    # 检查并安装Docker
    if ! command -v docker >/dev/null 2>&1; then
        log_info "安装Docker..."
        if [[ "$PKG_MANAGER" == "yum" ]]; then
            yum install -y yum-utils device-mapper-persistent-data lvm2 >/dev/null 2>&1
            curl -fsSL "https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo" -o /etc/yum.repos.d/docker-ce.repo
            yum install -y docker-ce docker-ce-cli containerd.io >/dev/null 2>&1
        else
            apt-get update >/dev/null 2>&1
            apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release >/dev/null 2>&1
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg >/dev/null 2>&1 || true
        fi
        
        systemctl enable docker >/dev/null 2>&1
        systemctl start docker >/dev/null 2>&1
    fi
    
    # 检查Docker版本
    DOCKER_VERSION=$(docker -v 2>/dev/null | awk '{print $3}' | cut -d',' -f1 | cut -d'-' -f1 || echo "")
    if [[ -n "$DOCKER_VERSION" ]]; then
        DOCKER_MAJOR=$(echo "$DOCKER_VERSION" | cut -d'.' -f1)
        if [[ "${DOCKER_MAJOR:-0}" -lt 23 ]]; then
            log_warning "Docker版本较低 ($DOCKER_VERSION)，建议升级到23.x以获得更好的兼容性"
        fi
    fi
    
    log_success "系统依赖安装完成"
}

# 配置Docker镜像加速
configure_docker_mirror() {
    log_step "配置Docker镜像加速..."
    
    mkdir -p /etc/docker >/dev/null 2>&1
    cat > /etc/docker/daemon.json << 'EOF'
{
  "registry-mirrors": [
    "https://mirror.ccs.tencentyun.com",
    "https://docker.mirrors.ustc.edu.cn",
    "https://registry.docker-cn.com"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  }
}
EOF
    
    systemctl daemon-reload >/dev/null 2>&1
    systemctl restart docker >/dev/null 2>&1
    
    log_success "Docker镜像加速配置完成"
}

# 检查并配置Docker Compose
configure_docker_compose() {
    log_step "配置Docker Compose..."
    
    # 优先使用已安装的docker-compose
    if command -v docker-compose >/dev/null 2>&1; then
        COMPOSE_CMD="docker-compose"
        log_success "使用已安装的docker-compose: $(docker-compose --version)"
    elif docker compose version >/dev/null 2>&1; then
        COMPOSE_CMD="docker compose"
        log_success "使用docker compose插件: $(docker compose version)"
    else
        log_error "未找到Docker Compose，请手动安装"
        error_exit "Docker Compose未安装"
    fi
    
    # 导出COMPOSE_CMD供后续使用
    export COMPOSE_CMD
}

# 克隆或更新代码
clone_or_update_repo() {
    log_step "获取项目代码..."
    
    # 如果是首次部署，克隆代码
    if [[ ! -d "${DEPLOY_DIR}/.git" ]]; then
        log_info "首次部署，克隆代码仓库..."
        git clone "${REPO_URL}" "${DEPLOY_DIR}" || error_exit "克隆代码失败"
    else
        log_info "更新现有代码..."
        cd "${DEPLOY_DIR}"
        git fetch origin || error_exit "获取远程更新失败"
        git reset --hard origin/main || error_exit "重置代码失败"
        git clean -fd || error_exit "清理工作目录失败"
    fi
    
    # 重新创建日志目录（可能被git clean清理）
    mkdir -p "${DEPLOY_DIR}/logs"
    mkdir -p "$(dirname "${DEPLOY_LOG}")" 2>/dev/null || true
    
    # 设置正确的权限
    chown -R root:root "${DEPLOY_DIR}"
    chmod 755 "${DEPLOY_DIR}"
    
    log_success "代码获取完成"
}

# 生成配置文件
generate_configs() {
    log_step "生成配置文件..."
    
    cd "${DEPLOY_DIR}"
    
    # 生成环境变量文件
    cat > .env << EOF
# 数据库配置
MYSQL_ROOT_PASSWORD=Aa123456
MYSQL_DATABASE=moyu_study
MYSQL_USER=moyu
MYSQL_PASSWORD=Aa123456

# 服务器配置
SERVER_HOST=0.0.0.0
SERVER_PORT=3000

# 数据库连接
DATABASE_HOST=mysql
DATABASE_PORT=3306
DATABASE_USER=moyu
DATABASE_PASSWORD=Aa123456
DATABASE_NAME=moyu_study

# JWT配置
JWT_SECRET=$(openssl rand -hex 32 2>/dev/null || echo "your-jwt-secret-key-change-in-production")

# Redis配置
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=

# 应用配置
NODE_ENV=production
API_BASE_URL=http://114.132.189.90

# Webhook配置
WEBHOOK_SECRET=$(generate_webhook_secret)
WEBHOOK_PORT=${WEBHOOK_PORT}
EOF
    
    log_success "配置文件生成完成"
}

# 生成Webhook密钥
generate_webhook_secret() {
    if [[ -f "${WEBHOOK_SECRET_FILE}" ]]; then
        cat "${WEBHOOK_SECRET_FILE}"
    else
        local secret
        secret=$(openssl rand -hex 32 2>/dev/null || echo "default-webhook-secret-change-this")
        echo "$secret" > "${WEBHOOK_SECRET_FILE}"
        chmod 600 "${WEBHOOK_SECRET_FILE}"
        echo "$secret"
    fi
}

# 部署应用服务
deploy_services() {
    log_step "部署应用服务..."
    
    cd "${DEPLOY_DIR}"
    
    # 确保COMPOSE_CMD已设置
    if [[ -z "${COMPOSE_CMD:-}" ]]; then
        configure_docker_compose
    fi
    
    # 停止现有服务
    if ${COMPOSE_CMD} ps -q >/dev/null 2>&1; then
        log_info "停止现有服务..."
        ${COMPOSE_CMD} down >/dev/null 2>&1 || true
    fi
    
    # 构建并启动服务
    log_info "构建并启动服务..."
    ${COMPOSE_CMD} up -d --build || error_exit "服务启动失败"
    
    # 等待服务启动
    log_info "等待服务启动..."
    sleep 30
    
    # 检查服务状态
    if ${COMPOSE_CMD} ps | grep -q "Up"; then
        log_success "服务部署成功"
    else
        error_exit "服务部署失败"
    fi
}

# 配置Webhook服务
setup_webhook() {
    log_step "配置Webhook自动部署..."
    
    # 检查端口是否被占用
    if netstat -tuln | grep -q ":${WEBHOOK_PORT} "; then
        log_warning "端口${WEBHOOK_PORT}已被占用，跳过Webhook配置"
        return
    fi
    
    # 生成webhook配置
    cat > "${DEPLOY_DIR}/webhook.json" << EOF
[
  {
    "id": "auto-deploy",
    "execute-command": "${DEPLOY_DIR}/scripts/webhook-handler.sh",
    "command-working-directory": "${DEPLOY_DIR}",
    "pass-arguments-to-command": [
      {
        "source": "string",
        "name": "auto-deploy"
      },
      {
        "source": "payload",
        "name": "head_commit.id"
      },
      {
        "source": "payload",
        "name": "pusher.name"
      },
      {
        "source": "payload",
        "name": "ref"
      }
    ],
    "trigger-rule": {
      "and": [
        {
          "match": {
            "type": "payload-hash-sha1",
            "secret": "$(cat "${WEBHOOK_SECRET_FILE}")",
            "parameter": {
              "source": "header",
              "name": "X-Hub-Signature"
            }
          }
        }
      ]
    }
  }
]
EOF
    
    # 创建webhook处理脚本
    cat > "${DEPLOY_DIR}/scripts/webhook-handler.sh" << 'EOF'
#!/bin/bash
set -euo pipefail

# Webhook自动部署处理脚本
DEPLOY_DIR="/opt/moyu"
LOG_FILE="${DEPLOY_DIR}/logs/webhook.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [WEBHOOK] $1" >> "${LOG_FILE}"
}

log "收到部署请求: $1 $2 $3 $4"

# 切换到项目目录
cd "${DEPLOY_DIR}"

# 拉取最新代码
log "拉取最新代码..."
git fetch origin
git reset --hard origin/main
git clean -fd

# 重新部署服务
log "重新部署服务..."
cd "${DEPLOY_DIR}"
if command -v docker-compose >/dev/null 2>&1; then
    docker-compose down
    docker-compose up -d --build
else
    docker compose down
    docker compose up -d --build
fi

log "部署完成"
EOF
    
    chmod +x "${DEPLOY_DIR}/scripts/webhook-handler.sh"
    
    log_success "Webhook配置完成"
    log_info "Webhook URL: http://114.132.189.90:${WEBHOOK_PORT}/hooks/auto-deploy"
    log_info "Secret: $(cat "${WEBHOOK_SECRET_FILE}")"
}

# 健康检查
health_check() {
    log_step "执行健康检查..."
    
    local max_attempts=30
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        if curl -f -s http://localhost/health >/dev/null 2>&1; then
            log_success "应用健康检查通过"
            break
        fi
        
        if [[ $attempt -eq $max_attempts ]]; then
            error_exit "健康检查失败，应用未正常启动"
        fi
        
        log_info "等待应用启动... (${attempt}/${max_attempts})"
        sleep 10
        ((attempt++))
    done
}

# 生成部署报告
generate_report() {
    log_step "生成部署报告..."
    
    cat > "${DEPLOY_DIR}/deploy-report.txt" << EOF
摸鱼学习站部署报告
==================

部署时间: $(date)
部署目录: ${DEPLOY_DIR}
服务器IP: 114.132.189.90

服务状态:
$(${COMPOSE_CMD:-docker-compose} ps)

访问地址:
- 主站: http://114.132.189.90
- API: http://114.132.189.90/api
- 健康检查: http://114.132.189.90/health

Webhook信息:
- URL: http://114.132.189.90:${WEBHOOK_PORT}/hooks/auto-deploy
- Secret: $(cat "${WEBHOOK_SECRET_FILE}" 2>/dev/null || echo "Not found")

配置文件位置:
- 环境变量: ${DEPLOY_DIR}/.env
- Webhook配置: ${DEPLOY_DIR}/webhook.json
- 部署日志: ${DEPLOY_LOG}

数据库信息:
- 主机: localhost:33066
- 用户: moyu
- 密码: Aa123456
- 数据库: moyu_study

备份目录: ${BACKUP_DIR}
EOF
    
    log_success "部署报告生成完成: ${DEPLOY_DIR}/deploy-report.txt"
}

# 显示部署结果
show_result() {
    echo ""
    echo -e "${GREEN}==============================================================================${NC}"
    echo -e "${GREEN}🎉 部署完成！${NC}"
    echo -e "${GREEN}==============================================================================${NC}"
    echo ""
    echo -e "${CYAN}📋 访问信息:${NC}"
    echo -e "   🌐 主站: ${BLUE}http://114.132.189.90${NC}"
    echo -e "   📚 题库练习: ${BLUE}http://114.132.189.90/practice${NC}"
    echo -e "   📅 每日十题: ${BLUE}http://114.132.189.90/daily${NC}"
    echo -e "   📊 学习统计: ${BLUE}http://114.132.189.90/stats${NC}"
    echo -e "   🔍 健康检查: ${BLUE}http://114.132.189.90/health${NC}"
    echo ""
    echo -e "${CYAN}🔧 管理命令:${NC}"
    echo -e "   查看状态: ${YELLOW}cd ${DEPLOY_DIR} && ${COMPOSE_CMD:-docker-compose} ps${NC}"
    echo -e "   查看日志: ${YELLOW}cd ${DEPLOY_DIR} && ${COMPOSE_CMD:-docker-compose} logs -f${NC}"
    echo -e "   重启服务: ${YELLOW}cd ${DEPLOY_DIR} && ${COMPOSE_CMD:-docker-compose} restart${NC}"
    echo -e "   停止服务: ${YELLOW}cd ${DEPLOY_DIR} && ${COMPOSE_CMD:-docker-compose} down${NC}"
    echo ""
    echo -e "${CYAN}📊 部署报告:${NC}"
    echo -e "   ${YELLOW}cat ${DEPLOY_DIR}/deploy-report.txt${NC}"
    echo ""
    echo -e "${CYAN}🔄 自动部署:${NC}"
    echo -e "   Webhook URL: ${BLUE}http://114.132.189.90:${WEBHOOK_PORT}/hooks/auto-deploy${NC}"
    echo -e "   Secret: ${YELLOW}$(cat "${WEBHOOK_SECRET_FILE}" 2>/dev/null || echo "Not found")${NC}"
    echo ""
    echo -e "${GREEN}==============================================================================${NC}"
}

# 主函数
main() {
    # 确保以root权限运行
    ensure_root
    
    # 创建日志目录
    mkdir -p "$(dirname "${DEPLOY_LOG}")" 2>/dev/null || true
    
    log_info "开始摸鱼学习站部署..."
    log_info "部署目录: ${DEPLOY_DIR}"
    
    # 执行部署步骤
    create_directories
    check_environment
    install_dependencies
    configure_docker_mirror
    configure_docker_compose
    clone_or_update_repo
    generate_configs
    deploy_services
    setup_webhook
    health_check
    generate_report
    show_result
    
    log_success "摸鱼学习站部署完成！"
}

# 执行主函数
main "$@"