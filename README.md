<<<<<<< HEAD
# moyu
摸鱼网站
=======
# 🚀 摸鱼学习站 (Moyu-Study)

一个基于Vue.js + Node.js + MySQL的在线学习管理系统，专为CentOS 7生产环境设计，支持Docker容器化部署和Webhook自动触发。

## 📋 项目概述

摸鱼学习站提供完整的在线学习解决方案，包括题库管理、每日练习、学习统计等功能，支持响应式设计和老板模式。

**仓库地址**: https://github.com/YYY2579/moyu.git  
**生产环境**: 114.132.189.90 (腾讯云)  
**部署目录**: /opt/moyu/

### 🎯 核心特性

- **📚 题库练习** - 支持按分类、难度、标签筛选题目
- **📅 每日十题** - 基于智能算法的个性化题目推荐
- **📊 学习统计** - 记录学习进度和效果分析
- **🎮 老板模式** - 一键隐藏界面，工作学习两不误
- **📱 响应式设计** - 完美适配手机、平板、电脑
- **🔄 设备隔离** - 每个设备独立的学习记录

## 🏗️ 技术架构

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   前端      │    │   后端      │    │   数据库    │
│  Vue.js     │────│  Node.js    │────│   MySQL     │
│  + Tailwind │    │  + Fastify  │    │    5.7      │
└─────────────┘    └─────────────┘    └─────────────┘
       │                   │                   │
       └───────────────────┴───────────────────┘
                    Docker容器化部署
```

### 📦 技术栈

**前端技术**:
- Vue 3.4+ - 渐进式JavaScript框架
- TypeScript 5.0+ - 类型安全的JavaScript
- Vite 5.0+ - 现代化构建工具
- TailwindCSS 3.0+ - 原子化CSS框架

**后端技术**:
- Node.js 20+ - JavaScript运行时
- Fastify 4.0+ - 高性能Web框架
- TypeScript 5.0+ - 类型安全开发
- MySQL 5.7 - 关系型数据库

**部署技术**:
- Docker 23.0+ - 容器化平台
- Docker Compose 2.5+ - 容器编排工具
- CentOS 7 - 服务器操作系统

## 🚀 快速部署

### 📋 环境要求

⚠️ **重要**: 首次部署前请仔细阅读 [详细准备指南](./PREPARATION-GUIDE.md)

**最低系统要求**:
- **操作系统**: CentOS 7.x (推荐) 或 Ubuntu 18.04+
- **CPU**: 2核心以上 (推荐4核心)
- **内存**: 4GB以上 (推荐8GB)
- **存储**: 20GB可用空间 (推荐50GB SSD)
- **网络**: 公网IP 114.132.189.90，可访问GitHub和Docker Hub

**必要端口配置**:
| 端口 | 协议 | 用途 | 说明 |
|------|------|------|------|
| 80   | TCP  | HTTP | Web服务访问 |
| 443  | TCP  | HTTPS | SSL加密访问(可选) |
| 33066| TCP  | MySQL | 数据库访问(仅限本机) |
| 9000 | TCP  | Webhook | 自动部署触发 |

**依赖软件版本**:
- **Docker**: 23.x (考虑Kubernetes兼容性)
- **Docker Compose**: 2.5.x (位于/usr/local/bin/)
- **MySQL**: 5.7.44
- **Git**: 1.8+

## 🔧 前期准备工作

### 1. Git安装和配置
```bash
# 安装Git
sudo yum install -y git  # CentOS 7
sudo apt-get install -y git  # Ubuntu

# 配置用户信息
git config --global user.name "Moyu Study Deploy"
git config --global user.email "deploy@moyu.study"

# 生成SSH密钥
ssh-keygen -t rsa -b 4096 -C "deploy@moyu.study" -N ""

# 查看公钥并添加到GitHub
cat ~/.ssh/id_rsa.pub
```

### 2. 添加SSH密钥到GitHub
1. 访问: https://github.com/settings/keys
2. 点击 "New SSH key"
3. 填写信息:
   - **Title**: Moyu Study Deploy Server
   - **Key**: 粘贴SSH公钥内容
4. 点击 "Add SSH key"

### 3. 测试连接和验证
```bash
# 测试GitHub SSH连接
ssh -T git@github.com
# 成功应显示: "Hi YYY2579! You've successfully authenticated..."

