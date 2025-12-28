#!/bin/bash
set -euo pipefail

# =============================================================================
# 🔐 权限验证和修复脚本
# 确保部署目录和文件权限正确配置
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
readonly SCRIPT_DIR="${DEPLOY_DIR}/scripts"
readonly LOG_DIR="${DEPLOY_DIR}/logs"
readonly DATA_DIR="${DEPLOY_DIR}/data"

# 日志函数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${PURPLE}[STEP]${NC} $1"; }

# 检查是否以root权限运行
ensure_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要root权限运行，请使用: sudo $0"
        exit 1
    fi
}

# 创建目录结构
create_directories() {
    log_step "创建并验证目录结构..."
    
    local dirs=(
        "${DEPLOY_DIR}"
        "${SCRIPT_DIR}"
        "${LOG_DIR}"
        "${DATA_DIR}"
        "${DATA_DIR}/mysql"
        "${DATA_DIR}/uploads"
        "${DEPLOY_DIR}/backups"
        "${DEPLOY_DIR}/deploy/volumes/mysql"
    )
    
    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            log_info "创建目录: $dir"
            mkdir -p "$dir"
        fi
    done
    
    log_success "目录结构验证完成"
}

# 设置目录权限
set_directory_permissions() {
    log_step "设置目录权限..."
    
    # 设置部署目录权限
    chmod 755 "${DEPLOY_DIR}" 2>/dev/null || true
    chown root:root "${DEPLOY_DIR}" 2>/dev/null || true
    
    # 设置脚本目录权限
    if [[ -d "${SCRIPT_DIR}" ]]; then
        chmod -R 755 "${SCRIPT_DIR}" 2>/dev/null || true
        chown -R root:root "${SCRIPT_DIR}" 2>/dev/null || true
    fi
    
    # 设置日志目录权限
    if [[ -d "${LOG_DIR}" ]]; then
        chmod -R 755 "${LOG_DIR}" 2>/dev/null || true
        chown -R root:root "${LOG_DIR}" 2>/dev/null || true
    fi
    
    # 设置数据目录权限 (Docker容器需要写权限)
    if [[ -d "${DATA_DIR}" ]]; then
        chmod -R 755 "${DATA_DIR}" 2>/dev/null || true
        chown -R root:root "${DATA_DIR}" 2>/dev/null || true
    fi
    
    # 设置备份目录权限
    if [[ -d "${DEPLOY_DIR}/backups" ]]; then
        chmod -R 755 "${DEPLOY_DIR}/backups" 2>/dev/null || true
        chown -R root:root "${DEPLOY_DIR}/backups" 2>/dev/null || true
    fi
    
    log_success "目录权限设置完成"
}

