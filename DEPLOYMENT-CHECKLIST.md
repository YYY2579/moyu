# 🚀 摸鱼学习站 - 生产环境部署检查清单

## 📋 部署前最终检查清单

在执行生产环境部署前，请逐项检查以下内容，确保所有条件都已满足。

---

## 🔧 系统环境检查 ✅

### 基础环境
- [ ] **服务器配置**: CPU≥2核，内存≥4GB，存储≥20GB
- [ ] **操作系统**: CentOS 7.x 或 Ubuntu 18.04+
- [ ] **网络连接**: 可访问GitHub和Docker Hub
- [ ] **公网IP**: 114.132.189.90 (腾讯云)

### 系统更新
- [ ] **系统更新**: `sudo yum update -y` 或 `sudo apt-get update && sudo apt-get upgrade -y`
- [ ] **重启系统**: (如有内核更新需要重启)
- [ ] **检查时区**: `timedatectl status` 或 `date`
- [ ] **检查DNS**: `nslookup github.com`

---

## 🔑 Git和SSH配置 ✅

### Git安装和配置
- [ ] **Git安装**: `git --version` 返回版本信息
- [ ] **Git用户配置**: `git config --list` 显示用户名和邮箱
- [ ] **SSH密钥生成**: `ls -la ~/.ssh/id_rsa*` 显示密钥文件
- [ ] **SSH密钥权限**: 私钥600权限，公钥644权限

### GitHub配置
- [ ] **SSH公钥已添加到GitHub**: 访问 https://github.com/settings/keys
- [ ] **SSH连接测试**: `ssh -T git@github.com` 返回成功信息
- [ ] **仓库克隆测试**: `git clone git@github.com:YYY2579/moyu.git /tmp/test`

---

## 🌐 网络和防火墙配置 ✅

### 端口配置
- [ ] **端口80开放**: HTTP访问
- [ ] **端口443开放**: HTTPS访问(可选)
- [ ] **端口9000开放**: Webhook自动部署
- [ ] **端口33066**: MySQL(仅本机访问)

### 防火墙配置
**CentOS 7 (firewalld)**:
- [ ] **firewalld运行**: `systemctl is-active firewalld`
- [ ] **端口已开放**: `sudo firewall-cmd --list-ports`
- [ ] **防火墙重载**: `sudo firewall-cmd --reload`

**Ubuntu (ufw)**:
- [ ] **ufw启用**: `sudo ufw status`
- [ ] **端口规则**: `sudo ufw status verbose`
- [ ] **防火墙状态**: `sudo ufw enable`

---

## 🐳 Docker环境配置 ✅

### Docker安装
- [ ] **Docker安装**: `docker --version` 返回23.x版本
- [ ] **Docker运行**: `systemctl is-active docker`
- [ ] **Docker开机启动**: `systemctl is-enabled docker`
- [ ] **Docker权限测试**: `docker ps` 无错误

### Docker Compose安装
- [ ] **Docker Compose安装**: `docker-compose --version` 或 `docker compose version`
- [ ] **版本确认**: 2.5.x或更高版本
- [ ] **执行权限**: `/usr/local/bin/docker-compose` 有执行权限

### Docker配置
- [ ] **镜像加速器**: `/etc/docker/daemon.json` 配置国内源
- [ ] **日志配置**: 日志轮转配置
- [ ] **Docker重启**: `sudo systemctl restart docker`

---

## 📁 目录和权限配置 ✅

### 部署目录创建
- [ ] **主目录**: `/opt/moyu/` 存在且权限755
- [ ] **脚本目录**: `/opt/moyu/scripts/` 存在且权限755
- [ ] **日志目录**: `/opt/moyu/logs/` 存在且权限755
- [ ] **数据目录**: `/opt/moyu/data/` 存在且权限755
- [ ] **备份目录**: `/opt/moyu/backups/` 存在且权限755

