#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# 🚀 摸鱼学习站 - CentOS 7 Docker部署脚本
# 专门针对腾讯云服务器114.132.189.90环境优化
# =============================================================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# 日志函数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${PURPLE}[STEP]${NC} $1"; }

# 开始部署
echo -e "${CYAN}"
echo "=============================================================================="
echo "🚀 摸鱼学习站 - CentOS 7 Docker部署"
echo "目标服务器: 114.132.189.90"
echo "=============================================================================="
echo -e "${NC}"
log_info "部署时间: $(date)"
log_info "操作系统: $(cat /etc/redhat-release)"
log_info "内核版本: $(uname -r)"
echo ""

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"
PROJECT_ROOT="$(pwd)"

log_info "项目目录: $PROJECT_ROOT"

# =============================================================================
# STEP 1: 系统环境检查和准备
# =============================================================================
log_step "步骤 1/8: 系统环境检查和准备"

# 检查是否为CentOS 7
if ! grep -q "CentOS Linux release 7" /etc/redhat-release; then
    log_error "此脚本仅支持CentOS 7系统"
    log_info "当前系统: $(cat /etc/redhat-release)"
    exit 1
fi

log_success "CentOS 7系统检查通过"

# 检查root权限
if [ "$(id -u)" -ne 0 ]; then
    log_error "此脚本需要root权限运行，请使用 sudo 执行"
    exit 1
fi

log_success "权限检查通过"

# 更新系统
log_info "更新系统软件包..."
yum update -y

# 安装必要工具
log_info "安装基础工具..."
yum install -y \
    curl \
    wget \
    git \
    unzip \
    htop \
    lsof \
    net-tools \
    telnet \
    vim

log_success "系统环境准备完成"
echo ""

# =============================================================================
# STEP 2: Docker环境配置
# =============================================================================
log_step "步骤 2/8: Docker环境配置"

# 卸载旧版本Docker
log_info "清理旧版本Docker..."
yum remove -y docker \
    docker-client \
    docker-client-latest \
    docker-common \
    docker-latest \
    docker-latest-logrotate \
    docker-logrotate \
    docker-engine || true

# 安装依赖
log_info "安装Docker依赖..."
yum install -y yum-utils device-mapper-persistent-data lvm2

# 添加Docker仓库（使用阿里云镜像）
log_info "添加Docker仓库..."
yum-config-manager \
    --add-repo \
    https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

# 安装Docker 23版本
log_info "安装Docker CE 23.x..."
yum install -y docker-ce docker-ce-cli containerd.io

# 配置Docker镜像加速
log_info "配置Docker镜像加速..."
mkdir -p /etc/docker
cat > /etc/docker/daemon.json << EOF
{
    "registry-mirrors": [
        "https://docker.m.daocloud.io",
        "https://hub.ratels.pro",
        "https://docker.1panel.live",
        "https://mirror.azure.cn",
        "https://docker.unidock.top"
    ],
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    },
    "storage-driver": "overlay2",
    "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF

# 启动Docker服务
log_info "启动Docker服务..."
systemctl enable docker
systemctl start docker

# 验证Docker版本
DOCKER_VERSION=$(docker --version)
log_info "Docker版本: $DOCKER_VERSION"

if [[ "$DOCKER_VERSION" != *"23"* ]]; then
    log_warning "Docker版本可能不是23.x，当前版本: $DOCKER_VERSION"
    log_warning "如需特定版本，请手动指定版本安装"
else
    log_success "Docker版本检查通过"
fi

log_success "Docker环境配置完成"
echo ""

# =============================================================================
# STEP 3: Docker Compose配置
# =============================================================================
log_step "步骤 3/8: Docker Compose配置"

