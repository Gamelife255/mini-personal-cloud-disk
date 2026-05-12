@echo off
chcp 65001 >nul
echo.
echo ╔══════════════════════════════════════════════════════════════╗
echo ║                    个人云盘一键启动脚本                        ║
echo ╚══════════════════════════════════════════════════════════════╝
echo.

:: 检查 Java 是否安装
java -version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ 错误：未检测到 Java，请先安装 Java 17+
    pause
    exit /b 1
)

:: 检查 Maven 是否安装
mvn -version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ 错误：未检测到 Maven，请先安装 Maven
    pause
    exit /b 1
)

:: 检查 Node.js 是否安装
node -v >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ 错误：未检测到 Node.js，请先安装 Node.js
    pause
    exit /b 1
)

echo ✅ 环境检查通过
echo.

:: 创建后端启动脚本
echo 创建后端启动脚本...
echo @echo off > start_backend.bat
echo cd disk-backend\backend >> start_backend.bat
echo mvn spring-boot:run >> start_backend.bat

:: 创建前端启动脚本
echo 创建前端启动脚本...
echo @echo off > start_frontend.bat
echo cd disk-frontend >> start_frontend.bat
echo npm run dev >> start_frontend.bat

echo.
echo 🚀 启动后端服务...
start "后端服务" cmd /k start_backend.bat

:: 等待后端启动
echo ⏳ 等待后端服务启动...
timeout /t 15 /nobreak >nul

echo.
echo 🚀 启动前端服务...
start "前端服务" cmd /k start_frontend.bat

:: 等待前端启动
echo ⏳ 等待前端服务启动...
timeout /t 5 /nobreak >nul

echo.
echo ✅ 服务启动完成！
echo.
echo ┌─────────────────────────────────────────────────────────────┐
echo │ 后端服务: http://localhost:8080                            │
echo │ 前端服务: http://localhost:5173                            │
echo └─────────────────────────────────────────────────────────────┘
echo.
echo 按任意键打开浏览器访问前端...
pause >nul

:: 打开浏览器
start http://localhost:5173

:: 清理临时脚本
del start_backend.bat start_frontend.bat /q >nul 2>&1

echo.
echo 🎉 个人云盘启动成功！
echo.
