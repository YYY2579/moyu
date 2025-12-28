#!/bin/bash

echo "🔧 检查系统环境和安装依赖..."
echo "================================"

# 检查操作系统
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "✅ Linux 系统检测通过"
    OS_TYPE="linux"
else
    echo "❌ 需要Linux系统环境"
    exit 1
fi

# 检查系统发行版
if [ -f /etc/centos-release ] || [ -f /etc/redhat-release ]; then
    DISTRO="centos"
    echo "📋 检测到 CentOS/RHEL 系统"
elif [ -f /etc/lsb-release ] || [ -f /etc/debian_version ]; then
    DISTRO="ubuntu"
    echo "📋 检测到 Ubuntu/Debian 系统"
else
    echo "❌ 不支持的Linux发行版"
    exit 1
fi

# 更新系统包
echo "📦 更新系统包..."
if [ "$DISTRO" = "centos" ]; then
    sudo yum update -y
elif [ "$DISTRO" = "ubuntu" ]; then
    sudo apt-get update -y
fi

# 安装基础工具
echo "🛠️ 安装基础工具..."
if [ "$DISTRO" = "centos" ]; then
    sudo yum install -y curl wget git unzip
elif [ "$DISTRO" = "ubuntu" ]; then
    sudo apt-get install -y curl wget git unzip
fi

# 安装 Git
if ! command -v git &> /dev/null; then
    echo "📦 安装 Git..."
    if [ "$DISTRO" = "centos" ]; then
        sudo yum install -y git
    elif [ "$DISTRO" = "ubuntu" ]; then
        sudo apt-get install -y git
    fi
else
    echo "✅ Git 已安装: $(git --version)"
fi

# 安装 Docker
if ! command -v docker &> /dev/null; then
    echo "📦 安装 Docker..."
    # 使用官方安装脚本
    curl -fsSL https://get.docker.com | sh
    
    # 启动Docker服务
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # 将当前用户添加到docker组
    sudo usermod -aG docker $USER
    
    echo "⚠️  请重新登录以使Docker用户组生效"
else
    echo "✅ Docker 已安装: $(docker --version)"
fi

# 安装 Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "📦 安装 Docker Compose..."
    # 获取最新版本
    DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
    
    # 下载并安装
    sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    # 创建符号链接
    if [ ! -f /usr/bin/docker-compose ]; then
        sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    fi
else
    echo "✅ Docker Compose 已安装: $(docker-compose --version)"
fi

# 配置防火墙
echo "🔥 配置防火墙规则..."
if [ "$DISTRO" = "centos" ]; then
    if command -v firewall-cmd &> /dev/null; then
        sudo firewall-cmd --permanent --add-port=80/tcp
        sudo firewall-cmd --permanent --add-port=9000/tcp
        sudo firewall-cmd --reload
        echo "✅ 防火墙规则已配置"
    else
        echo "⚠️  请手动配置防火墙开放80和9000端口"
    fi
elif [ "$DISTRO" = "ubuntu" ]; then
    if command -v ufw &> /dev/null; then
        sudo ufw --force reset
        sudo ufw allow 22/tcp    # SSH
        sudo ufw allow 80/tcp    # HTTP
        sudo ufw allow 9000/tcp  # Webhook
        sudo ufw --force enable
        echo "✅ 防火墙规则已配置"
    else
        echo "⚠️  请手动配置防火墙开放80和9000端口"
    fi
fi

# 创建部署目录
echo "📁 创建部署目录..."
sudo mkdir -p /opt/moyu
sudo chown $USER:$USER /opt/moyu

# 检查系统资源
echo "📊 系统资源检查..."
echo "CPU 核心数: $(nproc)"
echo "内存总量: $(free -h | grep '^Mem:' | awk '{print $2}')"
echo "磁盘空间: $(df -h / | tail -1 | awk '{print $4}')"

# 验证安装
echo ""
echo "🔍 验证安装结果..."
echo "Git 版本: $(git --version 2>/dev/null || echo '未安装')"
echo "Docker 版本: $(docker --version 2>/dev/null || echo '未安装')"
echo "Docker Compose 版本: $(docker-compose --version 2>/dev/null || echo '未安装')"

# 检查Docker服务状态
if command -v docker &> /dev/null; then
    if sudo systemctl is-active --quiet docker; then
        echo "✅ Docker 服务运行正常"
    else
        echo "⚠️  Docker 服务未运行，请启动: sudo systemctl start docker"
    fi
fi

echo ""
echo "✅ 环境检查和依赖安装完成"
echo "================================"
echo ""
echo "📝 下一步操作:"
echo "1. 如果是新安装的Docker，请重新登录以使用户组生效"
echo "2. 运行项目部署脚本: ./scripts/deploy-moyu.sh"
echo ""