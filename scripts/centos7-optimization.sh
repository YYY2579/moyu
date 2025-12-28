#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# 🔧 CentOS 7 系统优化脚本
# 针对摸鱼学习站部署环境的系统优化
# =============================================================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 检查权限
if [ "$(id -u)" -ne 0 ]; then
    echo "此脚本需要root权限运行"
    exit 1
fi

log_info "开始CentOS 7系统优化..."
echo ""

# =============================================================================
# 1. 系统更新和仓库配置
# =============================================================================
log_info "1. 配置系统仓库和更新"

# 备份原有仓库配置
if [ ! -d "/etc/yum.repos.d/backup" ]; then
    mkdir -p /etc/yum.repos.d/backup
    cp /etc/yum.repos.d/*.repo /etc/yum.repos.d/backup/ 2>/dev/null || true
fi

# 清理缓存
yum clean all

# 更新系统
yum update -y

log_success "系统更新完成"
echo ""

# =============================================================================
# 2. 内核参数优化
# =============================================================================
log_info "2. 优化内核参数"

# 创建系统参数配置文件
cat > /etc/sysctl.d/99-moyu-optimize.conf << 'EOF'
# 网络优化
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.core.netdev_max_backlog = 5000

# 内存管理优化
vm.swappiness = 10
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5

# 文件描述符限制
fs.file-max = 65536

# Docker 优化
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 512
EOF

# 应用参数
sysctl -p /etc/sysctl.d/99-moyu-optimize.conf

log_success "内核参数优化完成"
echo ""

# =============================================================================
# 3. 系统限制优化
# =============================================================================
log_info "3. 配置系统限制"

# 修改 limits 配置
cat >> /etc/security/limits.conf << 'EOF'

# Docker 和摸鱼学习站优化
* soft nofile 65536
* hard nofile 65536
* soft nproc 32768
* hard nproc 32768
root soft nofile 65536
root hard nofile 65536
EOF

# 更新系统PAM配置
echo "session required pam_limits.so" >> /etc/pam.d/common-session 2>/dev/null || true

log_success "系统限制配置完成"
echo ""

# =============================================================================
# 4. Swap 配置优化
# =============================================================================
log_info "4. 优化 Swap 配置"

# 检查当前swap配置
SWAP_TOTAL=$(free | grep Swap | awk '{print $2}')
SWAP_FREE=$(free | grep Swap | awk '{print $3}')

if [ "$SWAP_TOTAL" -eq 0 ]; then
    log_info "未检测到 Swap，创建 2GB Swap 文件..."
    
    # 创建 swap 文件
    fallocate -l 2G /swapfile
    
    # 设置权限
    chmod 600 /swapfile
    
    # 设置为 swap
    mkswap /swapfile
    
    # 启用 swap
    swapon /swapfile
    
    # 添加到 fstab
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
    
    log_success "2GB Swap 创建并启用"
else
    log_info "当前已配置 Swap: ${SWAP_TOTAL}KB"
fi

# 调整 swappiness
echo 10 > /proc/sys/vm/swappiness
echo 'vm.swappiness = 10' >> /etc/sysctl.conf

log_success "Swap 优化完成"
echo ""

# =============================================================================
# 5. 防火墙和SELinux优化
# =============================================================================
log_info "5. 优化安全配置"

# 防火墙配置
if systemctl is-active --quiet firewalld; then
    # 添加 trusted zones
    firewall-cmd --permanent --zone=trusted --add-interface=docker0 2>/dev/null || true
    
    # 添加 Docker 网络
    firewall-cmd --permanent --zone=trusted --add-source=172.17.0.0/16 2>/dev/null || true
    
    # 重新加载
    firewall-cmd --reload
    
    log_success "防火墙配置优化完成"
else
    log_warning "firewalld 未运行，跳过防火墙配置"
fi

# SELinux 配置优化
if getenforce | grep -q "Enforcing"; then
    # 安装 SELinux 管理工具
    yum install -y policycoreutils-python
    
    # 设置 Docker SELinux 策略
    setsebool -P docker_transition_unconfined 1
    
    # 允许容器网络访问
    setsebool -P httpd_can_network_connect 1
    setsebool -P httpd_can_network_relay 1
    
    log_success "SELinux 配置优化完成"
else
    log_info "SELinux 未启用"
fi

echo ""

# =============================================================================
# 6. 系统服务优化
# =============================================================================
log_info "6. 优化系统服务"

# 禁用不必要的服务
DISABLED_SERVICES=(
    "postfix"     # 邮件服务
    "bluetooth"   # 蓝牙服务
    "cups"        # 打印服务
    "avahi-daemon" # mDNS 服务
)

for service in "${DISABLED_SERVICES[@]}"; do
    if systemctl is-enabled "$service" >/dev/null 2>&1; then
        systemctl disable "$service"
        systemctl stop "$service" 2>/dev/null || true
        log_info "禁用服务: $service"
    fi
done

# 启用必要的服务
ENABLED_SERVICES=(
    "docker"      # Docker 服务
    "network"     # 网络服务
)

for service in "${ENABLED_SERVICES[@]}"; do
    systemctl enable "$service" 2>/dev/null || true
    systemctl start "$service" 2>/dev/null || true
done

log_success "系统服务优化完成"
echo ""

# =============================================================================
# 7. 清理和优化
# =============================================================================
log_info "7. 系统清理和优化"

# 清理系统缓存
yum clean all

# 清理临时文件
rm -rf /tmp/* 2>/dev/null || true
rm -rf /var/tmp/* 2>/dev/null || true

# 清理日志文件 (保留最近7天)
find /var/log -name "*.log" -mtime +7 -delete 2>/dev/null || true
find /var/log -name "*.log.*" -mtime +7 -delete 2>/dev/null || true

# 优化已安装的包
yum autoremove -y

log_success "系统清理完成"
echo ""

# =============================================================================
# 8. 创建监控脚本
# =============================================================================
log_info "8. 创建系统监控脚本"

# 创建监控脚本
cat > /usr/local/bin/moyu-monitor.sh << 'EOF'
#!/bin/bash
# 摸鱼学习站系统监控脚本

echo "==== 系统监控报告 $(date) ===="
echo ""

# CPU使用率
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')
echo "CPU使用率: ${CPU_USAGE}%"

# 内存使用率
MEM_TOTAL=$(free -m | awk 'NR==2{print $2}')
MEM_USED=$(free -m | awk 'NR==2{print $3}')
MEM_USAGE=$((MEM_USED * 100 / MEM_TOTAL))
echo "内存使用: ${MEM_USED}MB / ${MEM_TOTAL}MB (${MEM_USAGE}%)"

# 磁盘使用率
DISK_USAGE=$(df -h / | awk 'NR==2{print $5}')
echo "磁盘使用率: ${DISK_USAGE}"

# Docker容器状态
DOCKER_RUNNING=$(docker ps --format "table {{.Names}}\t{{.Status}}" | grep -c "Up" || echo "0")
DOCKER_TOTAL=$(docker ps -a --format "table {{.Names}}" | wc -l)
echo "Docker容器: ${DOCKER_RUNNING}/${DOCKER_TOTAL} 运行中"

# 服务端口检查
HTTP_STATUS=$(netstat -tlnp 2>/dev/null | grep -c ":80 " || echo "0")
MYSQL_STATUS=$(netstat -tlnp 2>/dev/null | grep -c ":33066 " || echo "0")
echo "端口监听: HTTP=${HTTP_STATUS}, MySQL=${MYSQL_STATUS}"

echo ""
echo "==== 监控完成 ===="
EOF

chmod +x /usr/local/bin/moyu-monitor.sh

# 创建定时任务 (每5分钟检查一次)
cat > /etc/cron.d/moyu-monitor << 'EOF'
# 摸鱼学习站系统监控
*/5 * * * * root /usr/local/bin/moyu-monitor.sh >> /var/log/moyu-monitor.log 2>&1
EOF

