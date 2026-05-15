@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: ============================================
::  Cloud Disk — Windows 一键部署脚本
::  用法: 双击运行 或 deploy.bat
::  自动完成: 环境检查 → 数据库初始化 → 构建前后端 → 启动服务
:: ============================================

title Cloud Disk — 一键部署

set "PROJECT_DIR=%~dp0.."
for %%i in ("%PROJECT_DIR%") do set "PROJECT_DIR=%%~fi"

echo.
echo ╔══════════════════════════════════════════╗
echo ║       Cloud Disk — Windows 一键部署       ║
echo ║       前后端构建 + 服务启动                ║
echo ╚══════════════════════════════════════════╝
echo.

set DEPLOY_START=%time:~0,2%%time:~3,2%%time:~6,2%

set "FRONTEND_DIR=%PROJECT_DIR%\disk-frontend"
set "BACKEND_DIR=%PROJECT_DIR%\disk-backend\backend"
set "STATIC_DIR=%BACKEND_DIR%\src\main\resources\static"

:: ============================================
:: 0. 收集部署信息
:: ============================================
echo ━━━ 部署前信息确认 ━━━
echo.
echo   项目目录: %PROJECT_DIR%
echo.

set /p SERVER_PORT="  → 后端服务端口 (直接回车默认 8080): "
if "%SERVER_PORT%"=="" set SERVER_PORT=8080

set /p MYSQL_PASS="  → MySQL root 密码 (直接回车使用默认): "
if "%MYSQL_PASS%"=="" set MYSQL_PASS=123456

:: 同步 application.yml 中的密码
set "APP_CONF=%PROJECT_DIR%\disk-backend\backend\src\main\resources\application.yml"
if exist "%APP_CONF%" (
    echo   正在同步 application.yml 数据库密码...
    powershell -NoProfile -Command ^
        "(Get-Content '%APP_CONF%' -Raw) -replace 'password: .*', 'password: %MYSQL_PASS%' | Set-Content '%APP_CONF%' -NoNewline"
    echo   [✓] application.yml 密码已同步
)

echo.
echo   服务端口: %SERVER_PORT%
echo   上传路径: ./upload/ (相对于后端工作目录)
echo.

:: ============================================
:: 1. 环境检查
:: ============================================
echo ━━━ [1/5] 检查运行环境 ━━━
echo.

:: Java
echo   检测 Java...
where java >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo   [✗] 未检测到 Java！请安装 JDK 17+
    echo       下载: https://adoptium.net/download/
    pause
    exit /b 1
)
for /f "tokens=3" %%a in ('java -version 2^>^&1 ^| findstr /i "version"') do set JAVA_VER=%%a
set JAVA_VER=%JAVA_VER:"=%
echo   [✓] Java: %JAVA_VER%

:: Node.js
echo   检测 Node.js...
where node >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo   [✗] 未检测到 Node.js！请安装 Node.js 18+
    echo       下载: https://nodejs.org/
    pause
    exit /b 1
)
for /f %%a in ('node -v') do set NODE_VER=%%a
echo   [✓] Node.js: %NODE_VER%

:: Maven
echo   检测 Maven...
where mvn >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo   [!] 未检测到 Maven，如果后端已有 JAR 包则跳过编译
    set MAVEN_MISSING=1
) else (
    for /f "tokens=3" %%a in ('mvn -v 2^>^&1 ^| findstr /i "Apache"') do set MVN_VER=%%a
    echo   [✓] Maven: !MVN_VER!
)

:: MySQL
echo   检测 MySQL...
where mysql >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo   [!] 未检测到 MySQL 命令行，跳过数据库初始化
    set MYSQL_MISSING=1
) else (
    echo   [✓] MySQL 客户端可用
)

