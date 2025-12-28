# 📋 提交前检查清单

## 🔍 项目提交验证

在将代码提交到 https://github.com/YYY2579/moyu.git 之前，请完成以下检查：

### ✅ 核心文件检查

- [ ] `README.md` - 项目文档完整且准确
- [ ] `deploy-centos7.sh` - 部署脚本可执行且功能完整
- [ ] `docker-compose.yml` - Docker配置正确
- [ ] `DEPENDENCIES.md` - 依赖清单完整
- [ ] `PROJECT-STRUCTURE.md` - 项目结构文档更新

### 🐳 Docker配置检查

- [ ] API Dockerfile 版本兼容 (Node.js 20-alpine)
- [ ] Web Dockerfile 版本兼容 (Nginx 1.25-alpine)
- [ ] MySQL镜像版本正确 (mysql:5.7.44)
- [ ] 环境变量配置完整
- [ ] 端口配置正确 (Web:80, MySQL:33066)

### 🔧 脚本功能检查

- [ ] `deploy-centos7.sh` 脚本可执行
- [ ] `scripts/quick-health-check.sh` 健康检查功能
- [ ] `scripts/centos7-optimization.sh` 系统优化功能
- [ ] `scripts/verify-deployment.sh` 部署验证功能

### 📖 文档完整性检查

- [ ] 所有软件版本号正确标注
- [ ] CentOS 7 特殊配置说明
- [ ] 腾讯云服务器IP (114.132.189.90) 正确
- [ ] 数据库密码 (Aa123456) 统一设置
- [ ] Docker Compose 2.5 路径 (/usr/local/bin/) 明确

### 🔒 安全配置检查

- [ ] MySQL端口仅限本机访问 (127.0.0.1:33066)
- [ ] SELinux配置说明
- [ ] 防火墙端口配置说明
- [ ] 生产环境安全建议

### 🧪 功能测试检查

- [ ] API健康检查端点正常
- [ ] 题库筛选功能正常
- [ ] 每日十题功能正常
- [ ] 老板模式快捷键 (Alt+B) 正常
- [ ] 响应式设计适配

### 📦 依赖版本兼容性

- [ ] Docker 23.x (Kubernetes兼容)
- [ ] Docker Compose 2.5.0
- [ ] Node.js 20.x
- [ ] MySQL 5.7.44
- [ ] Vue.js 3.3+
- [ ] CentOS 7.x

### 🚀 部署流程检查

- [ ] 一键部署流程完整
- [ ] 错误处理机制完善
- [ ] 日志输出清晰
- [ ] 健康检查全面
- [ ] 配置生成自动化

### 🎯 服务器特定检查

- [ ] 腾讯云IP地址正确 (114.132.189.90)
- [ ] CentOS 7 特定优化
- [ ] 国内镜像源配置
- [ ] 系统资源要求说明

## 🔄 提交流程

### 1. 本地验证
```bash
# 检查脚本权限
ls -la deploy-centos7.sh scripts/*.sh

# 检查配置文件
cat .env.example
cat docker-compose.yml

# 运行语法检查
bash -n deploy-centos7.sh
bash -n scripts/*.sh
```

### 2. Git提交
```bash
# 添加所有文件
git add .

# 查看状态
git status

# 提交代码
git commit -m "feat: 完成CentOS 7专用部署配置

- 添加专用部署脚本 deploy-centos7.sh
- 配置Docker 23.x和Docker Compose 2.5.0
- 优化CentOS 7系统配置
- 完善项目文档和依赖说明
- 删除不必要的Windows相关文件
- 设置服务器IP为114.132.189.90
- 配置数据库密码为Aa123456"

# 推送到远程仓库
git push origin main
```

### 3. 部署验证
```bash
# 在服务器上拉取最新代码
git clone https://github.com/YYY2579/moyu.git
cd moyu

# 运行部署验证
sudo chmod +x deploy-centos7.sh
sudo ./deploy-centos7.sh

# 运行部署验证脚本
sudo chmod +x scripts/verify-deployment.sh
sudo ./scripts/verify-deployment.sh
```

## ⚠️ 注意事项

### 🔐 敏感信息
- 不要在代码中硬编码真实的敏感信息
- 使用环境变量管理密码和token
- `.env` 文件应添加到 `.gitignore`

### 🐛 常见问题
1. **脚本权限**: 确保所有 `.sh` 文件有执行权限
2. **版本冲突**: 检查Docker和Docker Compose版本兼容性
3. **网络问题**: 确保服务器能访问Docker镜像仓库
4. **权限问题**: 确保以root权限运行部署脚本

### 📋 版本控制
- 使用语义化版本号
- 在提交信息中清楚描述变更内容
- 重要的功能变更需要更新文档

## 📞 问题反馈

如果在部署过程中遇到问题：

1. 查看部署日志输出
2. 运行健康检查脚本
3. 检查系统资源使用情况
4. 查看GitHub Issues
5. 创建新的Issue并提供详细信息

---

**提交前请务必完成以上所有检查项！**

*最后更新: 2024年12月28日*