log_success "监控脚本创建完成"
echo ""

# =============================================================================
# 优化完成总结
# =============================================================================
echo -e "${GREEN}"
echo "=============================================================================="
echo "🎉 CentOS 7 系统优化完成！"
echo "=============================================================================="
echo -e "${NC}"

echo -e "${BLUE}📊 优化内容:${NC}"
echo -e "   🔧 内核参数优化"
echo -e "   📈 系统限制调整"
echo -e "   💾 Swap 配置优化"
echo -e "   🛡️  防火墙和SELinux优化"
echo -e "   ⚙️  系统服务优化"
echo -e "   🧹 系统清理"
echo -e "   📈 监控脚本创建"
echo ""

echo -e "${BLUE}🔧 管理命令:${NC}"
echo -e "   📊 系统监控: ${GREEN}/usr/local/bin/moyu-monitor.sh${NC}"
echo -e "   📝 监控日志: ${GREEN}/var/log/moyu-monitor.log${NC}"
echo -e "   🔧 内核参数: ${GREEN}sysctl -p /etc/sysctl.d/99-moyu-optimize.conf${NC}"
echo -e "   🔄 重新应用优化: ${GREEN}sysctl --system${NC}"
echo ""

echo -e "${BLUE}⚠️  注意事项:${NC}"
echo -e "   🔍 建议重启系统以完全应用所有优化"
echo -e "   📊 可定期查看监控日志了解系统状态"
echo -e "   🔄 如需恢复原始配置，可使用 /etc/yum.repos.d/backup/ 备份"
echo ""

log_success "CentOS 7 系统优化脚本执行完成"

exit 0