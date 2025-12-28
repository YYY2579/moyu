# 🚀 摸鱼学习站 - 前期准备工作指南

## 📋 概述

本指南详细说明了部署摸鱼学习站到生产环境所需的所有前期准备工作，确保部署过程顺畅无遗漏。

**目标服务器**: 114.132.189.90 (腾讯云)  
**部署目录**: /opt/moyu/  
**仓库地址**: https://github.com/YYY2579/moyu.git  

---

## 🔧 1. 服务器基础准备

### 1.1 服务器要求

**最低配置**:
- **CPU**: 2核心
- **内存**: 4GB RAM
- **存储**: 20GB 可用空间
- **网络**: 公网IP，开放必要端口

**推荐配置**:
- **CPU**: 4核心
- **内存**: 8GB RAM  
- **存储**: 50GB SSD
- **网络**: 100Mbps带宽

### 1.2 操作系统要求

**支持的系统**:
- ✅ CentOS 7.x (推荐)
- ✅ Ubuntu 18.04/20.04/22.04
- ✅ RHEL 7.x/8.x

**系统检查**:
```bash
# 检查系统版本
cat /etc/redhat-release  # CentOS/RHEL
cat /etc/os-release      # Ubuntu

# 检查内核版本
uname -r

# 检查系统资源
free -h
df -h
nproc
```

### 1.3 网络端口配置

**需要开放的端口**:
| 端口 | 协议 | 用途 | 说明 |
|------|------|------|------|
| 80   | TCP  | HTTP | Web服务访问 |
| 443  | TCP  | HTTPS | SSL加密访问(可选) |
| 33066| TCP  | MySQL | 数据库访问(仅限本机) |
| 9000 | TCP  | Webhook | 自动部署触发 |

**防火墙配置**:
```bash
# CentOS 7 (firewalld)
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --permanent --add-port=9000/tcp
sudo firewall-cmd --reload

# Ubuntu (ufw)
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 9000/tcp
sudo ufw enable
```

---

## 🔑 2. Git安装和配置

### 2.1 Git安装步骤

**CentOS 7**:
```bash
# 安装Git
sudo yum install -y git

# 验证安装
git --version
```

**Ubuntu**:
```bash
# 更新包列表
sudo apt-get update

# 安装Git
sudo apt-get install -y git

# 验证安装
git --version
```

### 2.2 Git配置

**配置用户信息**:
```bash
# 配置全局用户信息
git config --global user.name "Moyu Study Deploy"
git config --global user.email "deploy@moyu.study"

# 配置默认编辑器
git config --global core.editor vim

# 配置自动换行处理
git config --global core.autocrlf input  # Linux
git config --global core.autocrlf true   # Windows

# 查看配置
git config --list
```

### 2.3 SSH密钥配置方法

**生成SSH密钥**:
```bash
# 生成新的SSH密钥对
ssh-keygen -t rsa -b 4096 -C "deploy@moyu.study"

# 设置密钥文件权限
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub
chmod 700 ~/.ssh

# 添加GitHub到known_hosts
ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts
chmod 644 ~/.ssh/known_hosts
```

**查看SSH公钥**:
```bash
# 显示公钥内容
cat ~/.ssh/id_rsa.pub
```

**在GitHub添加SSH密钥**:
1. 访问: https://github.com/settings/keys
2. 点击 "New SSH key"
3. 填写信息:
   - **Title**: Moyu Study Deploy Server
   - **Key**: 粘贴公钥内容
4. 点击 "Add SSH key"

**测试SSH连接**:
```bash
# 测试GitHub SSH连接
ssh -T git@github.com

# 成功会显示: "Hi YYY2579! You've successfully authenticated..."
```

---

## 🪝 3. Webhook设置要求

### 3.1 Webhook服务要求

**系统要求**:
- 可访问公网的HTTP服务
- 固定IP地址 (114.132.189.90)
- 端口9000对外开放

