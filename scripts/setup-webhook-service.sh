#!/bin/bash
set -euo pipefail

# =============================================================================
# 🪝 Webhook自动部署服务配置脚本
# 用于配置GitHub Webhook自动触发部署
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
readonly WEBHOOK_SERVICE="/etc/systemd/system/webhook.service"
readonly WEBHOOK_BIN="/usr/local/bin/webhook"
readonly WEBHOOK_PORT="9000"
readonly WEBHOOK_CONFIG="${DEPLOY_DIR}/webhook.json"
readonly WEBHOOK_SECRET_FILE="${DEPLOY_DIR}/.webhook_secret"

# 日志函数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${PURPLE}[STEP]${NC} $1"; }

# 确保以root权限运行
ensure_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要root权限运行，请使用: sudo $0"
        exit 1
    fi
}

# 下载并安装webhook
install_webhook() {
    log_step "安装Webhook服务..."
    
    # 检查是否已安装
    if [[ -f "${WEBHOOK_BIN}" ]]; then
        log_info "Webhook已安装，跳过安装步骤"
        return
    fi
    
    # 检测系统架构
    ARCH=$(uname -m)
    case $ARCH in
        x86_64) WEBHOOK_ARCH="amd64" ;;
        aarch64) WEBHOOK_ARCH="arm64" ;;
        armv7l) WEBHOOK_ARCH="armv6" ;;
        *) log_error "不支持的系统架构: $ARCH"; exit 1 ;;
    esac
    
    # 下载webhook
    local webhook_version="2.8.1"
    local download_url="https://github.com/adnanh/webhook/releases/download/${webhook_version}/webhook-linux-${WEBHOOK_ARCH}-${webhook_version}.tar.gz"
    
    log_info "下载Webhook ${webhook_version} for ${WEBHOOK_ARCH}..."
    
    # 创建临时目录
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    # 下载并解压
    wget -q "$download_url" -O webhook.tar.gz || {
        log_error "下载Webhook失败"
        rm -rf "$temp_dir"
        exit 1
    }
    
    tar -xzf webhook.tar.gz || {
        log_error "解压Webhook失败"
        rm -rf "$temp_dir"
        exit 1
    }
    
    # 安装到系统目录
    mv webhook-linux-${WEBHOOK_ARCH}-${webhook_version}/webhook "${WEBHOOK_BIN}"
    chmod +x "${WEBHOOK_BIN}"
    
    # 清理临时目录
    cd /
    rm -rf "$temp_dir"
    
    log_success "Webhook安装完成: ${WEBHOOK_BIN}"
}

# 创建webhook配置文件
create_webhook_config() {
    log_step "创建Webhook配置..."
    
    # 读取webhook密钥
    if [[ ! -f "${WEBHOOK_SECRET_FILE}" ]]; then
        log_error "Webhook密钥文件不存在: ${WEBHOOK_SECRET_FILE}"
        log_info "请先运行部署脚本: ${DEPLOY_DIR}/deploy.sh"
        exit 1
    fi
    
    local webhook_secret
    webhook_secret=$(cat "${WEBHOOK_SECRET_FILE}")
    
    # 创建webhook配置
    cat > "${WEBHOOK_CONFIG}" << EOF
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
            "secret": "${webhook_secret}",
            "parameter": {
              "source": "header",
              "name": "X-Hub-Signature"
            }
          }
        }
      ]
    },
    "response-message": "部署请求已接收，正在处理...",
    "success-http-code": 200
  }
]
EOF
    
    chmod 644 "${WEBHOOK_CONFIG}"
    
    log_success "Webhook配置创建完成: ${WEBHOOK_CONFIG}"
}

