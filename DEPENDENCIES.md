# 📦 环境依赖清单

## 🖥️ 系统要求

### 操作系统
- **名称**: CentOS 7.x
- **版本**: 7.9 或更高版本
- **架构**: x86_64

### 硬件要求
- **CPU**: 最少 2 核，推荐 4 核
- **内存**: 最少 2GB RAM，推荐 4GB RAM
- **存储**: 最少 10GB 可用空间，推荐 20GB SSD
- **网络**: 稳定的互联网连接

## 🐳 Docker 环境

### Docker CE (Community Edition)
- **版本**: 23.x (推荐 23.0.6+)
- **兼容性**: 考虑 Kubernetes 兼容性
- **安装方式**: 官方仓库安装

### Docker Compose
- **版本**: 2.5.x (指定 2.5.0)
- **安装位置**: `/usr/local/bin/docker-compose`
- **软链接**: `/usr/bin/docker-compose`

## 📚 核心软件依赖

### 基础工具
```bash
# 系统工具
curl          # HTTP 客户端工具
wget          # 文件下载工具
git           # 版本控制系统
unzip         # 解压缩工具
htop          # 系统监控工具
lsof          # 网络连接查看工具
net-tools     # 网络工具集
telnet        # 网络测试工具
vim           # 文本编辑器
```

### 容器运行时
```bash
# Docker 核心组件
docker-ce           # Docker 引擎
docker-ce-cli       # Docker 命令行工具
containerd.io       # 容器运行时
```

## 🌐 容器镜像依赖

### 数据库镜像
```yaml
image: mysql:5.7.44
- 版本: MySQL 5.7.44
- 字符集: utf8mb4
- 排序规则: utf8mb4_unicode_ci
```

### 前端镜像
```dockerfile
# 构建阶段
FROM node:20-alpine AS deps
FROM node:20-alpine AS build

# 运行阶段  
FROM nginx:1.25-alpine
- 版本: Nginx 1.25
- 变体: Alpine Linux
```

### 后端镜像
```dockerfile
# 构建阶段
FROM node:20-alpine AS builder

# 运行阶段
FROM node:20-alpine
- 版本: Node.js 20.x
- 变体: Alpine Linux
```

## 📦 Node.js 依赖

### 后端依赖 (package.json)
```json
{
  "dependencies": {
    "@fastify/cors": "^9.0.1",
    "@fastify/sensible": "^5.5.0", 
    "fastify": "^4.24.3",
    "mysql2": "^3.6.5",
    "typescript": "^5.3.2"
  },
  "devDependencies": {
    "@types/node": "^20.9.0",
    "ts-node": "^10.9.1",
    "tsx": "^4.6.0"
  }
}
```

### 前端依赖 (package.json)
```json
{
  "dependencies": {
    "vue": "^3.3.8",
    "vue-router": "^4.2.5",
    "tailwindcss": "^3.3.6",
    "autoprefixer": "^10.4.16",
    "postcss": "^8.4.32"
  },
  "devDependencies": {
    "@vitejs/plugin-vue": "^4.5.0",
    "typescript": "^5.3.2",
    "vite": "^5.0.0"
  }
}
```

## 🔧 系统配置

### 防火墙配置
```bash
# 需要开放的服务端口
http    # HTTP服务 (端口 80)
https   # HTTPS服务 (端口 443)
```

### SELinux 配置
```bash
# SELinux 布尔值
httpd_can_network_connect=1    # 允许HTTP网络连接
httpd_can_network_relay=1       # 允许HTTP网络中继
```

### Docker 配置
```json
{
  "registry-mirrors": [
    "https://docker.m.daocloud.io",
    "https://hub.ratels.pro",
    "https://docker.1panel.live",
    "https://mirror.azure.cn",
    "https://docker.unidock.top"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "exec-opts": ["native.cgroupdriver=systemd"]
}
```

## 📋 版本兼容性矩阵

| 组件 | 最低版本 | 推荐版本 | 测试版本 | 备注 |
|------|----------|----------|----------|------|
| CentOS | 7.6 | 7.9 | 7.9 | 需要启用 EOL |
| Docker | 20.10 | 23.0.6 | 23.0.6 | 考虑 K8s 兼容 |
| Docker Compose | 2.0 | 2.5.0 | 2.5.0 | 指定版本 |
| Node.js | 18.0 | 20.9.0 | 20.9.0 | 镜像版本 |
| MySQL | 5.7 | 5.7.44 | 5.7.44 | 稳定版本 |
| Nginx | 1.20 | 1.25 | 1.25 | Alpine 变体 |
| Vue.js | 3.2 | 3.3.8 | 3.3.8 | 渐进式框架 |

## 🔍 依赖检查脚本

### 系统依赖检查
```bash
#!/bin/bash
# 检查系统版本
cat /etc/redhat-release

# 检查 Docker 版本
docker --version

# 检查 Docker Compose 版本
docker-compose version

# 检查系统资源
free -h
df -h
lscpu
```

### 网络连接检查
```bash
# 检查外网连接
curl -I https://registry-1.docker.io

# 检查 DNS 解析
nslookup registry-1.docker.io

# 检查端口占用
netstat -tlnp | grep -E "(80|33066)"
```

## ⚠️ 注意事项

### 1. Docker 版本兼容性
- Docker 23.x 具有更好的 Kubernetes 兼容性
- 建议使用官方仓库安装，避免版本冲突
- 确保与 Docker Compose 版本匹配

### 2. 系统资源限制
- CentOS 7 默认内存限制可能需要调整
- 建议启用 swap 分区以应对内存不足
- 磁盘 I/O 性能影响容器启动速度

### 3. 网络配置
- 企业环境可能需要配置 HTTP 代理
- 防火墙规则需要正确配置
- SELinux 可能影响容器网络访问

### 4. 安全考虑
- 生产环境应更新默认密码
- 定期更新容器镜像
- 配置日志轮转避免磁盘满

## 🔄 升级路径

### 从旧版本升级
```bash
# 1. 备份数据
docker-compose exec mysql mysqldump -u root -p study_site > backup.sql

# 2. 更新 Docker
yum update -y docker-ce docker-ce-cli containerd.io

# 3. 重新部署
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### 版本锁定
```bash
# 锁定 Docker 版本 (避免意外升级)
yum versionlock docker-ce docker-ce-cli containerd.io

# 锁定 Docker Compose
chmod 444 /usr/local/bin/docker-compose
```

---

确保所有依赖满足要求，部署过程会更加顺利。如有问题，请参考上述版本兼容性矩阵。