:: Redis
echo   检测 Redis...
where redis-cli >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo   [!] 未检测到 Redis，验证码存储和JWT黑名单功能将不可用
    echo       下载: https://github.com/tporadowski/redis/releases (Windows)
    echo       或使用 Docker: docker run -d -p 6379:6379 redis:7-alpine
    set REDIS_MISSING=1
) else (
    rem 测试 Redis 是否在运行
    redis-cli ping >nul 2>&1
    if !ERRORLEVEL! EQU 0 (
        echo   [✓] Redis 已连接
    ) else (
        echo   [!] Redis 未运行，请在启动后端前启动 Redis 服务
        set REDIS_MISSING=1
    )
)

echo   [✓] 环境检查完成

:: ============================================
:: 2. 数据库初始化
:: ============================================
echo.
echo ━━━ [2/5] 初始化数据库 ━━━
echo.

set "SQL_FILE=%PROJECT_DIR%\sql\schema.sql"
if not exist "%SQL_FILE%" (
    echo   [!] 未找到 schema.sql，跳过数据库初始化
    goto :skip_db
)
if "%MYSQL_MISSING%"=="1" (
    echo   [!] MySQL 不可用，跳过数据库初始化
    goto :skip_db
)

echo   正在连接 MySQL 并执行建表脚本...
mysql -u root -p%MYSQL_PASS% -e "SELECT 1" 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo   [!] MySQL 连接失败，请检查密码是否正确
    echo   [!] 跳过数据库初始化，请稍后手动执行:
    echo       mysql -u root -p ^< sql\schema.sql
) else (
    mysql -u root -p%MYSQL_PASS% < "%SQL_FILE%" 2>nul
    if !ERRORLEVEL! EQU 0 (
        echo   [✓] 数据库表结构已初始化
    ) else (
        echo   [!] 数据库初始化可能已完成（已存在的表会跳过）
    )
)

:skip_db

:: ============================================
:: 3. 创建上传目录
:: ============================================
echo.
echo ━━━ [3/5] 检查上传目录 ━━━
echo.

:: 后端启动时会自动创建 ./upload/ 目录，这里只是提前确保
set "UPLOAD_DIR=%BACKEND_DIR%\upload"
if not exist "%UPLOAD_DIR%" (
    mkdir "%UPLOAD_DIR%" 2>nul
    echo   [✓] 上传目录已创建: %UPLOAD_DIR%
) else (
    echo   [✓] 上传目录已存在: %UPLOAD_DIR%
)

:: ============================================
:: 4. 构建前后端
:: ============================================
echo.
echo ━━━ [4/5] 构建项目 ━━━
echo.

:: --- 构建前端 ---
echo   ── 构建前端 ──
cd /d "%FRONTEND_DIR%"

if not exist "node_modules" (
    echo   正在安装前端依赖...
    call npm install
    if !ERRORLEVEL! NEQ 0 (
        echo   [✗] npm install 失败！
        pause
        exit /b 1
    )
)

echo   正在清理旧构建产物...
if exist "dist" rmdir /s /q "dist"

echo   正在构建前端...
call npx vite build
if !ERRORLEVEL! NEQ 0 (
    echo   [✗] 前端构建失败！
    pause
    exit /b 1
)
echo   [✓] 前端构建完成

:: 复制前端到后端 static 目录
echo   正在部署前端到后端 static 目录...
if exist "%STATIC_DIR%" rmdir /s /q "%STATIC_DIR%"
mkdir "%STATIC_DIR%"
xcopy /e /y "dist\*" "%STATIC_DIR%\" >nul
echo   [✓] 前端已部署到: %STATIC_DIR%

:: --- 构建后端 ---
echo.
echo   ── 构建后端 ──
cd /d "%BACKEND_DIR%"

if "%MAVEN_MISSING%"=="1" (
    echo   [!] Maven 不可用，跳过编译
    echo   [!] 将使用已有的 JAR 包（如存在）
    goto :skip_backend_build
)

echo   正在清理旧构建...
if exist "target" rmdir /s /q "target"

echo   正在编译后端 (首次需下载依赖，请耐心等待)...
call mvn clean package -DskipTests
if !ERRORLEVEL! NEQ 0 (
    echo   [✗] 后端构建失败！
    pause
    exit /b 1
)
echo   [✓] 后端编译完成

