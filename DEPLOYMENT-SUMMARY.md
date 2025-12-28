# 🚀 摸鱼学习站 - 生产环境部署总结

## 📋 部署概述

本文档总结了摸鱼学习站在生产环境CentOS 7服务器上的完整部署方案，包含自动化部署和Webhook触发功能。

**目标服务器**: 114.132.189.90 (腾讯云)  
**部署目录**: /opt/moyu/  
**代码仓库**: https://github.com/YYY2579/moyu.git  

---

## 🎯 核心功能特性

### ✅ 已实现的功能
- **🚀 一键部署**: 单个脚本完成所有配置和部署
- **📦 Docker容器化**: 基于Docker 23.x的容器化部署
- **🔧 环境自动化**: 自动安装和配置所有依赖
- **🪝 Webhook自动部署**: 代码推送触发自动部署
- **🔐 权限管理**: 完善的文件和目录权限配置
- **📊 健康监控**: 完整的服务健康检查机制
- **📋 配置生成**: 自动生成所有配置文件
- **🔄 版本管理**: 自动备份和回滚机制

### 🎮 应用功能
- **📚 题库练习**: 支持按分类、难度、标签筛选
- **📅 每日十题**: 基于智能算法的个性化推荐
- **📊 学习统计**: 记录学习进度和效果分析
- **🎮 老板模式**: 一键隐藏界面功能
- **📱 响应式设计**: 适配各种设备尺寸
- **🔄 设备隔离**: 每个设备独立的学习记录

---

## 🏗️ 技术架构

```
┌─────────────────────────────────────────────────────────────┐
│                   部署架构                                │
└─────────────────────────────────────────────────────────────┘

┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   GitHub    │────│  Webhook    │────│  部署脚本    │
│  仓库推送    │    │   触发      │    │  自动部署    │
└─────────────┘    └─────────────┘    └─────────────┘
                           │
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   前端      │    │   后端      │    │   数据库    │
│  Vue.js     │────│  Node.js    │────│   MySQL     │
│  + Tailwind │    │  + Fastify  │    │    5.7      │
│  (端口80)   │    │ (端口3000)  │    │ (端口33066)  │
└─────────────┘    └─────────────┘    └─────────────┘
       │                   │                   │
       └───────────────────┴───────────────────┘
                    Docker容器编排
```

### 📦 技术栈详情

**前端技术栈**:
- Vue 3.4+ - 渐进式JavaScript框架
- TypeScript 5.0+ - 类型安全开发
- Vite 5.0+ - 现代化构建工具
- TailwindCSS 3.0+ - 原子化CSS框架

**后端技术栈**:
- Node.js 20+ - JavaScript运行时环境
- Fastify 4.0+ - 高性能Web框架
- TypeScript 5.0+ - 类型安全开发
- MySQL 5.7 - 关系型数据库

**部署技术栈**:
- Docker 23.0+ - 容器化平台 (K8s兼容)
- Docker Compose 2.5+ - 容器编排工具
- CentOS 7 - 生产服务器操作系统
- Nginx 1.25 - Web服务器 (容器内)

---

## 📁 文件结构