**依赖服务**:
- Docker (已安装并运行)
- Git (已配置SSH密钥)
- 系统权限 (root或sudo)

### 3.2 GitHub Webhook配置

**配置步骤**:
1. 登录GitHub: https://github.com/YYY2579/moyu/settings/hooks
2. 点击 "Add webhook"
3. 填写配置信息:
   - **Payload URL**: `http://114.132.189.90:9000/hooks/auto-deploy`
   - **Content type**: `application/json`
   - **Secret**: (自动生成的密钥，见部署脚本)
   - **SSL verification**: 勾选 (如使用HTTPS)
4. 选择触发事件:
   - ✅ Just the `push` event
5. 点击 "Add webhook"

**Webhook URL格式**:
```
HTTP:  http://114.132.189.90:9000/hooks/auto-deploy
HTTPS: https://114.132.189.90:9000/hooks/auto-deploy
```

**安全配置**:
- 使用强随机密钥 (部署脚本自动生成)
- 配置防火墙规则限制访问
- 定期轮换Webhook密钥

### 3.3 Webhook测试

**测试方法**:
1. 在GitHub Webhook页面点击 "Recent Deliveries"
2. 查看推送记录和响应状态
3. 确保状态为 "200 OK"

**手动测试**:
```bash
# 推送测试代码到仓库
git add .
git commit -m "测试webhook自动部署"
git push origin main

# 查看webhook日志
journalctl -u webhook -f

# 查看部署日志
tail -f /opt/moyu/logs/webhook.log
```

---

## 🔐 4. 服务器目录权限配置

### 4.1 创建部署目录

**目录结构**:
```
/opt/moyu/
├── .git/                    # Git仓库
├── .env                     # 环境配置
├── .webhook_secret          # Webhook密钥
├── api/                     # 后端代码
├── web/                     # 前端代码
├── deploy/                  # 部署相关文件
├── scripts/                 # 部署脚本
├── logs/                    # 日志目录
├── data/                    # 数据目录
│   ├── mysql/              # MySQL数据
│   └── uploads/            # 上传文件
├── backups/                 # 备份目录
├── docker-compose.yml       # Docker编排文件
└── deploy.sh               # 主部署脚本
```

**创建目录**:
```bash
# 创建主部署目录
sudo mkdir -p /opt/moyu

# 创建子目录
sudo mkdir -p /opt/moyu/{logs,data/{mysql,uploads},backups,scripts}

# 设置目录权限
sudo chmod 755 /opt/moyu
sudo chmod -R 755 /opt/moyu/scripts
sudo chmod -R 755 /opt/moyu/logs
```

### 4.2 文件权限配置

**目录权限设置**:
```bash
# 设置所有者为root
sudo chown -R root:root /opt/moyu

# 设置目录权限
sudo find /opt/moyu -type d -exec chmod 755 {} \;

# 设置文件权限
sudo find /opt/moyu -type f -exec chmod 644 {} \;

# 设置脚本执行权限
sudo chmod +x /opt/moyu/deploy.sh
sudo chmod +x /opt/moyu/scripts/*.sh
```

**特殊权限文件**:
```bash
# SSH密钥权限
sudo chmod 600 /opt/moyu/.webhook_secret

# 环境配置文件
sudo chmod 600 /opt/moyu/.env

# 日志目录可写
sudo chmod 755 /opt/moyu/logs
sudo chmod 644 /opt/moyu/logs/*
```

### 4.3 SELinux配置 (CentOS 7)

**检查SELinux状态**:
```bash
# 查看SELinux状态
getenforce
sestatus
```

**配置SELinux策略**:
```bash
# 临时禁用SELinux (重启后恢复)
sudo setenforce 0

# 永久禁用SELinux (需要重启)
sudo sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

# 或者设置SELinux为宽松模式
sudo setenforce Permissive
```

