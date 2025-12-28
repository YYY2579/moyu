#!/bin/bash

echo "🚀 开始部署摸鱼学习站..."
echo "================================"

# 设置变量
PROJECT_DIR="/opt/moyu"
REPO_URL="https://github.com/YYY2579/moyu.git"
BRANCH="main"

# 检查当前用户
if [ "$EUID" -eq 0 ]; then
    echo "❌ 请不要使用root用户运行此脚本"
    exit 1
fi

# 检查Docker用户组
if ! groups $USER | grep -q docker; then
    echo "❌ 当前用户不在docker组中，请重新登录或运行: newgrp docker"
    exit 1
fi

# 创建部署目录
echo "📁 准备部署目录: $PROJECT_DIR"
if [ ! -d "$PROJECT_DIR" ]; then
    mkdir -p "$PROJECT_DIR"
    echo "✅ 创建部署目录"
fi

# 进入部署目录
cd "$PROJECT_DIR" || {
    echo "❌ 无法进入部署目录: $PROJECT_DIR"
    exit 1
}

# 克隆或更新项目
if [ -d "$PROJECT_DIR/.git" ]; then
    echo "📥 更新现有项目..."
    git fetch origin
    git reset --hard origin/$BRANCH
    git clean -fd
else
    echo "📥 克隆项目..."
    git clone -b $BRANCH $REPO_URL "$PROJECT_DIR"
fi

# 检查项目文件
echo "🔍 验证项目文件..."
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ 未找到 docker-compose.yml 文件"
    exit 1
fi

if [ ! -d "web" ] || [ ! -d "api" ]; then
    echo "❌ 项目结构不完整"
    exit 1
fi

# 创建环境变量文件
echo "📝 生成环境配置..."
ENV_FILE="$PROJECT_DIR/.env"
if [ -f "$ENV_FILE" ]; then
    echo "⚠️  环境文件已存在，备份为 .env.backup"
    cp "$ENV_FILE" "$ENV_FILE.backup"
fi

cat > "$ENV_FILE" << 'EOF'
# 数据库配置
MYSQL_ROOT_PASSWORD=moyu123456
MYSQL_DATABASE=moyu_study
MYSQL_USER=moyu_user
MYSQL_PASSWORD=moyu_user_password

# JWT配置
JWT_SECRET=moyu_jwt_secret_key_2024

# Webhook配置
WEBHOOK_SECRET=moyu_webhook_secret_2024

# 时区配置
TZ=Asia/Shanghai

# 管理员Token
ADMIN_TOKEN=moyu_admin_token_2024

# 服务器IP（可选，用于配置文件）
SERVER_IP=
EOF

# 设置文件权限
echo "🔐 设置文件权限..."
chmod 600 "$ENV_FILE"
chmod +x scripts/*.sh 2>/dev/null || true

# 创建必要的目录
echo "📂 创建数据目录..."
mkdir -p deploy/volumes/mysql
mkdir -p deploy/volumes/logs
mkdir -p deploy/mysql-init

# 检查配置文件
echo "🔧 检查配置文件..."
if [ ! -f "deploy/mysql-init/01-init.sql" ]; then
    echo "📝 创建数据库初始化脚本..."
    mkdir -p deploy/mysql-init
    cat > deploy/mysql-init/01-init.sql << 'EOF'
CREATE DATABASE IF NOT EXISTS moyu_study CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE moyu_study;

-- 用户表
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    device_id VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 题目表
CREATE TABLE IF NOT EXISTS questions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    category VARCHAR(50) NOT NULL,
    question TEXT NOT NULL,
    answer TEXT NOT NULL,
    explanation TEXT,
    difficulty VARCHAR(20) DEFAULT 'medium',
    tags JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 学习记录表
CREATE TABLE IF NOT EXISTS attempts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    device_id VARCHAR(255) NOT NULL,
    question_id INT NOT NULL,
    answer TEXT NOT NULL,
    is_correct BOOLEAN DEFAULT FALSE,
    time_spent INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (question_id) REFERENCES questions(id),
    INDEX idx_device_id (device_id),
    INDEX idx_created_at (created_at)
);

-- 收藏表
CREATE TABLE IF NOT EXISTS bookmarks (
    id INT AUTO_INCREMENT PRIMARY KEY,
    device_id VARCHAR(255) NOT NULL,
    question_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (question_id) REFERENCES questions(id),
    UNIQUE KEY unique_bookmark (device_id, question_id)
);
EOF
fi

# 设置文件权限
chmod -R 755 deploy/
chown -R $USER:$USER "$PROJECT_DIR"

# 验证Docker Compose配置
echo "🔍 验证Docker Compose配置..."
if docker-compose config > /dev/null 2>&1; then
    echo "✅ Docker Compose配置验证通过"
else
    echo "❌ Docker Compose配置有误:"
    docker-compose config
    exit 1
fi

# 显示部署信息
echo ""
echo "📋 部署信息:"
echo "  项目目录: $PROJECT_DIR"
echo "  Git仓库: $REPO_URL"
echo "  分支: $BRANCH"
echo "  配置文件: $ENV_FILE"
echo "  数据目录: deploy/volumes/"
echo ""

# 检查端口占用
echo "🔍 检查端口占用..."
if command -v netstat &> /dev/null; then
    if netstat -tlnp 2>/dev/null | grep -q ":80 "; then
        echo "⚠️  端口80已被占用"
    fi
    if netstat -tlnp 2>/dev/null | grep -q ":33067 "; then
        echo "⚠️  端口33067已被占用"
    fi
    if netstat -tlnp 2>/dev/null | grep -q ":9000 "; then
        echo "⚠️  端口9000已被占用"
    fi
fi

echo ""
echo "✅ 项目初始化完成"
echo "================================"
echo ""
echo "📝 下一步操作:"
echo "1. 启动服务: ./scripts/start-services.sh"
echo "2. 健康检查: ./scripts/health-check.sh"
echo "3. 访问网站: http://$(curl -s ifconfig.me 2>/dev/null || echo 'your-ip')"
echo ""