### 文件权限设置
- [ ] **部署脚本**: `deploy.sh` 有执行权限
- [ ] **配置脚本**: `scripts/*.sh` 有执行权限
- [ ] **配置文件**: `.env` 和 `.webhook_secret` 权限600
- [ ] **目录所有者**: 所有者是root用户

### SELinux配置 (CentOS 7)
- [ ] **SELinux状态**: `getenforce` 显示Permissive或Disabled
- [ ] **或配置策略**: Docker访问目录的SELinux策略已设置

---

## 🪝 Webhook配置 ✅

### Webhook服务准备
- [ ] **Webhook端口9000未被占用**
- [ ] **防火墙开放9000端口**
- [ ] **systemd服务配置文件准备**
- [ ] **webhook处理脚本准备**

### GitHub Webhook准备
- [ ] **GitHub仓库访问权限**
- [ ] **Webhook Secret准备**
- [ ] **Webhook URL确认**: `http://114.132.189.90:9000/hooks/auto-deploy`

---

## 🔍 最终验证命令 ✅

在执行部署前，运行以下命令进行最终验证：

```bash
#!/bin/bash
echo "=== 最终部署前验证 ==="

# 1. 系统信息
echo "1. 系统信息:"
echo "   OS: $(cat /etc/redhat-release 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME)"
echo "   内存: $(free -h | grep Mem | awk '{print $2}')"
echo "   磁盘: $(df -h / | tail -1 | awk '{print $4}') 可用"
echo "   网络: $(ping -c 1 github.com >/dev/null 2>&1 && echo "正常" || echo "异常")"

# 2. Git配置
echo ""
echo "2. Git配置:"
echo "   版本: $(git --version 2>/dev/null || echo "未安装")"
echo "   用户: $(git config --global user.name 2>/dev/null || echo "未配置")"
echo "   邮箱: $(git config --global user.email 2>/dev/null || echo "未配置")"
echo "   SSH: $(ssh -T git@github.com 2>&1 | grep -q successfully && echo "连接正常" || echo "连接异常")"

# 3. Docker环境
echo ""
echo "3. Docker环境:"
echo "   版本: $(docker --version 2>/dev/null || echo "未安装")"
echo "   状态: $(systemctl is-active docker 2>/dev/null || echo "未运行")"
echo "   Compose: $(docker-compose --version 2>/dev/null || docker compose version 2>/dev/null || echo "未安装")"

# 4. 网络端口
echo ""
echo "4. 网络端口:"
echo "   80端口: $(netstat -tuln 2>/dev/null | grep ":80 " && echo "被占用" || echo "可用")"
echo "   9000端口: $(netstat -tuln 2>/dev/null | grep ":9000 " && echo "被占用" || echo "可用")"

# 5. 目录权限
echo ""
echo "5. 目录权限:"
if [[ -d "/opt/moyu" ]]; then
    echo "   部署目录: 存在 ($(stat -c "%a" /opt/moyu))"
    echo "   所有者: $(stat -c "%U:%G" /opt/moyu)"
else
    echo "   部署目录: 不存在"
fi

# 6. 脚本权限
echo ""
echo "6. 脚本权限:"
if [[ -f "/opt/moyu/deploy.sh" ]]; then
    echo "   deploy.sh: $(stat -c "%a" /opt/moyu/deploy.sh)"
else
    echo "   deploy.sh: 不存在"
fi

echo ""
echo "=== 验证完成 ==="
```

---

## 🚀 部署执行流程 ✅

### 标准部署流程
1. **环境准备**:
   ```bash
   # 克隆配置脚本
   git clone https://github.com/YYY2579/moyu.git /tmp/moyu-setup
   cd /tmp/moyu-setup
   ```

2. **Git配置** (首次部署必需):
   ```bash
   sudo chmod +x scripts/setup-git.sh
   sudo ./scripts/setup-git.sh
   ```