**Docker SELinux配置**:
```bash
# 允许Docker访问目录
sudo semanage fcontext -a -t svirt_sandbox_file_t "/opt/moyu/data(/.*)?"
sudo restorecon -R /opt/moyu/data

# 允许Docker绑定端口
sudo semanage port -a -t http_port_t -p tcp 80
sudo semanage port -a -t http_port_t -p tcp 9000
```

---

## 🐳 5. Docker环境准备

### 5.1 Docker版本要求

**推荐版本**:
- **Docker Engine**: 23.x 或更高 (Kubernetes兼容)
- **Docker Compose**: 2.5.0 或更高

**检查当前版本**:
```bash
# 检查Docker版本
docker --version
docker info

# 检查Docker Compose
docker-compose --version
# 或
docker compose version
```

### 5.2 Docker安装 (CentOS 7)

**安装步骤**:
```bash
# 安装依赖
sudo yum install -y yum-utils device-mapper-persistent-data lvm2

# 添加Docker仓库
sudo yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

# 安装Docker
sudo yum install -y docker-ce docker-ce-cli containerd.io

# 启动并启用Docker
sudo systemctl start docker
sudo systemctl enable docker

# 添加用户到docker组 (可选)
sudo usermod -aG docker $USER
```

### 5.3 Docker Compose安装

**方法一: 使用系统包管理器**:
```bash
# CentOS 7
sudo yum install -y docker-compose-plugin

# Ubuntu
sudo apt-get install -y docker-compose-plugin
```

**方法二: 手动下载**:
```bash
# 下载Docker Compose 2.5.0
sudo curl -L "https://github.com/docker/compose/releases/download/v2.5.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# 设置执行权限
sudo chmod +x /usr/local/bin/docker-compose

# 验证安装
docker-compose --version
```

### 5.4 Docker镜像加速配置

**配置镜像加速器**:
```bash
# 创建Docker配置目录
sudo mkdir -p /etc/docker

# 配置镜像加速
sudo tee /etc/docker/daemon.json > /dev/null << 'EOF'
{
  "registry-mirrors": [
    "https://mirror.ccs.tencentyun.com",
    "https://docker.mirrors.ustc.edu.cn",
    "https://registry.docker-cn.com"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  }
}
EOF

# 重启Docker服务
sudo systemctl daemon-reload
sudo systemctl restart docker
```

---

## 🔍 6. 环境验证清单

### 6.1 系统环境检查

**检查脚本**:
```bash
#!/bin/bash
echo "=== 系统环境检查 ==="

# 检查操作系统
echo "操作系统: $(cat /etc/redhat-release 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME)"
echo "内核版本: $(uname -r)"
echo "系统架构: $(uname -m)"

# 检查资源
echo "内存信息: $(free -h | grep Mem)"
echo "磁盘空间: $(df -h / | tail -1)"
echo "CPU核心: $(nproc)"

# 检查网络
echo "公网IP: $(curl -s ifconfig.me 2>/dev/null || echo "无法获取")"
echo "DNS解析: $(nslookup github.com 2>/dev/null | grep -A1 "Server:" || echo "DNS异常")"
```

### 6.2 服务状态检查

**检查服务**:
```bash
#!/bin/bash
echo "=== 服务状态检查 ==="

# 检查Docker
if command -v docker >/dev/null 2>&1; then
    echo "Docker版本: $(docker --version)"
    echo "Docker状态: $(systemctl is-active docker)"
    echo "Docker信息: $(docker info --format '{{.ServerVersion}}' 2>/dev/null || echo "无法获取")"
else
    echo "Docker: 未安装"
fi

# 检查Docker Compose
if command -v docker-compose >/dev/null 2>&1; then
    echo "Docker Compose: $(docker-compose --version)"
elif docker compose version >/dev/null 2>&1; then
    echo "Docker Compose: $(docker compose version)"
else
    echo "Docker Compose: 未安装"
fi

# 检查Git
if command -v git >/dev/null 2>&1; then
    echo "Git版本: $(git --version)"
    echo "Git配置: $(git config --global user.name) <$(git config --global user.email)>"
else
    echo "Git: 未安装"
fi
```