# 设置文件权限
set_file_permissions() {
    log_step "设置文件权限..."
    
    # 设置脚本执行权限
    local scripts=(
        "${DEPLOY_DIR}/deploy.sh"
        "${SCRIPT_DIR}/setup-git.sh"
        "${SCRIPT_DIR}/setup-webhook-service.sh"
        "${SCRIPT_DIR}/quick-health-check.sh"
        "${SCRIPT_DIR}/centos7-optimization.sh"
        "${SCRIPT_DIR}/verify-deployment.sh"
        "${SCRIPT_DIR}/webhook-handler.sh"
        "${SCRIPT_DIR}/verify-permissions.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [[ -f "$script" ]]; then
            log_info "设置脚本权限: $(basename "$script")"
            chmod +x "$script" 2>/dev/null || true
        fi
    done
    
    # 设置配置文件权限
    local config_files=(
        "${DEPLOY_DIR}/.env"
        "${DEPLOY_DIR}/.webhook_secret"
        "${DEPLOY_DIR}/webhook.json"
    )
    
    for file in "${config_files[@]}"; do
        if [[ -f "$file" ]]; then
            log_info "设置配置文件权限: $(basename "$file")"
            chmod 600 "$file" 2>/dev/null || true
            chown root:root "$file" 2>/dev/null || true
        fi
    done
    
    # 设置普通文件权限
    if [[ -d "${DEPLOY_DIR}" ]]; then
        find "${DEPLOY_DIR}" -type f ! -path '*/.*' ! -path '*/.git/*' ! -name '*.sh' ! -name '.env*' ! -name '*secret*' -exec chmod 644 {} \; 2>/dev/null || true
    fi
    
    log_success "文件权限设置完成"
}

# 验证Docker权限
verify_docker_permissions() {
    log_step "验证Docker权限..."
    
    if ! command -v docker >/dev/null 2>&1; then
        log_warning "Docker未安装，跳过权限验证"
        return
    fi
    
    # 检查Docker服务状态
    if systemctl is-active --quiet docker; then
        log_success "Docker服务运行正常"
    else
        log_warning "Docker服务未运行，尝试启动..."
        systemctl start docker 2>/dev/null || true
    fi
    
    # 测试Docker权限
    if docker ps >/dev/null 2>&1; then
        log_success "Docker权限验证通过"
    else
        log_warning "Docker权限验证失败，可能需要使用sudo运行Docker命令"
    fi
}

# 验证Git权限
verify_git_permissions() {
    log_step "验证Git权限..."
    
    if ! command -v git >/dev/null 2>&1; then
        log_warning "Git未安装，跳过权限验证"
        return
    fi
    
    # 检查Git配置
    if [[ -d "${DEPLOY_DIR}/.git" ]]; then
        cd "${DEPLOY_DIR}"
        
        # 测试Git读取权限
        if git status >/dev/null 2>&1; then
            log_success "Git仓库权限验证通过"
        else
            log_warning "Git仓库权限验证失败"
        fi
        
        # 测试远程连接
        if git remote get-url origin >/dev/null 2>&1; then
            log_info "Git远程仓库配置正确"
        else
            log_warning "Git远程仓库配置异常"
        fi
    fi
}

# 验证SSH密钥权限
verify_ssh_permissions() {
    log_step "验证SSH密钥权限..."
    
    local ssh_dir="/root/.ssh"
    
    if [[ -d "$ssh_dir" ]]; then
        # 检查SSH目录权限
        local ssh_dir_perm
        ssh_dir_perm=$(stat -c "%a" "$ssh_dir" 2>/dev/null || echo "")
        if [[ "$ssh_dir_perm" == "700" ]]; then
            log_success "SSH目录权限正确: 700"
        else
            log_warning "SSH目录权限异常: ${ssh_dir_perm}，应为700"
            chmod 700 "$ssh_dir" 2>/dev/null || true
        fi
        
        # 检查私钥权限
        local private_keys=("$ssh_dir/id_rsa" "$ssh_dir/id_ed25519")
        for key in "${private_keys[@]}"; do
            if [[ -f "$key" ]]; then
                local key_perm
                key_perm=$(stat -c "%a" "$key" 2>/dev/null || echo "")
                if [[ "$key_perm" == "600" ]]; then
                    log_success "SSH私钥权限正确: $(basename "$key") - 600"
                else
                    log_warning "SSH私钥权限异常: $(basename "$key") - ${key_perm}，应为600"
                    chmod 600 "$key" 2>/dev/null || true
                fi
            fi
        done
        
        # 检查公钥权限
        local public_keys=("$ssh_dir/id_rsa.pub" "$ssh_dir/id_ed25519.pub")
        for key in "${public_keys[@]}"; do
            if [[ -f "$key" ]]; then
                local key_perm
                key_perm=$(stat -c "%a" "$key" 2>/dev/null || echo "")
                if [[ "$key_perm" == "644" ]]; then
                    log_success "SSH公钥权限正确: $(basename "$key") - 644"
                else
                    log_warning "SSH公钥权限异常: $(basename "$key") - ${key_perm}，应为644"
                    chmod 644 "$key" 2>/dev/null || true
                fi
            fi
        done
    else
        log_info "SSH目录不存在，跳过权限验证"
    fi
}

# 验证网络端口权限
verify_network_permissions() {
    log_step "验证网络端口权限..."
    
    local ports=("80" "9000")
    
    for port in "${ports[@]}"; do
        if netstat -tuln 2>/dev/null | grep -q ":$port "; then
            local service
            service=$(netstat -tuln 2>/dev/null | grep ":$port " | head -1 | awk '{print $7}' | cut -d'/' -f1)
            log_info "端口 $port 已被占用: PID $service"
        else
            log_info "端口 $port 可用"
        fi
    done
    
    # 检查防火墙状态
    if command -v firewall-cmd >/dev/null 2>&1; then
        if systemctl is-active --quiet firewalld; then
            log_info "firewalld 运行中"
            if firewall-cmd --list-ports | grep -q "80/tcp"; then
                log_success "防火墙已开放端口 80"
            else
                log_warning "防火墙未开放端口 80"
            fi
            if firewall-cmd --list-ports | grep -q "9000/tcp"; then
                log_success "防火墙已开放端口 9000"
            else
                log_warning "防火墙未开放端口 9000"
            fi
        else
            log_info "firewalld 未运行"
        fi
    elif command -v ufw >/dev/null 2>&1; then
        if ufw status | grep -q "Status: active"; then
            log_info "ufw 运行中"
            if ufw status | grep -q "80.*ALLOW"; then
                log_success "防火墙已开放端口 80"
            else
                log_warning "防火墙未开放端口 80"
            fi
            if ufw status | grep -q "9000.*ALLOW"; then
                log_success "防火墙已开放端口 9000"
            else
                log_warning "防火墙未开放端口 9000"
            fi
        else
            log_info "ufw 未运行"
        fi
    fi
}

# 生成权限报告
generate_permission_report() {
    log_step "生成权限报告..."
    
    local report_file="${DEPLOY_DIR}/permissions-report.txt"
    
    cat > "$report_file" << EOF
摸鱼学习站权限验证报告
====================

验证时间: $(date)
部署目录: ${DEPLOY_DIR}

目录权限:
$(ls -la "${DEPLOY_DIR}" 2>/dev/null | head -10 || echo "无法获取")

脚本文件权限:
$(find "${SCRIPT_DIR}" -name "*.sh" -exec ls -la {} \; 2>/dev/null || echo "无脚本文件")

配置文件权限:
$(find "${DEPLOY_DIR}" -maxdepth 1 -name ".*" -type f -exec ls -la {} \; 2>/dev/null || echo "无配置文件")

Docker权限:
Docker版本: $(docker --version 2>/dev/null || echo "未安装")
Docker状态: $(systemctl is-active docker 2>/dev/null || echo "未知")

Git权限:
Git版本: $(git --version 2>/dev/null || echo "未安装")
Git配置: $(git config --global user.name 2>/dev/null || echo "未配置") <$(git config --global user.email 2>/dev/null || echo "未配置")>

SSH权限:
SSH目录: $(ls -la /root/.ssh 2>/dev/null | head -5 || echo "不存在")

网络端口:
80端口状态: $(netstat -tuln 2>/dev/null | grep ":80 " && echo "被占用" || echo "可用")
9000端口状态: $(netstat -tuln 2>/dev/null | grep ":9000 " && echo "被占用" || echo "可用")

防火墙状态:
$(systemctl is-active firewalld 2>/dev/null || systemctl is-active ufw 2>/dev/null || echo "未运行")
EOF
    
    log_success "权限报告生成完成: $report_file"
}

# 显示验证结果
show_result() {
    echo ""
    echo -e "${GREEN}==============================================================================${NC}"
    echo -e "${GREEN}🔐 权限验证完成！${NC}"
    echo -e "${GREEN}==============================================================================${NC}"
    echo ""
    echo -e "${CYAN}📋 验证结果:${NC}"
    echo -e "   部署目录: ${BLUE}${DEPLOY_DIR}${NC}"
    echo -e "   脚本权限: ${GREEN}已设置执行权限${NC}"
    echo -e "   配置文件: ${YELLOW}已设置安全权限${NC}"
    echo -e "   Docker: ${BLUE}$(systemctl is-active docker 2>/dev/null || echo "未运行")${NC}"
    echo ""
    echo -e "${CYAN}📊 详细报告:${NC}"
    echo -e "   权限报告: ${YELLOW}${DEPLOY_DIR}/permissions-report.txt${NC}"
    echo ""
    echo -e "${CYAN}🔧 后续操作:${NC}"
    echo -e "   运行部署: ${YELLOW}sudo ${DEPLOY_DIR}/deploy.sh${NC}"
    echo -e "   配置Git: ${YELLOW}sudo ${SCRIPT_DIR}/setup-git.sh${NC}"
    echo -e "   设置Webhook: ${YELLOW}sudo ${SCRIPT_DIR}/setup-webhook-service.sh${NC}"
    echo ""
    echo -e "${GREEN}==============================================================================${NC}"
}

# 主函数
main() {
    ensure_root
    
    log_info "开始权限验证..."
    
    create_directories
    set_directory_permissions
    set_file_permissions
    verify_docker_permissions
    verify_git_permissions
    verify_ssh_permissions
    verify_network_permissions
    generate_permission_report
    show_result
    
    log_success "权限验证完成！"
}

# 执行主函数
main "$@"