3. **权限验证**:
   ```bash
   sudo chmod +x scripts/verify-permissions.sh
   sudo ./scripts/verify-permissions.sh
   ```

4. **执行部署**:
   ```bash
   sudo chmod +x deploy.sh
   sudo ./deploy.sh
   ```

5. **配置Webhook** (自动部署必需):
   ```bash
   sudo chmod +x scripts/setup-webhook-service.sh
   sudo ./scripts/setup-webhook-service.sh
   ```

6. **验证部署**:
   ```bash
   curl -f http://114.132.189.90/health
   ```

### 快速部署命令
```bash
# 完整一键部署
git clone https://github.com/YYY2579/moyu.git /tmp/moyu-setup && \
cd /tmp/moyu-setup && \
sudo ./scripts/setup-git.sh && \
sudo ./deploy.sh && \
sudo ./scripts/setup-webhook-service.sh && \
curl -f http://114.132.189.90/health
```

---

## 📊 部署后验证 ✅

### 服务状态检查
- [ ] **网站访问**: http://114.132.189.90 正常打开
- [ ] **健康检查**: http://114.132.189.90/health 返回200
- [ ] **Docker容器**: `docker-compose ps` 显示所有服务Up
- [ ] **数据库连接**: MySQL容器正常运行
- [ ] **应用日志**: 无严重错误信息

### 功能测试
- [ ] **主页加载**: 主页正常显示
- [ ] **题库功能**: 题目练习功能正常
- [ ] **每日十题**: 每日题目功能正常
- [ ] **学习统计**: 统计页面正常显示
- [ ] **老板模式**: Alt+B快捷键正常工作

### Webhook测试
- [ ] **Webhook服务**: `systemctl status webhook` 运行正常
- [ ] **GitHub配置**: Webhook已正确配置
- [ ] **自动部署**: 推送代码触发自动部署
- [ ] **部署日志**: `/opt/moyu/logs/webhook.log` 记录正常

---

## 🆘 故障排除清单 ❌

### 常见问题和解决方案

**Git连接问题**:
- [ ] **检查SSH密钥**: `cat ~/.ssh/id_rsa.pub`
- [ ] **重新添加密钥**: GitHub设置页面重新添加
- [ ] **测试连接**: `ssh -T git@github.com`

**Docker权限问题**:
- [ ] **检查Docker状态**: `systemctl status docker`
- [ ] **用户组权限**: `usermod -aG docker $USER`
- [ ] **使用sudo**: `sudo docker ps`

**端口占用问题**:
- [ ] **查找占用进程**: `sudo netstat -tulnp | grep :80`
- [ ] **停止冲突服务**: `sudo systemctl stop nginx/apache2`
- [ ] **修改端口配置**: 编辑docker-compose.yml

**防火墙问题**:
- [ ] **检查防火墙状态**: `sudo firewall-cmd --state`
- [ ] **开放端口**: `sudo firewall-cmd --add-port=80/tcp`
- [ ] **重载配置**: `sudo firewall-cmd --reload`

**权限问题**:
- [ ] **运行权限脚本**: `sudo ./scripts/verify-permissions.sh`
- [ ] **检查文件权限**: `ls -la /opt/moyu/`
- [ ] **修复权限**: `sudo chown -R root:root /opt/moyu`

---

## 📞 技术支持

### 获取帮助
- **部署日志**: `/opt/moyu/logs/deploy.log`
- **Webhook日志**: `/opt/moyu/logs/webhook.log`
- **Docker日志**: `cd /opt/moyu && docker-compose logs -f`
- **系统日志**: `journalctl -xe`

### 联系方式
- **项目仓库**: https://github.com/YYY2579/moyu
- **问题反馈**: 提交GitHub Issues
- **文档更新**: 提交Pull Request

---

**检查清单版本**: v1.0  
**最后更新**: $(date)  
**适用环境**: CentOS 7 / Ubuntu 18.04+  

✅ **所有检查项完成后，即可开始生产环境部署！**