# 检查现有的docker-compose
if [ -f "/usr/local/bin/docker-compose" ]; then
    EXISTING_VERSION=$(/usr/local/bin/docker-compose version --short 2>/dev/null || echo "unknown")
    log_info "现有docker-compose版本: $EXISTING_VERSION"
    
    if [[ "$EXISTING_VERSION" == "2.5"* ]]; then
        log_success "docker-compose 2.5已存在，无需重新安装"
    else
        log_warning "版本不匹配，将重新安装docker-compose 2.5.0"
        rm -f /usr/local/bin/docker-compose
    fi
fi

# 安装docker-compose 2.5.0
if [ ! -f "/usr/local/bin/docker-compose" ]; then
    log_info "下载docker-compose 2.5.0..."
    curl -L "https://github.com/docker/compose/releases/download/v2.5.0/docker-compose-linux-x86_64" \
        -o /usr/local/bin/docker-compose
    
    chmod +x /usr/local/bin/docker-compose
    
    # 创建软链接
    ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
fi

# 验证docker-compose
COMPOSE_VERSION=$(docker-compose version --short)
log_info "Docker Compose版本: $COMPOSE_VERSION"

if [[ "$COMPOSE_VERSION" != "2.5"* ]]; then
    log_error "docker-compose版本不正确: $COMPOSE_VERSION"
    exit 1
else
    log_success "docker-compose版本检查通过"
fi

log_success "Docker Compose配置完成"
echo ""

# =============================================================================
# STEP 4: 防火墙和SELinux配置
# =============================================================================
log_step "步骤 4/8: 防火墙和SELinux配置"

# 配置防火墙
log_info "配置防火墙规则..."
if systemctl is-active --quiet firewalld; then
    # 开放HTTP端口
    firewall-cmd --permanent --add-service=http
    # 开放HTTPS端口
    firewall-cmd --permanent --add-service=https
    # 重载防火墙规则
    firewall-cmd --reload
    log_success "防火墙配置完成"
else
    log_warning "firewalld未运行，跳过防火墙配置"
fi

# 配置SELinux
log_info "配置SELinux..."
if getenforce | grep -q "Enforcing"; then
    log_info "SELinux处于强制模式，配置容器访问..."
    setsebool -P httpd_can_network_connect 1
    setsebool -P httpd_can_network_relay 1
    log_success "SELinux配置完成"
else
    log_info "SELinux未处于强制模式"
fi

log_success "安全配置完成"
echo ""

# =============================================================================
# STEP 5: 项目配置生成
# =============================================================================
log_step "步骤 5/8: 项目配置生成"

# 设置固定密码（根据要求）
MYSQL_PASSWORD="Aa123456"
MYSQL_ROOT_PASSWORD="Aa123456"
ADMIN_TOKEN="moyu_admin_token_2024"
SERVER_IP="114.132.189.90"

# 创建.env文件
log_info "生成环境配置文件..."
cat > .env << EOF
# 数据库配置
MYSQL_DATABASE=study_site
MYSQL_USER=yyy
MYSQL_PASSWORD=$MYSQL_PASSWORD
MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD

# 管理员Token
ADMIN_TOKEN=$ADMIN_TOKEN

# 时区设置
TZ=Asia/Shanghai

# 服务器配置
SERVER_IP=$SERVER_IP
EOF

# 创建数据目录
log_info "创建数据目录..."
mkdir -p deploy/volumes/mysql
mkdir -p deploy/backups
mkdir -p logs

# 设置权限
chown -R root:root deploy/volumes
chmod 755 deploy/volumes
chmod 755 deploy/volumes/mysql

# 显示配置信息
log_info "配置文件已生成 (.env):"
log_info "  数据库密码: $MYSQL_PASSWORD"
log_info "  数据库root密码: $MYSQL_ROOT_PASSWORD" 
log_info "  管理员Token: $ADMIN_TOKEN"
log_info "  服务器IP: $SERVER_IP"

# 保存配置信息
cat > deploy-config.txt << EOF
摸鱼学习站 - CentOS 7 部署配置信息
生成时间: $(date)
服务器IP: $SERVER_IP