# 测试网络连通性
ping -c 1 github.com
curl -s https://github.com > /dev/null && echo "GitHub访问正常"
```

### 4. 防火墙配置
```bash
# CentOS 7
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=9000/tcp
sudo firewall-cmd --reload

# Ubuntu
sudo ufw allow 80/tcp
sudo ufw allow 9000/tcp
sudo ufw enable
```

## 🚀 生产环境部署

### 🐳 一键部署到/opt/moyu/目录

```bash
# 1. 克隆配置脚本到临时目录
git clone https://github.com/YYY2579/moyu.git /tmp/moyu-setup
cd /tmp/moyu-setup

# 2. 配置Git环境 (首次部署必需)
sudo chmod +x scripts/setup-git.sh
sudo ./scripts/setup-git.sh

# 3. 执行主部署脚本 (部署到/opt/moyu/)
sudo chmod +x deploy.sh
sudo ./deploy.sh

# 4. 配置Webhook自动部署 (可选)
sudo chmod +x scripts/setup-webhook-service.sh
sudo ./scripts/setup-webhook-service.sh
```

**部署脚本功能**:
- ✅ **全自动部署** - 部署到生产目录 `/opt/moyu/`
- ✅ **环境检查** - 验证系统要求和依赖
- ✅ **自动安装Docker** - 23.x版本，Kubernetes兼容
- ✅ **镜像加速配置** - 国内镜像源加速
- ✅ **权限管理** - 自动设置正确的文件和目录权限
- ✅ **配置生成** - 自动生成 `.env` 等配置文件
- ✅ **健康检查** - 完整的服务状态验证
- ✅ **备份机制** - 自动备份和版本管理
- ✅ **日志记录** - 详细的部署日志和错误追踪

**Webhook自动部署功能**:
- ✅ **代码推送触发** - GitHub Webhook自动触发部署
- ✅ **签名验证** - 安全的HMAC签名验证
- ✅ **并发控制** - 防止重复部署的锁机制
- ✅ **自动回滚** - 部署失败时自动回滚
- ✅ **健康检查** - 部署后自动验证服务状态

### 📦 部署配置

**预设配置**:
- **数据库密码**: `Aa123456`
- **服务器IP**: `114.132.189.90` (腾讯云)
- **数据库端口**: `33066` (仅限本机访问)
- **Web端口**: `80`
- **Docker版本**: 23.x (K8s兼容)
- **Docker Compose**: 2.5.0 (/usr/local/bin/)

**配置文件**:
- `.env` - 环境变量配置
- `deploy-config.txt` - 部署配置备份

## 🌐 访问地址

部署完成后，可通过以下地址访问：

- **🌐 主站**: `http://114.132.189.90`
- **📚 题库练习**: `http://114.132.189.90/practice`
- **📅 每日十题**: `http://114.132.189.90/daily`
- **📊 学习统计**: `http://114.132.189.90/stats`

## 🛠️ 管理命令

### 服务管理

```bash
# 查看服务状态
docker-compose ps

# 查看实时日志
docker-compose logs -f

# 查看特定服务日志
docker-compose logs api
docker-compose logs web
docker-compose logs mysql

# 重启服务
docker-compose restart

# 停止服务
docker-compose down

# 完全重置
docker-compose down -v
```

### 数据库管理

```bash
# 连接数据库
docker-compose exec mysql mysql -u root -p

# 数据库备份
docker-compose exec mysql mysqldump -u root -p study_site > backup.sql

# 恢复数据库
docker-compose exec -i mysql mysql -u root -p study_site < backup.sql
```

### 系统维护

```bash
# 清理Docker缓存
docker system prune -f

# 更新项目
git pull origin main
docker-compose build --no-cache
docker-compose up -d

# 健康检查
./scripts/quick-health-check.sh
```

## 📁 项目结构

