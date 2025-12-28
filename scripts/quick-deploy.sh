#!/bin/bash

# 摸鱼学习站 - 一键部署脚本
# 作者: Moyu Study Team
# 版本: 1.0.0

set -e  # 遇到错误立即退出

echo "🎯 摸鱼学习站 - 一键部署脚本"
echo "================================"
echo "版本: 1.0.0"
echo "更新时间: 2024-12-28"
echo ""

# 检查是否为root用户
if [ "$EUID" -eq 0 ]; then
    echo "❌ 请不要使用root用户运行此脚本"
    echo "💡 建议创建普通用户并添加到docker组"
    exit 1
fi

# 显示系统信息
echo "🖥️ 系统信息:"
echo "  操作系统: $(uname -s)"
echo "  内核版本: $(uname -r)"
echo "  CPU架构: $(uname -m)"
echo "  用户名: $(whoami)"
echo "  当前目录: $(pwd)"
echo ""

# 检查网络连接
echo "🌐 检查网络连接..."
if ping -c 1 github.com &> /dev/null; then
    echo "✅ GitHub连接正常"
else
    echo "❌ 无法连接GitHub，请检查网络设置"
    exit 1
fi

# 检查Docker用户组
echo "👥 检查用户权限..."
if ! groups $USER | grep -q docker; then
    echo "⚠️  当前用户不在docker组中"
    echo "🔧 尝试添加用户到docker组..."
    sudo usermod -aG docker $USER
    echo "📝 请重新登录以使用户组生效，然后重新运行此脚本"
    echo "💡 或者使用: newgrp docker"
    exit 1
else
    echo "✅ Docker权限正常"
fi

# 设置项目变量
PROJECT_DIR="/opt/moyu"
SCRIPT_DIR="$PROJECT_DIR/scripts"
REPO_URL="https://github.com/YYY2579/moyu.git"

# 执行部署步骤
echo ""
echo "📍 步骤 1/4: 环境检查和依赖安装"
echo "----------------------------------------"

if [ ! -f "$SCRIPT_DIR/install-dependencies.sh" ]; then
    echo "📥 下载部署脚本..."
    mkdir -p "$SCRIPT_DIR"
    curl -fsSL "https://raw.githubusercontent.com/YYY2579/moyu/main/scripts/install-dependencies.sh" -o "$SCRIPT_DIR/install-dependencies.sh"
    chmod +x "$SCRIPT_DIR/install-dependencies.sh"
fi

if bash "$SCRIPT_DIR/install-dependencies.sh"; then
    echo "✅ 环境检查和依赖安装完成"
else
    echo "❌ 环境检查和依赖安装失败"
    exit 1
fi

echo ""
echo "📍 步骤 2/4: 项目拉取和初始化"
echo "----------------------------------------"

if [ ! -f "$SCRIPT_DIR/deploy-moyu.sh" ]; then
    echo "📥 下载部署脚本..."
    curl -fsSL "https://raw.githubusercontent.com/YYY2579/moyu/main/scripts/deploy-moyu.sh" -o "$SCRIPT_DIR/deploy-moyu.sh"
    chmod +x "$SCRIPT_DIR/deploy-moyu.sh"
fi

if bash "$SCRIPT_DIR/deploy-moyu.sh"; then
    echo "✅ 项目拉取和初始化完成"
else
    echo "❌ 项目拉取和初始化失败"
    exit 1
fi

echo ""
echo "📍 步骤 3/4: 服务启动和健康检查"
echo "----------------------------------------"

if [ ! -f "$SCRIPT_DIR/start-services.sh" ]; then
    echo "📥 下载启动脚本..."
    curl -fsSL "https://raw.githubusercontent.com/YYY2579/moyu/main/scripts/start-services.sh" -o "$SCRIPT_DIR/start-services.sh"
    chmod +x "$SCRIPT_DIR/start-services.sh"
fi

if bash "$SCRIPT_DIR/start-services.sh"; then
    echo "✅ 服务启动和健康检查完成"
else
    echo "❌ 服务启动和健康检查失败"
    exit 1
fi

echo ""
echo "📍 步骤 4/4: 部署验证"
echo "----------------------------------------"

if [ ! -f "$SCRIPT_DIR/health-check.sh" ]; then
    echo "📥 下载健康检查脚本..."
    curl -fsSL "https://raw.githubusercontent.com/YYY2579/moyu/main/scripts/health-check.sh" -o "$SCRIPT_DIR/health-check.sh"
    chmod +x "$SCRIPT_DIR/health-check.sh"
fi

if bash "$SCRIPT_DIR/health-check.sh"; then
    echo "✅ 部署验证完成"
else
    echo "⚠️  部署验证发现问题，但服务可能仍在运行"
fi

# 获取服务器信息
echo ""
echo "🌐 获取服务器信息..."
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "localhost")
SERVER_HOSTNAME=$(hostname 2>/dev/null || echo "unknown")

# 部署完成报告
echo ""
echo "🎉 部署完成！"
echo "================================"
echo ""
echo "📋 部署信息:"
echo "  项目目录: $PROJECT_DIR"
echo "  服务器IP: $SERVER_IP"
echo "  主机名: $SERVER_HOSTNAME"
echo "  部署时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""
echo "🌐 访问地址:"
echo "  🏠 主站: http://$SERVER_IP"
echo "  🐧 Linux学习: http://$SERVER_IP/linux"
echo "  🐳 Docker学习: http://$SERVER_IP/docker"
echo "  ✏️ 练习系统: http://$SERVER_IP/practice"
echo "  📊 学习进度: http://$SERVER_IP/progress"
echo "  🔍 健康检查: http://$SERVER_IP/health"
echo ""
echo "📋 管理命令:"
echo "  进入项目目录: cd $PROJECT_DIR"
echo "  查看服务状态: docker-compose ps"
echo "  查看实时日志: docker-compose logs -f"
echo "  重启所有服务: docker-compose restart"
echo "  停止所有服务: docker-compose down"
echo "  重新构建部署: docker-compose build --no-cache && docker-compose up -d"
echo ""
echo "🔧 故障排查:"
echo "  完整健康检查: ./scripts/health-check.sh"
echo "  查看详细日志: docker-compose logs [service-name]"
echo "  进入容器调试: docker-compose exec [service-name] sh"
echo ""
echo "📞 技术支持:"
echo "  问题反馈: https://github.com/YYY2579/moyu/issues"
echo "  文档地址: https://github.com/YYY2579/moyu/blob/main/README.md"
echo ""
echo "🎯 开始您的学习之旅吧！"
echo "================================"

# 显示最后的祝福语
echo ""
echo "✨ 祝您学习愉快，技术进步！"
echo "🐟 摸鱼学习站 - 让技术学习更简单"