### 6.3 网络连通性检查

**网络测试**:
```bash
#!/bin/bash
echo "=== 网络连通性检查 ==="

# 测试基本网络
echo "本地网络: $(ping -c 1 8.8.8.8 >/dev/null 2>&1 && echo "正常" || echo "异常")"

# 测试GitHub连接
echo "GitHub连接: $(ping -c 1 github.com >/dev/null 2>&1 && echo "正常" || echo "异常")"

# 测试HTTPS
echo "HTTPS访问: $(curl -s -o /dev/null -w "%{http_code}" https://github.com | grep -q "200" && echo "正常" || echo "异常")"

# 测试Docker Hub
echo "Docker Hub: $(curl -s -o /dev/null -w "%{http_code}" https://registry.hub.docker.com | grep -q "200" && echo "正常" || echo "异常")"

# 检查端口占用
echo "80端口占用: $(netstat -tuln | grep ":80 " && echo "被占用" || echo "空闲")"
echo "9000端口占用: $(netstat -tuln | grep ":9000 " && echo "被占用" || echo "空闲")"
```

---

## 📋 7. 部署前检查清单

### 7.1 必需项检查 ✅

- [ ] **服务器配置**: CPU≥2核，内存≥4GB，存储≥20GB
- [ ] **操作系统**: CentOS 7.x 或 Ubuntu 18.04+
- [ ] **网络连通**: 可访问GitHub和Docker Hub
- [ ] **防火墙配置**: 开放端口80, 443, 9000
- [ ] **Git安装**: 已安装并配置用户信息
- [ ] **SSH密钥**: 已生成并添加到GitHub
- [ ] **Docker**: 版本23.x已安装并运行
- [ ] **Docker Compose**: 版本2.5.0+已安装
- [ ] **目录权限**: /opt/moyu目录及子目录权限正确
- [ ] **SELinux**: 已配置或禁用

### 7.2 可选项配置 🔧

- [ ] **SSL证书**: 配置HTTPS访问
- [ ] **监控告警**: 配置服务监控
- [ ] **日志收集**: 配置集中日志
- [ ] **备份策略**: 配置自动备份
- [ ] **负载均衡**: 配置多实例部署

### 7.3 安全加固 🔒

- [ ] **系统更新**: 已安装最新安全补丁
- [ ] **防火墙**: 最小化开放端口
- [ ] **SSH配置**: 禁用密码登录，仅允许密钥登录
- [ ] **用户权限**: 避免使用root日常操作
- [ ] **文件权限**: 敏感文件权限正确设置

---

## 🚀 8. 快速部署流程

### 8.1 一键部署命令

**完整的部署流程**:
```bash
# 1. 克隆配置脚本仓库
git clone https://github.com/YYY2579/moyu.git /tmp/moyu-setup
cd /tmp/moyu-setup

# 2. 设置脚本执行权限
chmod +x scripts/setup-git.sh
chmod +x scripts/setup-webhook-service.sh
chmod +x deploy.sh

# 3. 配置Git和SSH
sudo ./scripts/setup-git.sh

# 4. 执行主部署脚本
sudo ./deploy.sh

# 5. 配置Webhook自动部署
sudo ./scripts/setup-webhook-service.sh

# 6. 验证部署
curl -f http://114.132.189.90/health
```

### 8.2 分步部署命令

**步骤1: 基础环境配置**
```bash
# 安装基础依赖
sudo yum update -y
sudo yum install -y curl wget git unzip

# 安装Docker
curl -fsSL https://get.docker.com | sh
sudo systemctl start docker
sudo systemctl enable docker

# 安装Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.5.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

**步骤2: Git配置**
```bash
# 配置Git
git config --global user.name "Moyu Study Deploy"
git config --global user.email "deploy@moyu.study"

# 生成SSH密钥
ssh-keygen -t rsa -b 4096 -C "deploy@moyu.study" -N ""