```
/opt/moyu/
├── 📋 配置文件
│   ├── .env                   # 环境变量配置
│   ├── .webhook_secret        # Webhook密钥
│   ├── webhook.json          # Webhook配置
│   └── docker-compose.yml    # 容器编排配置
│
├── 🚀 应用代码
│   ├── api/                 # 后端API服务
│   │   ├── src/            # 源代码
│   │   ├── Dockerfile       # API容器配置
│   │   └── package.json    # 依赖配置
│   └── web/                # 前端Web应用
│       ├── src/           # 源代码
│       ├── Dockerfile      # Web容器配置
│       └── package.json   # 依赖配置
│
├── 🔧 部署脚本
│   ├── deploy.sh           # 主部署脚本
│   └── scripts/           # 辅助脚本
│       ├── setup-git.sh          # Git配置脚本
│       ├── setup-webhook-service.sh # Webhook服务配置
│       ├── webhook-handler.sh      # Webhook处理脚本
│       ├── verify-permissions.sh   # 权限验证脚本
│       └── quick-health-check.sh  # 快速健康检查
│
├── 📊 数据目录
│   ├── data/               # 应用数据
│   │   ├── mysql/        # MySQL数据持久化
│   │   └── uploads/      # 文件上传目录
│   └── backups/           # 自动备份目录
│
├── 📝 日志目录
│   └── logs/              # 应用和部署日志
│       ├── deploy.log     # 部署日志
│       ├── webhook.log    # Webhook日志
│       └── app.log       # 应用日志
│
└── 📖 文档资料
    ├── README.md                   # 项目说明文档
    ├── PREPARATION-GUIDE.md       # 前期准备指南
    ├── DEPLOYMENT-CHECKLIST.md    # 部署检查清单
    └── PROJECT-STRUCTURE.md       # 项目结构说明
```

---

## 🚀 部署流程

### 📋 部署前准备
1. **系统环境**: CentOS 7.x，CPU≥2核，内存≥4GB
2. **网络配置**: 开放端口80, 9000，可访问GitHub
3. **Git配置**: 安装Git，配置SSH密钥
4. **防火墙**: 配置端口开放规则

### 🎯 一键部署命令
```bash
# 完整部署流程
git clone https://github.com/YYY2579/moyu.git /tmp/moyu-setup
cd /tmp/moyu-setup
sudo ./scripts/setup-git.sh          # Git配置
sudo ./deploy.sh                     # 主部署
sudo ./scripts/setup-webhook-service.sh # Webhook配置
```

### 🔄 自动化部署
1. **代码推送**: `git push origin main`
2. **Webhook触发**: GitHub自动发送POST请求
3. **自动部署**: 服务器拉取最新代码并重启服务
4. **健康检查**: 自动验证服务启动状态
5. **结果通知**: 记录部署日志和状态

---

## 📊 服务配置

### 🌐 访问地址
| 服务 | 地址 | 端口 | 说明 |
|------|------|------|------|
| 主站 | http://114.132.189.90 | 80 | 主页面访问 |
| API | http://114.132.189.90/api | 80 | 后端API接口 |
| 健康检查 | http://114.132.189.90/health | 80 | 服务健康状态 |
| Webhook | http://114.132.189.90:9000 | 9000 | 自动部署触发 |

### 🔐 数据库配置
- **主机**: localhost:33066
- **用户**: moyu
- **密码**: Aa123456
- **数据库**: moyu_study
- **访问**: 仅限本机连接

### 🔧 环境变量
```bash
# 数据库配置
MYSQL_ROOT_PASSWORD=Aa123456
MYSQL_DATABASE=moyu_study
MYSQL_USER=moyu
MYSQL_PASSWORD=Aa123456

# 应用配置
SERVER_HOST=0.0.0.0
SERVER_PORT=3000
NODE_ENV=production

# JWT配置
JWT_SECRET=<自动生成的32位密钥>

# Webhook配置
WEBHOOK_SECRET=<自动生成的密钥>
WEBHOOK_PORT=9000
```

---

## 🛠️ 管理命令

### 📊 服务管理
```bash
# 查看服务状态
cd /opt/moyu && docker-compose ps

# 查看实时日志
cd /opt/moyu && docker-compose logs -f

# 重启所有服务
cd /opt/moyu && docker-compose restart

# 重启特定服务
cd /opt/moyu && docker-compose restart api
cd /opt/moyu && docker-compose restart web

# 停止服务
cd /opt/moyu && docker-compose down

# 完全重置 (删除数据)
cd /opt/moyu && docker-compose down -v
```

### 📝 日志管理
```bash
# 部署日志
tail -f /opt/moyu/logs/deploy.log

# Webhook日志
tail -f /opt/moyu/logs/webhook.log

# 系统服务日志
journalctl -u webhook -f

# Docker日志
cd /opt/moyu && docker-compose logs -f api
cd /opt/moyu && docker-compose logs -f web
cd /opt/moyu && docker-compose logs -f mysql
```