数据库信息:
  数据库名: study_site
  用户名: yyy
  密码: $MYSQL_PASSWORD
  Root密码: $MYSQL_ROOT_PASSWORD

管理员信息:
  管理员Token: $ADMIN_TOKEN
  访问地址: http://$SERVER_IP/

端口信息:
  HTTP: 80
  MySQL外部访问: 33066 (仅限本机)

请妥善保存此文件，后续可能需要用到。
EOF

log_success "项目配置完成"
echo ""

# =============================================================================
# STEP 6: 镜像构建和优化
# =============================================================================
log_step "步骤 6/8: 镜像构建和优化"

# 清理Docker缓存
log_info "清理Docker缓存..."
docker system prune -f

# 拉取基础镜像
log_info "拉取基础镜像..."
docker pull mysql:5.7.44

# 构建应用镜像
log_info "构建应用镜像..."
docker-compose build --no-cache

if [ $? -ne 0 ]; then
    log_error "镜像构建失败"
    exit 1
fi

log_success "镜像构建完成"
echo ""

# =============================================================================
# STEP 7: 服务启动和配置
# =============================================================================
log_step "步骤 7/8: 服务启动和配置"

# 停止已存在的服务
log_info "停止已存在的服务..."
docker-compose down || true

# 启动服务
log_info "启动应用服务..."
docker-compose up -d

if [ $? -ne 0 ]; then
    log_error "服务启动失败"
    exit 1
fi

log_success "服务启动完成"
echo ""

# =============================================================================
# STEP 8: 健康检查和验证
# =============================================================================
log_step "步骤 8/8: 健康检查和验证"

log_info "等待服务启动完成..."
sleep 20

# MySQL健康检查
log_info "检查MySQL服务状态..."
MYSQL_CONTAINER=$(docker-compose ps -q mysql 2>/dev/null || echo "")
if [ -n "$MYSQL_CONTAINER" ]; then
    for i in {1..30}; do
        HEALTH_STATUS=$(docker inspect -f '{{.State.Health.Status}}' "$MYSQL_CONTAINER" 2>/dev/null || echo "unknown")
        if [ "$HEALTH_STATUS" = "healthy" ]; then
            log_success "MySQL服务健康检查通过 ✅"
            break
        fi
        
        if [ $i -eq 30 ]; then
            log_warning "MySQL健康检查超时，但服务可能仍在启动中"
        fi
        sleep 2
    done
else
    log_error "MySQL容器不存在"
fi

# API服务检查
log_info "检查API服务状态..."
for i in {1..60}; do
    if curl -s -f "http://localhost/api/health" >/dev/null 2>&1; then
        log_success "API服务健康检查通过 ✅"
        break
    fi
    
    if [ $i -eq 60 ]; then
        log_error "API服务健康检查失败"
        log_info "检查API服务日志:"
        docker-compose logs api --tail=20
        exit 1
    fi
    sleep 2
done

# Web服务检查
log_info "检查Web服务状态..."
if curl -s -f "http://localhost/" >/dev/null 2>&1; then
    log_success "Web服务访问正常 ✅"
else
    log_warning "Web服务可能还在启动中"
fi

log_success "所有服务检查完成"
echo ""

# =============================================================================
# 部署完成信息
# =============================================================================
echo -e "${GREEN}"
echo "=============================================================================="
echo "🎉 部署成功完成！"
echo "=============================================================================="
echo -e "${NC}"

echo -e "${CYAN}📱 访问信息:${NC}"
echo -e "   🌐 网站地址: ${GREEN}http://$SERVER_IP${NC}"
echo -e "   🗄️  数据库端口: ${YELLOW}33066${NC} (仅限本机访问)"
echo ""

echo -e "${CYAN}🔑 重要配置:${NC}"
echo -e "   📋 配置文件: ${YELLOW}deploy-config.txt${NC}"
echo -e "   🔐 数据库密码: ${YELLOW}$MYSQL_PASSWORD${NC}"
echo -e "   🎯 管理员Token: ${YELLOW}$ADMIN_TOKEN${NC}"
echo ""

