@echo off
echo 🔧 修复部署问题 (Windows版本)
echo ==========================

echo 🛑 停止并清理现有容器...
docker-compose down --remove-orphans 2>nul

echo 🗑️ 清理冲突容器...
docker stop webhook 2>nul
docker rm webhook 2>nul
docker stop web 2>nul  
docker rm web 2>nul
docker stop api 2>nul
docker rm api 2>nul
docker stop moyu-study-2-mysql-1 2>nul
docker rm moyu-study-2-mysql-1 2>nul

echo 🔫 检查端口占用...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :33066') do (
    echo 杀死占用33066端口的进程: %%a
    taskkill /F /PID %%a 2>nul
)

echo 🌐 清理Docker网络...
docker network prune -f 2>nul

echo 📝 设置环境变量...
(
echo MYSQL_ROOT_PASSWORD=moyu123456
echo MYSQL_DATABASE=moyu_study
echo MYSQL_USER=moyu_user
echo MYSQL_PASSWORD=moyu_user_password
echo.
echo JWT_SECRET=moyu_jwt_secret_key_2023
echo.
echo WEBHOOK_SECRET=moyu_webhook_secret_2023
) > .env

echo ✅ 环境变量已设置

echo 🔨 重新构建镜像...
docker-compose build --no-cache

echo 🚀 启动服务...
docker-compose up -d

echo ⏳ 等待服务启动...
timeout /t 20 /nobreak

echo 📊 检查服务状态...
docker-compose ps

echo 🎉 部署完成！
echo ==========================
echo 🌐 访问地址: http://114.132.189.90
echo 🔍 健康检查: http://114.132.189.90/health
echo.
echo 📋 管理命令:
echo   查看日志: docker-compose logs -f [service-name]
echo   重启服务: docker-compose restart [service-name]
echo   停止服务: docker-compose down
echo.
pause