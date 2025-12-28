#!/bin/bash
# =============================================================================
# 🪝 Webhook自动部署处理脚本
# 由GitHub Webhook触发，自动执行部署
# =============================================================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# 配置
readonly DEPLOY_DIR="/opt/moyu"
readonly DEPLOY_LOG="${DEPLOY_DIR}/logs/deploy.log"
readonly LOCK_FILE="/tmp/webhook-deploy.lock"

# 日志函数
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$DEPLOY_LOG"
}

log_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$DEPLOY_LOG"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$DEPLOY_LOG"
}

# 锁机制，防止重复部署
check_lock() {
    if [[ -f "$LOCK_FILE" ]]; then
        local lock_time=$(stat -c %Y "$LOCK_FILE" 2>/dev/null || stat -f %m "$LOCK_FILE")
        local current_time=$(date +%s)
        local elapsed=$((current_time - lock_time))
        
        # 如果锁文件超过10分钟，认为是死锁，可以继续
        if [[ $elapsed -lt 600 ]]; then
            log_error "部署正在进行中（已运行${elapsed}秒），跳过本次触发"
            exit 0
        else
            log "检测到过期锁文件（${elapsed}秒），自动清理"
            rm -f "$LOCK_FILE"
        fi
    fi
}

# 创建锁
create_lock() {
    echo "PID: $$" > "$LOCK_FILE"
    log "创建部署锁文件"
}

# 删除锁
remove_lock() {
    rm -f "$LOCK_FILE"
    log "清理部署锁文件"
}

# 错误处理
error_handler() {
    local exit_code=$?
    log_error "部署失败！退出码: $exit_code"
    remove_lock
    exit $exit_code
}

# 设置错误处理
trap error_handler ERR
trap remove_lock EXIT

# 主函数
main() {
    log "=========================================="
    log "🚀 Webhook触发自动部署"
    log "=========================================="
    
    # 检查锁
    check_lock
    create_lock
    
    # 进入部署目录
    cd "$DEPLOY_DIR" || {
        log_error "无法进入部署目录: $DEPLOY_DIR"
        exit 1
    }
    
    # 创建日志目录
    mkdir -p "$(dirname "$DEPLOY_LOG")"
    
    # 1. 拉取最新代码
    log "📥 拉取最新代码..."
    git fetch origin
    local current_commit=$(git rev-parse HEAD)
    local latest_commit=$(git rev-parse origin/main)
    
    if [[ "$current_commit" == "$latest_commit" ]]; then
        log_success "代码已是最新版本，无需更新"
        log "当前版本: ${current_commit:0:8}"
        log "=========================================="
        exit 0
    fi
    
    log "更新版本: ${current_commit:0:8} → ${latest_commit:0:8}"
    
    # 2. 重置到最新代码
    log "🔄 更新代码..."
    git reset --hard origin/main || {
        log_error "代码更新失败"
        exit 1
    }
    
    # 3. 重新部署
    log "🚀 开始重新部署..."
    bash "$DEPLOY_DIR/deploy.sh" || {
        log_error "部署失败，尝试回滚"
        git reset --hard "$current_commit"
        log_error "已回滚到之前版本: ${current_commit:0:8}"
        exit 1
    }
    
    # 4. 验证部署
    log "🔍 验证部署结果..."
    if curl -f -s http://localhost/health > /dev/null; then
        log_success "✅ 部署成功！"
        log "新版本: ${latest_commit:0:8}"
    else
        log_error "部署验证失败，尝试回滚"
        git reset --hard "$current_commit"
        log_error "已回滚到之前版本: ${current_commit:0:8}"
        exit 1
    fi
    
    log "=========================================="
    log "✅ Webhook自动部署完成"
    log "=========================================="
}

# 执行主函数
main "$@"