:skip_backend_build

:: 查找 JAR 文件
set "JAR_FILE="
for /r "target" %%f in (*.jar) do (
    if not "%%~nf"=="%%~nf" (
        echo %%f | findstr /v "sources" >nul
        if !ERRORLEVEL! EQU 0 set "JAR_FILE=%%f"
    )
)
if "%JAR_FILE%"=="" (
    for /r "." %%f in (*.jar) do (
        echo %%f | findstr /v "sources" >nul
        if !ERRORLEVEL! EQU 0 (
            set "JAR_FILE=%%f"
            goto :jar_found
        )
    )
    echo   [✗] 未找到 JAR 文件！
    pause
    exit /b 1
)
:jar_found
echo   [✓] JAR 文件: %JAR_FILE%

:: ============================================
:: 5. 启动服务
:: ============================================
echo.
echo ━━━ [5/5] 启动服务 ━━━
echo.

:: 检查端口是否被占用，如果有旧进程则先停止
echo   检查端口 %SERVER_PORT% 是否被占用...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":%SERVER_PORT% " ^| findstr "LISTENING"') do (
    echo   [!] 发现旧进程 PID: %%a，正在停止...
    taskkill /f /pid %%a >nul 2>&1
    echo   [✓] 旧进程已停止
)

:: 更新 application.yml 端口
powershell -NoProfile -Command ^
    "$content = Get-Content '%APP_CONF%' -Raw; $content = $content -replace '(?m)^  port: \d+', '  port: %SERVER_PORT%'; Set-Content '%APP_CONF%' $content -NoNewline"

:: 启动后端
echo   正在启动后端服务 (端口: %SERVER_PORT%)...
start "CloudDisk-Backend" /B java -jar -Dfile.encoding=UTF-8 "%JAR_FILE%"

:: 等待启动
echo   等待服务启动...
set /a COUNT=0
:wait_loop
timeout /t 2 /nobreak >nul
set /a COUNT+=2
netstat -ano | findstr ":%SERVER_PORT% " | findstr "LISTENING" >nul
if !ERRORLEVEL! EQU 0 (
    echo   [✓] 后端服务已启动 (耗时 !COUNT! 秒)
    goto :started
)
if !COUNT! LSS 60 goto :wait_loop

echo   [!] 服务启动超时，但进程可能仍在初始化中
echo   [!] 请稍后手动访问 http://localhost:%SERVER_PORT% 确认

:started
:: ============================================
:: 部署完成
:: ============================================
set DEPLOY_END=%time:~0,2%%time:~3,2%%time:~6,2%

echo.
echo ╔══════════════════════════════════════════╗
echo ║                                          ║
echo ║         🎉  部署全部完成！                ║
echo ║                                          ║
echo ╚══════════════════════════════════════════╝
echo.
echo   ┌──── 部署信息 ────────────────────────┐
echo   │                                        │
echo   │  访问地址:  http://localhost:%SERVER_PORT%
echo   │  项目目录:  %PROJECT_DIR%
echo   │  上传目录:  %UPLOAD_DIR%
echo   │                                        │
echo   └────────────────────────────────────────┘
echo.
echo   ┌──── 常用命令 ────────────────────────┐
echo   │                                        │
echo   │  更新并重新部署:                        │
echo   │    deploy\update.bat                    │
echo   │                                        │
echo   │  停止后端服务:                          │
echo   │    关闭 "CloudDisk-Backend" 窗口       │
echo   │    或运行:                              │
echo   │    for /f "tokens=5" %%%%a in           │
echo   │    ('netstat -ano ^| findstr           │
echo   │    ":%SERVER_PORT%" ^| findstr LISTENING')│
echo   │    do taskkill /f /pid %%%%a            │
echo   │                                        │
echo   └────────────────────────────────────────┘
echo.
echo   按任意键退出...
pause >nul