```
moyu/
├── api/                    # 后端API服务
│   ├── src/               # 源代码目录
│   │   ├── routes/        # API路由
│   │   ├── seed/          # 数据库种子数据
│   │   └── *.ts          # 核心文件
│   ├── Dockerfile         # API容器配置
│   └── package.json      # 依赖配置
├── web/                   # 前端Web应用
│   ├── src/              # 源代码目录
│   │   ├── pages/        # 页面组件
│   │   ├── lib/          # 工具函数
│   │   └── *.vue        # 组件文件
│   ├── Dockerfile        # Web容器配置
│   └── package.json     # 依赖配置
├── deploy/               # 部署相关文件
│   ├── mysql-init/       # 数据库初始化脚本
│   └── volumes/         # 数据持久化目录
├── scripts/              # 辅助脚本
│   ├── quick-health-check.sh    # 健康检查
│   └── fix-permissions.sh      # 权限修复
├── docker-compose.yml     # 容器编排配置
├── deploy-centos7.sh     # CentOS 7部署脚本
├── .env                 # 环境变量（自动生成）
└── README.md            # 项目文档
```

## 🔧 开发环境

### 本地开发

```bash
# 1. 安装依赖
cd api && npm install
cd ../web && npm install

# 2. 启动开发环境
# 后端
cd api && npm run dev

# 前端
cd web && npm run dev
```

### 环境变量

```bash
# .env 文件示例
MYSQL_DATABASE=study_site
MYSQL_USER=yyy
MYSQL_PASSWORD=Aa123456
MYSQL_ROOT_PASSWORD=Aa123456
ADMIN_TOKEN=your_admin_token
TZ=Asia/Shanghai
SERVER_IP=114.132.189.90
```

## 📊 API接口

### 核心接口

| 方法 | 路径 | 描述 |
|------|------|------|
| GET | `/api/questions` | 获取题目列表（支持筛选） |
| GET | `/api/questions/:id` | 获取题目详情 |
| GET | `/api/daily` | 获取每日十题 |
| POST | `/api/attempts` | 提交学习记录 |
| GET | `/api/stats` | 获取学习统计 |
| GET | `/api/meta` | 获取题库元数据 |

### 管理接口

| 方法 | 路径 | 描述 |
|------|------|------|
| GET | `/api/admin/export/questions` | 导出所有题目 |
| GET | `/api/admin/export/commands` | 导出所有命令 |

**认证方式**: 通过`X-Admin-Token`请求头传递`ADMIN_TOKEN`

## 🔍 问题排查

### 常见问题

**Q: 部署后无法访问网站？**
```bash
# 检查服务状态
docker-compose ps

# 检查端口占用
netstat -tlnp | grep :80

# 检查防火墙
firewall-cmd --list-all

# 查看日志
docker-compose logs -f
```

**Q: 数据库连接失败？**
```bash
# 检查MySQL容器状态
docker-compose logs mysql

# 测试数据库连接
docker-compose exec mysql mysql -u root -pAa123456

# 检查数据库健康状态
docker inspect $(docker-compose ps -q mysql) | grep Health
```

**Q: 服务启动失败？**
```bash
# 重新构建镜像
docker-compose build --no-cache

# 清理并重新启动
docker-compose down -v
docker-compose up -d

# 查看详细错误
docker-compose logs api --tail=50
```

### 性能优化

```bash
# 监控资源使用
docker stats

# 清理未使用的资源
docker system prune -a

# 优化数据库
docker-compose exec mysql mysql -u root -pAa123456 \
  -e "OPTIMIZE TABLE study_site.questions;"
```

## 🔄 版本升级

```bash
# 1. 备份数据
docker-compose exec mysql mysqldump -u root -pAa123456 \
  study_site > backup-$(date +%Y%m%d).sql

# 2. 更新代码
git pull origin main

# 3. 重新部署
docker-compose down
docker-compose build --no-cache
docker-compose up -d

# 4. 验证部署
./scripts/quick-health-check.sh
```

## 🤝 贡献指南

1. Fork 本项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 提交 Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

## 📞 技术支持

- 📧 邮箱支持: [项目维护者邮箱]
- 🐛 问题反馈: [GitHub Issues](https://github.com/YYY2579/moyu/issues)
- 📖 文档更新: [GitHub Wiki](https://github.com/YYY2579/moyu/wiki)

---

## 🎉 开始使用

1. **克隆项目**: `git clone https://github.com/YYY2579/moyu.git`
2. **进入目录**: `cd moyu`
3. **一键部署**: `sudo ./deploy-centos7.sh`
4. **开始学习**: 访问 `http://114.132.189.90`

🎯 **祝您学习愉快！**

---

*最后更新: 2024年12月*
>>>>>>> e2d4e7b (🚀 feat: 完整的生产环境部署方案和Webhook自动化)