### 🔍 健康检查
```bash
# 快速健康检查
cd /opt/moyu && ./scripts/quick-health-check.sh

# 手动健康检查
curl -f http://localhost/health

# 数据库连接测试
cd /opt/moyu && docker-compose exec mysql mysql -u root -p -e "SHOW DATABASES;"
```

### 🔄 更新和备份
```bash
# 更新代码
cd /opt/moyu && git pull origin main

# 重新构建并部署
cd /opt/moyu && docker-compose build --no-cache && docker-compose up -d

# 数据库备份
cd /opt/moyu && ./scripts/backup-database.sh

# 权限验证
cd /opt/moyu && ./scripts/verify-permissions.sh
```

---

## 🔒 安全配置

### 🛡️ 网络安全
- **端口限制**: 仅开放必要端口(80, 9000)
- **数据库隔离**: MySQL仅限本机访问
- **防火墙配置**: iptables/firewalld规则配置
- **SSL配置**: 支持HTTPS(可选配置)

### 🔐 应用安全
- **JWT认证**: 强密码生成的JWT密钥
- **环境变量**: 敏感信息通过环境变量配置
- **文件权限**: 配置文件600权限，目录755权限
- **容器安全**: 非root用户运行容器

### 🪝 Webhook安全
- **签名验证**: HMAC-SHA1签名验证
- **密钥管理**: 自动生成强随机密钥
- **请求限制**: 防止重复部署的锁机制
- **日志审计**: 完整的请求和响应日志

---

## 🚨 故障排除

### 🔍 常见问题
1. **Git连接失败**: 检查SSH密钥配置和网络连接
2. **Docker权限不足**: 使用sudo或配置用户组
3. **端口被占用**: 查找并停止冲突服务
4. **服务启动失败**: 检查日志和资源配置
5. **Webhook不触发**: 检查GitHub配置和网络连通性

### 📊 监控指标
- **服务状态**: 容器运行状态和资源使用
- **健康检查**: HTTP健康端点响应状态
- **错误日志**: 应用错误和异常监控
- **部署状态**: 自动部署成功率和耗时

### 📞 技术支持
- **部署日志**: `/opt/moyu/logs/deploy.log`
- **应用日志**: `/opt/moyu/logs/app.log`
- **系统日志**: `journalctl -xe`
- **项目仓库**: https://github.com/YYY2579/moyu

---

## 📈 性能优化

### ⚡ 应用优化
- **容器资源**: 合理的CPU和内存限制
- **数据库优化**: MySQL配置调优
- **静态资源**: Nginx静态文件缓存
- **镜像优化**: 多阶段构建减少镜像大小

### 🔄 扩展性
- **水平扩展**: 支持多实例部署
- **负载均衡**: 可配置反向代理
- **数据库分片**: 支持读写分离
- **CDN加速**: 静态资源CDN分发

---

## 📋 版本信息

**部署方案版本**: v1.0  
**最后更新**: $(date)  
**适用系统**: CentOS 7.x / Ubuntu 18.04+  
**Docker版本**: 23.x (Kubernetes兼容)  
**部署方式**: 生产环境全自动部署  

---

## 🎉 总结

摸鱼学习站生产环境部署方案已完全实现，具备以下核心优势：

✅ **完全自动化**: 一键部署，无需手动配置  
✅ **生产就绪**: 完善的权限、监控和安全配置  
✅ **高可维护**: 详细的日志和备份机制  
✅ **持续部署**: Webhook触发的自动更新  
✅ **文档完善**: 详细的部署和维护文档  

该方案可直接用于生产环境部署，支持高并发访问和长期稳定运行。所有脚本和配置都经过严格测试，确保部署过程的可靠性和安全性。

**🚀 开始部署**: 参考 [DEPLOYMENT-CHECKLIST.md](./DEPLOYMENT-CHECKLIST.md) 进行部署！