echo -e "${CYAN}🛠️  管理命令:${NC}"
echo -e "   📊 查看服务状态: ${BLUE}docker-compose ps${NC}"
echo -e "   📝 查看日志: ${BLUE}docker-compose logs -f${NC}"
echo -e "   🔄 重启服务: ${BLUE}docker-compose restart${NC}"
echo -e "   🛑 停止服务: ${BLUE}docker-compose down${NC}"
echo ""

echo -e "${CYAN}🎮 摸鱼提示:${NC}"
echo -e "   🎯 在网站中按下 ${YELLOW}Alt + B${NC} 可瞬间开启老板模式！"
echo -e "   📚 每日10题功能已自动开启，欢迎开始学习！"
echo ""

echo -e "${CYAN}🔧 系统服务:${NC}"
echo -e "   🔥 Docker服务: ${BLUE}systemctl status docker${NC}"
echo -e "   🛡️  防火墙状态: ${BLUE}firewall-cmd --list-all${NC}"
echo -e "   🔒 SELinux状态: ${BLUE}getenforce${NC}"
echo ""

echo -e "${GREEN}=============================================================================="
echo "🚀 部署完成 - 服务器: $SERVER_IP"
echo "=============================================================================="
echo -e "${NC}"

# 保存配置信息到当前目录
log_info "配置信息已保存到: deploy-config.txt"

# 显示快速访问链接
echo -e "${PURPLE}🔗 快速访问:${NC}"
echo -e "   📖 题库练习: ${GREEN}http://$SERVER_IP/practice${NC}"
echo -e "   📅 每日十题: ${GREEN}http://$SERVER_IP/daily${NC}"
echo -e "   📊 学习统计: ${GREEN}http://$SERVER_IP/stats${NC}"
echo ""

# 设置开机自启
log_info "设置Docker服务开机自启..."
systemctl enable docker

# 询问SSH配置
echo ""
log_warning "是否需要配置SSH密钥以便后续代码推送？"
read -p "配置SSH密钥？(y/n): " config_ssh

if [[ "$config_ssh" == "y" || "$config_ssh" == "Y" ]]; then
    log_info "配置SSH密钥..."
    
    # 检查是否已有SSH密钥
    if [ -f "/root/.ssh/id_rsa" ]; then
        log_info "SSH密钥已存在"
        SSH_PUB_KEY=$(cat /root/.ssh/id_rsa.pub)
        echo "公钥内容: $SSH_PUB_KEY"
    else
        log_info "生成新的SSH密钥..."
        ssh-keygen -t rsa -b 4096 -N "" -f /root/.ssh/id_rsa
        
        SSH_PUB_KEY=$(cat /root/.ssh/id_rsa.pub)
        log_info "SSH密钥生成完成"
    fi
    
    echo ""
    echo -e "${CYAN}📋 请将以下公钥添加到GitHub:${NC}"
    echo -e "${YELLOW}$SSH_PUB_KEY${NC}"
    echo ""
    echo -e "${BLUE}操作步骤:${NC}"
    echo "1. 复制上面的公钥内容"
    echo "2. 登录GitHub: https://github.com"
    echo "3. 进入 Settings > SSH and GPG keys"
    echo "4. 点击 'New SSH key'"
    echo "5. 粘贴公钥并保存"
    echo ""
    
    read -p "添加完成后，测试SSH连接？(y/n): " test_ssh
    if [[ "$test_ssh" == "y" || "$test_ssh" == "Y" ]]; then
        log_info "测试GitHub SSH连接..."
        if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
            log_success "GitHub SSH连接测试成功"
        else
            log_warning "GitHub SSH连接测试失败，请检查配置"
        fi
    fi
fi

log_info "建议将项目启动脚本添加到开机自启"
echo "可添加到 /etc/rc.local 或创建systemd服务"

exit 0