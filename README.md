# 🐟 摸鱼学习站 (Moyu-Study)

> 专业的 Linux & Docker 技术学习平台，简洁高效的学习体验

## 📋 项目简介

摸鱼学习站是一个专为技术学习者设计的在线教育平台，专注于 Linux 命令和 Docker 容器技术的系统学习。平台提供完整的学习路径、练习题目和进度跟踪功能。

**🌟 特色功能**
- 📚 **Linux 命令学习** - 150+ 常用命令，从基础到进阶
- 🐳 **Docker 技术实战** - 80+ 知识点，涵盖理论到实践
- ✏️ **智能练习系统** - 500+ 练习题，支持多种练习模式
- 📊 **学习进度追踪** - 可视化学习统计和成就系统
- 📱 **响应式设计** - 完美适配桌面端和移动端

## 🚀 快速开始

### 🔗 演示地址
- **主站**: http://114.132.189.90
- **Linux 学习**: http://114.132.189.90/linux
- **Docker 学习**: http://114.132.189.90/docker
- **练习系统**: http://114.132.189.90/practice

### 🛠️ 技术栈

**前端**
- Vue 3.4+ - 现代化前端框架
- TypeScript 5.0+ - 类型安全开发
- Element Plus - UI 组件库
- Vite 5.0+ - 极速构建工具

**后端**
- Node.js 20+ - 服务器运行时
- Fastify 4.0+ - 高性能 Web 框架
- MySQL 5.7 - 关系型数据库
- TypeScript 5.0+ - 类型安全开发

**部署**
- Docker 23.0+ - 容器化平台
- Docker Compose 2.5+ - 容器编排
- CentOS 7+ - 生产环境操作系统

## 📦 标准化部署指南

### ⚙️ 环境要求

**硬件要求**
- CPU: 2核心以上 (推荐4核心)
- 内存: 4GB以上 (推荐8GB)
- 存储: 20GB可用空间 (推荐50GB SSD)
- 网络: 公网IP，可访问 GitHub 和 Docker Hub

**软件要求**
- 操作系统: CentOS 7.x / Ubuntu 18.04+
- Docker: 23.x 或更高版本
- Docker Compose: 2.5.x 或更高版本
- Git: 1.8+ 

**端口配置**
| 端口 | 协议 | 用途 | 说明 |
|------|------|------|------|
| 80   | TCP  | HTTP | Web 服务访问 |
| 33067| TCP  | MySQL | 数据库访问(仅限本机) |
| 9000 | TCP  | Webhook | 自动部署触发 |

### 🔧 Linux 标准部署脚本

#### 1. 环境检查和依赖安装

```bash
#!/bin/bash
# install-dependencies.sh

echo "🔧 检查系统环境和安装依赖..."

# 检查操作系统
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "✅ Linux 系统检测通过"
else
    echo "❌ 需要Linux系统环境"
    exit 1
fi

# 安装 Git
if ! command -v git &> /dev/null; then
    echo "📦 安装 Git..."
    if command -v yum &> /dev/null; then
        sudo yum install -y git
    elif command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y git
    else
        echo "❌ 无法安装Git，请手动安装"
        exit 1
    fi
fi

# 安装 Docker
if ! command -v docker &> /dev/null; then
    echo "📦 安装 Docker..."
    curl -fsSL https://get.docker.com | sh
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker $USER
fi

# 安装 Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "📦 安装 Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# 配置防火墙
echo "🔥 配置防火墙规则..."
if command -v firewall-cmd &> /dev/null; then
    sudo firewall-cmd --permanent --add-port=80/tcp
    sudo firewall-cmd --permanent --add-port=9000/tcp
    sudo firewall-cmd --reload
elif command -v ufw &> /dev/null; then
    sudo ufw allow 80/tcp
    sudo ufw allow 9000/tcp
    sudo ufw --force enable
fi

echo "✅ 环境检查和依赖安装完成"
```

#### 2. 项目拉取和初始化