# 创建webhook处理脚本
create_webhook_handler() {
    log_step "创建Webhook处理脚本..."
    
    cat > "${DEPLOY_DIR}/scripts/webhook-handler.sh" << 'EOF'
#!/bin/bash
set -euo pipefail

# Webhook自动部署处理脚本
DEPLOY_DIR="/opt/moyu"
LOG_FILE="${DEPLOY_DIR}/logs/webhook.log"
BACKUP_DIR="${DEPLOY_DIR}/backups"
LOCK_FILE="/tmp/webhook-deploy.lock"

# 日志函数
log() {
    local message="$(date '+%Y-%m-%d %H:%M:%S') [WEBHOOK] $1"
    echo "$message"
    echo "$message" >> "${LOG_FILE}" 2>/dev/null || true
}

# 检查锁文件，防止并发部署
check_lock() {
    if [[ -f "${LOCK_FILE}" ]]; then
        local pid
        pid=$(cat "${LOCK_FILE}" 2>/dev/null || echo "")
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            log "检测到正在进行的部署，跳过本次请求 (PID: $pid)"
            exit 0
        else
            # 清理无效的锁文件
            rm -f "${LOCK_FILE}"
        fi
    fi
    
    # 创建锁文件
    echo $$ > "${LOCK_FILE}"
    trap 'rm -f "${LOCK_FILE}"' EXIT
}

# 备份当前版本
backup_current() {
    if [[ -d "${DEPLOY_DIR}/.git" ]]; then
        local backup_name="backup-$(date +%Y%m%d-%H%M%S)"
        local backup_path="${BACKUP_DIR}/${backup_name}"
        
        log "备份当前版本到: ${backup_path}"
        mkdir -p "${backup_path}"
        cp -r "${DEPLOY_DIR}"/* "${backup_path}/" 2>/dev/null || true
        
        # 保留最近5个备份
        cd "${BACKUP_DIR}"
        ls -t | tail -n +6 | xargs -r rm -rf
    fi
}

# 执行部署
deploy() {
    log "收到部署请求: $1 $2 $3 $4"
    log "开始自动部署流程..."
    
    # 切换到项目目录
    cd "${DEPLOY_DIR}"
    
    # 记录当前版本
    local current_commit
    current_commit=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
    log "当前版本: ${current_commit}"
    
    # 拉取最新代码
    log "拉取最新代码..."
    if ! git fetch origin; then
        log "拉取代码失败"
        exit 1
    fi
    
    # 重置到最新版本
    log "重置到最新版本..."
    if ! git reset --hard origin/main; then
        log "重置代码失败"
        exit 1
    fi
    
    if ! git clean -fd; then
        log "清理工作目录失败"
        exit 1
    fi
    
    # 记录新版本
    local new_commit
    new_commit=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
    log "新版本: ${new_commit}"
    
    # 更新配置文件（如果需要）
    if [[ -f "${DEPLOY_DIR}/.env.example" && ! -f "${DEPLOY_DIR}/.env" ]]; then
        log "创建环境配置文件..."
        cp "${DEPLOY_DIR}/.env.example" "${DEPLOY_DIR}/.env"
    fi
    
    # 重新部署服务
    log "重新部署Docker服务..."
    if ! docker-compose down; then
        log "停止服务失败"
        exit 1
    fi
    
    if ! docker-compose up -d --build; then
        log "启动服务失败"
        exit 1
    fi
    
    # 等待服务启动
    log "等待服务启动..."
    sleep 30
    
    # 健康检查
    local max_attempts=10
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        if curl -f -s http://localhost/health >/dev/null 2>&1; then
            log "部署成功！服务健康检查通过"
            echo "自动部署完成！$(date)" >> "${DEPLOY_DIR}/logs/deploy-success.log" 2>/dev/null || true
            break
        fi
        
        if [[ $attempt -eq $max_attempts ]]; then
            log "部署失败，健康检查未通过"
            # 回滚到备份版本
            if [[ -n "${current_commit}" && "${current_commit}" != "unknown" ]]; then
                log "回滚到备份版本: ${current_commit}"
                git reset --hard "${current_commit}"
                docker-compose down
                docker-compose up -d --build
            fi
            exit 1
        fi
        
        log "等待服务启动... (${attempt}/${max_attempts})"
        sleep 10
        ((attempt++))
    done
}

# 主函数
main() {
    # 检查锁文件
    check_lock
    
    # 备份当前版本
    backup_current
    
    # 执行部署
    deploy "$@"
    
    log "Webhook自动部署完成"
}

# 执行主函数
main "$@"
EOF
    
    chmod +x "${DEPLOY_DIR}/scripts/webhook-handler.sh"
    
    log_success "Webhook处理脚本创建完成"
}

# 创建systemd服务
create_systemd_service() {
    log_step "创建systemd服务..."
    
    cat > "${WEBHOOK_SERVICE}" << EOF
[Unit]
Description=Webhook Service for Auto Deployment
After=network.target docker.service
Requires=docker.service

[Service]
Type=simple
User=root
Group=root
ExecStart=${WEBHOOK_BIN} -verbose -hooks=${WEBHOOK_CONFIG} -port=${WEBHOOK_PORT} -hotreload
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=webhook

[Install]
WantedBy=multi-user.target
EOF
    
    # 重新加载systemd
    systemctl daemon-reload
    
    # 启用并启动服务
    systemctl enable webhook.service
    systemctl start webhook.service
    
    # 检查服务状态
    if systemctl is-active --quiet webhook.service; then
        log_success "Webhook服务启动成功"
    else
        log_error "Webhook服务启动失败"
        systemctl status webhook.service
        exit 1
    fi
}

# 配置防火墙
configure_firewall() {
    log_step "配置防火墙规则..."
    
    # 检查防火墙状态
    if command -v firewall-cmd >/dev/null 2>&1; then
        if systemctl is-active --quiet firewalld; then
            firewall-cmd --permanent --add-port="${WEBHOOK_PORT}/tcp" >/dev/null 2>&1 || true
            firewall-cmd --reload >/dev/null 2>&1 || true
            log_info "防火墙规则已更新 (firewalld)"
        fi
    elif command -v ufw >/dev/null 2>&1; then
        if ufw status | grep -q "Status: active"; then
            ufw allow "${WEBHOOK_PORT}/tcp" >/dev/null 2>&1 || true
            log_info "防火墙规则已更新 (ufw)"
        fi
    else
        log_warning "未检测到防火墙，请手动开放端口 ${WEBHOOK_PORT}"
    fi
}

# 生成GitHub配置说明
generate_github_instructions() {
    log_step "生成GitHub Webhook配置说明..."
    
    local webhook_secret
    webhook_secret=$(cat "${WEBHOOK_SECRET_FILE}")
    
    cat > "${DEPLOY_DIR}/GITHUB-WEBHOOK-SETUP.md" << EOF
# GitHub Webhook 配置说明

## 📋 基本信息

- **仓库地址**: https://github.com/YYY2579/moyu.git
- **Webhook URL**: http://114.132.189.90:${WEBHOOK_PORT}/hooks/auto-deploy
- **Content Type**: application/json
- **Secret**: ${webhook_secret}

## 🔧 配置步骤

### 1. 登录GitHub
访问: https://github.com/YYY2579/moyu/settings/hooks

### 2. 添加Webhook
1. 点击 "Add webhook"
2. 填写以下信息:
   - **Payload URL**: \`http://114.132.189.90:${WEBHOOK_PORT}/hooks/auto-deploy\`
   - **Content type**: \`application/json\`
   - **Secret**: \`${webhook_secret}\`
3. 选择触发事件:
   - ✅ Just the \`push\` event
   - 或者选择:
     - ✅ Pushes
     - ✅ Branch or tag creation
     - ✅ Branch or tag deletion
4. 点击 "Add webhook"

### 3. 测试Webhook
1. 在Webhook页面点击 "Recent Deliveries"
2. 查看最近的推送记录
3. 确保状态为 "200 OK"

## 🔍 测试方法

### 推送测试
\`\`\`bash
# 修改代码后推送到仓库
git add .
git commit -m "测试webhook自动部署"
git push origin main
\`\`\`

### 手动测试
\`\`\`bash
# 在服务器上查看webhook日志
journalctl -u webhook -f

# 查看部署日志
tail -f ${DEPLOY_DIR}/logs/webhook.log
\`\`\`

## 📊 监控日志

- **Webhook服务日志**: \`journalctl -u webhook -f\`
- **部署日志**: \`tail -f ${DEPLOY_DIR}/logs/webhook.log\`
- **应用日志**: \`cd ${DEPLOY_DIR} && docker-compose logs -f\`

## 🚨 故障排除

### 1. Webhook未触发
- 检查GitHub Webhook URL是否正确
- 确认Secret是否匹配
- 查看GitHub Webhook的Recent Deliveries

### 2. 部署失败
- 查看webhook日志: \`tail -f ${DEPLOY_DIR}/logs/webhook.log\`
- 检查Docker服务状态: \`cd ${DEPLOY_DIR} && docker-compose ps\`
- 查看应用日志: \`cd ${DEPLOY_DIR} && docker-compose logs -f\`

### 3. 权限问题
- 确保脚本有执行权限: \`chmod +x ${DEPLOY_DIR}/scripts/webhook-handler.sh\`
- 检查目录权限: \`ls -la ${DEPLOY_DIR}/\`

## 🔄 自动化流程

1. 代码推送到GitHub仓库
2. GitHub发送Webhook到服务器
3. Webhook服务接收请求并验证签名
4. 执行自动部署脚本
5. 拉取最新代码并重启服务
6. 执行健康检查
7. 记录部署日志

---

**配置时间**: $(date)
**服务器**: 114.132.189.90
**部署目录**: ${DEPLOY_DIR}
EOF
    
    log_success "GitHub配置说明已生成: ${DEPLOY_DIR}/GITHUB-WEBHOOK-SETUP.md"
}

# 显示配置结果
show_result() {
    echo ""
    echo -e "${GREEN}==============================================================================${NC}"
    echo -e "${GREEN}🪝 Webhook自动部署配置完成！${NC}"
    echo -e "${GREEN}==============================================================================${NC}"
    echo ""
    echo -e "${CYAN}📋 Webhook信息:${NC}"
    echo -e "   URL: ${BLUE}http://114.132.189.90:${WEBHOOK_PORT}/hooks/auto-deploy${NC}"
    echo -e "   Secret: ${YELLOW}$(cat "${WEBHOOK_SECRET_FILE}")${NC}"
    echo ""
    echo -e "${CYAN}🔧 服务管理:${NC}"
    echo -e "   查看状态: ${YELLOW}systemctl status webhook${NC}"
    echo -e "   重启服务: ${YELLOW}systemctl restart webhook${NC}"
    echo -e "   查看日志: ${YELLOW}journalctl -u webhook -f${NC}"
    echo ""
    echo -e "${CYAN}📖 配置说明:${NC}"
    echo -e "   详细文档: ${YELLOW}${DEPLOY_DIR}/GITHUB-WEBHOOK-SETUP.md${NC}"
    echo ""
    echo -e "${CYAN}🔄 测试方法:${NC}"
    echo -e "   推送代码: ${YELLOW}git push origin main${NC}"
    echo -e "   查看日志: ${YELLOW}tail -f ${DEPLOY_DIR}/logs/webhook.log${NC}"
    echo ""
    echo -e "${GREEN}==============================================================================${NC}"
}

# 主函数
main() {
    ensure_root
    
    log_info "开始配置Webhook自动部署服务..."
    
    install_webhook
    create_webhook_config
    create_webhook_handler
    create_systemd_service
    configure_firewall
    generate_github_instructions
    show_result
    
    log_success "Webhook自动部署配置完成！"
}

# 执行主函数
main "$@"