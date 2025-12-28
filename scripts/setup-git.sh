#!/bin/bash
set -euo pipefail

# =============================================================================
# 🔧 Git仓库配置脚本
# 用于配置SSH密钥和Git仓库连接
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
readonly SSH_REPO_URL="git@github.com:YYY2579/moyu.git"
readonly SSH_KEY_DIR="/root/.ssh"
readonly SSH_PRIVATE_KEY="${SSH_KEY_DIR}/id_rsa"
readonly SSH_PUBLIC_KEY="${SSH_KEY_DIR}/id_rsa.pub"

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

# 安装Git
install_git() {
    log_step "检查并安装Git..."
    
    if command -v git >/dev/null 2>&1; then
        local git_version
        git_version=$(git --version)
        log_success "Git已安装: ${git_version}"
        return
    fi
    
    log_info "安装Git..."
    
    # 检测包管理器
    if command -v yum >/dev/null 2>&1; then
        yum install -y git
    elif command -v apt-get >/dev/null 2>&1; then
        apt-get update && apt-get install -y git
    else
        log_error "不支持的包管理器，请手动安装Git"
        exit 1
    fi
    
    log_success "Git安装完成"
}

# 配置Git用户信息
configure_git_user() {
    log_step "配置Git用户信息..."
    
    # 设置默认的Git用户信息
    git config --global user.name "Moyu Study Deploy"
    git config --global user.email "deploy@moyu.study"
    
    log_success "Git用户信息配置完成"
    log_info "用户名: Moya Study Deploy"
    log_info "邮箱: deploy@moyu.study"
}

# 生成或使用现有SSH密钥
setup_ssh_key() {
    log_step "配置SSH密钥..."
    
    # 创建SSH目录
    mkdir -p "${SSH_KEY_DIR}"
    chmod 700 "${SSH_KEY_DIR}"
    
    # 检查是否已有SSH密钥
    if [[ -f "${SSH_PRIVATE_KEY}" ]]; then
        log_info "发现现有SSH密钥，使用现有密钥"
        
        # 显示公钥
        local public_key
        public_key=$(cat "${SSH_PUBLIC_KEY}" 2>/dev/null || echo "")
        if [[ -n "$public_key" ]]; then
            log_success "SSH公钥:"
            echo -e "${CYAN}$public_key${NC}"
        else
            log_warning "未找到SSH公钥文件"
        fi
        
        return
    fi
    
    # 生成新的SSH密钥
    log_info "生成新的SSH密钥..."
    ssh-keygen -t rsa -b 4096 -N "" -f "${SSH_PRIVATE_KEY}" -C "deploy@moyu.study"
    
    # 设置正确的权限
    chmod 600 "${SSH_PRIVATE_KEY}"
    chmod 644 "${SSH_PUBLIC_KEY}"
    
    log_success "SSH密钥生成完成"
    
    # 显示公钥
    local public_key
    public_key=$(cat "${SSH_PUBLIC_KEY}")
    log_success "SSH公钥:"
    echo -e "${CYAN}$public_key${NC}"
}

# 测试GitHub SSH连接
test_github_ssh() {
    log_step "测试GitHub SSH连接..."
    
    # 添加GitHub到known_hosts
    ssh-keyscan -t rsa github.com >> "${SSH_KEY_DIR}/known_hosts" 2>/dev/null || true
    chmod 644 "${SSH_KEY_DIR}/known_hosts"
    
    # 测试连接
    local test_result
    test_result=$(ssh -o StrictHostKeyChecking=no -T git@github.com 2>&1 || true)
    
    if echo "$test_result" | grep -q "successfully authenticated"; then
        log_success "GitHub SSH连接测试成功"
        return
    elif echo "$test_result" | grep -q "Hi YYY2579"; then
        log_success "GitHub SSH连接测试成功"
        return
    else
        log_warning "GitHub SSH连接测试失败"
        log_info "测试结果: $test_result"
        log_info "可能需要将SSH公钥添加到GitHub"
        return
    fi
}

# 配置Git仓库访问
configure_git_repo() {
    log_step "配置Git仓库访问..."
    
    # 如果部署目录不存在，创建它
    mkdir -p "${DEPLOY_DIR}"
    
    # 如果还没有克隆仓库，先克隆
    if [[ ! -d "${DEPLOY_DIR}/.git" ]]; then
        log_info "克隆Git仓库到部署目录..."
        
        # 尝试使用SSH方式克隆
        if ssh -o StrictHostKeyChecking=no -T git@github.com 2>&1 | grep -q "successfully authenticated\|Hi YYY2579"; then
            log_info "使用SSH方式克隆仓库..."
            git clone "${SSH_REPO_URL}" "${DEPLOY_DIR}" || {
                log_warning "SSH克隆失败，尝试HTTPS方式..."
                git clone "${REPO_URL}" "${DEPLOY_DIR}"
            }
        else
            log_info "使用HTTPS方式克隆仓库..."
            git clone "${REPO_URL}" "${DEPLOY_DIR}"
        fi
    else
        log_info "更新现有仓库配置..."
        cd "${DEPLOY_DIR}"
        
        # 检查当前远程URL
        local current_remote
        current_remote=$(git remote get-url origin 2>/dev/null || echo "")
        
        # 如果SSH可用，切换到SSH方式
        if ssh -o StrictHostKeyChecking=no -T git@github.com 2>&1 | grep -q "successfully authenticated\|Hi YYY2579"; then
            if [[ "$current_remote" != "${SSH_REPO_URL}" ]]; then
                log_info "切换到SSH远程URL..."
                git remote set-url origin "${SSH_REPO_URL}"
            fi
        else
            if [[ "$current_remote" != "${REPO_URL}" ]]; then
                log_info "使用HTTPS远程URL..."
                git remote set-url origin "${REPO_URL}"
            fi
        fi
        
        # 测试远程连接
        if ! git fetch origin >/dev/null 2>&1; then
            log_error "无法连接到Git仓库，请检查网络和认证配置"
            exit 1
        fi
    fi
    
    log_success "Git仓库配置完成"
}