```bash
#!/bin/bash
# deploy-moyu.sh

echo "🚀 开始部署摸鱼学习站..."

# 设置变量
PROJECT_DIR="/opt/moyu"
REPO_URL="https://github.com/YYY2579/moyu.git"

# 创建部署目录
sudo mkdir -p $PROJECT_DIR
sudo chown $USER:$USER $PROJECT_DIR

# 克隆项目
if [ -d "$PROJECT_DIR/.git" ]; then
    echo "📥 更新现有项目..."
    cd $PROJECT_DIR
    git pull origin main
else
    echo "📥 克隆项目..."
    git clone $REPO_URL $PROJECT_DIR
    cd $PROJECT_DIR
fi

# 创建环境变量文件
echo "📝 生成环境配置..."
cat > .env << EOF
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
EOF

# 设置文件权限
chmod 600 .env
chmod +x scripts/*.sh

echo "✅ 项目初始化完成"
```

#### 3. 服务启动和健康检查

```bash
#!/bin/bash
# start-services.sh

echo "🔨 构建和启动服务..."

# 停止现有容器
docker-compose down --remove-orphans 2>/dev/null || true

# 构建镜像
echo "🏗️ 构建Docker镜像..."
docker-compose build --no-cache

# 启动服务
echo "🚀 启动服务..."
docker-compose up -d

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 30

# 健康检查
echo "🔍 执行健康检查..."
./scripts/health-check.sh

echo "✅ 服务启动完成"
echo "🌐 访问地址: http://$(curl -s ifconfig.me)"
```

#### 4. 一键部署脚本

```bash
#!/bin/bash
# quick-deploy.sh - 一键部署摸鱼学习站

set -e  # 遇到错误立即退出

echo "🎯 摸鱼学习站 - 一键部署脚本"
echo "================================"

# 检查是否为root用户
if [ "$EUID" -eq 0 ]; then
    echo "❌ 请不要使用root用户运行此脚本"
    exit 1
fi

# 执行部署步骤
echo "📍 步骤 1/4: 环境检查和依赖安装"
./scripts/install-dependencies.sh

echo "📍 步骤 2/4: 项目拉取和初始化"
./scripts/deploy-moyu.sh

echo "📍 步骤 3/4: 服务启动和健康检查"
./scripts/start-services.sh

echo "📍 步骤 4/4: 部署验证"
./scripts/verify-deployment.sh

echo ""
echo "🎉 部署完成！"
echo "================================"
echo "🌐 访问地址: http://$(curl -s ifconfig.me)"
echo "📱 移动端: http://$(curl -s ifconfig.me)"
echo "🔍 健康检查: http://$(curl -s ifconfig.me)/health"
echo ""
echo "📋 管理命令:"
echo "  查看状态: docker-compose ps"
echo "  查看日志: docker-compose logs -f"
echo "  重启服务: docker-compose restart"
echo "  停止服务: docker-compose down"
echo ""
```

### 📋 部署执行步骤

#### 方法一：一键自动部署（推荐）

```bash
# 下载并执行一键部署脚本
curl -fsSL https://raw.githubusercontent.com/YYY2579/moyu/main/scripts/quick-deploy.sh | bash

# 或者分步执行
git clone https://github.com/YYY2579/moyu.git
cd moyu
chmod +x scripts/*.sh
sudo ./scripts/quick-deploy.sh
```

#### 方法二：手动分步部署

```bash
# 1. 克隆项目
git clone https://github.com/YYY2579/moyu.git
cd moyu

# 2. 安装依赖
sudo ./scripts/install-dependencies.sh

# 3. 初始化项目
./scripts/deploy-moyu.sh

# 4. 启动服务
./scripts/start-services.sh

# 5. 验证部署
./scripts/verify-deployment.sh
```

#### 方法三：直接 Docker 部署

```bash
# 1. 拉取项目
git clone https://github.com/YYY2579/moyu.git
cd moyu

# 2. 配置环境变量
cp .env.example .env
# 编辑 .env 文件，设置数据库密码等

# 3. 启动服务
docker-compose up -d

# 4. 初始化数据库
docker-compose exec api npm run seed

# 5. 健康检查
curl http://localhost/health
```

## 🔧 管理和维护

### 📊 服务状态管理

