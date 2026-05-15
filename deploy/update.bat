@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: ============================================
::  Cloud Disk — Windows 一键更新脚本
::  用法: 双击运行 或 update.bat
::  自动: git pull → 构建前后端 → 重启服务
:: ============================================

title Cloud Disk — 一键更新

set "PROJECT_DIR=%~dp0.."
for %%i in ("%PROJECT_DIR%") do set "PROJECT_DIR=%%~fi"

echo.
echo ╔══════════════════════════════════════════╗
echo ║       Cloud Disk — 一键更新               ║
echo ║       git pull + 构建 + 重启              ║
echo ╚══════════════════════════════════════════╝
echo.

set UPDATE_START=%time%

:: ============================================
:: 读取当前配置
:: ============================================
set "APP_CONF=%PROJECT_DIR%\disk-backend\backend\src\main\resources\application.yml"
set SERVER_PORT=8080
if exist "%APP_CONF%" (
    for /f "tokens=2" %%a in ('findstr "port:" "%APP_CONF%" ^| findstr /v "465"') do (
        set SERVER_PORT=%%a
    )
)

:: 检查后端是否在运行
echo   ── 检查当前服务状态 ──
set BACKEND_PID=
for /f "tokens=5" %%a in ('netstat -ano 2^>nul ^| findstr ":%SERVER_PORT% " ^| findstr "LISTENING"') do (
    set BACKEND_PID=%%a
)
if not "%BACKEND_PID%"=="" (
    echo   后端正在运行 (PID: %BACKEND_PID%)
) else (
    echo   后端未运行
)

:: ============================================
:: 1. Git Pull 拉取最新代码
:: ============================================
echo.
echo ━━━ [1/4] 拉取最新代码 ━━━

cd /d "%PROJECT_DIR%"

:: 检查是否是 git 仓库
if not exist ".git" (
    echo   [!] 不是 git 仓库，跳过 git pull
    goto :build
)

:: 保存本地修改
git stash --include-untracked -m "auto-stash-before-update-%date%" 2>nul
if !ERRORLEVEL! EQU 0 echo   [✓] 本地修改已暂存

echo   正在拉取远程代码...
git pull
if !ERRORLEVEL! NEQ 0 (
    echo   [!] git pull 失败，将使用本地代码继续构建
) else (
    echo   [✓] 代码已更新
    :: 显示最新 commit
    for /f "delims=" %%a in ('git log -1 --oneline') do echo   最新提交: %%a
)

:build

:: ============================================
:: 2. 构建前端
:: ============================================
echo.
echo ━━━ [2/4] 构建前端 ━━━

set "FRONTEND_DIR=%PROJECT_DIR%\disk-frontend"
set "BACKEND_DIR=%PROJECT_DIR%\disk-backend\backend"
set "STATIC_DIR=%BACKEND_DIR%\src\main\resources\static"

cd /d "%FRONTEND_DIR%"

if not exist "node_modules" (
    echo   正在安装前端依赖...
    call npm install
    if !ERRORLEVEL! NEQ 0 (
        echo   [✗] npm install 失败！
        pause
        exit /b 1
    )
) else (
    :: 检查 package.json 是否比 node_modules 新
    for %%f in (package.json) do set "PKG_TIME=%%~tf"
    for %%f in (node_modules) do set "NM_TIME=%%~tf"
    if "!PKG_TIME!" GTR "!NM_TIME!" (
        echo   [!] package.json 已更新，正在更新依赖...
        call npm install
    )
)

echo   正在构建前端...
if exist "dist" rmdir /s /q "dist"
call npx vite build
if !ERRORLEVEL! NEQ 0 (
    echo   [✗] 前端构建失败！
    pause
    exit /b 1
)
echo   [✓] 前端构建完成

:: 复制到后端 static 目录
echo   正在部署前端到后端 static 目录...
if exist "%STATIC_DIR%" rmdir /s /q "%STATIC_DIR%"
mkdir "%STATIC_DIR%"
xcopy /e /y "dist\*" "%STATIC_DIR%\" >nul
echo   [✓] 前端已部署

:: ============================================
:: 3. 构建后端
:: ============================================
echo.
echo ━━━ [3/4] 构建后端 ━━━

cd /d "%BACKEND_DIR%"

where mvn >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo   [!] Maven 不可用，跳过编译
    echo   [!] 将使用已有的 JAR 包（如存在）
    goto :skip_backend
)

echo   正在编译后端...
call mvn clean package -DskipTests
if !ERRORLEVEL! NEQ 0 (
    echo   [✗] 后端构建失败！
    pause
    exit /b 1
)
echo   [✓] 后端编译完成

:skip_backend

:: 查找 JAR 文件
set "JAR_FILE="
for /r "target" %%f in (*.jar) do (
    echo %%f | findstr /v "sources" >nul
    if !ERRORLEVEL! EQU 0 set "JAR_FILE=%%f"
)
if "%JAR_FILE%"=="" (
    for /r "." %%f in (*.jar) do (
        echo %%f | findstr /v "sources" >nul
        if !ERRORLEVEL! EQU 0 (
            set "JAR_FILE=%%f"
            goto :jar_found2
        )
    )
    echo   [✗] 未找到 JAR 文件！
    pause
    exit /b 1
)
:jar_found2
echo   [✓] JAR: %JAR_FILE%

:: ============================================
:: 4. 重启服务
:: ============================================
echo.
echo ━━━ [4/4] 重启服务 ━━━

:: 停止旧进程
set BACKEND_PID=
for /f "tokens=5" %%a in ('netstat -ano 2^>nul ^| findstr ":%SERVER_PORT% " ^| findstr "LISTENING"') do (
    set BACKEND_PID=%%a
)
if not "%BACKEND_PID%"=="" (
    echo   正在停止旧进程 (PID: %BACKEND_PID%)...
    taskkill /f /pid %BACKEND_PID% >nul 2>&1
    timeout /t 2 /nobreak >nul
    echo   [✓] 旧进程已停止
)

:: 启动新进程
echo   正在启动后端服务...
start "CloudDisk-Backend" /B java -jar -Dfile.encoding=UTF-8 "%JAR_FILE%"

:: 等待启动
echo   等待服务启动...
set /a COUNT=0
:wait_loop2
timeout /t 2 /nobreak >nul
set /a COUNT+=2
netstat -ano | findstr ":%SERVER_PORT% " | findstr "LISTENING" >nul
if !ERRORLEVEL! EQU 0 (
    echo   [✓] 服务已启动 (耗时 !COUNT! 秒)
    goto :update_done
)
if !COUNT! LSS 60 goto :wait_loop2

echo   [!] 服务启动超时，请手动检查

:update_done
set UPDATE_END=%time%

echo.
echo ╔══════════════════════════════════════════╗
echo ║         更新完成！                        ║
echo ╚══════════════════════════════════════════╝
echo.
echo   访问地址: http://localhost:%SERVER_PORT%
echo   开始时间: %UPDATE_START%
echo   结束时间: %UPDATE_END%
echo.
echo   按任意键退出...
pause >nul