# 生成GitHub配置指南
generate_github_setup_guide() {
    log_step "生成GitHub配置指南..."
    
    local public_key
    public_key=$(cat "${SSH_PUBLIC_KEY}" 2>/dev/null || echo "")
    
    cat > "${DEPLOY_DIR}/GITHUB-SETUP-GUIDE.md" << EOF
# GitHub SSH密钥配置指南

## 📋 基本信息

- **GitHub用户名**: YYY2579
- **仓库名称**: moyu
- **仓库地址**: https://github.com/YYY2579/moyu.git
- **SSH地址**: git@github.com:YYY2579/moyu.git

## 🔑 SSH公钥

\`\`\`
${public_key}
\`\`\`

## 🔧 GitHub配置步骤

### 1. 登录GitHub
访问: https://github.com/settings/keys

### 2. 添加SSH密钥
1. 点击 "New SSH key" 或 "Add SSH key"
2. 填写信息:
   - **Title**: Moyu Study Deploy Server
   - **Key**: 粘贴上面的SSH公钥
3. 点击 "Add SSH key"

### 3. 验证SSH连接
在服务器上运行:
\`\`\`bash
ssh -T git@github.com
\`\`\`

成功后会显示: "Hi YYY2579! You've successfully authenticated..."

## 🚀 使用方法

### 克隆仓库
\`\`\`bash
# SSH方式 (推荐)
git clone git@github.com:YYY2579/moyu.git

# HTTPS方式
git clone https://github.com/YYY2579/moyu.git
\`\`\`

### 推送代码
\`\`\`bash
cd moyu
git add .
git commit -m "更新内容"
git push origin main
\`\`\`

## 🔧 Git配置信息

当前Git配置:
- 用户名: \$(git config --global user.name)
- 邮箱: \$(git config --global user.email)
- 编辑器: \$(git config --global core.editor || echo "未设置")

## 📊 测试连接

### 测试SSH连接
\`\`\`bash
ssh -T git@github.com
\`\`\`

### 测试Git操作
\`\`\`bash
cd ${DEPLOY_DIR}
git fetch origin
git status
\`\`\`

## 🚨 常见问题

### 1. SSH连接被拒绝
- 确保SSH密钥已正确添加到GitHub
- 检查SSH密钥文件权限: \`chmod 600 ~/.ssh/id_rsa\`
- 检查known_hosts文件: \`ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts\`

### 2. Git推送失败
- 检查仓库权限
- 确认分支名称: \`git branch -a\`
- 使用强制推送: \`git push -f origin main\`

### 3. 权限被拒绝
- 确保是仓库所有者或协作者
- 检查SSH密钥是否匹配
- 验证GitHub账户状态

---

**配置时间**: $(date)
**服务器**: 114.132.189.90
**部署目录**: ${DEPLOY_DIR}
EOF
    
    log_success "GitHub配置指南已生成: ${DEPLOY_DIR}/GITHUB-SETUP-GUIDE.md"
}

# 显示配置结果
show_result() {
    echo ""
    echo -e "${GREEN}==============================================================================${NC}"
    echo -e "${GREEN}🔧 Git仓库配置完成！${NC}"
    echo -e "${GREEN}==============================================================================${NC}"
    echo ""
    echo -e "${CYAN}📋 配置信息:${NC}"
    echo -e "   仓库地址: ${BLUE}${REPO_URL}${NC}"
    echo -e "   SSH地址: ${BLUE}${SSH_REPO_URL}${NC}"
    echo -e "   部署目录: ${BLUE}${DEPLOY_DIR}${NC}"
    echo ""
    echo -e "${CYAN}🔑 SSH密钥:${NC}"
    echo -e "   私钥: ${YELLOW}${SSH_PRIVATE_KEY}${NC}"
    echo -e "   公钥: ${YELLOW}${SSH_PUBLIC_KEY}${NC}"
    echo ""
    echo -e "${CYAN}📖 配置指南:${NC}"
    echo -e "   详细文档: ${YELLOW}${DEPLOY_DIR}/GITHUB-SETUP-GUIDE.md${NC}"
    echo ""
    echo -e "${CYAN}🔄 测试连接:${NC}"
    echo -e "   SSH测试: ${YELLOW}ssh -T git@github.com${NC}"
    echo -e "   Git测试: ${YELLOW}cd ${DEPLOY_DIR} && git status${NC}"
    echo ""
    echo -e "${CYAN}📝 下一步:${NC}"
    echo -e "   1. 访问GitHub添加SSH密钥"
    echo -e "   2. 测试SSH连接: ${YELLOW}ssh -T git@github.com${NC}"
    echo -e "   3. 运行部署脚本: ${YELLOW}cd ${DEPLOY_DIR} && ./deploy.sh${NC}"
    echo ""
    echo -e "${GREEN}==============================================================================${NC}"
}

# 主函数
main() {
    ensure_root
    
    log_info "开始配置Git仓库..."
    
    install_git
    configure_git_user
    setup_ssh_key
    test_github_ssh
    configure_git_repo
    generate_github_setup_guide
    show_result
    
    log_success "Git仓库配置完成！"
}

# 执行主函数
main "$@"