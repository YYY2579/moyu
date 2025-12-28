# 摸鱼学习站 - 部署指南

## 🚀 一键部署命令

### 方式一：使用完整构建脚本（推荐）
```bash
# 克隆项目
git clone git@github.com:YYY2579/moyu.git moyu-study-2
cd moyu-study-2

# 执行一键部署脚本
chmod +x build-and-deploy.sh
./build-and-deploy.sh
```

### 方式二：手动部署
```bash
# 1. 拉取最新代码
git clone git@github.com:YYY2579/moyu.git moyu-study-2
cd moyu-study-2

# 2. 构建和启动服务
docker-compose down
docker-compose build --no-cache
docker-compose up -d

# 3. 查看服务状态
docker-compose ps

# 4. 查看日志
docker-compose logs -f
```

## 📋 服务说明

启动后包含以下服务：
- **Web服务**: http://114.132.189.90 (前端应用)
- **API服务**: http://114.132.189.90:8080 (后端API)
- **MySQL服务**: 端口3306 (数据库)
- **Webhook服务**: 端口9000 (自动部署)

## 🔧 管理命令

### 查看服务状态
```bash
docker-compose ps
```

### 查看日志
```bash
# 查看所有服务日志
docker-compose logs -f

# 查看特定服务日志
docker-compose logs -f web
docker-compose logs -f api
```

### 重启服务
```bash
# 重启所有服务
docker-compose restart

# 重启特定服务
docker-compose restart web
docker-compose restart api
```

### 更新应用
```bash
# 拉取最新代码
git pull origin main

# 重新构建和部署
docker-compose build --no-cache
docker-compose up -d
```

### 停止服务
```bash
docker-compose down
```

## 🌐 访问地址

部署完成后，可以通过以下地址访问：

- **主应用**: http://114.132.189.90
- **健康检查**: http://114.132.189.90/health
- **API文档**: http://114.132.189.90:8080/docs (如果有)

## 📱 移动端访问

应用完全支持移动端，可以直接在手机浏览器中访问：
- 在手机浏览器输入: http://114.132.189.90
- 支持添加到主屏幕作为PWA应用

## 🔍 故障排查

### 如果页面无法访问
```bash
# 检查服务是否运行
docker-compose ps

# 检查端口占用
netstat -tlnp | grep :80

# 查看nginx配置
docker-compose exec web nginx -t
```

### 如果构建失败
```bash
# 清理Docker缓存
docker system prune -a

# 重新构建
docker-compose build --no-cache
```

### 如果数据库连接问题
```bash
# 检查MySQL容器状态
docker-compose logs mysql

# 重启数据库
docker-compose restart mysql
```

## 🎯 主要功能

部署完成后，你可以使用以下功能：

### 📚 学习模块
- **Linux命令学习**: `/linux`
- **Docker技术学习**: `/docker`
- **题库练习**: `/practice`
- **学习进度**: `/progress`

### ✏️ 练习系统
- **随机练习**: 随机选择50道题目
- **每日挑战**: 每天20道精选题目
- **模拟考试**: 100道题完整考试

### 📊 进度追踪
- **学习统计**: 答题数、正确率、学习天数
- **成就系统**: 解锁学习徽章
- **历史记录**: 详细的学习轨迹

## 🎉 恭喜！

你的摸鱼学习站现在已经是一个功能完整、体验优秀的技术学习平台！

**主要特色**:
- 🎨 现代化UI设计
- 📱 完美移动端体验  
- 🚀 高性能优化
- 📖 丰富的学习内容
- 🎯 个性化学习路径

享受你的学习之旅吧！🐟