```bash
# 查看所有服务状态
docker-compose ps

# 查看服务日志
docker-compose logs -f              # 所有服务
docker-compose logs web              # Web服务
docker-compose logs api              # API服务
docker-compose logs mysql            # MySQL服务

# 服务控制
docker-compose start                 # 启动所有服务
docker-compose stop                  # 停止所有服务
docker-compose restart               # 重启所有服务
docker-compose down                  # 停止并删除容器
docker-compose down -v               # 停止并删除数据卷
```

### 🗄️ 数据库管理

```bash
# 连接数据库
docker-compose exec mysql mysql -u root -p

# 数据库备份
docker-compose exec mysql mysqldump -u root -p moyu_study > backup_$(date +%Y%m%d).sql

# 数据库恢复
docker-compose exec -i mysql mysql -u root -p moyu_study < backup_20241228.sql

# 数据库优化
docker-compose exec mysql mysql -u root -p -e "OPTIMIZE TABLE moyu_study.questions;"
```

### 🔄 更新和升级

```bash
# 更新代码
git pull origin main

# 重新构建和部署
docker-compose build --no-cache
docker-compose up -d

# 验证更新
curl http://localhost/health
```

### 🧹 清理和维护

```bash
# 清理Docker缓存
docker system prune -f

# 清理未使用的镜像和容器
docker system prune -a

# 日志轮转
docker-compose logs --tail=1000 > /var/log/moyu-$(date +%Y%m%d).log
```

## 🐛 问题排查

### 🔍 常见问题解决

**1. 端口占用问题**
```bash
# 检查端口占用
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :33067

# 停止占用服务
sudo systemctl stop nginx  # 如果nginx占用了80端口
```

**2. 权限问题**
```bash
# 修复文件权限
sudo chown -R $USER:$USER /opt/moyu
chmod +x /opt/moyu/scripts/*.sh
```

**3. Docker服务问题**
```bash
# 检查Docker状态
sudo systemctl status docker

# 重启Docker服务
sudo systemctl restart docker
```

**4. 数据库连接问题**
```bash
# 检查MySQL容器状态
docker-compose ps mysql

# 查看MySQL日志
docker-compose logs mysql

# 重置数据库
docker-compose down -v
docker-compose up -d mysql
```

### 📞 技术支持

如果遇到部署问题，请按以下步骤排查：

1. **检查系统日志**: `journalctl -xe`
2. **检查Docker日志**: `docker-compose logs`
3. **网络连通性**: `curl -I http://github.com`
4. **磁盘空间**: `df -h`
5. **内存使用**: `free -h`

## 📁 项目结构

```
moyu-study-2/
├── api/                    # 后端API服务
│   ├── src/               # 源代码
│   │   ├── routes/        # API路由
│   │   ├── models/        # 数据模型
│   │   └── utils/         # 工具函数
│   ├── Dockerfile         # Docker构建文件
│   └── package.json       # 依赖配置
├── web/                   # 前端Web应用
│   ├── src/              # 源代码
│   │   ├── views/         # 页面组件
│   │   ├── components/    # 通用组件
│   │   ├── router/        # 路由配置
│   │   └── utils/         # 工具函数
│   ├── Dockerfile         # Docker构建文件
│   └── package.json       # 依赖配置
├── scripts/               # 部署脚本
│   ├── install-dependencies.sh
│   ├── deploy-moyu.sh
│   ├── start-services.sh
│   └── health-check.sh
├── deploy/               # 部署相关
│   ├── mysql-init/       # 数据库初始化
│   └── volumes/          # 数据持久化
├── docker-compose.yml    # 容器编排配置
├── .env.example          # 环境变量模板
└── README.md             # 项目文档
```

## 🤝 贡献指南

我们欢迎任何形式的贡献！

1. Fork 本项目
2. 创建功能分支: `git checkout -b feature/amazing-feature`
3. 提交更改: `git commit -m 'Add amazing feature'`
4. 推送分支: `git push origin feature/amazing-feature`
5. 提交 Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

## 🎉 致谢

感谢所有为这个项目做出贡献的开发者和学习者！

---

**🚀 立即开始您的Linux和Docker学习之旅！**

*最后更新: 2024年12月28日*