# 查看公钥并添加到GitHub
cat ~/.ssh/id_rsa.pub
```

**步骤3: 项目部署**
```bash
# 创建部署目录
sudo mkdir -p /opt/moyu
cd /opt/moyu

# 克隆项目
git clone https://github.com/YYY2579/moyu.git .

# 执行部署
sudo ./deploy.sh
```

---

## 🆘 9. 常见问题解决

### 9.1 Git相关问题

**问题**: SSH连接被拒绝
```
Permission denied (publickey).
fatal: Could not read from remote repository.
```

**解决方案**:
```bash
# 检查SSH密钥
ls -la ~/.ssh/id_rsa*

# 测试SSH连接
ssh -T git@github.com

# 重新生成密钥
ssh-keygen -t rsa -b 4096 -C "deploy@moyu.study"

# 检查GitHub密钥设置
# 访问: https://github.com/settings/keys
```

### 9.2 Docker相关问题

**问题**: Docker权限不足
```
permission denied while trying to connect to the Docker daemon socket
```

**解决方案**:
```bash
# 使用sudo运行Docker命令
sudo docker ps

# 或将用户添加到docker组
sudo usermod -aG docker $USER
newgrp docker

# 重启Docker服务
sudo systemctl restart docker
```

**问题**: 镜像拉取失败
```
error pulling image configuration: Get https://...
```

**解决方案**:
```bash
# 配置镜像加速器
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json > /dev/null << 'EOF'
{
  "registry-mirrors": [
    "https://mirror.ccs.tencentyun.com",
    "https://docker.mirrors.ustc.edu.cn"
  ]
}
EOF

sudo systemctl restart docker
```

### 9.3 权限相关问题

**问题**: 目录权限不足
```
Permission denied: '/opt/moyu'
```

**解决方案**:
```bash
# 设置正确的目录权限
sudo chown -R root:root /opt/moyu
sudo chmod -R 755 /opt/moyu
sudo chmod +x /opt/moyu/*.sh
sudo chmod +x /opt/moyu/scripts/*.sh
```

**问题**: SELinux阻止访问
```
Permission denied: SELinux is preventing...
```

**解决方案**:
```bash
# 临时禁用SELinux
sudo setenforce 0

# 永久禁用(重启后生效)
sudo sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

# 或设置SELinux策略
sudo semanage fcontext -a -t svirt_sandbox_file_t "/opt/moyu(/.*)?"
sudo restorecon -R /opt/moyu
```

### 9.4 网络相关问题

**问题**: 端口被占用
```
bind: address already in use
```

**解决方案**:
```bash
# 查找占用端口的进程
sudo netstat -tulnp | grep :80
sudo lsof -i :80

# 停止占用端口的服务
sudo systemctl stop nginx
sudo systemctl stop apache2

# 或修改端口配置
# 编辑 /opt/moyu/docker-compose.yml
```

**问题**: 防火墙阻止访问
```
Connection timed out
```

**解决方案**:
```bash
# CentOS 7
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=9000/tcp
sudo firewall-cmd --reload

# Ubuntu
sudo ufw allow 80/tcp
sudo ufw allow 9000/tcp
sudo ufw reload
```

---

## 📞 10. 技术支持

### 10.1 获取帮助

**日志文件位置**:
- 部署日志: `/opt/moyu/logs/deploy.log`
- Webhook日志: `/opt/moyu/logs/webhook.log`
- Docker日志: `cd /opt/moyu && docker-compose logs -f`

**系统服务状态**:
```bash
# Docker状态
systemctl status docker

# Webhook状态
systemctl status webhook

# 网络状态
netstat -tulnp
```

### 10.2 联系方式

**项目仓库**: https://github.com/YYY2579/moyu  
**问题反馈**: 提交GitHub Issues  
**文档更新**: 提交Pull Request

---

**准备指南版本**: v1.0  
**最后更新**: $(date)  
**适用环境**: CentOS 7 / Ubuntu 18.04+  

完成所有准备工作后，即可开始执行部署脚本进行正式部署！🚀